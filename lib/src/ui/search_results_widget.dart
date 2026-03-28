import 'package:flutter/material.dart';

import '../animations/animation_presets.dart';
import '../core/search_result.dart';
import '../core/search_state.dart';
import '../theme/search_theme.dart';
import 'states/search_states.dart';

/// Display mode for search results.
enum SearchResultsLayout {
  /// Vertical list layout.
  list,

  /// Grid layout.
  grid,

  /// Sectioned/grouped layout.
  sectioned,
}

/// Display density for result items.
enum SearchResultDensity {
  /// Compact: title only.
  compact,

  /// Comfortable: title + subtitle.
  comfortable,

  /// Rich: image + title + subtitle + trailing action.
  rich,
}

/// A widget that displays search results with animations and state handling.
///
/// Supports list, grid, and sectioned layouts with multiple display densities.
///
/// ```dart
/// SearchResultsWidget<Product>(
///   state: controller.state,
///   itemBuilder: (context, result, index) => ListTile(
///     title: Text(result.title),
///   ),
/// )
/// ```
class SearchResultsWidget<T> extends StatelessWidget {
  /// Creates a search results widget.
  const SearchResultsWidget({
    super.key,
    required this.state,
    this.itemBuilder,
    this.onItemTap,
    this.layout = SearchResultsLayout.list,
    this.density = SearchResultDensity.comfortable,
    this.animationConfig = const SearchAnimationConfig(),
    this.emptyState,
    this.errorState,
    this.loadingWidget,
    this.onRetry,
    this.showShimmer = true,
    this.gridCrossAxisCount = 2,
    this.gridChildAspectRatio = 1.0,
    this.headerBuilder,
    this.footerBuilder,
    this.separatorBuilder,
    this.physics,
    this.padding,
    this.shrinkWrap = false,
  });

  /// Current search state.
  final SearchState<T> state;

  /// Custom builder for each result item.
  final Widget Function(
      BuildContext context, SearchResult<T> result, int index)? itemBuilder;

  /// Called when a result item is tapped.
  final void Function(SearchResult<T> result)? onItemTap;

  /// Layout mode for results.
  final SearchResultsLayout layout;

  /// Display density.
  final SearchResultDensity density;

  /// Animation configuration for result items.
  final SearchAnimationConfig animationConfig;

  /// Custom empty state widget.
  final Widget? emptyState;

  /// Custom error state widget.
  final Widget? errorState;

  /// Custom loading widget.
  final Widget? loadingWidget;

  /// Callback when retry is pressed on error state.
  final VoidCallback? onRetry;

  /// Whether to show shimmer loading.
  final bool showShimmer;

  /// Cross axis count for grid layout.
  final int gridCrossAxisCount;

  /// Child aspect ratio for grid layout.
  final double gridChildAspectRatio;

  /// Optional header widget builder.
  final Widget Function(BuildContext context, SearchState<T> state)?
      headerBuilder;

  /// Optional footer widget builder.
  final Widget Function(BuildContext context, SearchState<T> state)?
      footerBuilder;

  /// Custom separator builder for list layout.
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  /// Scroll physics.
  final ScrollPhysics? physics;

  /// Padding around the results.
  final EdgeInsets? padding;

  /// Whether to shrink wrap the list.
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (headerBuilder != null) headerBuilder!(context, state),
        Expanded(child: _buildContent(context)),
        if (footerBuilder != null) footerBuilder!(context, state),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (state.status) {
      case SearchStatus.idle:
        return const SizedBox.shrink();
      case SearchStatus.loading:
        return loadingWidget ??
            (showShimmer
                ? const ShimmerLoading()
                : const SearchLoadingState());
      case SearchStatus.error:
        return errorState ??
            SearchErrorState(
              message: state.error,
              onRetry: onRetry,
            );
      case SearchStatus.empty:
        return emptyState ??
            SearchEmptyState(query: state.query);
      case SearchStatus.success:
        return _buildResults(context);
    }
  }

  Widget _buildResults(BuildContext context) {
    switch (layout) {
      case SearchResultsLayout.list:
        return _buildListResults(context);
      case SearchResultsLayout.grid:
        return _buildGridResults(context);
      case SearchResultsLayout.sectioned:
        return _buildSectionedResults(context);
    }
  }

  Widget _buildListResults(BuildContext context) {
    final results = state.results;

    if (separatorBuilder != null) {
      return ListView.separated(
        padding: padding ?? const EdgeInsets.symmetric(vertical: 8),
        physics: physics,
        shrinkWrap: shrinkWrap,
        itemCount: results.length,
        separatorBuilder: separatorBuilder!,
        itemBuilder: (context, index) => _buildAnimatedItem(
          context,
          results[index],
          index,
        ),
      );
    }

    return ListView.builder(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 8),
      physics: physics,
      shrinkWrap: shrinkWrap,
      itemCount: results.length,
      itemBuilder: (context, index) => _buildAnimatedItem(
        context,
        results[index],
        index,
      ),
    );
  }

  Widget _buildGridResults(BuildContext context) {
    final results = state.results;

    return GridView.builder(
      padding: padding ?? const EdgeInsets.all(16),
      physics: physics,
      shrinkWrap: shrinkWrap,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridCrossAxisCount,
        childAspectRatio: gridChildAspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) => _buildAnimatedItem(
        context,
        results[index],
        index,
      ),
    );
  }

  Widget _buildSectionedResults(BuildContext context) {
    if (state.sections.isEmpty) {
      return _buildListResults(context);
    }

    return ListView.builder(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 8),
      physics: physics,
      shrinkWrap: shrinkWrap,
      itemCount: state.sections.length,
      itemBuilder: (context, sectionIndex) {
        final section = state.sections[sectionIndex];
        return _SearchSection<T>(
          section: section,
          itemBuilder: itemBuilder,
          onItemTap: onItemTap,
          density: density,
          animationConfig: animationConfig,
        );
      },
    );
  }

  Widget _buildAnimatedItem(
    BuildContext context,
    SearchResult<T> result,
    int index,
  ) {
    final child = itemBuilder?.call(context, result, index) ??
        _DefaultResultItem<T>(
          result: result,
          density: density,
          query: state.query,
          onTap: onItemTap != null ? () => onItemTap!(result) : null,
        );

    return AnimatedSearchItem(
      index: index,
      config: animationConfig,
      child: child,
    );
  }
}

