import 'package:flutter/widgets.dart';

/// Advanced configuration options for search behavior and text handling.
///
/// Use this to customize debouncing, input transformation, matching rules,
/// overlay behavior, animations, and result limits.
///
/// ```dart
/// SearchConfig(
///   debounceDuration: Duration(milliseconds: 400),
///   minQueryLength: 2,
///   trimInput: true,
///   caseSensitive: false,
///   overlayEnabled: true,
///   recentHistoryEnabled: true,
/// )
/// ```
class SearchConfig {
  /// Creates a search configuration with sane defaults.
  const SearchConfig({
    this.debounceDuration = const Duration(milliseconds: 300),
    this.minQueryLength = 1,
    this.maxResultCount = 50,
    this.trimInput = true,
    this.caseSensitive = false,
    this.inputTransformation = InputTransformation.none,
    this.autoCorrect = true,
    this.textCapitalization = TextCapitalization.none,
    this.searchInTitle = true,
    this.searchInSubtitle = true,
    this.searchInTags = true,
    this.recentHistoryEnabled = true,
    this.maxHistoryItems = 10,
    this.overlayEnabled = false,
    this.overlayMaxHeight = 400,
    this.animationEnabled = true,
  });

  /// Duration to debounce search queries.
  ///
  /// Defaults to 300 ms. Set higher for remote search, lower for local.
  final Duration debounceDuration;

  /// Minimum query length before search triggers.
  ///
  /// Defaults to 1. Set to 2 or 3 for large datasets or API search.
  final int minQueryLength;

  /// Maximum number of results to return.
  ///
  /// Defaults to 50.
  final int maxResultCount;

  /// Whether to trim whitespace from input before searching.
  ///
  /// Defaults to `true`.
  final bool trimInput;

  /// Whether search matching is case-sensitive.
  ///
  /// Defaults to `false` (case-insensitive).
  final bool caseSensitive;

  /// Text transformation to apply to the query before searching.
  ///
  /// Defaults to [InputTransformation.none].
  final InputTransformation inputTransformation;

  /// Whether autocorrect is enabled on the search text field.
  ///
  /// Defaults to `true`.
  final bool autoCorrect;

  /// Text capitalization for the search text field.
  ///
  /// Defaults to [TextCapitalization.none].
  final TextCapitalization textCapitalization;

  /// Whether to search in result titles.
  ///
  /// Defaults to `true`.
  final bool searchInTitle;

  /// Whether to search in result subtitles.
  ///
  /// Defaults to `true`.
  final bool searchInSubtitle;

  /// Whether to search in tags/keywords metadata.
  ///
  /// Defaults to `true`.
  final bool searchInTags;

  /// Whether to enable recent search history.
  ///
  /// Defaults to `true`.
  final bool recentHistoryEnabled;

  /// Maximum number of recent history items to keep.
  ///
  /// Defaults to 10.
  final int maxHistoryItems;

  /// Whether to display results in an overlay dropdown.
  ///
  /// Defaults to `false` (inline results).
  final bool overlayEnabled;

  /// Maximum height of the overlay dropdown panel.
  ///
  /// Defaults to 400 logical pixels.
  final double overlayMaxHeight;

  /// Whether animations are enabled.
  ///
  /// Defaults to `true`.
  final bool animationEnabled;

  /// Transforms the query string according to this config.
  String transformQuery(String query) {
    var result = query;
    if (trimInput) {
      result = result.trim();
    }
    switch (inputTransformation) {
      case InputTransformation.none:
        break;
      case InputTransformation.lowercase:
        result = result.toLowerCase();
      case InputTransformation.uppercase:
        result = result.toUpperCase();
    }
    return result;
  }

  /// Creates a copy with the given fields replaced.
  SearchConfig copyWith({
    Duration? debounceDuration,
    int? minQueryLength,
    int? maxResultCount,
    bool? trimInput,
    bool? caseSensitive,
    InputTransformation? inputTransformation,
    bool? autoCorrect,
    TextCapitalization? textCapitalization,
    bool? searchInTitle,
    bool? searchInSubtitle,
    bool? searchInTags,
    bool? recentHistoryEnabled,
    int? maxHistoryItems,
    bool? overlayEnabled,
    double? overlayMaxHeight,
    bool? animationEnabled,
  }) {
    return SearchConfig(
      debounceDuration: debounceDuration ?? this.debounceDuration,
      minQueryLength: minQueryLength ?? this.minQueryLength,
      maxResultCount: maxResultCount ?? this.maxResultCount,
      trimInput: trimInput ?? this.trimInput,
      caseSensitive: caseSensitive ?? this.caseSensitive,
      inputTransformation: inputTransformation ?? this.inputTransformation,
      autoCorrect: autoCorrect ?? this.autoCorrect,
      textCapitalization: textCapitalization ?? this.textCapitalization,
      searchInTitle: searchInTitle ?? this.searchInTitle,
      searchInSubtitle: searchInSubtitle ?? this.searchInSubtitle,
      searchInTags: searchInTags ?? this.searchInTags,
      recentHistoryEnabled: recentHistoryEnabled ?? this.recentHistoryEnabled,
      maxHistoryItems: maxHistoryItems ?? this.maxHistoryItems,
      overlayEnabled: overlayEnabled ?? this.overlayEnabled,
      overlayMaxHeight: overlayMaxHeight ?? this.overlayMaxHeight,
      animationEnabled: animationEnabled ?? this.animationEnabled,
    );
  }
}

/// Text transformation applied to search input.
enum InputTransformation {
  /// No transformation.
  none,

  /// Convert to lowercase.
  lowercase,

  /// Convert to uppercase.
  uppercase,
}
