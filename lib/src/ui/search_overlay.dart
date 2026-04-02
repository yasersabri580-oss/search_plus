import 'package:flutter/material.dart';
import 'package:search_plus/search_plus.dart';

import '../animations/animation_presets.dart';
import '../core/search_controller.dart';
import '../core/search_result.dart';
import '../core/search_state.dart';
import 'search_bar_widget.dart';
import 'states/search_states.dart';

/// A search widget that displays results in a floating overlay dropdown
/// beneath the search bar.
///
/// The overlay automatically opens when results are available and closes
/// on outside tap, Escape key, or focus loss.
///
/// ```dart
/// SearchPlusOverlay<Product>(
///   controller: controller,
///   hintText: 'Search products…',
///   itemBuilder: (context, result, index) => ListTile(
///     title: Text(result.title),
///   ),
/// )
/// ```
class SearchPlusOverlay<T> extends StatefulWidget {
  /// Creates a search overlay widget.
  const SearchPlusOverlay({
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
    this.maxOverlayHeight = 400,
    this.overlayDecoration,
    this.overlayBorderRadius,
    this.overlayElevation = 8,
    this.showShimmer = true,
    this.animationConfig = const SearchAnimationConfig(),
    this.addToHistoryOnSubmit = true,
    this.closeOnSelect = true,
    this.enableBackgroundBlur = false,
    this.keyboardDismissOnScroll = true,
    this.emptyBuilder,
    this.onOverlayVisibilityChanged,
    this.overlayAnimationDuration = const Duration(milliseconds: 200),
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

  /// Maximum height of the overlay dropdown.
  final double maxOverlayHeight;

  /// Custom decoration for the overlay panel.
  final BoxDecoration? overlayDecoration;

  /// Border radius for the overlay panel.
  final BorderRadius? overlayBorderRadius;

  /// Shadow elevation for the overlay panel.
  final double overlayElevation;

  /// Whether to show shimmer loading in the overlay.
  final bool showShimmer;

  /// Animation configuration for overlay items.
  final SearchAnimationConfig animationConfig;

  /// Whether to add to history on submit.
  final bool addToHistoryOnSubmit;

  /// Whether to close the overlay when a result is selected.
  final bool closeOnSelect;

  /// Whether to show a blurred/dimmed background when the overlay is visible.
  final bool enableBackgroundBlur;

  /// Whether to dismiss the keyboard when scrolling in the overlay.
  final bool keyboardDismissOnScroll;

  /// Custom builder for the empty state in the overlay.
  final Widget Function(BuildContext context, String query)? emptyBuilder;

  /// Called when the overlay visibility changes.
  final ValueChanged<bool>? onOverlayVisibilityChanged;

  /// Duration of the overlay open/close animation.
  final Duration overlayAnimationDuration;

  @override
  State<SearchPlusOverlay<T>> createState() => _SearchPlusOverlayState<T>();
}

class _SearchPlusOverlayState<T> extends State<SearchPlusOverlay<T>>
    with SingleTickerProviderStateMixin {
  final _layerLink = LayerLink();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isOverlayVisible = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onControllerChanged);

    _fadeController = AnimationController(
      duration: widget.overlayAnimationDuration,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _textController.dispose();
    widget.controller.removeListener(_onControllerChanged);
    _fadeController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      // Delay to allow tap on overlay items to register
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!_focusNode.hasFocus && mounted) {
          _hideOverlay();
        }
      });
    } else if (_shouldShowOverlay()) {
      _showOverlay();
    }
  }

  void _onControllerChanged() {
    if (_focusNode.hasFocus && _shouldShowOverlay()) {
      if (!_isOverlayVisible) {
        _showOverlay();
      } else {
        _overlayEntry?.markNeedsBuild();
      }
    } else if (!_shouldShowOverlay() && _isOverlayVisible) {
      _hideOverlay();
    }
  }

  bool _shouldShowOverlay() {
    final state = widget.controller.state;
    return state.status != SearchStatus.idle;
  }

  void _showOverlay() {
    if (_isOverlayVisible) {
      _overlayEntry?.markNeedsBuild();
      return;
    }

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _isOverlayVisible = true;
    _fadeController.forward();
    widget.onOverlayVisibilityChanged?.call(true);
  }

  void _hideOverlay() {
    if (!_isOverlayVisible) return;

    _fadeController.reverse().then((_) {
      _removeOverlay();
      widget.onOverlayVisibilityChanged?.call(false);
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOverlayVisible = false;
  }

  void _onItemTapped(SearchResult<T> result) {
    widget.onItemTap?.call(result);
    if (widget.closeOnSelect) {
      _hideOverlay();
      _focusNode.unfocus();
    }
  }

  void _onSubmitted(String query) {
    if (widget.addToHistoryOnSubmit) {
      widget.controller.addToHistory(query);
    }
    widget.onSubmitted?.call(query);
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) {
        final overlayPanel = Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 4),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _OverlayPanel<T>(
                controller: widget.controller,
                maxHeight: widget.maxOverlayHeight,
                decoration: widget.overlayDecoration,
                borderRadius: widget.overlayBorderRadius,
                elevation: widget.overlayElevation,
                showShimmer: widget.showShimmer,
                animationConfig: widget.animationConfig,
                itemBuilder: widget.itemBuilder,
                onItemTap: _onItemTapped,
                onDismiss: _hideOverlay,
                keyboardDismissOnScroll: widget.keyboardDismissOnScroll,
                emptyBuilder: widget.emptyBuilder,
              ),
            ),
          ),
        );

        if (widget.enableBackgroundBlur) {
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: _hideOverlay,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
              overlayPanel,
            ],
          );
        }

        return overlayPanel;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: SearchPlusBar(
        controller: _textController,
        focusNode: _focusNode,
        onChanged: (query) => widget.controller.search(query),
        onSubmitted: _onSubmitted,
        hintText: widget.hintText,
        leading: widget.leading,
        trailing: widget.trailing,
        autofocus: widget.autofocus,
        showClearButton: widget.showClearButton,
      ),
    );
  }
}

