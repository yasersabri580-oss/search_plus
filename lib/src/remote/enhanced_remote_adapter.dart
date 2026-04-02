import 'dart:async';

import '../adapters/search_adapter.dart';
import '../cache/search_cache.dart';
import '../core/search_result.dart';
import '../utils/search_logger.dart';
import 'cancellable_operation.dart';
import 'query_deduplicator.dart';
import 'remote_search_config.dart';
import 'retry_strategy.dart';

/// Callback to transform a search query before it is sent to the API.
typedef RequestTransformer = Map<String, dynamic> Function(
  String query,
  int limit,
  int offset,
  RemoteSearchConfig config,
);

/// Callback to parse raw API response data into search results.
typedef ResponseParser<T> = List<SearchResult<T>> Function(
  dynamic responseData,
);

/// Callback for analytics/tracking of search events.
typedef SearchAnalyticsCallback = void Function(SearchAnalyticsEvent event);

/// Represents a search analytics event.
class SearchAnalyticsEvent {
  /// Creates a search analytics event.
  const SearchAnalyticsEvent({
    required this.type,
    required this.query,
    this.resultCount,
    this.duration,
    this.error,
    this.metadata,
  });

  /// The type of event.
  final SearchAnalyticsEventType type;

  /// The search query.
  final String query;

  /// Number of results returned.
  final int? resultCount;

  /// Duration of the search operation.
  final Duration? duration;

  /// Error if the search failed.
  final Object? error;

  /// Additional metadata.
  final Map<String, dynamic>? metadata;
}

/// Types of analytics events.
enum SearchAnalyticsEventType {
  /// A search was started.
  searchStarted,

  /// A search completed successfully.
  searchCompleted,

  /// A search failed.
  searchFailed,

  /// Results were served from cache.
  cacheHit,

  /// A search was cancelled.
  searchCancelled,

  /// A retry was attempted.
  retryAttempted,
}

/// An elite remote search adapter with advanced networking capabilities.
///
/// Combines retry strategies, request cancellation, query deduplication,
/// caching, analytics, and custom request/response transformers into
/// a single, production-ready adapter.
///
/// ```dart
/// final adapter = EnhancedRemoteAdapter<Product>(
///   searchFunction: (query, limit, offset) async {
///     final response = await http.get(
///       Uri.parse('https://api.example.com/search?q=$query&limit=$limit&offset=$offset'),
///     );
///     return parseProducts(response.body);
///   },
///   config: RemoteSearchConfig(
///     retryCount: 3,
///     enableCache: true,
///     cacheTtl: Duration(minutes: 5),
///     timeout: Duration(seconds: 10),
///   ),
/// );
/// ```
class EnhancedRemoteAdapter<T> extends SearchAdapter<T> {
  /// Creates an enhanced remote adapter.
  EnhancedRemoteAdapter({
    required this.searchFunction,
    this.suggestFunction,
    this.config = const RemoteSearchConfig(),
    this.requestTransformer,
    this.onAnalytics,
    this.rankingHook,
  }) {
    if (config.retryCount > 0) {
      _retryStrategy = RetryStrategy(
        maxAttempts: config.retryCount,
        baseDelay: config.retryDelay,
        useExponentialBackoff: config.useExponentialBackoff,
        maxDelay: config.maxBackoffDelay,
      );
    }
    if (config.enableCache) {
      _cache = MemorySearchCache<SearchResult<T>>(
        ttl: config.cacheTtl,
        maxEntries: 100,
      );
    }
    if (config.enableDeduplication) {
      _deduplicator = QueryDeduplicator<List<SearchResult<T>>>();
    }
  }

  /// The async function that performs the actual remote search.
  final Future<List<SearchResult<T>>> Function(
    String query,
    int limit,
    int offset,
  ) searchFunction;

  /// Optional function to provide remote suggestions.
  final Future<List<String>> Function(String query)? suggestFunction;

  /// Configuration for this adapter.
  final RemoteSearchConfig config;

  /// Optional transformer for outgoing search requests.
  final RequestTransformer? requestTransformer;

  /// Optional analytics callback.
  final SearchAnalyticsCallback? onAnalytics;

  /// Optional hook to re-rank results after fetching.
  ///
  /// Useful for AI-powered ranking or custom business logic.
  final List<SearchResult<T>> Function(
    List<SearchResult<T>> results,
    String query,
  )? rankingHook;

  RetryStrategy? _retryStrategy;
  MemorySearchCache<SearchResult<T>>? _cache;
  QueryDeduplicator<List<SearchResult<T>>>? _deduplicator;
  CancellableOperation<List<SearchResult<T>>>? _currentOperation;

