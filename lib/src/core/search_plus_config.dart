import '../utils/search_logger.dart';

/// Global configuration for the search_plus package.
///
/// Provides a simple interface for enabling debug logging and
/// configuring package-wide settings.
///
/// ```dart
/// // Enable debug logs
/// SearchPlusConfig.enableDebugLogs = true;
///
/// // Or use the detailed setup
/// SearchPlusConfig.configure(
///   enableDebugLogs: true,
///   logLevel: SearchLogLevel.info,
/// );
/// ```
class SearchPlusConfig {
  SearchPlusConfig._();

  static bool _debugLogs = false;

  /// Whether debug logging is enabled.
  ///
  /// Default: `false`. When set to `true`, enables structured debug
  /// logging with timestamps and lifecycle tracking.
  static bool get enableDebugLogs => _debugLogs;
  static set enableDebugLogs(bool value) {
    _debugLogs = value;
    if (value) {
      SearchLogger.enable(level: SearchLogLevel.debug);
    } else {
      SearchLogger.disable();
    }
  }

  /// Configure the package with detailed options.
  ///
  /// [enableDebugLogs] enables or disables debug logging.
  /// [logLevel] sets the minimum log level (default: debug when enabled).
  /// [onLog] provides a custom log handler callback.
  static void configure({
    bool enableDebugLogs = false,
    SearchLogLevel logLevel = SearchLogLevel.debug,
    SearchLogCallback? onLog,
  }) {
    _debugLogs = enableDebugLogs;
    if (enableDebugLogs) {
      SearchLogger.enable(level: logLevel, onLog: onLog);
    } else {
      SearchLogger.disable();
    }
  }

  /// Resets all configuration to defaults.
  static void reset() {
    _debugLogs = false;
    SearchLogger.disable();
  }
}
