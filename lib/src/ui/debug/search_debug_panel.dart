import 'package:flutter/material.dart';

import '../../core/search_controller.dart';
import '../../core/search_state.dart';
import '../../utils/search_logger.dart';

/// An on-screen debug overlay that shows live search state, query, result
/// count, and a scrollable log of recent [SearchLogger] messages.
///
/// Wrap your example screen with this widget to get a draggable debug panel:
///
/// ```dart
/// SearchDebugPanel(
///   controller: myController,
///   child: MySearchScreen(),
/// )
/// ```
class SearchDebugPanel<T> extends StatefulWidget {
  /// Creates a debug panel overlay.
  const SearchDebugPanel({
    super.key,
    required this.controller,
    required this.child,
    this.initiallyExpanded = false,
    this.maxLogLines = 100,
  });

  /// The search controller to observe.
  final SearchPlusController<T> controller;

  /// The screen content underneath the panel.
  final Widget child;

  /// Whether the panel starts in expanded state.
  final bool initiallyExpanded;

  /// Maximum number of log lines to keep.
  final int maxLogLines;

  @override
  State<SearchDebugPanel<T>> createState() => _SearchDebugPanelState<T>();
}

class _SearchDebugPanelState<T> extends State<SearchDebugPanel<T>> {
  late bool _expanded;
  final _logs = <_LogEntry>[];
  final _scrollController = ScrollController();
  SearchLogCallback? _previousCallback;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;

    // Capture logs into our in-memory buffer while preserving any existing
    // callback.
    _previousCallback = null; // We don't chain — we own the callback.
    SearchLogger.enable(
      level: SearchLogLevel.debug,
      onLog: _onLog,
    );
  }

  void _onLog(SearchLogLevel level, String message,
      {Object? error, StackTrace? stackTrace}) {
    if (!mounted) return;
    setState(() {
      _logs.add(_LogEntry(
        time: DateTime.now(),
        level: level,
        message: message,
      ));
      if (_logs.length > widget.maxLogLines) {
        _logs.removeRange(0, _logs.length - widget.maxLogLines);
      }
    });
    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Restore to default dart:developer logging
    SearchLogger.enable(level: SearchLogLevel.debug);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          right: 8,
          bottom: 8,
          child: _expanded ? _buildExpandedPanel() : _buildCollapsedButton(),
        ),
      ],
    );
  }

  Widget _buildCollapsedButton() {
    return FloatingActionButton.small(
      heroTag: 'search_debug_panel',
      onPressed: () => setState(() => _expanded = true),
      child: const Icon(Icons.bug_report, size: 20),
    );
  }

  Widget _buildExpandedPanel() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: colorScheme.surfaceContainer,
      child: SizedBox(
        width: 320,
        height: 340,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(Icons.bug_report,
                      size: 16, color: colorScheme.onPrimaryContainer),
                  const SizedBox(width: 6),
                  Text(
                    'Debug Panel',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => setState(() => _logs.clear()),
                    child: Icon(Icons.delete_outline,
                        size: 16, color: colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => setState(() => _expanded = false),
                    child: Icon(Icons.close,
                        size: 16, color: colorScheme.onPrimaryContainer),
                  ),
                ],
              ),
            ),
            // State summary
            ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                final state = widget.controller.state;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: colorScheme.surfaceContainerHighest,
                  child: DefaultTextStyle(
                    style: theme.textTheme.labelSmall!.copyWith(
                      fontFamily: 'monospace',
                      color: colorScheme.onSurface,
                    ),
                    child: Row(
                      children: [
                        _StatusChip(status: state.status),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'q="${state.query}" '
                            'r=${state.results.length} '
                            'h=${state.history.length}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Log list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(6),
                itemCount: _logs.length,
                itemBuilder: (context, i) {
                  final entry = _logs[i];
                  final ts =
                      '${entry.time.hour.toString().padLeft(2, '0')}:'
                      '${entry.time.minute.toString().padLeft(2, '0')}:'
                      '${entry.time.second.toString().padLeft(2, '0')}';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '$ts ${entry.message}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: _logColor(entry.level, colorScheme),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _logColor(SearchLogLevel level, ColorScheme cs) => switch (level) {
        SearchLogLevel.debug => cs.onSurfaceVariant,
        SearchLogLevel.info => cs.primary,
        SearchLogLevel.warning => Colors.orange,
        SearchLogLevel.error => cs.error,
        SearchLogLevel.none => cs.onSurface,
      };
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final SearchStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      SearchStatus.idle => (Colors.grey, 'IDLE'),
      SearchStatus.loading => (Colors.blue, 'LOAD'),
      SearchStatus.success => (Colors.green, 'OK'),
      SearchStatus.empty => (Colors.orange, 'EMPTY'),
      SearchStatus.error => (Colors.red, 'ERR'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _LogEntry {
  _LogEntry({
    required this.time,
    required this.level,
    required this.message,
  });

  final DateTime time;
  final SearchLogLevel level;
  final String message;
}
