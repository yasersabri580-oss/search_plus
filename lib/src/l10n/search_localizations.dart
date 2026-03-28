import 'package:flutter/widgets.dart';

/// Localization strings for the search_plus package.
///
/// Provides default English strings. Override to add other languages.
///
/// ```dart
/// SearchLocalizations(
///   hintText: 'Buscar...',
///   emptyResultsText: 'Sin resultados',
/// )
/// ```
class SearchLocalizations {
  /// Creates search localizations with default English strings.
  const SearchLocalizations({
    this.hintText = 'Search...',
    this.emptyResultsText = 'No results found',
    this.emptyResultsSubtext = 'Try a different search term',
    this.errorText = 'Something went wrong',
    this.retryText = 'Retry',
    this.clearText = 'Clear',
    this.cancelText = 'Cancel',
    this.searchHistoryTitle = 'Recent searches',
    this.suggestionsTitle = 'Suggestions',
    this.loadingText = 'Searching...',
    this.resultsCountText = '{count} results',
    this.voiceSearchTooltip = 'Voice search',
    this.clearSearchTooltip = 'Clear search',
  });

  final String hintText;
  final String emptyResultsText;
  final String emptyResultsSubtext;
  final String errorText;
  final String retryText;
  final String clearText;
  final String cancelText;
  final String searchHistoryTitle;
  final String suggestionsTitle;
  final String loadingText;
  final String resultsCountText;
  final String voiceSearchTooltip;
  final String clearSearchTooltip;

  /// Formats the results count text.
  String formatResultsCount(int count) {
    return resultsCountText.replaceAll('{count}', count.toString());
  }
}

/// An inherited widget that provides [SearchLocalizations] to descendants.
class SearchLocalizationsProvider extends InheritedWidget {
  /// Creates a localizations provider.
  const SearchLocalizationsProvider({
    super.key,
    required this.localizations,
    required super.child,
  });

  /// The localizations data.
  final SearchLocalizations localizations;

  /// Retrieves the nearest localizations or returns defaults.
  static SearchLocalizations of(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<SearchLocalizationsProvider>();
    return widget?.localizations ?? const SearchLocalizations();
  }

  @override
  bool updateShouldNotify(SearchLocalizationsProvider oldWidget) =>
      localizations != oldWidget.localizations;
}
