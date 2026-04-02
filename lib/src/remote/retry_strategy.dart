import 'dart:math';

import '../utils/search_logger.dart';

/// A strategy for retrying failed operations with configurable backoff.
///
/// Supports both constant and exponential backoff delays.
///
/// ```dart
/// final strategy = RetryStrategy(
///   maxAttempts: 3,
///   baseDelay: Duration(seconds: 1),
///   useExponentialBackoff: true,
/// );
///
/// final result = await strategy.execute(() => fetchFromApi());
/// ```
class RetryStrategy {
  /// Creates a retry strategy.
  const RetryStrategy({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(seconds: 1),
    this.useExponentialBackoff = true,
    this.maxDelay = const Duration(seconds: 30),
    this.jitter = true,
    this.retryIf,
  });

  /// Maximum number of retry attempts (total calls = maxAttempts + 1).
  final int maxAttempts;

  /// Base delay between retries.
  final Duration baseDelay;

  /// Whether to use exponential backoff (delay doubles each attempt).
  final bool useExponentialBackoff;

  /// Maximum delay between retries.
  final Duration maxDelay;

  /// Whether to add random jitter to delays (prevents thundering herd).
  final bool jitter;

  /// Optional predicate to decide if an error is retryable.
  ///
  /// If `null`, all errors are retried.
  final bool Function(Object error, int attempt)? retryIf;

  /// Calculates the delay for the given [attempt] number (0-based).
  Duration delayForAttempt(int attempt) {
    Duration delay;
    if (useExponentialBackoff) {
      final exponentialMs =
          baseDelay.inMilliseconds * pow(2, attempt).toInt();
      delay = Duration(
        milliseconds: min(exponentialMs, maxDelay.inMilliseconds),
      );
    } else {
      delay = baseDelay;
    }

    if (jitter) {
      final jitterMs = Random().nextInt(delay.inMilliseconds ~/ 4 + 1);
      delay = Duration(milliseconds: delay.inMilliseconds + jitterMs);
    }

    return delay;
  }

  /// Executes [operation] with retry logic.
  ///
  /// Returns the result of the first successful call.
  /// Throws the last error if all attempts fail.
  Future<T> execute<T>(Future<T> Function() operation) async {
    Object? lastError;
    StackTrace? lastStackTrace;

    for (var attempt = 0; attempt <= maxAttempts; attempt++) {
      try {
        if (attempt > 0) {
          final delay = delayForAttempt(attempt - 1);
          SearchLogger.debug(
            '[Retry] Attempt ${attempt + 1}/${maxAttempts + 1} '
            'after ${delay.inMilliseconds}ms delay',
          );
          await Future<void>.delayed(delay);
        }

        return await operation();
      } catch (e, st) {
        lastError = e;
        lastStackTrace = st;

        if (attempt >= maxAttempts) break;

        // Check if error is retryable
        if (retryIf != null && !retryIf!(e, attempt)) {
          SearchLogger.debug(
            '[Retry] Error not retryable at attempt ${attempt + 1}: $e',
          );
          break;
        }

        SearchLogger.warning(
          '[Retry] Attempt ${attempt + 1}/${maxAttempts + 1} failed: $e',
        );
      }
    }

    SearchLogger.error(
      '[Retry] All ${maxAttempts + 1} attempts failed',
      error: lastError,
    );
    if (lastError != null && lastStackTrace != null) {
      Error.throwWithStackTrace(lastError, lastStackTrace);
    }
    throw StateError('Retry failed with no error captured');
  }
}
