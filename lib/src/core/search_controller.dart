import 'dart:async';

import 'package:flutter/foundation.dart';

import '../adapters/search_adapter.dart';
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
  });

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
  final _stateController = StreamController<SearchState<T>>.broadcast();

  /// Stream of search state changes.
  Stream<SearchState<T>> get stateStream => _stateController.stream;

  SearchState<T> _currentState = const SearchState();

  /// The current search state.
  SearchState<T> get currentState => _currentState;

  /// Performs a debounced search with the given [query].
  ///
  /// Cancels any pending search. Only the latest query's results are emitted.
  void search(String query) {
    _debounceTimer?.cancel();

    if (query.length < minQueryLength) {
      _emit(_currentState.copyWith(
        query: query,
        results: const [],
        sections: const [],
        status: query.isEmpty ? SearchStatus.idle : SearchStatus.empty,
      ));
      return;
    }

    _emit(_currentState.copyWith(
      query: query,
      status: SearchStatus.loading,
    ));

    _debounceTimer = Timer(debounceDuration, () {
      _executeSearch(query);
    });
  }

  /// Performs an immediate search without debouncing.
  Future<void> searchImmediate(String query) async {
    _debounceTimer?.cancel();
    if (query.length < minQueryLength) {
      _emit(_currentState.copyWith(
        query: query,
        results: const [],
        status: query.isEmpty ? SearchStatus.idle : SearchStatus.empty,
      ));
      return;
    }
    await _executeSearch(query);
  }

  Future<void> _executeSearch(String query) async {
    final requestId = ++_requestId;

    try {
      final results = await adapter.search(query, limit: maxResults);

      // Only emit if this is still the latest request (cancellation)
      if (requestId != _requestId) return;

      if (results.isEmpty) {
        _emit(_currentState.copyWith(
          query: query,
          results: const [],
          sections: const [],
          status: SearchStatus.empty,
        ));
      } else {
        _emit(_currentState.copyWith(
          query: query,
          results: results,
          status: SearchStatus.success,
        ));
      }
    } catch (e) {
      if (requestId != _requestId) return;

      _emit(_currentState.copyWith(
        query: query,
        status: SearchStatus.error,
        error: e.toString(),
      ));
    }
  }

  /// Fetches search suggestions for the given [query].
  Future<List<String>> suggest(String query) async {
    try {
      return await adapter.suggest(query);
    } catch (_) {
      return const [];
    }
  }

  /// Clears the current search state.
  void clear() {
    _debounceTimer?.cancel();
    _requestId++;
    _emit(const SearchState());
  }

  void _emit(SearchState<T> state) {
    _currentState = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  /// Disposes resources.
  void dispose() {
    _debounceTimer?.cancel();
    _stateController.close();
    adapter.dispose();
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
    _subscription = _engine.stateStream.listen((state) {
      _state = state.copyWith(history: _history);
      notifyListeners();
    });
  }

  final SearchEngine<T> _engine;
  late final StreamSubscription<SearchState<T>> _subscription;
  SearchState<T> _state = const SearchState();
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
  void search(String query) => _engine.search(query);

  /// Performs an immediate search.
  Future<void> searchImmediate(String query) =>
      _engine.searchImmediate(query);

  /// Gets suggestions for the current query.
  Future<List<String>> suggest(String query) => _engine.suggest(query);

  /// Adds a query to search history.
  void addToHistory(String query) {
    if (query.trim().isEmpty) return;
    _history.remove(query);
    _history.insert(0, query);
    if (_history.length > maxHistoryItems) {
      _history.removeLast();
    }
    _state = _state.copyWith(history: List.unmodifiable(_history));
    notifyListeners();
  }

  /// Clears search history.
  void clearHistory() {
    _history.clear();
    _state = _state.copyWith(history: const []);
    notifyListeners();
  }

  /// Clears the current search.
  void clear() => _engine.clear();

  @override
  void dispose() {
    _subscription.cancel();
    _engine.dispose();
    super.dispose();
  }
}
