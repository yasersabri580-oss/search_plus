import 'package:flutter/material.dart';

/// A widget that highlights matched portions of text.
///
/// Renders the [text] with [query] portions highlighted using
/// a configurable style. Great for showing which part of a search result
/// matched the query.
///
/// ```dart
/// HighlightText(
///   text: 'Flutter Framework',
///   query: 'Flu',
///   highlightStyle: TextStyle(
///     backgroundColor: Colors.yellow.withValues(alpha: 0.3),
///     fontWeight: FontWeight.bold,
///   ),
/// )
/// ```
class HighlightText extends StatelessWidget {
  /// Creates a highlight text widget.
  const HighlightText({
    super.key,
    required this.text,
    required this.query,
    this.style,
    this.highlightStyle,
    this.highlightColor,
    this.caseSensitive = false,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
  });

  /// The full text to display.
  final String text;

  /// The query to highlight within [text].
  final String query;

  /// Style for non-highlighted portions.
  final TextStyle? style;

  /// Style for highlighted portions.
  ///
  /// Defaults to bold with a soft yellow background.
  final TextStyle? highlightStyle;

  /// Background color for highlighted portions.
  final Color? highlightColor;

  /// Whether the match is case-sensitive.
  final bool caseSensitive;

  /// Maximum number of lines to display.
  final int? maxLines;

  /// How to handle text overflow.
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text, style: style, maxLines: maxLines, overflow: overflow);
    }

    final theme = Theme.of(context);
    final defaultStyle = style ?? theme.textTheme.bodyMedium ?? const TextStyle();
    final defaultHighlight = highlightStyle ??
        defaultStyle.copyWith(
          fontWeight: FontWeight.bold,
          backgroundColor: highlightColor ??
              theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
          color: theme.colorScheme.onPrimaryContainer,
        );

    final spans = _buildSpans(defaultStyle, defaultHighlight);

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  List<TextSpan> _buildSpans(TextStyle normalStyle, TextStyle matchStyle) {
    final spans = <TextSpan>[];

    final textToSearch = caseSensitive ? text : text.toLowerCase();
    final queryToFind = caseSensitive ? query : query.toLowerCase();

    int start = 0;
    while (start < text.length) {
      final index = textToSearch.indexOf(queryToFind, start);
      if (index == -1) {
        // No more matches — add remaining text
        spans.add(TextSpan(
          text: text.substring(start),
          style: normalStyle,
        ));
        break;
      }

      // Add text before match
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: normalStyle,
        ));
      }

      // Add matched text (preserving original case)
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: matchStyle,
      ));

      start = index + query.length;
    }

    return spans;
  }
}
