import 'package:flutter/material.dart';

import '../adapters/local_search_adapter.dart';
import '../animations/animation_presets.dart';
import '../core/search_controller.dart';
import '../core/search_result.dart';
import '../core/search_state.dart';
import '../l10n/search_localizations.dart';
import '../theme/search_theme.dart';
import 'search_bar_widget.dart';
import 'search_results_widget.dart';

/// A ready-to-use searchable list that combines [SearchPlusBar] with
/// [SearchPlusResults] and manages a [SearchPlusController] internally.
///
/// Pass a list of items, tell the widget how to extract searchable text and
/// how to convert each item into a [SearchResult], and you're done.
///
/// ## Minimal example
///
/// ```dart
/// SearchableListView<String>(
///   items: ['Apple', 'Banana', 'Cherry', 'Date'],
///   searchableFields: (item) => [item],
///   toResult: (item) => SearchResult(id: item, title: item, data: item),
/// )
/// ```
///
/// ## Custom item builder
///
/// ```dart
/// SearchableListView<Product>(
///   items: products,
///   searchableFields: (p) => [p.name, p.category],
///   toResult: (p) => SearchResult(id: p.id, title: p.name, subtitle: p.category, data: p),
///   itemBuilder: (context, result, index) => ListTile(
///     leading: Image.network(result.data!.imageUrl),
///     title: Text(result.title),
///     subtitle: Text(result.subtitle ?? ''),
///   ),
/// )
/// ```
class SearchableListView<T> extends StatefulWidget {
  /// Creates a searchable list view backed by a local adapter.
  const SearchableListView({
    super.key,
    required this.items,
    required this.searchableFields,
    required this.toResult,
    this.itemBuilder,
    this.onItemTap,
    this.onQueryChanged,
    this.hintText,
    this.autofocus = false,
    this.showClearButton = true,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.minQueryLength = 1,
    this.maxResults = 50,
    this.enableFuzzySearch = false,
    this.layout = SearchResultsLayout.list,
    this.density = SearchResultDensity.comfortable,
    this.animationConfig = const SearchAnimationConfig(),
    this.emptyState,
    this.errorState,
    this.loadingWidget,
    this.showShimmer = true,
    this.gridCrossAxisCount = 2,
    this.gridChildAspectRatio = 1.0,
    this.barPadding,
    this.resultsPadding,
    this.headerBuilder,
    this.footerBuilder,
    this.separatorBuilder,
    this.idleBuilder,
    this.physics,
    this.shrinkWrap = false,
    this.theme,
    this.localizations,
    this.emptyBuilder,
    this.leading,
    this.trailing,
    this.onVoiceSearch,
    this.onFilterPressed,
    this.showDebounceIndicator = false,
  });

  // ---- Data & mapping ---------------------------------------------------

  /// The list of items to search through.
  final List<T> items;

  /// Extracts searchable text fields from each item.
  ///
  /// The first element is weighted as the "title" field; subsequent elements
  /// are weighted as "subtitle" fields when scoring results.
  final List<String> Function(T item) searchableFields;

  /// Converts an item into a [SearchResult] for display.
  final SearchResult<T> Function(T item) toResult;

  // ---- Result rendering -------------------------------------------------

  /// Custom builder for each result item.
  ///
  /// If null, a default [ListTile] is used based on [density].
  final Widget Function(
      BuildContext context, SearchResult<T> result, int index)? itemBuilder;

  /// Called when a result item is tapped.
  final void Function(SearchResult<T> result)? onItemTap;

  /// Called each time the search query text changes.
  final ValueChanged<String>? onQueryChanged;

  // ---- Search bar -------------------------------------------------------

  /// Placeholder text for the search bar.
  final String? hintText;

  /// Whether the search bar should auto-focus on mount.
  final bool autofocus;

  /// Whether to show the clear button when text is present.
  final bool showClearButton;

  /// Leading widget for the search bar (e.g. a custom search icon).
  final Widget? leading;

  /// Trailing widget for the search bar.
  final Widget? trailing;

  /// Callback for voice search. If null, the voice button is hidden.
  final VoidCallback? onVoiceSearch;

  /// Callback for the filter button. If null, the filter button is hidden.
  final VoidCallback? onFilterPressed;

  /// Whether to show a debounce progress indicator below the search bar.
  final bool showDebounceIndicator;

  // ---- Search engine config ---------------------------------------------

  /// Debounce duration before the search executes.
  final Duration debounceDuration;

  /// Minimum number of characters before search triggers.
  final int minQueryLength;

  /// Maximum number of results to return.
  final int maxResults;

  /// Whether to enable fuzzy (Levenshtein-distance) matching.
  final bool enableFuzzySearch;

  // ---- Results layout ---------------------------------------------------

  /// Layout mode for the results list.
  final SearchResultsLayout layout;

  /// Display density for result items.
  final SearchResultDensity density;

  /// Animation configuration for result items.
  final SearchAnimationConfig animationConfig;

  /// Custom empty state widget.
  final Widget? emptyState;

  /// Custom error state widget.
  final Widget? errorState;

