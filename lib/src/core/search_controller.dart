import 'dart:async';

import 'package:flutter/foundation.dart';

import '../adapters/search_adapter.dart';
import '../utils/search_logger.dart';
import 'search_result.dart';
import 'search_state.dart';

/// The core search engine that coordinates adapters and manages search logic.
///
/// Handles debouncing, cancellation, and state management.
class SearchEngine<T> {
  /// Creates a search engine with the given [adapter].
  SearchEngine({
    required this.adapter,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.minQueryLength = 1,
    this.maxResults = 50,
  }) {
    // DEBUG: Log engine creation
    SearchLogger.debug(
      '[SearchEngine] Created with adapter=${adapter.runtimeType}, '
      'debounceDuration=$debounceDuration, minQueryLength=$minQueryLength, maxResults=$maxResults',
    );
  }

  /// The search adapter to use.
  final SearchAdapter<T> adapter;

  /// Duration to debounce search queries.
  final Duration debounceDuration;

  /// Minimum query length before search triggers.
  final int minQueryLength;

  /// Maximum number of results to return.
  final int maxResults;

  Timer? _debounceTimer;
  int _requestId = 0;

  /// Stream controller for search states.
  ///
  /// Uses a synchronous controller so that listeners are notified immediately
  /// when state changes, ensuring that awaiting [searchImmediate] or calling
  /// [clear] reflects the updated state without a microtask delay.
  final _stateController = StreamController<SearchState<T>>.broadcast(
    sync: true,
  );

  /// Stream of search state changes.
  Stream<SearchState<T>> get stateStream => _stateController.stream;

  SearchState<T> _currentState = SearchState();

  /// The current search state.
  SearchState<T> get currentState => _currentState;

  /// Performs a debounced search with the given [query].
  ///
  /// Cancels any pending search. Only the latest query's results are emitted.
  void search(String query) {
    // DEBUG: Entry
    SearchLogger.debug('[SearchEngine.search] Called with query="$query"');
    _debounceTimer?.cancel();
    if (_debounceTimer?.isActive == true) {
      SearchLogger.debug(
        '[SearchEngine.search] Cancelled previous debounce timer',
      );
    }
    SearchLogger.searchQuery(query);

    if (query.length < minQueryLength) {
      SearchLogger.debug(
        '[SearchEngine.search] Query too short (${query.length} < $minQueryLength) -> idle/empty',
      );
      _emit(
        _currentState.copyWith(
          query: query,
          results: const [],
          sections: const [],
          status: query.isEmpty ? SearchStatus.idle : SearchStatus.empty,
        ),
      );
      return;
    }

    SearchLogger.debug(
      '[SearchEngine.search] Starting debounce timer for ${debounceDuration.inMilliseconds}ms',
    );
    _emit(_currentState.copyWith(query: query, status: SearchStatus.loading));

    _debounceTimer = Timer(debounceDuration, () {
      SearchLogger.debug(
        '[SearchEngine.search] Debounce timer elapsed, executing search for "$query"',
      );
      _executeSearch(query);
    });
  }

  /// Performs an immediate search without debouncing.
  Future<void> searchImmediate(String query) async {
    // DEBUG: Entry
    SearchLogger.debug(
      '[SearchEngine.searchImmediate] Called with query="$query"',
    );
    _debounceTimer?.cancel();
    if (_debounceTimer?.isActive == true) {
      SearchLogger.debug(
        '[SearchEngine.searchImmediate] Cancelled pending debounce timer',
      );
    }
    SearchLogger.searchQuery(query, immediate: true);
    if (query.length < minQueryLength) {
      SearchLogger.debug(
        '[SearchEngine.searchImmediate] Query too short -> idle/empty',
      );
      _emit(
        _currentState.copyWith(
          query: query,
          results: const [],
          status: query.isEmpty ? SearchStatus.idle : SearchStatus.empty,
        ),
      );
      return;
    }
    await _executeSearch(query);
  }

