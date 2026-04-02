import 'package:flutter/material.dart';

/// A widget that displays search suggestions as interactive chips.
///
/// Typically used below the search bar to show trending topics,
/// recent searches, or auto-complete suggestions.
///
/// ```dart
/// SuggestionChips(
///   suggestions: ['Flutter', 'Dart', 'Widget'],
///   onSuggestionTap: (suggestion) => controller.searchImmediate(suggestion),
/// )
/// ```
class SuggestionChips extends StatelessWidget {
  /// Creates suggestion chips widget.
  const SuggestionChips({
    super.key,
    required this.suggestions,
    this.onSuggestionTap,
    this.selectedSuggestion,
    this.chipStyle,
    this.selectedChipStyle,
    this.icon,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.scrollable = false,
  });

  /// The list of suggestion strings to display.
  final List<String> suggestions;

  /// Called when a suggestion chip is tapped.
  final ValueChanged<String>? onSuggestionTap;

  /// The currently selected suggestion (if any).
  final String? selectedSuggestion;

  /// Style for unselected chips.
  final ChipThemeData? chipStyle;

  /// Style for the selected chip.
  final ChipThemeData? selectedChipStyle;

  /// Optional leading icon for each chip.
  final IconData? icon;

  /// Horizontal spacing between chips.
  final double spacing;

  /// Vertical spacing between rows.
  final double runSpacing;

  /// Padding around the chip area.
  final EdgeInsets padding;

  /// Whether to use a horizontal scrollable layout instead of wrap.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final chips = suggestions.map((suggestion) {
      final isSelected = suggestion == selectedSuggestion;
      return _buildChip(context, suggestion, isSelected, colorScheme);
    }).toList();

    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        child: Row(
          children: [
            for (int i = 0; i < chips.length; i++) ...[
              if (i > 0) SizedBox(width: spacing),
              chips[i],
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        children: chips,
      ),
    );
  }

  Widget _buildChip(
    BuildContext context,
    String suggestion,
    bool isSelected,
    ColorScheme colorScheme,
  ) {
    return Material(
      color: Colors.transparent,
      child: ActionChip(
        avatar: icon != null
            ? Icon(icon, size: 16, color: isSelected
                ? colorScheme.onSecondaryContainer
                : colorScheme.onSurfaceVariant)
            : null,
        label: Text(suggestion),
        labelStyle: TextStyle(
          color: isSelected
              ? colorScheme.onSecondaryContainer
              : colorScheme.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 13,
        ),
        backgroundColor: isSelected
            ? colorScheme.secondaryContainer
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        side: BorderSide(
          color: isSelected
              ? colorScheme.secondary.withValues(alpha: 0.3)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        onPressed: () => onSuggestionTap?.call(suggestion),
      ),
    );
  }
}
