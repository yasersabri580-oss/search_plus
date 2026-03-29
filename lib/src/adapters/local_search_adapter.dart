import 'dart:math' as math;

import '../core/search_result.dart';
import 'search_adapter.dart';

/// A search adapter that searches through an in-memory list of items.
///
/// Supports exact, prefix, contains, and fuzzy matching with configurable
/// scoring and ranking.
///
/// ```dart
/// final adapter = LocalSearchAdapter<Product>(
///   items: products,
///   searchableFields: (p) => [p.name, p.description],
///   toResult: (p) => SearchResult(id: p.id, title: p.name, data: p),
/// );
/// ```
class LocalSearchAdapter<T> extends SearchAdapter<T> {
  /// Creates a local search adapter.
  LocalSearchAdapter({
    required this.items,
    required this.searchableFields,
    required this.toResult,
    this.rankingConfig = const SearchRankingConfig(),
    this.enableFuzzySearch = false,
  });

  /// The full list of items to search through.
  List<T> items;

  /// Extracts searchable text fields from an item.
  final List<String> Function(T item) searchableFields;

  /// Converts an item to a [SearchResult].
  final SearchResult<T> Function(T item) toResult;

  /// Configuration for ranking and scoring.
  final SearchRankingConfig rankingConfig;

  /// Whether to enable fuzzy search matching.
  final bool enableFuzzySearch;

  @override
  Future<List<SearchResult<T>>> search(
    String query, {
    int limit = 50,
    int offset = 0,
  }) async {
    if (query.isEmpty) return const [];

    final normalizedQuery = query.toLowerCase().trim();
    final scored = <SearchResult<T>>[];

    for (final item in items) {
      final fields = searchableFields(item);
      double bestScore = 0.0;

      for (int i = 0; i < fields.length; i++) {
        final field = fields[i].toLowerCase();
        final weight =
            i == 0 ? rankingConfig.titleWeight : rankingConfig.subtitleWeight;
        final score = _scoreMatch(normalizedQuery, field) * weight;
        if (score > bestScore) bestScore = score;
      }

      if (bestScore > 0) {
        final result = toResult(item);
        scored.add(result.copyWith(
          score: bestScore,
          source: SearchResultSource.local,
        ));
      }
    }

    scored.sort();

    final end = math.min(offset + limit, scored.length);
    if (offset >= scored.length) return const [];
    return scored.sublist(offset, end);
  }

  double _scoreMatch(String query, String field) {
    // Exact match
    if (field == query) return 1.0 * rankingConfig.boostExactMatch;

    // Prefix match
    if (field.startsWith(query)) return 0.9 * rankingConfig.boostPrefixMatch;

    // Word-start match (e.g., searching "app" matches "my application")
    final words = field.split(RegExp(r'\s+'));
    for (final word in words) {
      if (word.startsWith(query)) return 0.8;
    }

    // Contains match
    if (field.contains(query)) return 0.6;

    // Fuzzy match
    if (enableFuzzySearch) {
      final distance = _levenshteinDistance(query, field);
      final maxLen = math.max(query.length, field.length);
      if (maxLen == 0) return 0.0;
      final similarity = 1.0 - (distance / maxLen);
      if (similarity >= (1.0 - rankingConfig.fuzzyThreshold)) {
        return similarity * 0.4;
      }
    }

    return 0.0;
  }

  static int _levenshteinDistance(String s, String t) {
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    // Only compare against each word in t for better fuzzy matching
    final words = t.split(RegExp(r'\s+'));
    int bestDistance = s.length + t.length;

    for (final word in words) {
      final distance = _levenshteinWord(s, word);
      if (distance < bestDistance) bestDistance = distance;
    }

    return bestDistance;
  }

  static int _levenshteinWord(String s, String t) {
    final sLen = s.length;
    final tLen = t.length;

    if (sLen == 0) return tLen;
    if (tLen == 0) return sLen;

    var previous = List<int>.generate(tLen + 1, (i) => i);
    var current = List<int>.filled(tLen + 1, 0);

    for (int i = 1; i <= sLen; i++) {
      current[0] = i;
      for (int j = 1; j <= tLen; j++) {
        final cost = s[i - 1] == t[j - 1] ? 0 : 1;
        current[j] = math.min(
          math.min(current[j - 1] + 1, previous[j] + 1),
          previous[j - 1] + cost,
        );
      }
      final temp = previous;
      previous = current;
      current = temp;
    }

    return previous[tLen];
  }

  @override
  Future<List<String>> suggest(String query) async {
    if (query.isEmpty) return const [];

    final normalizedQuery = query.toLowerCase().trim();
    final seen = <String>{};
    final suggestions = <String>[];

    for (final item in items) {
      final fields = searchableFields(item);
      for (final field in fields) {
        if (field.toLowerCase().startsWith(normalizedQuery) &&
            seen.add(field)) {
          suggestions.add(field);
          if (suggestions.length >= 5) return suggestions;
        }
      }
    }

    return suggestions;
  }
}
