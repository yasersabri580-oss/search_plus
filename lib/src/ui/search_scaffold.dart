import 'package:flutter/material.dart';

import '../animations/animation_presets.dart';
import '../core/search_controller.dart';
import '../core/search_result.dart';
import '../core/search_state.dart';
import '../l10n/search_localizations.dart';
import '../theme/search_theme.dart';
import 'search_bar_widget.dart';
import 'search_results_widget.dart';

/// A complete search scaffold that combines search bar, results, and states.
///
/// This is the highest-level widget for quick integration.
///
/// ```dart
/// SearchScaffold<Product>(
///   controller: searchController,
///   itemBuilder: (context, result, index) => ListTile(
///     title: Text(result.title),
///     subtitle: Text(result.subtitle ?? ''),
///   ),
///   onItemTap: (result) => navigateToDetail(result.data),
/// )
/// ```
class SearchScaffold<T> extends StatefulWidget {
  /// Creates a search scaffold.
  const SearchScaffold({
    super.key,
    required this.controller,
    this.itemBuilder,
    this.onItemTap,
    this.onSubmitted,
    this.hintText,
    this.leading,
    this.trailing,
    this.autofocus = false,
    this.showClearButton = true,
    this.onVoiceSearch,
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
    this.addToHistoryOnSubmit = true,
  });

  /// The search controller.
  final SearchPlusController<T> controller;

  /// Custom builder for each result item.
  final Widget Function(
      BuildContext context, SearchResult<T> result, int index)? itemBuilder;

  /// Called when a result item is tapped.
  final void Function(SearchResult<T> result)? onItemTap;

  /// Called when the user submits the search.
  final ValueChanged<String>? onSubmitted;

  /// Placeholder text.
  final String? hintText;

  /// Leading widget for the search bar.
  final Widget? leading;

  /// Trailing widget for the search bar.
  final Widget? trailing;

  /// Whether to autofocus the search bar.
  final bool autofocus;

  /// Whether to show the clear button.
  final bool showClearButton;

  /// Callback for voice search.
  final VoidCallback? onVoiceSearch;

  /// Layout mode.
  final SearchResultsLayout layout;

  /// Display density.
  final SearchResultDensity density;

  /// Animation configuration.
  final SearchAnimationConfig animationConfig;

  /// Custom empty state widget.
  final Widget? emptyState;

  /// Custom error state widget.
  final Widget? errorState;

  /// Custom loading widget.
  final Widget? loadingWidget;

  /// Whether to show shimmer loading.
  final bool showShimmer;

  /// Grid cross axis count.
  final int gridCrossAxisCount;

  /// Grid child aspect ratio.
  final double gridChildAspectRatio;

  /// Padding around the search bar.
  final EdgeInsets? barPadding;

  /// Padding around the results.
  final EdgeInsets? resultsPadding;

  /// Optional header builder.
  final Widget Function(BuildContext context, SearchState<T> state)?
      headerBuilder;

  /// Optional footer builder.
  final Widget Function(BuildContext context, SearchState<T> state)?
      footerBuilder;

  /// Custom separator builder.
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  /// Widget to show when search is idle (no query entered).
  final Widget Function(BuildContext context)? idleBuilder;

  /// Scroll physics.
  final ScrollPhysics? physics;

  /// Whether to shrink wrap the results.
  final bool shrinkWrap;

  /// Optional theme override.
  final SearchThemeData? theme;

  /// Optional localizations override.
  final SearchLocalizations? localizations;

  /// Whether to add to history on submit.
  final bool addToHistoryOnSubmit;

  @override
  State<SearchScaffold<T>> createState() => _SearchScaffoldState<T>();
}

class _SearchScaffoldState<T> extends State<SearchScaffold<T>> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onSubmitted(String query) {
    if (widget.addToHistoryOnSubmit) {
      widget.controller.addToHistory(query);
    }
    widget.onSubmitted?.call(query);
  }

  @override
  Widget build(BuildContext context) {
    Widget child = ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;

        return Column(
          children: [
            Padding(
              padding: widget.barPadding ??
                  const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SearchPlusBar(
                controller: _textController,
                onChanged: (query) => widget.controller.search(query),
                onSubmitted: _onSubmitted,
                hintText: widget.hintText,
                leading: widget.leading,
                trailing: widget.trailing,
                autofocus: widget.autofocus,
                showClearButton: widget.showClearButton,
                onVoiceSearch: widget.onVoiceSearch,
              ),
            ),
            if (state.isIdle && widget.idleBuilder != null)
              Expanded(child: widget.idleBuilder!(context))
            else
              Expanded(
                child: SearchResultsWidget<T>(
                  state: state,
                  itemBuilder: widget.itemBuilder,
                  onItemTap: widget.onItemTap,
                  layout: widget.layout,
                  density: widget.density,
                  animationConfig: widget.animationConfig,
                  emptyState: widget.emptyState,
                  errorState: widget.errorState,
                  loadingWidget: widget.loadingWidget,
                  onRetry: () => widget.controller
                      .searchImmediate(widget.controller.query),
                  showShimmer: widget.showShimmer,
                  gridCrossAxisCount: widget.gridCrossAxisCount,
                  gridChildAspectRatio: widget.gridChildAspectRatio,
                  headerBuilder: widget.headerBuilder,
                  footerBuilder: widget.footerBuilder,
                  separatorBuilder: widget.separatorBuilder,
                  physics: widget.physics,
                  padding: widget.resultsPadding,
                  shrinkWrap: widget.shrinkWrap,
                ),
              ),
          ],
        );
      },
    );

    // Apply theme if provided
    if (widget.theme != null) {
      child = SearchTheme(data: widget.theme!, child: child);
    }

    // Apply localizations if provided
    if (widget.localizations != null) {
      child = SearchLocalizationsProvider(
        localizations: widget.localizations!,
        child: child,
      );
    }

    return child;
  }
}