  Future<void> _executeSearch(String query) async {
    // DEBUG: Entry
    SearchLogger.debug(
      '[SearchEngine._executeSearch] Starting for query="$query"',
    );
    final requestId = ++_requestId;
    SearchLogger.debug(
      '[SearchEngine._executeSearch] Assigned requestId=$requestId (current _requestId=$_requestId)',
    );

    final stopwatch = Stopwatch()..start();
    try {
      SearchLogger.debug(
        '[SearchEngine._executeSearch] Calling adapter.search with limit=$maxResults',
      );
      final results = await adapter.search(query, limit: maxResults);
      stopwatch.stop();
      SearchLogger.adapterResults(
        adapter.runtimeType.toString(),
        results.length,
        stopwatch.elapsed,
      );

      // Only emit if this is still the latest request (cancellation)
      if (requestId != _requestId) {
        SearchLogger.debug(
          '[SearchEngine._executeSearch] Request $requestId cancelled (current requestId=$_requestId) -> ignoring results',
        );
        return;
      }

      if (results.isEmpty) {
        SearchLogger.debug(
          '[SearchEngine._executeSearch] No results -> empty state',
        );
        _emit(
          _currentState.copyWith(
            query: query,
            results: const [],
            sections: const [],
            status: SearchStatus.empty,
          ),
        );
      } else {
        SearchLogger.debug(
          '[SearchEngine._executeSearch] Got ${results.length} results -> success state',
        );
        _emit(
          _currentState.copyWith(
            query: query,
            results: results,
            status: SearchStatus.success,
            hasMoreResults: results.length >= maxResults,
            currentPage: 0,
          ),
        );
      }
    } catch (e, st) {
      stopwatch.stop();
      SearchLogger.debug('[SearchEngine._executeSearch] Exception caught: $e');
      SearchLogger.adapterError(
        adapter.runtimeType.toString(),
        e,
        stackTrace: st,
      );

      if (requestId != _requestId) {
        SearchLogger.debug(
          '[SearchEngine._executeSearch] Error for stale request $requestId -> ignoring',
        );
        return;
      }

      SearchLogger.debug(
        '[SearchEngine._executeSearch] Emitting error state: $e',
      );
      _emit(
        _currentState.copyWith(
          query: query,
          status: SearchStatus.error,
          error: e.toString(),
        ),
      );
    }
  }

  /// Fetches search suggestions for the given [query].
  Future<List<String>> suggest(String query) async {
    SearchLogger.debug('[SearchEngine.suggest] Called with query="$query"');
    try {
      final suggestions = await adapter.suggest(query);
      SearchLogger.debug(
        '[Suggest] ${suggestions.length} suggestion(s) for "$query"',
      );
      SearchLogger.debug(
        '[SearchEngine.suggest] Returning suggestions: $suggestions',
      );
      return suggestions;
    } catch (e) {
      SearchLogger.warning('[Suggest] failed for "$query": $e');
      SearchLogger.debug(
        '[SearchEngine.suggest] Returning empty list due to error',
      );
      return const [];
    }
  }

  /// Clears the current search state.
  void clear() {
    SearchLogger.debug('[SearchEngine.clear] Called');
    _debounceTimer?.cancel();
    if (_debounceTimer?.isActive == true) {
      SearchLogger.debug(
        '[SearchEngine.clear] Cancelled active debounce timer',
      );
    }
    final oldRequestId = _requestId;
    _requestId++;
    SearchLogger.info('[Search] clear');
    SearchLogger.debug(
      '[SearchEngine.clear] Incremented requestId from $oldRequestId to $_requestId',
    );
    _emit(const SearchState());
  }

  void _emit(SearchState<T> state) {
    // DEBUG: Log emission
    SearchLogger.debug(
      '[SearchEngine._emit] Emitting state: status=${state.status}, query="${state.query}", results=${state.results.length}, error=${state.error}',
    );
    final oldStatus = _currentState.status;
    _currentState = state;
    if (oldStatus != state.status) {
      SearchLogger.stateTransition(
        oldStatus.name,
        state.status.name,
        query: state.query,
      );
      SearchLogger.debug(
        '[SearchEngine._emit] Status transition: ${oldStatus.name} -> ${state.status.name}',
      );
    }
    if (!_stateController.isClosed) {
      _stateController.add(state);
      SearchLogger.debug('[SearchEngine._emit] State added to stream');
    } else {
      SearchLogger.debug(
        '[SearchEngine._emit] State controller is closed, cannot add state',
      );
    }
  }

  /// Disposes resources.
  void dispose() {
    SearchLogger.debug('[SearchEngine.dispose] Called');
    _debounceTimer?.cancel();
    _stateController.close();
    adapter.dispose();
    SearchLogger.debug('[SearchEngine.dispose] Resources disposed');
  }
}

