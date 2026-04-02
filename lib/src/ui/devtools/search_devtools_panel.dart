import 'package:flutter/material.dart';

import '../../core/search_controller.dart';
import '../../core/search_state.dart';
import '../../utils/search_logger.dart';

/// An enhanced debug overlay with tabbed interface showing live logs,
/// search results preview, and performance metrics.
///
/// Provides a floating debug button that expands into a rich debug panel
/// with three tabs: Logs, Results, and Performance.
///
/// ```dart
/// SearchDevToolsPanel(
///   controller: myController,
///   enabled: true,
///   child: MyApp(),
/// )
/// ```
class SearchDevToolsPanel<T> extends StatefulWidget {
  /// Creates a devtools panel overlay.
  const SearchDevToolsPanel({
    super.key,
    required this.controller,
    required this.child,
    this.enabled = true,
    this.initiallyExpanded = false,
    this.maxLogLines = 200,
    this.position = DevToolsPosition.bottomRight,
  });

  /// The search controller to observe.
  final SearchPlusController<T> controller;

  /// The screen content underneath the panel.
  final Widget child;

  /// Whether the devtools panel is enabled.
  final bool enabled;

  /// Whether the panel starts in expanded state.
  final bool initiallyExpanded;

  /// Maximum number of log lines to keep.
  final int maxLogLines;

  /// Position of the floating debug button.
  final DevToolsPosition position;

  @override
  State<SearchDevToolsPanel<T>> createState() => _SearchDevToolsPanelState<T>();
}

/// Position for the devtools floating button.
enum DevToolsPosition {
  /// Bottom-right corner.
  bottomRight,

  /// Bottom-left corner.
  bottomLeft,

  /// Top-right corner.
  topRight,

  /// Top-left corner.
  topLeft,
}

