import '../core/search_result.dart';
import 'search_adapter.dart';

/// A search adapter that combines local and remote search results.
///
/// Results are merged and ranked by score with optional priority weighting.
///
/// ```dart
/// final adapter = HybridSearchAdapter<Product>(
///   localAdapter: localAdapter,
///   remoteAdapter: remoteAdapter,
///   localWeight: 1.2,  // Boost local results slightly
///   remoteWeight: 1.0,
/// );
/// ```
class HybridSearchAdapter<T> extends SearchAdapter<T> {
  /// Creates a hybrid search adapter.
  HybridSearchAdapter({
    required this.localAdapter,
    required this.remoteAdapter,
    this.localWeight = 1.0,
    this.remoteWeight = 1.0,
    this.deduplicateById = true,
  });

  /// The local search adapter.
  final SearchAdapter<T> localAdapter;

  /// The remote search adapter.
  final SearchAdapter<T> remoteAdapter;

  /// Weight multiplier for local results' scores.
  final double localWeight;

  /// Weight multiplier for remote results' scores.
  final double remoteWeight;

  /// Whether to remove duplicate results based on ID.
  final bool deduplicateById;

  @override
  Future<List<SearchResult<T>>> search(
    String query, {
    int limit = 50,
    int offset = 0,
  }) async {
    final futures = await Future.wait([
      _trySearch(localAdapter, query, limit, offset),
      _trySearch(remoteAdapter, query, limit, offset),
    ]);

    final localResults = futures[0];
    final remoteResults = futures[1];

    // If both adapters failed, rethrow so the engine can surface the error.
    if (localResults == null && remoteResults == null) {
      throw Exception('Both local and remote search failed');
    }

    // Apply weights
    final weighted = <SearchResult<T>>[];

    for (final r in localResults ?? const []) {
      weighted.add(r.copyWith(
        score: r.score * localWeight,
        source: SearchResultSource.local,
      ));
    }

    for (final r in remoteResults ?? const []) {
      weighted.add(r.copyWith(
        score: r.score * remoteWeight,
        source: SearchResultSource.remote,
      ));
    }

    // Deduplicate
    if (deduplicateById) {
      final seen = <String>{};
      final deduped = <SearchResult<T>>[];
      weighted.sort();
      for (final r in weighted) {
        if (seen.add(r.id)) {
          deduped.add(r.copyWith(source: SearchResultSource.merged));
        }
      }
      return deduped;
    }

    weighted.sort();
    return weighted;
  }

  /// Attempts a search, returning null on failure instead of throwing.
  Future<List<SearchResult<T>>?> _trySearch(
    SearchAdapter<T> adapter,
    String query,
    int limit,
    int offset,
  ) async {
    try {
      return await adapter.search(query, limit: limit, offset: offset);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<String>> suggest(String query) async {
    final results = await Future.wait([
      _trySuggest(localAdapter, query),
      _trySuggest(remoteAdapter, query),
    ]);
    final combined = <String>{
      ...results[0] ?? const <String>[],
      ...results[1] ?? const <String>[],
    };
    return combined.toList();
  }

  /// Attempts to get suggestions, returning null on failure instead of throwing.
  Future<List<String>?> _trySuggest(
    SearchAdapter<T> adapter,
    String query,
  ) async {
    try {
      return await adapter.suggest(query);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    localAdapter.dispose();
    remoteAdapter.dispose();
  }
}
