import 'dart:developer' as developer;

/// Log levels for the search_plus logger.
enum SearchLogLevel {
  /// Detailed diagnostic information.
  debug,

  /// General informational messages.
  info,

  /// Warnings about potential issues.
  warning,

  /// Errors that prevented an operation from completing.
  error,

  /// Completely disable logging.
  none,
}

/// A callback for custom log handling.
///
/// Receives the [level], a formatted [message], and an optional [error]
/// and [stackTrace].
typedef SearchLogCallback = void Function(
  SearchLogLevel level,
  String message, {
  Object? error,
  StackTrace? stackTrace,
});

/// Lightweight, zero-dependency logger for the search_plus package.
///
/// Call [SearchLogger.enable] at app start to turn on console logging.
/// Optionally supply a custom [SearchLogCallback] to route logs to your own
/// logging infrastructure.
///
/// ```dart
/// // Enable all logs at debug level
/// SearchLogger.enable(level: SearchLogLevel.debug);
///
/// // Or send them to your own logger
/// SearchLogger.enable(
///   level: SearchLogLevel.info,
///   onLog: (level, message, {error, stackTrace}) {
///     myLogger.log(message);
///   },
/// );
/// ```
class SearchLogger {
  SearchLogger._();

  static SearchLogLevel _level = SearchLogLevel.none;
  static SearchLogCallback? _onLog;
  static bool _useDevLog = true;

  /// Enable logging with the given minimum [level].
  ///
  /// When [onLog] is provided it replaces the default `dart:developer` output.
  /// Set [useDevLog] to `false` to suppress `dart:developer` logging even
  /// without a custom callback (useful in release builds).
  static void enable({
    SearchLogLevel level = SearchLogLevel.debug,
    SearchLogCallback? onLog,
    bool useDevLog = true,
  }) {
    _level = level;
    _onLog = onLog;
    _useDevLog = useDevLog;
  }

  /// Disable all logging.
  static void disable() {
    _level = SearchLogLevel.none;
    _onLog = null;
  }

  /// The current minimum log level.
  static SearchLogLevel get level => _level;

  /// Whether logging is active (level is not [SearchLogLevel.none]).
  static bool get isEnabled => _level != SearchLogLevel.none;

  // ---------------------------------------------------------------------------
  // Convenience methods
  // ---------------------------------------------------------------------------

  /// Log a debug-level message.
  static void debug(String message) =>
      _log(SearchLogLevel.debug, message);

  /// Log an info-level message.
  static void info(String message) =>
      _log(SearchLogLevel.info, message);

  /// Log a warning-level message.
  static void warning(String message,
          {Object? error, StackTrace? stackTrace}) =>
      _log(SearchLogLevel.warning, message,
          error: error, stackTrace: stackTrace);

  /// Log an error-level message.
  static void error(String message,
          {Object? error, StackTrace? stackTrace}) =>
      _log(SearchLogLevel.error, message,
          error: error, stackTrace: stackTrace);

  // ---------------------------------------------------------------------------
  // Semantic helpers — called from package internals
  // ---------------------------------------------------------------------------

  /// Log a state transition in the search controller.
  static void stateTransition(String from, String to, {String? query}) {
    if (!_shouldLog(SearchLogLevel.debug)) return;
    final q = query != null ? ' query="$query"' : '';
    debug('[State] $from \u2192 $to$q');
  }

  /// Log a search query being dispatched.
  static void searchQuery(String query, {bool immediate = false}) {
    if (!_shouldLog(SearchLogLevel.info)) return;
    final mode = immediate ? 'immediate' : 'debounced';
    info('[Search] query="$query" ($mode)');
  }

  /// Log adapter results.
  static void adapterResults(
      String adapterName, int count, Duration elapsed) {
    if (!_shouldLog(SearchLogLevel.debug)) return;
    debug('[Adapter] $adapterName returned $count result(s) '
        'in ${elapsed.inMilliseconds}ms');
  }

  /// Log an adapter error.
  static void adapterError(
    String adapterName,
    Object err, {
    StackTrace? stackTrace,
  }) {
    if (!_shouldLog(SearchLogLevel.error)) return;
    error('[Adapter] $adapterName failed: $err',
        error: err, stackTrace: stackTrace);
  }

  /// Log fake API behavior (for demo/test usage).
  static void fakeApi(String message) {
    if (!_shouldLog(SearchLogLevel.debug)) return;
    debug('[FakeAPI] $message');
  }

  /// Log a UI/example interaction.
  static void ui(String message) {
    if (!_shouldLog(SearchLogLevel.debug)) return;
    debug('[UI] $message');
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  static bool _shouldLog(SearchLogLevel messageLevel) {
    return messageLevel.index >= _level.index &&
        _level != SearchLogLevel.none;
  }

  static void _log(
    SearchLogLevel messageLevel,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_shouldLog(messageLevel)) return;

    final prefix = _prefix(messageLevel);
    final formatted = '$prefix $message';

    // Custom callback
    if (_onLog != null) {
      _onLog!(messageLevel, formatted,
          error: error, stackTrace: stackTrace);
      return;
    }

    // dart:developer log
    if (_useDevLog) {
      developer.log(
        formatted,
        name: 'search_plus',
        level: _devLogLevel(messageLevel),
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static String _prefix(SearchLogLevel level) => switch (level) {
        SearchLogLevel.debug => '\u{1F50D}',
        SearchLogLevel.info => '\u{2139}\uFE0F',
        SearchLogLevel.warning => '\u{26A0}\uFE0F',
        SearchLogLevel.error => '\u{274C}',
        SearchLogLevel.none => '',
      };

  static int _devLogLevel(SearchLogLevel level) => switch (level) {
        SearchLogLevel.debug => 500,
        SearchLogLevel.info => 800,
        SearchLogLevel.warning => 900,
        SearchLogLevel.error => 1000,
        SearchLogLevel.none => 0,
      };
}
