import 'package:flutter/material.dart';
import 'package:search_plus/search_plus.dart';

/// Demonstrates [AppBarSearchButton] — a compact expandable search action
/// designed to live inside an [AppBar.actions] list.
///
/// The example shows:
/// * Default icon-only appearance.
/// * Smooth expand on hover (desktop / web) and tap (all platforms).
/// * Persistent expanded state while text is present.
/// * Auto-collapse when the field is cleared and focus is lost.
/// * Live filtering of a local fruit list.
/// * Responsive layout that works on both narrow and wide screens.
class AppBarSearchExample extends StatefulWidget {
  const AppBarSearchExample({super.key});

  @override
  State<AppBarSearchExample> createState() => _AppBarSearchExampleState();
}

class _AppBarSearchExampleState extends State<AppBarSearchExample> {
  static const _allItems = [
    'Apple',
    'Apricot',
    'Banana',
    'Blueberry',
    'Cherry',
    'Coconut',
    'Date',
    'Elderberry',
    'Fig',
    'Grape',
    'Guava',
    'Honeydew',
    'Kiwi',
    'Lemon',
    'Lime',
    'Lychee',
    'Mango',
    'Nectarine',
    'Orange',
    'Papaya',
    'Peach',
    'Pear',
    'Pineapple',
    'Plum',
    'Pomegranate',
    'Raspberry',
    'Strawberry',
    'Tangerine',
    'Watermelon',
  ];

  String _query = '';

  List<String> get _filtered => _query.isEmpty
      ? _allItems
      : _allItems
          .where((item) => item.toLowerCase().contains(_query.toLowerCase()))
          .toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AppBar Search'),
        centerTitle: true,
        actions: [
          // ── AppBarSearchButton lives here ────────────────────────────────
          AppBarSearchButton(
            hintText: 'Search fruits…',
            onChanged: (query) => setState(() => _query = query),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ── Instruction banner ───────────────────────────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _query.isEmpty
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: _Banner(
              icon: Icons.mouse_outlined,
              text: 'Hover over the 🔍 icon (desktop) or tap it to expand'
                  ' the search field.',
              color: colorScheme.secondaryContainer,
              textColor: colorScheme.onSecondaryContainer,
            ),
            secondChild: _Banner(
              icon: Icons.filter_list_rounded,
              text: 'Showing results for "$_query"',
              color: colorScheme.primaryContainer,
              textColor: colorScheme.onPrimaryContainer,
            ),
          ),

          // ── Results list ─────────────────────────────────────────────────
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 56,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No results for "$_query"',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 72,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                    itemBuilder: (context, index) {
                      final item = _filtered[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              colorScheme.primaryContainer.withValues(
                            alpha: 0.6,
                          ),
                          child: Text(
                            item[0],
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: _HighlightedText(
                          text: item,
                          query: _query,
                          style: theme.textTheme.bodyLarge!,
                          highlightColor: colorScheme.primaryContainer,
                          highlightTextColor: colorScheme.onPrimaryContainer,
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onTap: () {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text('Selected: $item'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.text,
    required this.color,
    required this.textColor,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: textColor.withValues(alpha: 0.8)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: textColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders [text] with the matching [query] portion highlighted.
class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.query,
    required this.style,
    required this.highlightColor,
    required this.highlightTextColor,
  });

  final String text;
  final String query;
  final TextStyle style;
  final Color highlightColor;
  final Color highlightTextColor;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return Text(text, style: style);

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matchStart = lowerText.indexOf(lowerQuery);

    if (matchStart == -1) return Text(text, style: style);

    final matchEnd = matchStart + query.length;

    return Text.rich(
      TextSpan(
        children: [
          if (matchStart > 0)
            TextSpan(
              text: text.substring(0, matchStart),
              style: style,
            ),
          TextSpan(
            text: text.substring(matchStart, matchEnd),
            style: style.copyWith(
              backgroundColor: highlightColor,
              color: highlightTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (matchEnd < text.length)
            TextSpan(
              text: text.substring(matchEnd),
              style: style,
            ),
        ],
      ),
    );
  }
}