/// A [ChangeNotifier]-based controller for use with Flutter widgets.
///
/// Wraps [SearchEngine] and provides a reactive API.
///
/// ```dart
/// final controller = SearchPlusController<Product>(
///   adapter: myAdapter,
/// );
///
/// // In a widget
/// ListenableBuilder(
///   listenable: controller,
///   builder: (context, _) {
///     final state = controller.state;
///     // Build UI based on state
///   },
/// );
/// ```
class SearchPlusController<T> extends ChangeNotifier {
  /// Creates a search controller with the given [adapter].
  SearchPlusController({
    required SearchAdapter<T> adapter,
    Duration debounceDuration = const Duration(milliseconds: 300),
    int minQueryLength = 1,
    int maxResults = 50,
    this.maxHistoryItems = 10,
  }) : _engine = SearchEngine<T>(
         adapter: adapter,
         debounceDuration: debounceDuration,
         minQueryLength: minQueryLength,
         maxResults: maxResults,
       ) {
    SearchLogger.debug(
      '[SearchPlusController] Created with maxHistoryItems=$maxHistoryItems',
    );
    _subscription = _engine.stateStream.listen((state) {
      SearchLogger.debug(
        '[SearchPlusController] Received state from engine: status=${state.status}, query="${state.query}"',
      );
      _state = state.copyWith(history: _history, error: state.error);
      notifyListeners();
      SearchLogger.debug('[SearchPlusController] Notified listeners');
    });
  }

  final SearchEngine<T> _engine;
  late final StreamSubscription<SearchState<T>> _subscription;
  SearchState<T> _state = SearchState();
  final List<String> _history = [];

  /// Maximum number of history items to keep.
  final int maxHistoryItems;

  /// The current search state.
  SearchState<T> get state => _state;

  /// Convenience accessors.
  String get query => _state.query;
  List<SearchResult<T>> get results => _state.results;
  bool get isLoading => _state.isLoading;
  bool get hasError => _state.hasError;
  bool get hasResults => _state.hasResults;
  SearchStatus get status => _state.status;

  /// Performs a debounced search.
  void search(String query) {
    SearchLogger.debug(
      '[SearchPlusController.search] Delegating to engine with query="$query"',
    );
    _engine.search(query);
  }

  /// Performs an immediate search.
  Future<void> searchImmediate(String query) {
    SearchLogger.debug(
      '[SearchPlusController.searchImmediate] Delegating to engine with query="$query"',
    );
    return _engine.searchImmediate(query);
  }

  /// Gets suggestions for the current query.
  Future<List<String>> suggest(String query) {
    SearchLogger.debug(
      '[SearchPlusController.suggest] Delegating to engine with query="$query"',
    );
    return _engine.suggest(query);
  }

  /// Adds a query to search history.
  void addToHistory(String query) {
    SearchLogger.debug(
      '[SearchPlusController.addToHistory] Adding query="$query"',
    );
    if (query.trim().isEmpty) {
      SearchLogger.debug(
        '[SearchPlusController.addToHistory] Query empty, ignoring',
      );
      return;
    }
    _history.remove(query);
    _history.insert(0, query);
    if (_history.length > maxHistoryItems) {
      final removed = _history.removeLast();
      SearchLogger.debug(
        '[SearchPlusController.addToHistory] Exceeded maxHistoryItems, removed "$removed"',
      );
    }
    _state = _state.copyWith(history: List.unmodifiable(_history));
    notifyListeners();
    SearchLogger.debug(
      '[SearchPlusController.addToHistory] History now: $_history',
    );
  }

  /// Clears search history.
  void clearHistory() {
    SearchLogger.debug(
      '[SearchPlusController.clearHistory] Clearing history (was $_history)',
    );
    _history.clear();
    _state = _state.copyWith(history: const []);
    notifyListeners();
    SearchLogger.debug('[SearchPlusController.clearHistory] History cleared');
  }

  /// Clears the current search.
  void clear() {
    SearchLogger.debug('[SearchPlusController.clear] Delegating to engine');
    _engine.clear();
  }

  /// Loads the next page of results for the current query.
  ///
  /// Only works when [state.hasMoreResults] is `true` and the current
  /// query is not empty. Appends new results to the existing list.
  Future<void> loadMore() async {
    if (!_state.hasMoreResults || _state.query.isEmpty) return;
    SearchLogger.debug(
      '[SearchPlusController.loadMore] Loading more for query="${_state.query}"',
    );

    final nextOffset = _state.results.length;
    try {
      final moreResults = await _engine.adapter.search(
        _state.query,
        limit: _engine.maxResults,
        offset: nextOffset,
      );

      final allResults = [..._state.results, ...moreResults];
      _state = _state.copyWith(
        results: allResults,
        hasMoreResults: moreResults.length >= _engine.maxResults,
        currentPage: _state.currentPage + 1,
        error: null,
      );
      notifyListeners();
      SearchLogger.debug(
        '[SearchPlusController.loadMore] Now have ${allResults.length} results, page ${_state.currentPage}',
      );
    } catch (e) {
      SearchLogger.warning('[SearchPlusController.loadMore] Failed: $e');
    }
  }

  @override
  void dispose() {
    SearchLogger.debug('[SearchPlusController.dispose] Called');
    _subscription.cancel();
    _engine.dispose();
    super.dispose();
    SearchLogger.debug('[SearchPlusController.dispose] Disposed');
  }
}
