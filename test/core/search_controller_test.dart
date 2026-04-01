import 'package:flutter_test/flutter_test.dart';
import 'package:search_plus/search_plus.dart';

void main() {
  group('SearchPlusController', () {
    late SearchPlusController<String> controller;

    setUp(() {
      controller = SearchPlusController<String>(
        adapter: LocalSearchAdapter<String>(
          items: ['Apple', 'Banana', 'Cherry', 'Date', 'Elderberry'],
          searchableFields: (item) => [item],
          toResult: (item) =>
              SearchResult(id: item, title: item, data: item),
        ),
        debounceDuration: Duration.zero,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('initial state is idle', () {
      expect(controller.status, SearchStatus.idle);
      expect(controller.results, isEmpty);
      expect(controller.query, isEmpty);
    });

    test('search returns matching results', () async {
      await controller.searchImmediate('apple');
      expect(controller.status, SearchStatus.success);
      expect(controller.results, hasLength(1));
      expect(controller.results.first.title, 'Apple');
    });

    test('search with no matches returns empty status', () async {
      await controller.searchImmediate('xyz');
      expect(controller.status, SearchStatus.empty);
      expect(controller.results, isEmpty);
    });

    test('clear resets state', () async {
      await controller.searchImmediate('apple');
      expect(controller.hasResults, isTrue);

      controller.clear();
      expect(controller.status, SearchStatus.idle);
      expect(controller.results, isEmpty);
    });

    test('empty query returns idle state', () async {
      await controller.searchImmediate('');
      expect(controller.status, SearchStatus.idle);
    });

    test('search history works', () {
      controller.addToHistory('test query 1');
      controller.addToHistory('test query 2');
      expect(controller.state.history, hasLength(2));
      expect(controller.state.history.first, 'test query 2');
    });

    test('duplicate history entries are deduplicated', () {
      controller.addToHistory('test');
      controller.addToHistory('other');
      controller.addToHistory('test');
      expect(controller.state.history, hasLength(2));
      expect(controller.state.history.first, 'test');
    });

    test('clear history removes all entries', () {
      controller.addToHistory('test 1');
      controller.addToHistory('test 2');
      controller.clearHistory();
      expect(controller.state.history, isEmpty);
    });

    test('history respects max items', () {
      final ctrl = SearchPlusController<String>(
        adapter: LocalSearchAdapter<String>(
          items: const [],
          searchableFields: (item) => [item],
          toResult: (item) =>
              SearchResult(id: item, title: item, data: item),
        ),
        maxHistoryItems: 3,
        debounceDuration: Duration.zero,
      );

      ctrl.addToHistory('one');
      ctrl.addToHistory('two');
      ctrl.addToHistory('three');
      ctrl.addToHistory('four');
      expect(ctrl.state.history, hasLength(3));
      expect(ctrl.state.history.last, 'two');

      ctrl.dispose();
    });

    test('error message is propagated to state', () async {
      final errorMessage = 'Test error from adapter';
      final controller = SearchPlusController<String>(
        adapter: RemoteSearchAdapter<String>(
          searchFunction: (query, limit, offset) async {
            throw Exception(errorMessage);
          },
        ),
        debounceDuration: Duration.zero,
      );

      await controller.searchImmediate('test');
      expect(controller.status, SearchStatus.error);
      expect(controller.state.error, isNotNull);
      expect(controller.state.error, contains(errorMessage));

      controller.dispose();
    });
  });
}
