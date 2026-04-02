import 'dart:math' as math;

import '../core/search_result.dart';
import 'search_adapter.dart';

class LocalSearchAdapter<T> extends SearchAdapter<T> {
  LocalSearchAdapter({
    required this.items,
    required this.searchableFields,
    required this.toResult,
    this.rankingConfig = const SearchRankingConfig(),
    this.enableFuzzySearch = false,
    this.enableDebug = false,
  });

  List<T> items;
  final List<String> Function(T item) searchableFields;
  final SearchResult<T> Function(T item) toResult;
  final SearchRankingConfig rankingConfig;
  final bool enableFuzzySearch;

  /// 🔥 Debug flag
  final bool enableDebug;

  void _log(String message) {
    if (enableDebug) {
      print('[LocalSearchAdapter] $message');
    }
  }

  @override
  Future<List<SearchResult<T>>> search(
    String query, {
    int limit = 50,
    int offset = 0,
  }) async {
    _log('--- SEARCH START ---');
    _log('Query: "$query"');

    if (query.isEmpty) {
      _log('Query is empty → returning []');
      return const [];
    }

    final normalizedQuery = query.toLowerCase().trim();
    final scored = <SearchResult<T>>[];

    for (final item in items) {
      final fields = searchableFields(item);
      double bestScore = 0.0;

      _log('Item: $item');

      for (int i = 0; i < fields.length; i++) {
        final field = fields[i].toLowerCase();
        final weight = i == 0
            ? rankingConfig.titleWeight
            : rankingConfig.subtitleWeight;

        final rawScore = _scoreMatch(normalizedQuery, field);
        final score = rawScore * weight;

        _log(' Field[$i]: "$field"');
        _log('  RawScore: $rawScore | Weight: $weight | FinalScore: $score');

        if (score > bestScore) {
          bestScore = score;
        }
      }

      if (bestScore > 0) {
        final result = toResult(item);
        _log(' ✅ MATCH → Score: $bestScore');

        scored.add(
          result.copyWith(score: bestScore, source: SearchResultSource.local),
        );
      } else {
        _log(' ❌ NO MATCH');
      }
    }

    _log('Sorting results...');
    scored.sort();

    final end = math.min(offset + limit, scored.length);

    if (offset >= scored.length) {
      _log('Offset خارج از محدوده → []');
      return const [];
    }

    final finalResults = scored.sublist(offset, end);

    _log('Final Results Count: ${finalResults.length}');
    _log('--- SEARCH END ---');

    return finalResults;
  }

  double _scoreMatch(String query, String field) {
    _log('   → Matching "$query" with "$field"');

    // Exact match
    if (field == query) {
      _log('   ✔ Exact Match');
      return 1.0 * rankingConfig.boostExactMatch;
    }

    // Prefix match
    if (field.startsWith(query)) {
      _log('   ✔ Prefix Match');
      return 0.9 * rankingConfig.boostPrefixMatch;
    }

    // Word-start match
    final words = field.split(RegExp(r'\s+'));
    for (final word in words) {
      if (word.startsWith(query)) {
        _log('   ✔ Word-start Match');
        return 0.8;
      }
    }

    // Contains match
    if (field.contains(query)) {
      _log('   ✔ Contains Match');
      return 0.6;
    }

    // Fuzzy match
    if (enableFuzzySearch) {
      final distance = _levenshteinDistance(query, field);
      final maxLen = math.max(query.length, field.length);

      final similarity = maxLen == 0 ? 0.0 : 1.0 - (distance / maxLen);

      _log('   🔍 Fuzzy → distance: $distance | similarity: $similarity');

      if (similarity >= (1.0 - rankingConfig.fuzzyThreshold)) {
        _log('   ✔ Fuzzy Match Accepted');
        return similarity * 0.4;
      } else {
        _log('   ❌ Fuzzy Rejected');
      }
    }

    return 0.0;
  }

  static int _levenshteinDistance(String s, String t) {
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
    _log('--- SUGGEST START ---');
    _log('Query: "$query"');

    if (query.isEmpty) {
      _log('Query empty → []');
      return const [];
    }

    final normalizedQuery = query.toLowerCase().trim();
    final seen = <String>{};
    final suggestions = <String>[];

    for (final item in items) {
      final fields = searchableFields(item);

      for (final field in fields) {
        final lower = field.toLowerCase();

        if (lower.startsWith(normalizedQuery) && seen.add(field)) {
          _log('Suggestion added: $field');
          suggestions.add(field);

          if (suggestions.length >= 5) {
            _log('Limit reached');
            return suggestions;
          }
        }
      }
    }

    _log('Suggestions Count: ${suggestions.length}');
    _log('--- SUGGEST END ---');

    return suggestions;
  }
}