/// The floating overlay panel that displays search results.
class _OverlayPanel<T> extends StatelessWidget {
  const _OverlayPanel({
    required this.controller,
    required this.maxHeight,
    this.decoration,
    this.borderRadius,
    this.elevation = 8,
    this.showShimmer = true,
    this.animationConfig = const SearchAnimationConfig(),
    this.itemBuilder,
    this.onItemTap,
    this.onDismiss,
    this.keyboardDismissOnScroll = true,
    this.emptyBuilder,
  });

  final SearchPlusController<T> controller;
  final double maxHeight;
  final BoxDecoration? decoration;
  final BorderRadius? borderRadius;
  final double elevation;
  final bool showShimmer;
  final SearchAnimationConfig animationConfig;
  final Widget Function(
      BuildContext context, SearchResult<T> result, int index)? itemBuilder;
  final void Function(SearchResult<T> result)? onItemTap;
  final VoidCallback? onDismiss;
  final bool keyboardDismissOnScroll;
  final Widget Function(BuildContext context, String query)? emptyBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final resolvedBorderRadius =
        borderRadius ?? BorderRadius.circular(16);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.state;

        return Material(
          elevation: elevation,
          borderRadius: resolvedBorderRadius,
          color: decoration?.color ?? colorScheme.surfaceContainer,
          shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
          clipBehavior: Clip.antiAlias,
          child: Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            decoration: decoration?.copyWith(
              borderRadius: resolvedBorderRadius,
            ),
            child: _buildContent(context, state),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, SearchState<T> state) {
    switch (state.status) {
      case SearchStatus.idle:
        return const SizedBox.shrink();
      case SearchStatus.loading:
        if (showShimmer) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: ShimmerLoading(
              itemCount: 3,
              itemHeight: 56,
            ),
          );
        }
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator.adaptive()),
        );
      case SearchStatus.error:
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SearchErrorState(
            message: state.error,
            onRetry: () =>
                controller.searchImmediate(controller.query),
          ),
        );
      case SearchStatus.empty:
        if (emptyBuilder != null) {
          return emptyBuilder!(context, state.query);
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SearchEmptyState(query: state.query),
        );
      case SearchStatus.success:
        return _buildResults(context, state);
    }
  }

  Widget _buildResults(BuildContext context, SearchState<T> state) {
    final results = state.results;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      shrinkWrap: true,
      keyboardDismissBehavior: keyboardDismissOnScroll
          ? ScrollViewKeyboardDismissBehavior.onDrag
          : ScrollViewKeyboardDismissBehavior.manual,
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        final child = itemBuilder?.call(context, result, index) ??
            _DefaultOverlayItem<T>(
              result: result,
              query: state.query,
              onTap: onItemTap != null ? () => onItemTap!(result) : null,
            );

        return AnimatedSearchItem(
          index: index,
          config: animationConfig,
          child: child,
        );
      },
    );
  }
}

/// Default overlay result item.
class _DefaultOverlayItem<T> extends StatelessWidget {
  const _DefaultOverlayItem({
    required this.result,
    required this.query,
    this.onTap,
  });

  final SearchResult<T> result;
  final String query;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  HighlightText(
                    text: result.title,
                    query: query,
                    style: theme.textTheme.bodyMedium,
                    highlightStyle: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                  if (result.subtitle != null)
                    Text(
                      result.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.north_west_rounded,
              size: 16,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// Deprecated: Use [SearchPlusOverlay] instead.
@Deprecated('Use SearchPlusOverlay instead. SearchOverlay was renamed to SearchPlusOverlay.')
typedef SearchOverlay<T> = SearchPlusOverlay<T>;
