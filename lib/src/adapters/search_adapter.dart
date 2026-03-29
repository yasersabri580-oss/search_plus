import '../core/search_result.dart';

/// Base interface for all search adapters.
///
/// Implement this to create custom search sources (API, database, etc.).
abstract class SearchAdapter<T> {
  /// Performs a search with the given [query].
  ///
  /// Returns a list of [SearchResult] items.
  /// Throws on failure; the controller handles error states.
  Future<List<SearchResult<T>>> search(
    String query, {
    int limit = 50,
    int offset = 0,
  });

  /// Optional: Provides search suggestions for the given [query].
  Future<List<String>> suggest(String query) async => const [];

  /// Disposes any resources held by this adapter.
  void dispose() {}
}

/// Configuration for ranking and scoring search results.
class SearchRankingConfig {
  /// Creates a ranking configuration.
  const SearchRankingConfig({
    this.titleWeight = 1.0,
    this.subtitleWeight = 0.5,
    this.fuzzyThreshold = 0.3,
    this.boostExactMatch = 2.0,
    this.boostPrefixMatch = 1.5,
  });

  /// Weight multiplier for title matches.
  final double titleWeight;

  /// Weight multiplier for subtitle matches.
  final double subtitleWeight;

  /// Threshold for fuzzy matching (0.0 = exact, 1.0 = very fuzzy).
  final double fuzzyThreshold;

  /// Score boost for exact matches.
  final double boostExactMatch;

  /// Score boost for prefix matches.
  final double boostPrefixMatch;
}
