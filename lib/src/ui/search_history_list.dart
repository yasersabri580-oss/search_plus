import 'package:flutter/material.dart';

/// A widget that displays search history with delete and tap actions.
///
/// ```dart
/// SearchHistoryList(
///   history: controller.state.history,
///   onHistoryTap: (query) => controller.searchImmediate(query),
///   onHistoryRemove: (query) => controller.removeFromHistory(query),
///   onClearAll: () => controller.clearHistory(),
/// )
/// ```
class SearchHistoryList extends StatelessWidget {
  /// Creates a search history list widget.
  const SearchHistoryList({
    super.key,
    required this.history,
    this.onHistoryTap,
    this.onHistoryRemove,
    this.onClearAll,
    this.title,
    this.maxItems = 10,
    this.showClearAll = true,
    this.icon = Icons.history_rounded,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  /// The list of history strings to display.
  final List<String> history;

  /// Called when a history item is tapped.
  final ValueChanged<String>? onHistoryTap;

  /// Called when a history item's remove button is tapped.
  final ValueChanged<String>? onHistoryRemove;

  /// Called when "Clear all" is tapped.
  final VoidCallback? onClearAll;

  /// Optional title for the history section.
  final String? title;

  /// Maximum number of items to display.
  final int maxItems;

  /// Whether to show the "Clear all" button.
  final bool showClearAll;

  /// Icon for each history item.
  final IconData icon;

  /// Padding around the list.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayItems = history.take(maxItems).toList();

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title ?? 'Recent searches',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (showClearAll && onClearAll != null)
                TextButton(
                  onPressed: onClearAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Clear all',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          // Items
          ...displayItems.map((query) => _HistoryItem(
                query: query,
                icon: icon,
                onTap: onHistoryTap != null ? () => onHistoryTap!(query) : null,
                onRemove: onHistoryRemove != null
                    ? () => onHistoryRemove!(query)
                    : null,
              )),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({
    required this.query,
    required this.icon,
    this.onTap,
    this.onRemove,
  });

  final String query;
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                query,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onRemove != null)
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: onRemove,
                tooltip: 'Remove',
              ),
          ],
        ),
      ),
    );
  }
}
