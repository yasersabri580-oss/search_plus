import 'package:flutter/material.dart' hide SearchBarThemeData;
import 'package:search_plus/search_plus.dart';

import 'api/fake_search_api.dart';

/// 🧪 Interactive demo screen for recording demos and testing every feature.
///
/// Toggle between datasets, styles, states, animations, and layouts from a
/// single screen with a control panel drawer.
class SearchPlusDemo extends StatefulWidget {
  const SearchPlusDemo({super.key});

  @override
  State<SearchPlusDemo> createState() => _SearchPlusDemoState();
}

// ---------------------------------------------------------------------------
// Enums for control panel
// ---------------------------------------------------------------------------

enum _Dataset { products, users, articles }

enum _StylePreset { minimal, modernSaas, dark, social, glass, darkPremium }

enum _ForcedState { none, loading, empty, error }

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class _SearchPlusDemoState extends State<SearchPlusDemo> {
  // -- Control panel values --
  _Dataset _dataset = _Dataset.products;
  _StylePreset _style = _StylePreset.modernSaas;
  SearchAnimationPreset _animation = SearchAnimationPreset.fadeSlideUp;
  SearchResultsLayout _layout = SearchResultsLayout.list;
  SearchResultDensity _density = SearchResultDensity.comfortable;
  _ForcedState _forcedState = _ForcedState.none;
  double _simulatedDelay = 600;
  bool _overlayMode = false;

  // -- API & controller --
  late FakeSearchApi _api;
  SearchPlusController<dynamic>? _controller;

  @override
  void initState() {
    super.initState();
    _rebuildController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _rebuildController() {
    _controller?.dispose();

    _api = FakeSearchApi(
      minDelay: Duration(milliseconds: (_simulatedDelay * 0.5).round()),
      maxDelay: Duration(milliseconds: _simulatedDelay.round()),
      errorRate: _forcedState == _ForcedState.error ? 1.0 : 0.0,
    );

    switch (_dataset) {
      case _Dataset.products:
        _controller = SearchPlusController<Product>(
          adapter: RemoteSearchAdapter<Product>(
            searchFunction: (q, limit, offset) => _api.searchProducts(q, limit: limit, offset: offset),
            suggestFunction: _api.suggestProducts,
          ),
          debounceDuration: const Duration(milliseconds: 300),
          maxHistoryItems: 8,
        );
      case _Dataset.users:
        _controller = SearchPlusController<AppUser>(
          adapter: RemoteSearchAdapter<AppUser>(
            searchFunction: (q, limit, offset) => _api.searchUsers(q, limit: limit, offset: offset),
            suggestFunction: _api.suggestUsers,
          ),
          debounceDuration: const Duration(milliseconds: 300),
          maxHistoryItems: 8,
        );
      case _Dataset.articles:
        _controller = SearchPlusController<Article>(
          adapter: RemoteSearchAdapter<Article>(
            searchFunction: (q, limit, offset) => _api.searchArticles(q, limit: limit, offset: offset),
          ),
          debounceDuration: const Duration(milliseconds: 300),
          maxHistoryItems: 8,
        );
    }

    if (mounted) setState(() {});
  }

  // -- Theme data per style preset ------------------------------------------

  SearchThemeData _themeForPreset(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (_style) {
      case _StylePreset.minimal:
        return SearchThemeData(
          searchBarTheme: SearchBarThemeData(
            borderRadius: BorderRadius.circular(8),
            elevation: 0,
            focusedElevation: 0,
            borderColor: cs.outline,
            focusedBorderColor: cs.primary,
            borderWidth: 1,
          ),
          resultTheme: const SearchResultThemeData(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        );
      case _StylePreset.modernSaas:
        return SearchThemeData(
          searchBarTheme: SearchBarThemeData(
            borderRadius: BorderRadius.circular(16),
            elevation: 0,
            focusedElevation: 4,
            shadowColor: cs.primary.withAlpha(30),
            focusedBorderColor: cs.primary,
          ),
          resultTheme: SearchResultThemeData(
            highlightColor: cs.primaryContainer,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
      case _StylePreset.dark:
        return SearchThemeData(
          searchBarTheme: SearchBarThemeData(
            borderRadius: BorderRadius.circular(12),
            backgroundColor: const Color(0xFF1E1E1E),
            focusedBackgroundColor: const Color(0xFF2A2A2A),
            borderColor: Colors.white24,
            focusedBorderColor: Colors.tealAccent,
            elevation: 0,
          ),
          resultTheme: const SearchResultThemeData(
            backgroundColor: Color(0xFF1E1E1E),
            highlightColor: Color(0xFF004D40),
            titleStyle: TextStyle(color: Colors.white),
            subtitleStyle: TextStyle(color: Colors.white70),
          ),
        );
      case _StylePreset.social:
        return SearchThemeData(
          searchBarTheme: SearchBarThemeData(
            borderRadius: BorderRadius.circular(28),
            backgroundColor: cs.surfaceContainerHighest.withAlpha(80),
            focusedBorderColor: cs.primary,
            height: 48,
          ),
          resultTheme: SearchResultThemeData(
            highlightColor: cs.primary.withAlpha(40),
          ),
        );
      case _StylePreset.glass:
        return SearchThemeData(
          searchBarTheme: SearchBarThemeData(
            borderRadius: BorderRadius.circular(20),
            backgroundColor: Colors.white.withAlpha(25),
            focusedBackgroundColor: Colors.white.withAlpha(40),
            borderColor: Colors.white30,
            focusedBorderColor: Colors.white70,
            elevation: 0,
          ),
          resultTheme: SearchResultThemeData(
            backgroundColor: Colors.white.withAlpha(15),
            highlightColor: Colors.white.withAlpha(25),
            titleStyle: TextStyle(color: Colors.white.withAlpha(230)),
            subtitleStyle: TextStyle(color: Colors.white.withAlpha(180)),
          ),
        );
      case _StylePreset.darkPremium:
        return SearchThemeData(
          searchBarTheme: SearchBarThemeData(
            borderRadius: BorderRadius.circular(14),
            backgroundColor: const Color(0xFF1A1A2E),
            focusedBackgroundColor: const Color(0xFF16213E),
            borderColor: const Color(0xFF0F3460),
            focusedBorderColor: const Color(0xFFE94560),
            elevation: 0,
            focusedElevation: 4,
            shadowColor: const Color(0xFFE94560).withAlpha(40),
          ),
          resultTheme: const SearchResultThemeData(
            backgroundColor: Color(0xFF1A1A2E),
            highlightColor: Color(0xFF0F3460),
            titleStyle: TextStyle(color: Color(0xFFEEEEEE)),
            subtitleStyle: TextStyle(color: Color(0xFF888888)),
          ),
        );
    }
  }

  // -- Build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isGlass = _style == _StylePreset.glass;
    final isDarkStyle =
        _style == _StylePreset.dark || _style == _StylePreset.darkPremium;

    Widget body = _buildSearchBody(context);

    // Glassmorphism background
    if (isGlass) {
      body = Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6A11CB),
              Color(0xFF2575FC),
            ],
          ),
        ),
        child: body,
      );
    }

    // Dark style background
    if (isDarkStyle) {
      body = ColoredBox(
        color: _style == _StylePreset.darkPremium
            ? const Color(0xFF0A0A23)
            : const Color(0xFF121212),
        child: body,
      );
    }

    return Theme(
      data: isDarkStyle || isGlass
          ? ThemeData.dark(useMaterial3: true).copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: isGlass
                    ? Colors.deepPurple
                    : _style == _StylePreset.darkPremium
                        ? const Color(0xFFE94560)
                        : Colors.teal,
                brightness: Brightness.dark,
              ),
            )
          : Theme.of(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('SearchPlus Demo'),
          backgroundColor: isGlass || isDarkStyle
              ? Colors.transparent
              : null,
          elevation: 0,
          foregroundColor: isGlass || isDarkStyle ? Colors.white : null,
        ),
        endDrawer: _ControlDrawer(
          dataset: _dataset,
          style: _style,
          animation: _animation,
          layout: _layout,
          density: _density,
          forcedState: _forcedState,
          simulatedDelay: _simulatedDelay,
          overlayMode: _overlayMode,
          onDatasetChanged: (v) {
            setState(() => _dataset = v);
            _rebuildController();
          },
          onStyleChanged: (v) => setState(() => _style = v),
          onAnimationChanged: (v) => setState(() => _animation = v),
          onLayoutChanged: (v) => setState(() => _layout = v),
          onDensityChanged: (v) => setState(() => _density = v),
          onForcedStateChanged: (v) {
            setState(() => _forcedState = v);
            _rebuildController();
          },
          onDelayChanged: (v) {
            setState(() => _simulatedDelay = v);
            _rebuildController();
          },
          onOverlayChanged: (v) => setState(() => _overlayMode = v),
        ),
        body: body,
      ),
    );
  }

  Widget _buildSearchBody(BuildContext context) {
    if (_controller == null) return const SizedBox.shrink();

    // Build an overridden state if forced
    final overrideState = _buildForcedState();

    return SearchTheme(
      data: _themeForPreset(context),
      child: _overlayMode
          ? _buildOverlayBody(context)
          : _buildInlineBody(context, overrideState),
    );
  }

  Widget _buildOverlayBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchOverlay<dynamic>(
            controller: _controller!,
            hintText: 'Search ${_dataset.name}…',
            maxOverlayHeight: 350,
            animationConfig: SearchAnimationConfig(
              preset: _animation,
              duration: const Duration(milliseconds: 250),
            ),
            onItemTap: (result) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text('Selected: ${result.title}')),
                );
            },
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Center(
              child: Text(
                'Overlay mode — results appear above this content',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.6),
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineBody(
      BuildContext context, SearchState<dynamic>? overrideState) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SearchPlusBar(
            onChanged: (q) => _controller!.search(q),
            onSubmitted: (q) {
              _controller!.addToHistory(q);
              _controller!.searchImmediate(q);
            },
            hintText: 'Search ${_dataset.name}…',
            leading: const Icon(Icons.search),
          ),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: _controller!,
            builder: (context, _) {
              final state = overrideState ?? _controller!.state;
              return SearchResultsWidget<dynamic>(
                state: state,
                layout: _layout,
                density: _density,
                animationConfig: SearchAnimationConfig(
                  preset: _animation,
                  duration: const Duration(milliseconds: 300),
                  staggerDelay: const Duration(milliseconds: 50),
                ),
                showShimmer: true,
                gridCrossAxisCount: 2,
                emptyState: const SearchEmptyState(
                  icon: Icon(Icons.search_off, size: 64),
                  title: 'Nothing found',
                  subtitle: 'Try a different keyword.',
                ),
                errorState: SearchErrorState(
                  icon: const Icon(Icons.error_outline, size: 64),
                  message: 'Simulated error. Tap retry.',
                  onRetry: () =>
                      _controller!.searchImmediate(_controller!.query),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  SearchState<dynamic>? _buildForcedState() {
    switch (_forcedState) {
      case _ForcedState.none:
        return null;
      case _ForcedState.loading:
        return const SearchState(
          query: 'demo',
          status: SearchStatus.loading,
        );
      case _ForcedState.empty:
        return const SearchState(
          query: 'xyznodata',
          status: SearchStatus.empty,
        );
      case _ForcedState.error:
        return const SearchState(
          query: 'demo',
          status: SearchStatus.error,
          error: 'Simulated network error.',
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Control Drawer
// ---------------------------------------------------------------------------

class _ControlDrawer extends StatelessWidget {
  const _ControlDrawer({
    required this.dataset,
    required this.style,
    required this.animation,
    required this.layout,
    required this.density,
    required this.forcedState,
    required this.simulatedDelay,
    required this.overlayMode,
    required this.onDatasetChanged,
    required this.onStyleChanged,
    required this.onAnimationChanged,
    required this.onLayoutChanged,
    required this.onDensityChanged,
    required this.onForcedStateChanged,
    required this.onDelayChanged,
    required this.onOverlayChanged,
  });

  final _Dataset dataset;
  final _StylePreset style;
  final SearchAnimationPreset animation;
  final SearchResultsLayout layout;
  final SearchResultDensity density;
  final _ForcedState forcedState;
  final double simulatedDelay;
  final bool overlayMode;
  final ValueChanged<_Dataset> onDatasetChanged;
  final ValueChanged<_StylePreset> onStyleChanged;
  final ValueChanged<SearchAnimationPreset> onAnimationChanged;
  final ValueChanged<SearchResultsLayout> onLayoutChanged;
  final ValueChanged<SearchResultDensity> onDensityChanged;
  final ValueChanged<_ForcedState> onForcedStateChanged;
  final ValueChanged<double> onDelayChanged;
  final ValueChanged<bool> onOverlayChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Control Panel',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Adjust settings to preview different configurations.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: 32),

            // Dataset
            _SectionTitle('Dataset'),
            SegmentedButton<_Dataset>(
              segments: const [
                ButtonSegment(
                  value: _Dataset.products,
                  label: Text('Products'),
                  icon: Icon(Icons.shopping_bag, size: 16),
                ),
                ButtonSegment(
                  value: _Dataset.users,
                  label: Text('Users'),
                  icon: Icon(Icons.person, size: 16),
                ),
                ButtonSegment(
                  value: _Dataset.articles,
                  label: Text('Articles'),
                  icon: Icon(Icons.article, size: 16),
                ),
              ],
              selected: {dataset},
              onSelectionChanged: (v) => onDatasetChanged(v.first),
            ),
            const SizedBox(height: 20),

            // Style
            _SectionTitle('Style'),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _StylePreset.values.map((preset) {
                final labels = {
                  _StylePreset.minimal: 'Min',
                  _StylePreset.modernSaas: 'SaaS',
                  _StylePreset.dark: 'Dark',
                  _StylePreset.social: 'Social',
                  _StylePreset.glass: 'Glass',
                  _StylePreset.darkPremium: 'Premium',
                };
                return ChoiceChip(
                  label: Text(labels[preset]!),
                  selected: style == preset,
                  onSelected: (_) => onStyleChanged(preset),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Animation
            _SectionTitle('Animation'),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: SearchAnimationPreset.values.map((preset) {
                return ChoiceChip(
                  label: Text(preset.name),
                  selected: animation == preset,
                  onSelected: (_) => onAnimationChanged(preset),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Layout
            _SectionTitle('Layout'),
            SegmentedButton<SearchResultsLayout>(
              segments: const [
                ButtonSegment(
                  value: SearchResultsLayout.list,
                  label: Text('List'),
                  icon: Icon(Icons.view_list, size: 16),
                ),
                ButtonSegment(
                  value: SearchResultsLayout.grid,
                  label: Text('Grid'),
                  icon: Icon(Icons.grid_view, size: 16),
                ),
              ],
              selected: {layout},
              onSelectionChanged: (v) => onLayoutChanged(v.first),
            ),
            const SizedBox(height: 20),

            // Density
            _SectionTitle('Density'),
            SegmentedButton<SearchResultDensity>(
              segments: const [
                ButtonSegment(
                  value: SearchResultDensity.compact,
                  label: Text('Compact'),
                ),
                ButtonSegment(
                  value: SearchResultDensity.comfortable,
                  label: Text('Comfy'),
                ),
                ButtonSegment(
                  value: SearchResultDensity.rich,
                  label: Text('Rich'),
                ),
              ],
              selected: {density},
              onSelectionChanged: (v) => onDensityChanged(v.first),
            ),
            const SizedBox(height: 20),

            // Forced State
            _SectionTitle('Force State'),
            SegmentedButton<_ForcedState>(
              segments: const [
                ButtonSegment(
                  value: _ForcedState.none,
                  label: Text('Auto'),
                ),
                ButtonSegment(
                  value: _ForcedState.loading,
                  label: Text('Load'),
                ),
                ButtonSegment(
                  value: _ForcedState.empty,
                  label: Text('Empty'),
                ),
                ButtonSegment(
                  value: _ForcedState.error,
                  label: Text('Error'),
                ),
              ],
              selected: {forcedState},
              onSelectionChanged: (v) => onForcedStateChanged(v.first),
            ),
            const SizedBox(height: 20),

            // Simulated delay
            _SectionTitle('API Delay: ${simulatedDelay.round()} ms'),
            Slider(
              min: 100,
              max: 3000,
              divisions: 29,
              value: simulatedDelay,
              label: '${simulatedDelay.round()} ms',
              onChanged: onDelayChanged,
            ),
            const SizedBox(height: 20),

            // Overlay mode
            _SectionTitle('Result Mode'),
            SwitchListTile(
              title: const Text('Overlay Dropdown'),
              subtitle: const Text('Show results in floating panel'),
              value: overlayMode,
              onChanged: onOverlayChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