class _SearchDevToolsPanelState<T> extends State<SearchDevToolsPanel<T>>
    with TickerProviderStateMixin {
  late bool _expanded;
  final _logs = <_DevToolsLogEntry>[];
  final _performanceEntries = <_PerformanceEntry>[];
  final _scrollController = ScrollController();
  late TabController _tabController;
  Offset _dragOffset = Offset.zero;

  int _totalSearchCount = 0;
  int _cacheHitCount = 0;
  int _errorCount = 0;
  Duration _totalSearchDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _tabController = TabController(length: 3, vsync: this);

    if (widget.enabled) {
      SearchLogger.enable(
        level: SearchLogLevel.debug,
        onLog: _onLog,
      );
    }
  }

  void _onLog(
    SearchLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!mounted) return;
    setState(() {
      final entry = _DevToolsLogEntry(
        time: DateTime.now(),
        level: level,
        message: message,
      );
      _logs.add(entry);
      if (_logs.length > widget.maxLogLines) {
        _logs.removeRange(0, _logs.length - widget.maxLogLines);
      }

      // Track performance metrics
      _trackMetrics(message);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _trackMetrics(String message) {
    if (message.contains('[Search]') && message.contains('query=')) {
      _totalSearchCount++;
    }
    if (message.contains('[Cache] HIT')) {
      _cacheHitCount++;
    }
    if (message.contains('[Adapter]') && message.contains('failed')) {
      _errorCount++;
    }
    if (message.contains('returned') && message.contains('result(s)')) {
      // Extract timing from adapter messages
      final match = RegExp(r'in (\d+)ms').firstMatch(message);
      if (match != null) {
        final ms = int.tryParse(match.group(1)!);
        if (ms != null) {
          _totalSearchDuration += Duration(milliseconds: ms);
          _performanceEntries.add(_PerformanceEntry(
            time: DateTime.now(),
            durationMs: ms,
            query: _extractQuery(message),
          ));
          if (_performanceEntries.length > 50) {
            _performanceEntries.removeAt(0);
          }
        }
      }
    }
  }

  String _extractQuery(String message) {
    final match = RegExp(r'query="([^"]*)"').firstMatch(message);
    return match?.group(1) ?? '';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    if (widget.enabled) {
      SearchLogger.enable(level: SearchLogLevel.debug);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Stack(
      children: [
        widget.child,
        Positioned(
          right: widget.position == DevToolsPosition.bottomRight ||
                  widget.position == DevToolsPosition.topRight
              ? 8 + _dragOffset.dx
              : null,
          left: widget.position == DevToolsPosition.bottomLeft ||
                  widget.position == DevToolsPosition.topLeft
              ? 8 + _dragOffset.dx
              : null,
          bottom: widget.position == DevToolsPosition.bottomRight ||
                  widget.position == DevToolsPosition.bottomLeft
              ? 8 + _dragOffset.dy
              : null,
          top: widget.position == DevToolsPosition.topRight ||
                  widget.position == DevToolsPosition.topLeft
              ? 8 + _dragOffset.dy
              : null,
          child: _expanded ? _buildExpandedPanel() : _buildFloatingButton(),
        ),
      ],
    );
  }

  Widget _buildFloatingButton() {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _dragOffset += details.delta;
        });
      },
      child: FloatingActionButton.small(
        heroTag: 'search_devtools_panel',
        onPressed: () => setState(() => _expanded = true),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Badge(
          isLabelVisible: _errorCount > 0,
          label: Text('$_errorCount'),
          child: const Icon(Icons.developer_mode, size: 20),
        ),
      ),
    );
  }

  Widget _buildExpandedPanel() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(16),
      color: colorScheme.surfaceContainer,
      child: SizedBox(
        width: 360,
        height: 420,
        child: Column(
          children: [
            // Header
            _buildHeader(theme, colorScheme),
            // State summary
            _buildStateSummary(theme, colorScheme),
            // Tab bar
            Container(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              child: TabBar(
                controller: _tabController,
                labelStyle: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(
                    icon: const Icon(Icons.receipt_long, size: 14),
                    text: 'Logs (${_logs.length})',
                    height: 36,
                  ),
                  const Tab(
                    icon: Icon(Icons.list_alt, size: 14),
                    text: 'Results',
                    height: 36,
                  ),
                  const Tab(
                    icon: Icon(Icons.speed, size: 14),
                    text: 'Perf',
                    height: 36,
                  ),
                ],
              ),
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLogsTab(theme, colorScheme),
                  _buildResultsTab(theme, colorScheme),
                  _buildPerformanceTab(theme, colorScheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(Icons.developer_mode, size: 16, color: colorScheme.onPrimaryContainer),
          const SizedBox(width: 6),
          Text(
            'SearchPlus DevTools',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _IconButton(
            icon: Icons.delete_outline,
            color: colorScheme.onPrimaryContainer,
            onTap: () => setState(() {
              _logs.clear();
              _performanceEntries.clear();
              _totalSearchCount = 0;
              _cacheHitCount = 0;
              _errorCount = 0;
              _totalSearchDuration = Duration.zero;
            }),
            tooltip: 'Clear all',
          ),
          const SizedBox(width: 4),
          _IconButton(
            icon: Icons.close,
            color: colorScheme.onPrimaryContainer,
            onTap: () => setState(() => _expanded = false),
            tooltip: 'Minimize',
          ),
        ],
      ),
    );
  }

  Widget _buildStateSummary(ThemeData theme, ColorScheme colorScheme) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              _DevToolsStatusChip(status: state.status),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'q="${state.query}" '
                  'r=${state.results.length} '
                  'p=${state.currentPage}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'monospace',
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogsTab(ThemeData theme, ColorScheme colorScheme) {
    if (_logs.isEmpty) {
      return Center(
        child: Text(
          'No logs yet.\nPerform a search to see logs.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(6),
      itemCount: _logs.length,
      itemBuilder: (context, i) {
        final entry = _logs[i];
        final ts = '${entry.time.hour.toString().padLeft(2, '0')}:'
            '${entry.time.minute.toString().padLeft(2, '0')}:'
            '${entry.time.second.toString().padLeft(2, '0')}.'
            '${entry.time.millisecond.toString().padLeft(3, '0')}';
        return Padding(
          padding: const EdgeInsets.only(bottom: 1),
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
    );
  }

  Widget _buildResultsTab(ThemeData theme, ColorScheme colorScheme) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;
        if (state.results.isEmpty) {
          return Center(
            child: Text(
              'No results to preview.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(6),
          itemCount: state.results.length,
          itemBuilder: (context, i) {
            final result = state.results[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _SourceBadge(source: result.source),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          result.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      Text(
                        'score: ${result.score.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 9,
                          fontFamily: 'monospace',
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (result.subtitle != null)
                    Text(
                      result.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        fontFamily: 'monospace',
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPerformanceTab(ThemeData theme, ColorScheme colorScheme) {
    final avgMs = _performanceEntries.isNotEmpty
        ? (_totalSearchDuration.inMilliseconds / _performanceEntries.length)
            .round()
        : 0;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats grid
          Row(
            children: [
              _MetricCard(
                label: 'Searches',
                value: '$_totalSearchCount',
                icon: Icons.search,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              _MetricCard(
                label: 'Cache Hits',
                value: '$_cacheHitCount',
                icon: Icons.cached,
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MetricCard(
                label: 'Errors',
                value: '$_errorCount',
                icon: Icons.error_outline,
                color: colorScheme.error,
              ),
              const SizedBox(width: 8),
              _MetricCard(
                label: 'Avg Time',
                value: '${avgMs}ms',
                icon: Icons.timer,
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Recent Timings',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _performanceEntries.isEmpty
                ? Center(
                    child: Text(
                      'No performance data yet.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _performanceEntries.length,
                    itemBuilder: (context, i) {
                      final entry = _performanceEntries[
                          _performanceEntries.length - 1 - i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            _TimingBar(
                              durationMs: entry.durationMs,
                              maxMs: 2000,
                              color: _timingColor(entry.durationMs),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${entry.durationMs}ms',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _timingColor(int ms) {
    if (ms < 100) return Colors.green;
    if (ms < 300) return Colors.orange;
    return Colors.red;
  }

  Color _logColor(SearchLogLevel level, ColorScheme cs) => switch (level) {
        SearchLogLevel.debug => cs.onSurfaceVariant,
        SearchLogLevel.info => cs.primary,
        SearchLogLevel.warning => Colors.orange,
        SearchLogLevel.error => cs.error,
        SearchLogLevel.none => cs.onSurface,
      };
}

// ---------------------------------------------------------------------------
// Private helper widgets
// ---------------------------------------------------------------------------

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final child = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Icon(icon, size: 16, color: color),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: child);
    }
    return child;
  }
}

class _DevToolsStatusChip extends StatelessWidget {
  const _DevToolsStatusChip({required this.status});
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

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source});
  final dynamic source;

  @override
  Widget build(BuildContext context) {
    final label = source.toString().split('.').last.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(30),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimingBar extends StatelessWidget {
  const _TimingBar({
    required this.durationMs,
    required this.maxMs,
    required this.color,
  });

  final int durationMs;
  final int maxMs;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = (durationMs / maxMs).clamp(0.0, 1.0);
    return Expanded(
      child: Container(
        height: 8,
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(30),
          borderRadius: BorderRadius.circular(4),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: ratio,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

class _DevToolsLogEntry {
  _DevToolsLogEntry({
    required this.time,
    required this.level,
    required this.message,
  });

  final DateTime time;
  final SearchLogLevel level;
  final String message;
}

class _PerformanceEntry {
  _PerformanceEntry({
    required this.time,
    required this.durationMs,
    required this.query,
  });

  final DateTime time;
  final int durationMs;
  final String query;
}
