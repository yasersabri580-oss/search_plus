import 'package:flutter_test/flutter_test.dart';
import 'package:search_plus/search_plus.dart';

void main() {
  group('SearchLogger', () {
    setUp(() {
      SearchLogger.disable();
    });

    tearDown(() {
      SearchLogger.disable();
    });

    test('isEnabled returns false when disabled', () {
      expect(SearchLogger.isEnabled, isFalse);
    });

    test('isEnabled returns true when enabled', () {
      SearchLogger.enable(level: SearchLogLevel.debug);
      expect(SearchLogger.isEnabled, isTrue);
    });

    test('level reflects the set log level', () {
      SearchLogger.enable(level: SearchLogLevel.warning);
      expect(SearchLogger.level, SearchLogLevel.warning);
    });

    test('disable resets to none', () {
      SearchLogger.enable(level: SearchLogLevel.info);
      SearchLogger.disable();
      expect(SearchLogger.level, SearchLogLevel.none);
      expect(SearchLogger.isEnabled, isFalse);
    });

    test('custom onLog callback receives messages', () {
      final logs = <String>[];
      SearchLogger.enable(
        level: SearchLogLevel.debug,
        onLog: (level, message, {error, stackTrace}) {
          logs.add(message);
        },
      );

      SearchLogger.info('hello');
      expect(logs, hasLength(1));
      expect(logs.first, contains('hello'));
    });

    test('messages below the threshold are suppressed', () {
      final logs = <String>[];
      SearchLogger.enable(
        level: SearchLogLevel.warning,
        onLog: (level, message, {error, stackTrace}) {
          logs.add(message);
        },
      );

      SearchLogger.debug('should be hidden');
      SearchLogger.info('also hidden');
      SearchLogger.warning('visible');
      SearchLogger.error('also visible');

      expect(logs, hasLength(2));
    });

    test('stateTransition logs from and to status', () {
      final logs = <String>[];
      SearchLogger.enable(
        level: SearchLogLevel.debug,
        onLog: (level, message, {error, stackTrace}) {
          logs.add(message);
        },
      );

      SearchLogger.stateTransition('idle', 'loading', query: 'test');
      expect(logs, hasLength(1));
      expect(logs.first, contains('idle'));
      expect(logs.first, contains('loading'));
      expect(logs.first, contains('test'));
    });

    test('searchQuery logs query and mode', () {
      final logs = <String>[];
      SearchLogger.enable(
        level: SearchLogLevel.debug,
        onLog: (level, message, {error, stackTrace}) {
          logs.add(message);
        },
      );

      SearchLogger.searchQuery('apple', immediate: true);
      expect(logs, hasLength(1));
      expect(logs.first, contains('apple'));
      expect(logs.first, contains('immediate'));
    });

    test('adapterResults logs count and timing', () {
      final logs = <String>[];
      SearchLogger.enable(
        level: SearchLogLevel.debug,
        onLog: (level, message, {error, stackTrace}) {
          logs.add(message);
        },
      );

      SearchLogger.adapterResults(
          'LocalSearchAdapter', 5, const Duration(milliseconds: 42));
      expect(logs, hasLength(1));
      expect(logs.first, contains('5 result(s)'));
      expect(logs.first, contains('42ms'));
    });
  });
}
