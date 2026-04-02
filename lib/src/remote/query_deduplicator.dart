import '../utils/search_logger.dart';

/// Deduplicates identical concurrent queries to avoid redundant work.
///
/// When multiple identical queries are triggered simultaneously,
/// only one actual operation is executed and the result is shared
/// among all waiters.
///
/// ```dart
/// final deduplicator = QueryDeduplicator<List<Result>>();
///
/// // Both calls share the same underlying execution
/// final result1 = deduplicator.deduplicate('flutter', () => api.search('flutter'));
/// final result2 = deduplicator.deduplicate('flutter', () => api.search('flutter'));
/// ```
class QueryDeduplicator<T> {
  final Map<String, Future<T>> _inflight = {};

  /// Executes [operation] for the given [key], deduplicating concurrent calls.
  ///
  /// If an operation for the same [key] is already in-flight, the existing
  /// future is returned instead of starting a new operation.
  Future<T> deduplicate(String key, Future<T> Function() operation) {
    if (_inflight.containsKey(key)) {
      SearchLogger.debug('[Dedup] Reusing in-flight request for "$key"');
      return _inflight[key]!;
    }

    SearchLogger.debug('[Dedup] Starting new request for "$key"');
    final future = operation().whenComplete(() {
      _inflight.remove(key);
      SearchLogger.debug('[Dedup] Completed and removed "$key"');
    });

    _inflight[key] = future;
    return future;
  }

  /// Cancels tracking of all in-flight operations.
  ///
  /// Note: This does not cancel the underlying futures, only removes
  /// them from the deduplication map.
  void clear() {
    _inflight.clear();
  }

  /// Number of currently in-flight operations.
  int get inflightCount => _inflight.length;
}