  @override
  Future<List<SearchResult<T>>> search(
    String query, {
    int limit = 50,
    int offset = 0,
  }) async {
    final stopwatch = Stopwatch()..start();

    // Cancel previous in-flight request
    if (config.enableRequestCancellation && _currentOperation != null) {
      if (!_currentOperation!.isCompleted) {
        _currentOperation!.cancel();
        _trackAnalytics(SearchAnalyticsEventType.searchCancelled, query);
        SearchLogger.debug(
          '[EnhancedRemote] Cancelled previous request',
        );
      }
    }

    // Check cache first
    if (_cache != null) {
      final cacheKey = _buildCacheKey(query, limit, offset);
      final cached = await _cache!.get(cacheKey);
      if (cached != null) {
        stopwatch.stop();
        _trackAnalytics(
          SearchAnalyticsEventType.cacheHit,
          query,
          resultCount: cached.length,
          duration: stopwatch.elapsed,
        );
        return cached;
      }
    }

    _trackAnalytics(SearchAnalyticsEventType.searchStarted, query);

    try {
      List<SearchResult<T>> results;

      // Build the operation
      Future<List<SearchResult<T>>> executeSearch() async {
        return _executeWithTimeout(query, limit, offset);
      }

      // Apply deduplication
      if (_deduplicator != null) {
        final dedupeKey = _buildCacheKey(query, limit, offset);
        results = await _deduplicator!.deduplicate(dedupeKey, () {
          return _executeWithRetry(executeSearch);
        });
      } else {
        results = await _executeWithRetry(executeSearch);
      }

      // Mark results as remote
      results = results
          .map((r) => r.copyWith(source: SearchResultSource.remote))
          .toList();

      // Apply ranking hook
      if (rankingHook != null) {
        results = rankingHook!(results, query);
        SearchLogger.debug(
          '[EnhancedRemote] Applied ranking hook, ${results.length} results',
        );
      }

      // Cache results
      if (_cache != null) {
        final cacheKey = _buildCacheKey(query, limit, offset);
        await _cache!.put(cacheKey, results);
      }

      stopwatch.stop();
      _trackAnalytics(
        SearchAnalyticsEventType.searchCompleted,
        query,
        resultCount: results.length,
        duration: stopwatch.elapsed,
      );

      SearchLogger.adapterResults(
        'EnhancedRemoteAdapter',
        results.length,
        stopwatch.elapsed,
      );

      return results;
    } catch (e) {
      stopwatch.stop();

      if (e is CancellationException) {
        return const [];
      }

      _trackAnalytics(
        SearchAnalyticsEventType.searchFailed,
        query,
        duration: stopwatch.elapsed,
        error: e,
      );

      SearchLogger.adapterError('EnhancedRemoteAdapter', e);
      rethrow;
    }
  }

  Future<List<SearchResult<T>>> _executeWithTimeout(
    String query,
    int limit,
    int offset,
  ) async {
    final operation = CancellableOperation<List<SearchResult<T>>>(
      () => searchFunction(query, limit, offset),
    );

    _currentOperation = operation;

    return operation.future.timeout(
      config.timeout,
      onTimeout: () {
        operation.cancel();
        throw TimeoutException(
          'Search timed out after ${config.timeout.inSeconds}s',
          config.timeout,
        );
      },
    );
  }

  Future<List<SearchResult<T>>> _executeWithRetry(
    Future<List<SearchResult<T>>> Function() operation,
  ) async {
    if (_retryStrategy != null) {
      return _retryStrategy!.execute(operation);
    }
    return operation();
  }

  @override
  Future<List<String>> suggest(String query) async {
    if (suggestFunction != null) {
      try {
        return await suggestFunction!(query);
      } catch (e) {
        SearchLogger.warning(
          '[EnhancedRemote] Suggestion failed: $e',
        );
        return const [];
      }
    }
    return const [];
  }

  String _buildCacheKey(String query, int limit, int offset) =>
      '$query:$limit:$offset';

  void _trackAnalytics(
    SearchAnalyticsEventType type,
    String query, {
    int? resultCount,
    Duration? duration,
    Object? error,
  }) {
    onAnalytics?.call(SearchAnalyticsEvent(
      type: type,
      query: query,
      resultCount: resultCount,
      duration: duration,
      error: error,
    ));
  }

  /// Clears the internal cache.
  Future<void> clearCache() async {
    await _cache?.clear();
  }

  /// Returns current cache statistics.
  Future<int> get cacheSize async => await _cache?.size ?? 0;

  @override
  void dispose() {
    _currentOperation?.cancel();
    _cache?.dispose();
    _deduplicator?.clear();
  }
}
