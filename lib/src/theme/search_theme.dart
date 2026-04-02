import 'package:flutter/material.dart';

/// Theme data for the search_plus package.
///
/// Provides comprehensive theming that integrates with Flutter's [ThemeData].
///
/// Use [SearchTheme] inherited widget to apply themes to descendants.
class SearchPlusThemeData {
  /// Creates search theme data.
  const SearchPlusThemeData({
    this.searchBarTheme = const SearchBarThemeData(),
    this.resultTheme = const SearchResultThemeData(),
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
  });

  /// Theme for the search bar.
  final SearchBarThemeData searchBarTheme;

  /// Theme for search results.
  final SearchResultThemeData resultTheme;

  /// Default animation duration.
  final Duration animationDuration;

  /// Default animation curve.
  final Curve animationCurve;

  /// Creates a copy with the given fields replaced.
  SearchPlusThemeData copyWith({
    SearchBarThemeData? searchBarTheme,
    SearchResultThemeData? resultTheme,
    Duration? animationDuration,
    Curve? animationCurve,
  }) {
    return SearchPlusThemeData(
      searchBarTheme: searchBarTheme ?? this.searchBarTheme,
      resultTheme: resultTheme ?? this.resultTheme,
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
    );
  }

  /// Resolves defaults from the [BuildContext]'s theme.
  SearchPlusThemeData resolve(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SearchPlusThemeData(
      searchBarTheme: searchBarTheme.resolve(context, colorScheme),
      resultTheme: resultTheme.resolve(context, colorScheme),
      animationDuration: animationDuration,
      animationCurve: animationCurve,
    );
  }
}

/// Theme data for the search bar widget.
class SearchBarThemeData {
  /// Creates search bar theme data.
  const SearchBarThemeData({
    this.backgroundColor,
    this.focusedBackgroundColor,
    this.borderRadius,
    this.elevation,
    this.focusedElevation,
    this.padding,
    this.height,
    this.textStyle,
    this.hintStyle,
    this.iconColor,
    this.cursorColor,
    this.borderColor,
    this.focusedBorderColor,
    this.borderWidth,
    this.shadowColor,
  });

  final Color? backgroundColor;
  final Color? focusedBackgroundColor;
  final BorderRadius? borderRadius;
  final double? elevation;
  final double? focusedElevation;
  final EdgeInsets? padding;
  final double? height;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final Color? iconColor;
  final Color? cursorColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final double? borderWidth;
  final Color? shadowColor;

  /// Resolves defaults from the color scheme.
  SearchBarThemeData resolve(BuildContext context, ColorScheme colorScheme) {
    return SearchBarThemeData(
      backgroundColor:
          backgroundColor ?? colorScheme.surfaceContainerHighest,
      focusedBackgroundColor:
          focusedBackgroundColor ?? colorScheme.surfaceContainerHighest,
      borderRadius: borderRadius ?? BorderRadius.circular(28),
      elevation: elevation ?? 0,
      focusedElevation: focusedElevation ?? 2,
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      height: height ?? 56,
      textStyle: textStyle ??
          Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: colorScheme.onSurface),
      hintStyle: hintStyle ??
          Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant),
      iconColor: iconColor ?? colorScheme.onSurfaceVariant,
      cursorColor: cursorColor ?? colorScheme.primary,
      borderColor: borderColor ?? colorScheme.outline.withValues(alpha: 0.2),
      focusedBorderColor: focusedBorderColor ?? colorScheme.primary,
      borderWidth: borderWidth ?? 1.0,
      shadowColor: shadowColor ?? colorScheme.shadow.withValues(alpha: 0.1),
    );
  }
}

/// Theme data for search result items.
class SearchResultThemeData {
  /// Creates search result theme data.
  const SearchResultThemeData({
    this.backgroundColor,
    this.selectedColor,
    this.hoveredColor,
    this.titleStyle,
    this.subtitleStyle,
    this.highlightColor,
    this.highlightStyle,
    this.dividerColor,
    this.iconColor,
    this.sectionHeaderStyle,
    this.sectionHeaderBackgroundColor,
    this.contentPadding,
    this.itemSpacing,
    this.imageSize,
    this.imageBorderRadius,
  });

  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? hoveredColor;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final Color? highlightColor;
  final TextStyle? highlightStyle;
  final Color? dividerColor;
  final Color? iconColor;
  final TextStyle? sectionHeaderStyle;
  final Color? sectionHeaderBackgroundColor;
  final EdgeInsets? contentPadding;
  final double? itemSpacing;
  final double? imageSize;
  final BorderRadius? imageBorderRadius;

  /// Resolves defaults from the color scheme.
  SearchResultThemeData resolve(
      BuildContext context, ColorScheme colorScheme) {
    return SearchResultThemeData(
      backgroundColor: backgroundColor ?? Colors.transparent,
      selectedColor: selectedColor ?? colorScheme.primaryContainer,
      hoveredColor:
          hoveredColor ?? colorScheme.onSurface.withValues(alpha: 0.04),
      titleStyle: titleStyle ??
          Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: colorScheme.onSurface),
      subtitleStyle: subtitleStyle ??
          Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: colorScheme.onSurfaceVariant),
      highlightColor: highlightColor ?? colorScheme.primaryContainer,
      highlightStyle: highlightStyle ??
          Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
      dividerColor:
          dividerColor ?? colorScheme.outlineVariant.withValues(alpha: 0.5),
      iconColor: iconColor ?? colorScheme.onSurfaceVariant,
      sectionHeaderStyle: sectionHeaderStyle ??
          Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
      sectionHeaderBackgroundColor: sectionHeaderBackgroundColor ??
          colorScheme.surfaceContainerLow,
      contentPadding: contentPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemSpacing: itemSpacing ?? 0,
      imageSize: imageSize ?? 48,
      imageBorderRadius: imageBorderRadius ?? BorderRadius.circular(8),
    );
  }
}

/// An inherited widget that provides [SearchPlusThemeData] to descendants.
class SearchTheme extends InheritedWidget {
  /// Creates a search theme.
  const SearchTheme({
    super.key,
    required this.data,
    required super.child,
  });

  /// The theme data.
  final SearchPlusThemeData data;

  /// Retrieves the nearest [SearchPlusThemeData] or returns defaults.
  static SearchPlusThemeData of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<SearchTheme>();
    if (widget != null) {
      return widget.data.resolve(context);
    }
    return const SearchPlusThemeData().resolve(context);
  }

  @override
  bool updateShouldNotify(SearchTheme oldWidget) => data != oldWidget.data;
}

/// Deprecated: Use [SearchPlusThemeData] instead.
@Deprecated('Use SearchPlusThemeData instead. SearchThemeData was renamed to SearchPlusThemeData.')
typedef SearchThemeData = SearchPlusThemeData;
