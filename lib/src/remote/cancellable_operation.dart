import 'dart:async';

import '../utils/search_logger.dart';

/// A cancellable async operation wrapper.
///
/// Allows cancellation of in-flight async operations. When cancelled,
/// the operation's result is discarded and the future completes with
/// a [CancellationException].
///
/// ```dart
/// final op = CancellableOperation<List<Result>>(
///   () => api.search('flutter'),
/// );
///
/// // Later, cancel if a new search is triggered
/// op.cancel();
/// ```
class CancellableOperation<T> {
  /// Creates a cancellable operation.
  CancellableOperation(Future<T> Function() operation)
      : _completer = Completer<T>() {
    _execute(operation);
  }

  final Completer<T> _completer;
  bool _cancelled = false;

  /// Whether this operation has been cancelled.
  bool get isCancelled => _cancelled;

  /// Whether this operation has completed (successfully or with error).
  bool get isCompleted => _completer.isCompleted;

  /// The future that completes with the operation result.
  Future<T> get future => _completer.future;

  Future<void> _execute(Future<T> Function() operation) async {
    try {
      final result = await operation();
      if (_cancelled) {
        SearchLogger.debug('[CancellableOp] Result discarded (cancelled)');
        if (!_completer.isCompleted) {
          _completer.completeError(
            CancellationException('Operation was cancelled'),
          );
        }
        return;
      }
      if (!_completer.isCompleted) {
        _completer.complete(result);
      }
    } catch (e, st) {
      if (_cancelled) {
        SearchLogger.debug(
          '[CancellableOp] Error discarded (cancelled): $e',
        );
        if (!_completer.isCompleted) {
          _completer.completeError(
            CancellationException('Operation was cancelled'),
          );
        }
        return;
      }
      if (!_completer.isCompleted) {
        _completer.completeError(e, st);
      }
    }
  }

  /// Cancels this operation.
  ///
  /// If the underlying future has not yet completed, the result will be
  /// discarded and [future] will complete with a [CancellationException].
  void cancel() {
    if (_cancelled || _completer.isCompleted) return;
    _cancelled = true;
    SearchLogger.debug('[CancellableOp] Operation cancelled');
  }
}

/// Exception thrown when a [CancellableOperation] is cancelled.
class CancellationException implements Exception {
  /// Creates a cancellation exception.
  const CancellationException([this.message = 'Operation was cancelled']);

  /// The message describing the cancellation.
  final String message;

  @override
  String toString() => 'CancellationException: $message';
}