  /// Custom loading widget.
  final Widget? loadingWidget;

  /// Whether to show shimmer loading.
  final bool showShimmer;

  /// Grid cross axis count (only used with [SearchResultsLayout.grid]).
  final int gridCrossAxisCount;

  /// Grid child aspect ratio (only used with [SearchResultsLayout.grid]).
  final double gridChildAspectRatio;

  /// Padding around the search bar.
  final EdgeInsets? barPadding;

  /// Padding around the results.
  final EdgeInsets? resultsPadding;

  /// Optional header builder above the results.
  final Widget Function(BuildContext context, SearchState<T> state)?
      headerBuilder;

  /// Optional footer builder below the results.
  final Widget Function(BuildContext context, SearchState<T> state)?
      footerBuilder;

  /// Custom separator builder for list layout.
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  /// Widget to show when search is idle (no query entered).
  final Widget Function(BuildContext context)? idleBuilder;

  /// Scroll physics for the results list.
  final ScrollPhysics? physics;

  /// Whether to shrink wrap the results list.
  final bool shrinkWrap;

  /// Custom builder for the empty state.
  final Widget Function(BuildContext context, String query)? emptyBuilder;

  // ---- Theming & localization -------------------------------------------

  /// Optional theme override for the search bar and results.
  final SearchPlusThemeData? theme;

  /// Optional localization override.
  final SearchLocalizations? localizations;

  @override
  State<SearchableListView<T>> createState() => _SearchableListViewState<T>();
}

class _SearchableListViewState<T> extends State<SearchableListView<T>> {
  late SearchPlusController<T> _controller;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _controller = _createController();
  }

  SearchPlusController<T> _createController() {
    return SearchPlusController<T>(
      adapter: LocalSearchAdapter<T>(
        items: widget.items,
        searchableFields: widget.searchableFields,
        toResult: widget.toResult,
        enableFuzzySearch: widget.enableFuzzySearch,
      ),
      debounceDuration: widget.debounceDuration,
      minQueryLength: widget.minQueryLength,
      maxResults: widget.maxResults,
    );
  }

  @override
  void didUpdateWidget(covariant SearchableListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Recreate the controller when the item list or mapping functions change.
    if (!identical(widget.items, oldWidget.items) ||
        !identical(widget.searchableFields, oldWidget.searchableFields) ||
        !identical(widget.toResult, oldWidget.toResult) ||
        widget.enableFuzzySearch != oldWidget.enableFuzzySearch ||
        widget.debounceDuration != oldWidget.debounceDuration ||
        widget.minQueryLength != oldWidget.minQueryLength ||
        widget.maxResults != oldWidget.maxResults) {
      final currentQuery = _controller.query;
      _controller.dispose();
      _controller = _createController();

      // Re-run the previous query so results stay in sync.
      if (currentQuery.isNotEmpty) {
        _controller.search(currentQuery);
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _controller.search(query);
    widget.onQueryChanged?.call(query);
  }

  @override
  Widget build(BuildContext context) {
    Widget child = ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;

        return Column(
          children: [
            Padding(
              padding: widget.barPadding ??
                  const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SearchPlusBar(
                controller: _textController,
                onChanged: _onChanged,
                hintText: widget.hintText,
                leading: widget.leading,
                trailing: widget.trailing,
                autofocus: widget.autofocus,
                showClearButton: widget.showClearButton,
                onVoiceSearch: widget.onVoiceSearch,
                onFilterPressed: widget.onFilterPressed,
                showDebounceIndicator: widget.showDebounceIndicator,
              ),
            ),
            if (state.isIdle && widget.idleBuilder != null)
              Expanded(child: widget.idleBuilder!(context))
            else
              Expanded(
                child: SearchPlusResults<T>(
                  state: state,
                  itemBuilder: widget.itemBuilder,
                  onItemTap: widget.onItemTap,
                  layout: widget.layout,
                  density: widget.density,
                  animationConfig: widget.animationConfig,
                  emptyState: widget.emptyState,
                  errorState: widget.errorState,
                  loadingWidget: widget.loadingWidget,
                  onRetry: () =>
                      _controller.searchImmediate(_controller.query),
                  showShimmer: widget.showShimmer,
                  gridCrossAxisCount: widget.gridCrossAxisCount,
                  gridChildAspectRatio: widget.gridChildAspectRatio,
                  headerBuilder: widget.headerBuilder,
                  footerBuilder: widget.footerBuilder,
                  separatorBuilder: widget.separatorBuilder,
                  physics: widget.physics,
                  padding: widget.resultsPadding,
                  shrinkWrap: widget.shrinkWrap,
                  emptyBuilder: widget.emptyBuilder,
                ),
              ),
          ],
        );
      },
    );

    // Apply theme if provided.
    if (widget.theme != null) {
      child = SearchTheme(data: widget.theme!, child: child);
    }

    // Apply localizations if provided.
    if (widget.localizations != null) {
      child = SearchLocalizationsProvider(
        localizations: widget.localizations!,
        child: child,
      );
    }

    return child;
  }
}
