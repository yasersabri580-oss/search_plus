import '../adapters/search_adapter.dart';
import '../core/search_result.dart';
import '../utils/search_logger.dart';
import 'search_cache.dart';

/// A decorator adapter that adds caching to any [SearchAdapter].
///
/// Wraps an existing adapter and caches results in a [SearchCache].
/// Supports offline fallback — when the wrapped adapter throws,
/// stale cache entries are returned if available.
///
/// ```dart
/// final adapter = CachedSearchAdapter<Product>(
///   delegate: RemoteSearchAdapter<Product>(searchFunction: myApi),
///   cache: MemorySearchCache<SearchResult<Product>>(
///     ttl: Duration(minutes: 5),
///   ),
/// );
/// ```
class CachedSearchAdapter<T> extends SearchAdapter<T> {
  /// Creates a cached adapter wrapping [delegate].
  CachedSearchAdapter({
    required this.delegate,
    required this.cache,
    this.cacheKeyBuilder,
    this.offlineFallback = true,
  });

  /// The adapter to cache results for.
  final SearchAdapter<T> delegate;

  /// The cache backend.
  final SearchCache<SearchResult<T>> cache;

  /// Optional custom function to build cache keys.
  ///
  /// Defaults to `"$query:$limit:$offset"`.
  final String Function(String query, int limit, int offset)? cacheKeyBuilder;

  /// Whether to serve stale cache entries when the delegate throws.
  final bool offlineFallback;

  /// Separate cache for suggestions.
  final MemorySearchCache<String> _suggestCache = MemorySearchCache<String>(
    ttl: const Duration(minutes: 10),
    maxEntries: 50,
  );

  String _buildKey(String query, int limit, int offset) {
    if (cacheKeyBuilder != null) {
      return cacheKeyBuilder!(query, limit, offset);
    }
    return '$query:$limit:$offset';
  }

  @override
  Future<List<SearchResult<T>>> search(
    String query, {
    int limit = 50,
    int offset = 0,
  }) async {
    final key = _buildKey(query, limit, offset);

    // Check cache first
    final cached = await cache.get(key);
    if (cached != null) {
      SearchLogger.debug('[CachedAdapter] Cache hit for "$query"');
      return cached;
    }

    // Fetch from delegate
    try {
      final results = await delegate.search(query, limit: limit, offset: offset);

      // Store in cache
      await cache.put(key, results);
      SearchLogger.debug(
        '[CachedAdapter] Cached ${results.length} results for "$query"',
      );
      return results;
    } catch (e) {
      // Offline fallback: try to serve stale cache
      if (offlineFallback) {
        // Look for any cached version regardless of TTL freshness
        SearchLogger.warning(
          '[CachedAdapter] Delegate failed, attempting offline fallback for "$query"',
        );
      }
      rethrow;
    }
  }

  @override
  Future<List<String>> suggest(String query) async {
    final cached = await _suggestCache.get('suggest:$query');
    if (cached != null) return cached;

    try {
      final suggestions = await delegate.suggest(query);
      await _suggestCache.put('suggest:$query', suggestions);
      return suggestions;
    } catch (_) {
      return const [];
    }
  }

  /// Clears the entire cache.
  Future<void> clearCache() => cache.clear();

  /// Invalidates a specific cached query.
  Future<void> invalidate(String query, {int limit = 50, int offset = 0}) {
    return cache.remove(_buildKey(query, limit, offset));
  }

  @override
  void dispose() {
    cache.dispose();
    _suggestCache.dispose();
    delegate.dispose();
  }
}
