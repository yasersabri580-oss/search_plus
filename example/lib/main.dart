import 'package:flutter/material.dart';

import 'examples/basic_example.dart';
import 'examples/intermediate_example.dart';
import 'examples/advanced_example.dart';
import 'examples/full_showcase_example.dart';
import 'examples/original_example.dart';
import 'examples/overlay_example.dart';
import 'searchplus_demo.dart';

void main() {
  runApp(const SearchPlusExampleApp());
}

class SearchPlusExampleApp extends StatefulWidget {
  const SearchPlusExampleApp({super.key});

  @override
  State<SearchPlusExampleApp> createState() => _SearchPlusExampleAppState();
}

class _SearchPlusExampleAppState extends State<SearchPlusExampleApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'search_plus Examples',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6A4CFF)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A4CFF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: _ExampleHub(
        themeMode: _themeMode,
        onThemeModeChanged: (mode) => setState(() => _themeMode = mode),
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// Example Hub — gateway to all examples
// ---------------------------------------------------------------------------

class _ExampleHub extends StatelessWidget {
  const _ExampleHub({
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('search_plus'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              onThemeModeChanged(
                themeMode == ThemeMode.dark
                    ? ThemeMode.light
                    : ThemeMode.dark,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.tertiary,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search Plus',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Production-grade search for Flutter.\n'
                  'Local · Remote · Hybrid · Animated · Themed',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Example cards
          _ExampleCard(
            icon: Icons.play_arrow_rounded,
            title: 'Basic Example',
            subtitle: 'Minimal local search with zero config.',
            color: Colors.green,
            onTap: () => _push(context, const BasicExample()),
          ),
          _ExampleCard(
            icon: Icons.tune,
            title: 'Intermediate Example',
            subtitle: 'Custom themes, fuzzy search, animations.',
            color: Colors.blue,
            onTap: () => _push(context, const IntermediateExample()),
          ),
          _ExampleCard(
            icon: Icons.cloud_sync,
            title: 'Advanced Example',
            subtitle: 'Remote API, suggestions, history, grid.',
            color: Colors.deepPurple,
            onTap: () => _push(context, const AdvancedExample()),
          ),
          _ExampleCard(
            icon: Icons.rocket_launch,
            title: 'Full Showcase',
            subtitle: 'Filters, tabs, trending, all states.',
            color: Colors.orange,
            onTap: () => _push(context, const FullShowcaseExample()),
          ),
          _ExampleCard(
            icon: Icons.dashboard_customize,
            title: 'Original Example',
            subtitle: 'Local + remote + hybrid with full settings.',
            color: Colors.teal,
            onTap: () => _push(context, const OriginalExample()),
          ),
          _ExampleCard(
            icon: Icons.layers_outlined,
            title: 'Overlay Example',
            subtitle: 'Floating dropdown results over content.',
            color: Colors.indigo,
            onTap: () => _push(context, const OverlayExample()),
          ),
          const Divider(height: 32),
          _ExampleCard(
            icon: Icons.science,
            title: 'Interactive Demo',
            subtitle: 'Control panel for testing every feature. Ideal for recording demos.',
            color: Colors.red,
            onTap: () => _push(context, const SearchPlusDemo()),
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }
}

// ---------------------------------------------------------------------------
// Example card widget
// ---------------------------------------------------------------------------

class _ExampleCard extends StatelessWidget {
  const _ExampleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