class _SearchSection<T> extends StatefulWidget {
  const _SearchSection({
    required this.section,
    this.itemBuilder,
    this.onItemTap,
    this.density = SearchResultDensity.comfortable,
    this.animationConfig = const SearchAnimationConfig(),
  });

  final SearchResultSection<T> section;
  final Widget Function(
      BuildContext context, SearchResult<T> result, int index)? itemBuilder;
  final void Function(SearchResult<T> result)? onItemTap;
  final SearchResultDensity density;
  final SearchAnimationConfig animationConfig;

  @override
  State<_SearchSection<T>> createState() => _SearchSectionState<T>();
}

class _SearchSectionState<T> extends State<_SearchSection<T>> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.section.isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final searchTheme = SearchTheme.of(context);
    final resultTheme = searchTheme.resultTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: resultTheme.sectionHeaderBackgroundColor,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.section.title,
                    style: resultTheme.sectionHeaderStyle,
                  ),
                ),
                AnimatedRotation(
                  turns: _isExpanded ? 0 : -0.25,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more_rounded,
                    color: resultTheme.iconColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: Column(
            children: [
              for (int i = 0; i < widget.section.results.length; i++)
                AnimatedSearchItem(
                  index: i,
                  config: widget.animationConfig,
                  child: widget.itemBuilder?.call(
                        context,
                        widget.section.results[i],
                        i,
                      ) ??
                      _DefaultResultItem<T>(
                        result: widget.section.results[i],
                        density: widget.density,
                        query: '',
                        onTap: widget.onItemTap != null
                            ? () =>
                                widget.onItemTap!(widget.section.results[i])
                            : null,
                      ),
                ),
            ],
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: _isExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

/// Default result item with three density modes.
class _DefaultResultItem<T> extends StatelessWidget {
  const _DefaultResultItem({
    required this.result,
    required this.density,
    this.query = '',
    this.onTap,
  });

  final SearchResult<T> result;
  final SearchResultDensity density;
  final String query;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final searchTheme = SearchTheme.of(context);
    final resultTheme = searchTheme.resultTheme;

    switch (density) {
      case SearchResultDensity.compact:
        return ListTile(
          dense: true,
          title: HighlightText(
            text: result.title,
            query: query,
            style: resultTheme.titleStyle,
            highlightColor: resultTheme.highlightColor,
            highlightStyle: resultTheme.highlightStyle,
          ),
          onTap: onTap,
          contentPadding: resultTheme.contentPadding,
        );
      case SearchResultDensity.comfortable:
        return ListTile(
          title: HighlightText(
            text: result.title,
            query: query,
            style: resultTheme.titleStyle,
            highlightColor: resultTheme.highlightColor,
            highlightStyle: resultTheme.highlightStyle,
          ),
          subtitle: result.subtitle != null
              ? HighlightText(
                  text: result.subtitle!,
                  query: query,
                  style: resultTheme.subtitleStyle,
                  maxLines: 1,
                )
              : null,
          onTap: onTap,
          contentPadding: resultTheme.contentPadding,
        );
      case SearchResultDensity.rich:
        return ListTile(
          leading: result.imageUrl != null
              ? ClipRRect(
                  borderRadius:
                      resultTheme.imageBorderRadius ?? BorderRadius.circular(8),
                  child: Image.network(
                    result.imageUrl!,
                    width: resultTheme.imageSize ?? 48,
                    height: resultTheme.imageSize ?? 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: resultTheme.imageSize ?? 48,
                      height: resultTheme.imageSize ?? 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: resultTheme.imageBorderRadius ??
                            BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.image_outlined,
                        color: resultTheme.iconColor,
                      ),
                    ),
                  ),
                )
              : Container(
                  width: resultTheme.imageSize ?? 48,
                  height: resultTheme.imageSize ?? 48,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius:
                        resultTheme.imageBorderRadius ?? BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.article_outlined,
                    color: resultTheme.iconColor,
                  ),
                ),
          title: HighlightText(
            text: result.title,
            query: query,
            style: resultTheme.titleStyle,
            highlightColor: resultTheme.highlightColor,
            highlightStyle: resultTheme.highlightStyle,
          ),
          subtitle: result.subtitle != null
              ? HighlightText(
                  text: result.subtitle!,
                  query: query,
                  style: resultTheme.subtitleStyle,
                  maxLines: 2,
                )
              : null,
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: resultTheme.iconColor,
          ),
          onTap: onTap,
          contentPadding: resultTheme.contentPadding,
        );
    }
  }
}
