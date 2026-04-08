import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:search_plus/search_plus.dart';


// Debug helper
void _debug(String message, [Object? value]) {
  if (kDebugMode) {
    if (value != null) {
      debugPrint('🔍 SearchResultsWidget: $message: $value');
    } else {
      debugPrint('🔍 SearchResultsWidget: $message');
    }
  }
}

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
/// SearchPlusResults<Product>(
///   state: controller.state,
///   itemBuilder: (context, result, index) => ListTile(
///     title: Text(result.title),
///   ),
/// )
/// ```
class SearchPlusResults<T> extends StatefulWidget {
  /// Creates a search results widget.
  const SearchPlusResults({
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
    this.emptyBuilder,
    this.onLoadMore,
    this.loadMoreThreshold = 200.0,
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

  /// Custom builder for the empty state. If provided, this is used instead
  /// of [emptyState] widget or the default [SearchEmptyState].
  /// Receives the current build context and the search query.
  final Widget Function(BuildContext context, String query)? emptyBuilder;

  /// Called when the user scrolls near the end of results.
  /// Use this to trigger loading more results (pagination).
  final VoidCallback? onLoadMore;

  /// Distance from the bottom (in pixels) at which [onLoadMore] triggers.
  final double loadMoreThreshold;

  @override
  State<SearchPlusResults<T>> createState() => _SearchPlusResultsState<T>();
}

class _SearchPlusResultsState<T> extends State<SearchPlusResults<T>> {
  @override
  Widget build(BuildContext context) {
    _debug('build called, status=${widget.state.status}, resultsCount=${widget.state.results.length}, layout=${widget.layout}, density=${widget.density}');
    return Column(
      children: [
        if (widget.headerBuilder != null)
          Builder(
            builder: (context) {
              _debug('building header');
              return widget.headerBuilder!(context, widget.state);
            },
          ),
        Expanded(child: _buildContent(context)),
        if (widget.footerBuilder != null)
          Builder(
            builder: (context) {
              _debug('building footer');
              return widget.footerBuilder!(context, widget.state);
            },
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    _debug('_buildContent, status=${widget.state.status}');
    switch (widget.state.status) {
      case SearchStatus.idle:
        _debug('idle state -> empty SizedBox');
        return const SizedBox.shrink();
      case SearchStatus.loading:
        _debug('loading state -> ${widget.loadingWidget != null ? "custom loading" : (widget.showShimmer ? "shimmer" : "default loading")}');
        return widget.loadingWidget ??
            (widget.showShimmer
                ? const ShimmerLoading()
                : const SearchLoadingState());
      case SearchStatus.error:
        _debug('error state -> ${widget.errorState != null ? "custom error" : "default error"}, message=${widget.state.error}');
        return widget.errorState ??
            SearchErrorState(
              message: widget.state.error,
              onRetry: widget.onRetry,
            );
      case SearchStatus.empty:
        _debug('empty state -> ${widget.emptyBuilder != null ? "custom emptyBuilder" : (widget.emptyState != null ? "custom empty" : "default empty")}, query=${widget.state.query}');
        if (widget.emptyBuilder != null) {
          return widget.emptyBuilder!(context, widget.state.query);
        }
        return widget.emptyState ??
            SearchEmptyState(query: widget.state.query);
      case SearchStatus.success:
        _debug('success state -> building results');
        return _buildResults(context);
    }
  }

  Widget _wrapWithLoadMoreDetection(Widget scrollableChild) {
    if (widget.onLoadMore == null) return scrollableChild;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification &&
            widget.state.hasMoreResults) {
          final maxScroll = notification.metrics.maxScrollExtent;
          final currentScroll = notification.metrics.pixels;
          if (maxScroll - currentScroll <= widget.loadMoreThreshold) {
            widget.onLoadMore!();
          }
        }
        return false;
      },
      child: scrollableChild,
    );
  }

  Widget _buildResults(BuildContext context) {
    _debug('_buildResults, layout=${widget.layout}, resultsCount=${widget.state.results.length}, sectionsCount=${widget.state.sections.length}');
    switch (widget.layout) {
      case SearchResultsLayout.list:
        return _wrapWithLoadMoreDetection(_buildListResults(context));
      case SearchResultsLayout.grid:
        return _wrapWithLoadMoreDetection(_buildGridResults(context));
      case SearchResultsLayout.sectioned:
        return _wrapWithLoadMoreDetection(_buildSectionedResults(context));
    }
  }

  Widget _buildListResults(BuildContext context) {
    final results = widget.state.results;
    _debug('_buildListResults, count=${results.length}, hasSeparator=${widget.separatorBuilder != null}, shrinkWrap=${widget.shrinkWrap}');

    if (widget.separatorBuilder != null) {
      return ListView.separated(
        padding: widget.padding ?? const EdgeInsets.symmetric(vertical: 8),
        physics: widget.physics,
        shrinkWrap: widget.shrinkWrap,
        itemCount: results.length,
        separatorBuilder: (context, index) {
          _debug('separatorBuilder for index $index');
          return widget.separatorBuilder!(context, index);
        },
        itemBuilder: (context, index) {
          _debug('building list item index $index');
          return _buildAnimatedItem(
            context,
            results[index],
            index,
          );
        },
      );
    }

    return ListView.builder(
      padding: widget.padding ?? const EdgeInsets.symmetric(vertical: 8),
      physics: widget.physics,
      shrinkWrap: widget.shrinkWrap,
      itemCount: results.length,
      itemBuilder: (context, index) {
        _debug('building list item index $index');
        return _buildAnimatedItem(
          context,
          results[index],
          index,
        );
      },
    );
  }

  Widget _buildGridResults(BuildContext context) {
    final results = widget.state.results;
    _debug('_buildGridResults, count=${results.length}, crossAxisCount=${widget.gridCrossAxisCount}, aspectRatio=${widget.gridChildAspectRatio}');

    return GridView.builder(
      padding: widget.padding ?? const EdgeInsets.all(16),
      physics: widget.physics,
      shrinkWrap: widget.shrinkWrap,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.gridCrossAxisCount,
        childAspectRatio: widget.gridChildAspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        _debug('building grid item index $index');
        return _buildAnimatedItem(
          context,
          results[index],
          index,
        );
      },
    );
  }

  Widget _buildSectionedResults(BuildContext context) {
    if (widget.state.sections.isEmpty) {
      _debug('_buildSectionedResults: sections empty, falling back to list layout');
      return _buildListResults(context);
    }
    _debug('_buildSectionedResults: ${widget.state.sections.length} sections');
    return ListView.builder(
      padding: widget.padding ?? const EdgeInsets.symmetric(vertical: 8),
      physics: widget.physics,
      shrinkWrap: widget.shrinkWrap,
      itemCount: widget.state.sections.length,
      itemBuilder: (context, sectionIndex) {
        final section = widget.state.sections[sectionIndex];
        _debug('building section index $sectionIndex, title="${section.title}", resultsCount=${section.results.length}, expanded=${section.isExpanded}');
        return _SearchSection<T>(
          section: section,
          itemBuilder: widget.itemBuilder,
          onItemTap: widget.onItemTap,
          density: widget.density,
          animationConfig: widget.animationConfig,
        );
      },
    );
  }

  Widget _buildAnimatedItem(
    BuildContext context,
    SearchResult<T> result,
    int index,
  ) {
    _debug('_buildAnimatedItem index $index, title="${result.title}", hasImage=${result.imageUrl != null}');
    final child = widget.itemBuilder?.call(context, result, index) ??
        _DefaultResultItem<T>(
          result: result,
          density: widget.density,
          query: widget.state.query,
          onTap: widget.onItemTap != null ? () => widget.onItemTap!(result) : null,
        );

    return AnimatedSearchItem(
      index: index,
      config: widget.animationConfig,
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
    _debug('_SearchSectionState initState, title="${widget.section.title}", initialExpanded=$_isExpanded');
  }

  @override
  Widget build(BuildContext context) {
    final searchTheme = SearchTheme.of(context);
    final resultTheme = searchTheme.resultTheme;

    _debug('_SearchSectionState build, title="${widget.section.title}", expanded=$_isExpanded, resultsCount=${widget.section.results.length}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            _debug('section header tapped, toggling expansion');
            setState(() => _isExpanded = !_isExpanded);
          },
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

    _debug('_DefaultResultItem build, density=$density, title="${result.title}", query="$query"');

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
                    errorBuilder: (_, _, _) => Container(
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

/// Deprecated: Use [SearchPlusResults] instead.
@Deprecated('Use SearchPlusResults instead. SearchResultsWidget was renamed to SearchPlusResults.')
typedef SearchResultsWidget<T> = SearchPlusResults<T>;