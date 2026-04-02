import 'package:flutter/material.dart';

import '../../core/search_controller.dart';
import '../../core/search_result.dart';
import '../../core/search_state.dart';
import '../search_bar_widget.dart';
import '../states/search_states.dart';
import 'glassmorphism_container.dart';
import 'skeleton_loading.dart';

/// A premium, ready-to-use search screen with modern design.
///
/// Combines search bar, results, loading states, empty/error states,
/// and smooth animations into a single, beautiful widget.
///
/// ```dart
/// SearchPlusScreen<Product>(
///   controller: myController,
///   itemBuilder: (context, result) => ListTile(
///     title: Text(result.title),
///   ),
///   theme: SearchPlusScreenTheme.modern(),
/// )
/// ```
class SearchPlusScreen<T> extends StatefulWidget {
  /// Creates a premium search screen.
  const SearchPlusScreen({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.onItemTap,
    this.theme,
    this.appBarTitle,
    this.showHistory = true,
    this.showSuggestions = true,
    this.enableHighlight = true,
    this.skeletonDensity = SearchSkeletonDensity.comfortable,
    this.enableGlassEffect = false,
    this.idleBuilder,
    this.headerBuilder,
    this.floatingActionButton,
    this.backgroundColor,
  });

  /// The search controller.
  final SearchPlusController<T> controller;

  /// Builder for each result item.
  final Widget Function(BuildContext context, SearchResult<T> result) itemBuilder;

  /// Called when a result item is tapped.
  final void Function(SearchResult<T> result)? onItemTap;

  /// Optional custom screen theme.
  final SearchPlusScreenTheme? theme;

  /// Title displayed in the app bar area.
  final String? appBarTitle;

  /// Whether to show search history when idle.
  final bool showHistory;

  /// Whether to show suggestions.
  final bool showSuggestions;

  /// Whether to highlight matched text in default result tiles.
  final bool enableHighlight;

  /// Density of skeleton loading items.
  final SearchSkeletonDensity skeletonDensity;

  /// Whether to use glassmorphism effect for the search bar.
  final bool enableGlassEffect;

  /// Widget to show when search is idle (no query entered).
  final Widget Function(BuildContext context)? idleBuilder;

  /// Optional header widget above the results.
  final Widget Function(BuildContext context, SearchState<T> state)? headerBuilder;

  /// Optional floating action button.
  final Widget? floatingActionButton;

  /// Background color for the screen.
  final Color? backgroundColor;

  @override
  State<SearchPlusScreen<T>> createState() => _SearchPlusScreenState<T>();
}

class _SearchPlusScreenState<T> extends State<SearchPlusScreen<T>>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenTheme = widget.theme ?? SearchPlusScreenTheme.modern();
    final bg = widget.backgroundColor ?? theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: widget.floatingActionButton,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Search Bar Area
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.appBarTitle != null) ...[
                      Text(
                        widget.appBarTitle!,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _buildSearchBar(screenTheme),
                  ],
                ),
              ),
              // Results Area
              Expanded(
                child: ListenableBuilder(
                  listenable: widget.controller,
                  builder: (context, _) {
                    final state = widget.controller.state;
                    return AnimatedSwitcher(
                      duration: screenTheme.transitionDuration,
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: _buildContent(state, screenTheme),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(SearchPlusScreenTheme screenTheme) {
    final searchBar = SearchPlusBar(
      onChanged: (query) => widget.controller.search(query),
      onSubmitted: (query) {
        widget.controller.addToHistory(query);
        widget.controller.searchImmediate(query);
      },
    );

    if (widget.enableGlassEffect) {
      return GlassmorphismContainer(
        borderRadius: screenTheme.barBorderRadius,
        blur: 10,
        opacity: 0.15,
        padding: EdgeInsets.zero,
        child: searchBar,
      );
    }
    return searchBar;
  }

  Widget _buildContent(SearchState<T> state, SearchPlusScreenTheme screenTheme) {
    // Header
    final header = widget.headerBuilder?.call(context, state);

    return Column(
      key: ValueKey(state.status),
      children: [
        if (header != null) header,
        Expanded(
          child: switch (state.status) {
            SearchStatus.idle => _buildIdleState(state),
            SearchStatus.loading => _buildLoadingState(),
            SearchStatus.success => _buildResultsList(state, screenTheme),
            SearchStatus.empty => _buildEmptyState(state),
            SearchStatus.error => _buildErrorState(state),
          },
        ),
      ],
    );
  }

  Widget _buildIdleState(SearchState<T> state) {
    if (widget.idleBuilder != null) {
      return widget.idleBuilder!(context);
    }

    if (widget.showHistory && state.history.isNotEmpty) {
      return _buildHistorySection(state);
    }

    return const SearchEmptyState(
      icon: Icon(Icons.search_rounded, size: 80, color: Colors.grey),
      title: 'Start searching',
      subtitle: 'Type something to find what you need',
    );
  }

  Widget _buildHistorySection(SearchState<T> state) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'Recent Searches',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => widget.controller.clearHistory(),
              child: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...state.history.map((query) => ListTile(
              leading: Icon(
                Icons.history_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              title: Text(query),
              onTap: () => widget.controller.searchImmediate(query),
              contentPadding: EdgeInsets.zero,
              dense: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            )),
      ],
    );
  }

  Widget _buildLoadingState() {
    return SearchSkeletonLoading(
      itemCount: 6,
      density: widget.skeletonDensity,
    );
  }

  Widget _buildResultsList(SearchState<T> state, SearchPlusScreenTheme screenTheme) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: state.results.length + (state.hasMoreResults ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.results.length) {
          return _buildLoadMoreIndicator();
        }

        final result = state.results[index];
        return TweenAnimationBuilder<double>(
          key: ValueKey(result.id),
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 200 + (index * 30)),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: InkWell(
            onTap: widget.onItemTap != null ? () => widget.onItemTap!(result) : null,
            borderRadius: BorderRadius.circular(screenTheme.itemBorderRadius),
            child: widget.itemBuilder(context, result),
          ),
        );
      },
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(SearchState<T> state) {
    return SearchEmptyState(query: state.query);
  }

  Widget _buildErrorState(SearchState<T> state) {
    return SearchErrorState(
      message: state.error,
      onRetry: () => widget.controller.searchImmediate(state.query),
    );
  }
}

/// Theme configuration for [SearchPlusScreen].
class SearchPlusScreenTheme {
  /// Creates a screen theme.
  const SearchPlusScreenTheme({
    this.barBorderRadius = 16.0,
    this.itemBorderRadius = 12.0,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.showResultCount = true,
    this.enableItemAnimations = true,
  });

  /// Creates a modern theme preset.
  factory SearchPlusScreenTheme.modern() => const SearchPlusScreenTheme(
        barBorderRadius: 16.0,
        itemBorderRadius: 12.0,
        transitionDuration: Duration(milliseconds: 250),
      );

  /// Creates a minimal theme preset.
  factory SearchPlusScreenTheme.minimal() => const SearchPlusScreenTheme(
        barBorderRadius: 8.0,
        itemBorderRadius: 4.0,
        transitionDuration: Duration(milliseconds: 150),
        showResultCount: false,
      );

  /// Border radius for the search bar.
  final double barBorderRadius;

  /// Border radius for result items.
  final double itemBorderRadius;

  /// Duration for state transition animations.
  final Duration transitionDuration;

  /// Whether to show the result count badge.
  final bool showResultCount;

  /// Whether to animate individual result items.
  final bool enableItemAnimations;
}
