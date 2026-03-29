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
    final results = await Future.wait([
      localAdapter.search(query, limit: limit, offset: offset),
      remoteAdapter.search(query, limit: limit, offset: offset),
    ]);

    final localResults = results[0];
    final remoteResults = results[1];

    // Apply weights
    final weighted = <SearchResult<T>>[];

    for (final r in localResults) {
      weighted.add(r.copyWith(
        score: r.score * localWeight,
        source: SearchResultSource.local,
      ));
    }

    for (final r in remoteResults) {
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

  @override
  Future<List<String>> suggest(String query) async {
    final results = await Future.wait([
      localAdapter.suggest(query),
      remoteAdapter.suggest(query),
    ]);
    final combined = <String>{...results[0], ...results[1]};
    return combined.toList();
  }

  @override
  void dispose() {
    localAdapter.dispose();
    remoteAdapter.dispose();
  }
}
