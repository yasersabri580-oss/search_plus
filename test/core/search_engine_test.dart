import 'package:flutter_test/flutter_test.dart';
import 'package:search_plus/search_plus.dart';

void main() {
  group('LocalSearchAdapter', () {
    late LocalSearchAdapter<String> adapter;

    setUp(() {
      adapter = LocalSearchAdapter<String>(
        items: [
          'Flutter',
          'Dart',
          'React Native',
          'Swift',
          'Kotlin',
          'TypeScript',
          'JavaScript',
          'Python',
          'Go',
          'Rust',
        ],
        searchableFields: (item) => [item],
        toResult: (item) =>
            SearchResult(id: item, title: item, data: item),
      );
    });

    test('exact match returns highest score', () async {
      final results = await adapter.search('dart');
      expect(results, isNotEmpty);
      expect(results.first.title, 'Dart');
    });

    test('prefix match works', () async {
      final results = await adapter.search('flu');
      expect(results, isNotEmpty);
      expect(results.first.title, 'Flutter');
    });

    test('contains match works', () async {
      final results = await adapter.search('script');
      expect(results, hasLength(2)); // TypeScript, JavaScript
    });

    test('empty query returns empty', () async {
      final results = await adapter.search('');
      expect(results, isEmpty);
    });

    test('no match returns empty', () async {
      final results = await adapter.search('xyz123');
      expect(results, isEmpty);
    });

    test('results are sorted by score', () async {
      final results = await adapter.search('go');
      // "Go" exact match should score higher than "Go" in other words
      if (results.length > 1) {
        expect(results.first.score, greaterThanOrEqualTo(results.last.score));
      }
    });

    test('limit parameter works', () async {
      final results = await adapter.search('t', limit: 2);
      expect(results.length, lessThanOrEqualTo(2));
    });

    test('offset parameter works', () async {
      final allResults = await adapter.search('t');
      if (allResults.length > 1) {
        final offsetResults = await adapter.search('t', offset: 1);
        expect(offsetResults.length, allResults.length - 1);
      }
    });

    test('results have local source', () async {
      final results = await adapter.search('dart');
      expect(results.first.source, SearchResultSource.local);
    });

    test('suggest returns prefix matches', () async {
      final suggestions = await adapter.suggest('Flu');
      expect(suggestions, contains('Flutter'));
    });
  });

  group('LocalSearchAdapter with fuzzy search', () {
    late LocalSearchAdapter<String> adapter;

    setUp(() {
      adapter = LocalSearchAdapter<String>(
        items: ['Flutter', 'Flatter', 'Flitter'],
        searchableFields: (item) => [item],
        toResult: (item) =>
            SearchResult(id: item, title: item, data: item),
        enableFuzzySearch: true,
        rankingConfig: const SearchRankingConfig(fuzzyThreshold: 0.5),
      );
    });

    test('fuzzy search finds similar terms', () async {
      final results = await adapter.search('flutter');
      expect(results, isNotEmpty);
      expect(results.first.title, 'Flutter');
    });
  });

  group('RemoteSearchAdapter', () {
    test('delegates to search function', () async {
      final adapter = RemoteSearchAdapter<String>(
        searchFunction: (query, limit, offset) async {
          return [
            SearchResult(
              id: '1',
              title: 'Remote Result for $query',
              data: query,
            ),
          ];
        },
      );

      final results = await adapter.search('test');
      expect(results, hasLength(1));
      expect(results.first.title, 'Remote Result for test');
      expect(results.first.source, SearchResultSource.remote);
    });

    test('suggest delegates to suggest function', () async {
      final adapter = RemoteSearchAdapter<String>(
        searchFunction: (query, limit, offset) async => [],
        suggestFunction: (query) async => ['suggestion1', 'suggestion2'],
      );

      final suggestions = await adapter.suggest('test');
      expect(suggestions, hasLength(2));
    });

    test('suggest returns empty when no function provided', () async {
      final adapter = RemoteSearchAdapter<String>(
        searchFunction: (query, limit, offset) async => [],
      );

      final suggestions = await adapter.suggest('test');
      expect(suggestions, isEmpty);
    });
  });

  group('HybridSearchAdapter', () {
    test('merges local and remote results', () async {
      final local = LocalSearchAdapter<String>(
        items: ['Local Apple'],
        searchableFields: (item) => [item],
        toResult: (item) =>
            SearchResult(id: item, title: item, data: item),
      );

      final remote = RemoteSearchAdapter<String>(
        searchFunction: (query, limit, offset) async {
          return [
            SearchResult(
              id: 'remote-1',
              title: 'Remote Apple',
              data: 'remote',
              score: 0.5,
            ),
          ];
        },
      );

      final hybrid = HybridSearchAdapter<String>(
        localAdapter: local,
        remoteAdapter: remote,
      );

      final results = await hybrid.search('apple');
      expect(results, hasLength(2));
    });

    test('deduplicates by ID', () async {
      final local = LocalSearchAdapter<String>(
        items: ['Apple'],
        searchableFields: (item) => [item],
        toResult: (item) =>
            SearchResult(id: 'apple', title: item, data: item),
      );

      final remote = RemoteSearchAdapter<String>(
        searchFunction: (query, limit, offset) async {
          return [
            SearchResult(
              id: 'apple',
              title: 'Apple Remote',
              data: 'remote',
              score: 0.5,
            ),
          ];
        },
      );

      final hybrid = HybridSearchAdapter<String>(
        localAdapter: local,
        remoteAdapter: remote,
        deduplicateById: true,
      );

      final results = await hybrid.search('apple');
      expect(results, hasLength(1));
      expect(results.first.source, SearchResultSource.merged);
    });

    test('applies weights correctly', () async {
      final local = LocalSearchAdapter<String>(
        items: ['Apple'],
        searchableFields: (item) => [item],
        toResult: (item) =>
            SearchResult(id: 'local-apple', title: item, data: item),
      );

      final remote = RemoteSearchAdapter<String>(
        searchFunction: (query, limit, offset) async {
          return [
            SearchResult(
              id: 'remote-apple',
              title: 'Apple',
              data: 'remote',
              score: 1.0,
            ),
          ];
        },
      );

      final hybrid = HybridSearchAdapter<String>(
        localAdapter: local,
        remoteAdapter: remote,
        localWeight: 2.0,
        remoteWeight: 0.5,
        deduplicateById: false,
      );

      final results = await hybrid.search('apple');
      expect(results, hasLength(2));
      // Local result should have higher score due to weight
      final localResult =
          results.firstWhere((r) => r.source == SearchResultSource.local);
      final remoteResult =
          results.firstWhere((r) => r.source == SearchResultSource.remote);
      expect(localResult.score, greaterThan(remoteResult.score));
    });

    test('returns local results when remote adapter fails', () async {
      final local = LocalSearchAdapter<String>(
        items: ['Local Apple'],
        searchableFields: (item) => [item],
        toResult: (item) =>
            SearchResult(id: item, title: item, data: item),
      );

      final remote = RemoteSearchAdapter<String>(
        searchFunction: (query, limit, offset) async {
          throw Exception('Network error');
        },
      );

      final hybrid = HybridSearchAdapter<String>(
        localAdapter: local,
        remoteAdapter: remote,
        deduplicateById: false,
      );

      final results = await hybrid.search('apple');
      expect(results, isNotEmpty);
      expect(results.first.source, SearchResultSource.local);
    });

    test('returns remote results when local adapter fails', () async {
      final local = RemoteSearchAdapter<String>(
        searchFunction: (query, limit, offset) async {
          throw Exception('Local error');
        },
      );

      final remote = RemoteSearchAdapter<String>(
        searchFunction: (query, limit, offset) async {
          return [
            SearchResult(
              id: 'remote-1',
              title: 'Remote Apple',
              data: 'remote',
              score: 0.5,
            ),
          ];
        },
      );

      final hybrid = HybridSearchAdapter<String>(
        localAdapter: local,
        remoteAdapter: remote,
        deduplicateById: false,
      );

      final results = await hybrid.search('apple');
      expect(results, isNotEmpty);
      expect(results.first.source, SearchResultSource.remote);
    });

    test('throws when both adapters fail', () async {
      final local = RemoteSearchAdapter<String>(
        searchFunction: (query, limit, offset) async {
          throw Exception('Local error');
        },
      );

      final remote = RemoteSearchAdapter<String>(
        searchFunction: (query, limit, offset) async {
          throw Exception('Remote error');
        },
      );

      final hybrid = HybridSearchAdapter<String>(
        localAdapter: local,
        remoteAdapter: remote,
      );

      expect(
        () => hybrid.search('apple'),
        throwsException,
      );
    });

    test('suggest gracefully handles one adapter failing', () async {
      final local = LocalSearchAdapter<String>(
        items: ['Flutter', 'Dart'],
        searchableFields: (item) => [item],
        toResult: (item) =>
            SearchResult(id: item, title: item, data: item),
      );

      final remote = RemoteSearchAdapter<String>(
        searchFunction: (query, limit, offset) async => [],
        suggestFunction: (query) async {
          throw Exception('Suggest error');
        },
      );

      final hybrid = HybridSearchAdapter<String>(
        localAdapter: local,
        remoteAdapter: remote,
      );

      final suggestions = await hybrid.suggest('Flu');
      expect(suggestions, contains('Flutter'));
    });
  });

  group('SearchResult', () {
    test('equality based on id', () {
      const a = SearchResult(id: '1', title: 'A');
      const b = SearchResult(id: '1', title: 'B');
      expect(a, equals(b));
    });

    test('compareTo sorts by score descending', () {
      const a = SearchResult(id: '1', title: 'A', score: 1.0);
      const b = SearchResult(id: '2', title: 'B', score: 2.0);
      expect(a.compareTo(b), greaterThan(0)); // b has higher score
    });

    test('copyWith preserves values', () {
      const original = SearchResult(
        id: '1',
        title: 'Original',
        subtitle: 'Sub',
        score: 1.0,
      );
      final copy = original.copyWith(title: 'Modified');
      expect(copy.id, '1');
      expect(copy.title, 'Modified');
      expect(copy.subtitle, 'Sub');
      expect(copy.score, 1.0);
    });
  });

  group('SearchState', () {
    test('initial state properties', () {
      const state = SearchState();
      expect(state.isIdle, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.hasError, isFalse);
      expect(state.hasResults, isFalse);
    });

    test('loading state', () {
      const state = SearchState(
        query: 'test',
        status: SearchStatus.loading,
      );
      expect(state.isLoading, isTrue);
      expect(state.isIdle, isFalse);
    });

    test('error state', () {
      const state = SearchState(
        query: 'test',
        status: SearchStatus.error,
        error: 'Something went wrong',
      );
      expect(state.hasError, isTrue);
      expect(state.error, isNotNull);
    });
  });
}
