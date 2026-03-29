import 'package:flutter/material.dart';

import '../l10n/search_localizations.dart';
import '../theme/search_theme.dart';

/// A beautiful empty state widget shown when search returns no results.
class SearchEmptyState extends StatelessWidget {
  /// Creates an empty state widget.
  const SearchEmptyState({
    super.key,
    this.icon,
    this.title,
    this.subtitle,
    this.action,
    this.query,
  });

  /// Custom icon to display.
  final Widget? icon;

  /// Custom title text.
  final String? title;

  /// Custom subtitle text.
  final String? subtitle;

  /// Optional action widget (e.g., a button).
  final Widget? action;

  /// The search query that produced no results.
  final String? query;

  @override
  Widget build(BuildContext context) {
    final l10n = SearchLocalizationsProvider.of(context);
    final theme = Theme.of(context);
    final searchTheme = SearchTheme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon ??
                Icon(
                  Icons.search_off_rounded,
                  size: 64,
                  color: searchTheme.resultTheme.iconColor ??
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
            const SizedBox(height: 16),
            Text(
              title ?? l10n.emptyResultsText,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle ?? l10n.emptyResultsSubtext,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// A beautiful error state widget with retry functionality.
class SearchErrorState extends StatelessWidget {
  /// Creates an error state widget.
  const SearchErrorState({
    super.key,
    this.message,
    this.onRetry,
    this.icon,
  });

  /// Error message to display.
  final String? message;

  /// Callback when retry is pressed.
  final VoidCallback? onRetry;

  /// Custom icon to display.
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final l10n = SearchLocalizationsProvider.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon ??
                Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: theme.colorScheme.error.withValues(alpha: 0.7),
                ),
            const SizedBox(height: 16),
            Text(
              message ?? l10n.errorText,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: onRetry,
                child: Text(l10n.retryText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A loading state widget with shimmer or progress indicator.
class SearchLoadingState extends StatelessWidget {
  /// Creates a loading state widget.
  const SearchLoadingState({
    super.key,
    this.message,
    this.showShimmer = true,
    this.shimmerItemCount = 5,
  });

  /// Optional loading message.
  final String? message;

  /// Whether to show shimmer skeleton loading.
  final bool showShimmer;

  /// Number of shimmer items.
  final int shimmerItemCount;

  @override
  Widget build(BuildContext context) {
    final l10n = SearchLocalizationsProvider.of(context);

    if (showShimmer) {
      return const SizedBox.shrink(); // Shimmer is handled in results widget
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator.adaptive(),
            const SizedBox(height: 16),
            Text(
              message ?? l10n.loadingText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
