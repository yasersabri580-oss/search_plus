import 'dart:async';
import 'dart:collection';

import '../utils/search_logger.dart';

/// An entry in the search cache.
class CacheEntry<T> {
  /// Creates a cache entry.
  CacheEntry({
    required this.data,
    required this.createdAt,
    this.ttl,
  });

  /// The cached data.
  final T data;

  /// When this entry was created.
  final DateTime createdAt;

  /// Optional time-to-live for this entry.
  final Duration? ttl;

  /// Whether this entry has expired.
  bool get isExpired {
    if (ttl == null) return false;
    return DateTime.now().difference(createdAt) > ttl!;
  }
}

/// Abstract interface for search caching.
///
/// Implement this to create custom cache backends (memory, disk, etc.).
abstract class SearchCache<T> {
  /// Retrieves cached results for the given [key].
  ///
  /// Returns `null` if no valid cache entry exists.
  Future<List<T>?> get(String key);

  /// Stores [data] in the cache with the given [key].
  Future<void> put(String key, List<T> data);

  /// Removes a specific entry from the cache.
  Future<void> remove(String key);

  /// Clears all cached entries.
  Future<void> clear();

  /// Whether the cache contains a valid entry for [key].
  Future<bool> containsKey(String key);

  /// Returns the number of entries in the cache.
  Future<int> get size;

  /// Disposes any resources held by this cache.
  void dispose() {}
}

/// An in-memory cache with optional TTL (time-to-live) expiration.
///
/// Results are stored in a [LinkedHashMap] for LRU-like eviction when
/// [maxEntries] is exceeded.
///
/// ```dart
/// final cache = MemorySearchCache<SearchResult<Product>>(
///   ttl: Duration(minutes: 5),
///   maxEntries: 100,
/// );
/// ```
class MemorySearchCache<T> extends SearchCache<T> {
  /// Creates a memory cache.
  ///
  /// [ttl] sets how long entries remain valid. If `null`, entries never expire.
  /// [maxEntries] limits cache size; oldest entries are evicted first.
  MemorySearchCache({
    this.ttl,
    this.maxEntries = 100,
  });

  /// Time-to-live for cache entries.
  final Duration? ttl;

  /// Maximum number of entries in the cache.
  final int maxEntries;

  final LinkedHashMap<String, CacheEntry<List<T>>> _store =
      LinkedHashMap<String, CacheEntry<List<T>>>();

  Timer? _cleanupTimer;

  /// Starts periodic cleanup of expired entries.
  ///
  /// Call this if you want automatic eviction. By default, expired entries
  /// are lazily cleaned up on access.
  void startPeriodicCleanup({Duration interval = const Duration(minutes: 1)}) {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(interval, (_) => _evictExpired());
  }

  @override
  Future<List<T>?> get(String key) async {
    final entry = _store[key];
    if (entry == null) {
      SearchLogger.debug('[Cache] MISS for key="$key"');
      return null;
    }

    if (entry.isExpired) {
      SearchLogger.debug('[Cache] EXPIRED for key="$key"');
      _store.remove(key);
      return null;
    }

    SearchLogger.debug('[Cache] HIT for key="$key" (${entry.data.length} items)');

    // Move to end for LRU behavior
    _store.remove(key);
    _store[key] = entry;

    return entry.data;
  }

  @override
  Future<void> put(String key, List<T> data) async {
    // Evict oldest if at capacity
    if (_store.length >= maxEntries && !_store.containsKey(key)) {
      final oldestKey = _store.keys.first;
      _store.remove(oldestKey);
      SearchLogger.debug('[Cache] Evicted oldest entry: "$oldestKey"');
    }

    _store[key] = CacheEntry<List<T>>(
      data: data,
      createdAt: DateTime.now(),
      ttl: ttl,
    );
    SearchLogger.debug(
      '[Cache] PUT key="$key" (${data.length} items, ttl=${ttl?.inSeconds}s)',
    );
  }

  @override
  Future<void> remove(String key) async {
    _store.remove(key);
    SearchLogger.debug('[Cache] Removed key="$key"');
  }

  @override
  Future<void> clear() async {
    final count = _store.length;
    _store.clear();
    SearchLogger.debug('[Cache] Cleared $count entries');
  }

  @override
  Future<bool> containsKey(String key) async {
    final entry = _store[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      _store.remove(key);
      return false;
    }
    return true;
  }

  @override
  Future<int> get size async => _store.length;

  void _evictExpired() {
    final expiredKeys = <String>[];
    for (final entry in _store.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }
    for (final key in expiredKeys) {
      _store.remove(key);
    }
    if (expiredKeys.isNotEmpty) {
      SearchLogger.debug('[Cache] Evicted ${expiredKeys.length} expired entries');
    }
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    _store.clear();
  }
}
