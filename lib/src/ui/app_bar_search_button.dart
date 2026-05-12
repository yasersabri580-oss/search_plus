import 'package:flutter/material.dart';

import '../l10n/search_localizations.dart';
import '../theme/search_theme.dart';

/// A compact animated search action intended for use in [AppBar.actions].
///
/// Renders a single search icon by default. On hover (desktop / web) the input
/// field smoothly expands beside the icon. Tapping the icon on any platform
/// also expands the field and focuses it. The expanded state is held as long
/// as the field contains text; once the field is cleared and both hover and
/// focus are gone the widget collapses back to icon-only.
///
/// The widget integrates naturally with [SearchTheme] / [SearchPlusThemeData]
/// and derives its colors, typography, and border styling from the ambient
/// theme — the same source used by [SearchPlusBar] and every other widget in
/// this package.
///
/// ## Basic usage
///
/// ```dart
/// AppBar(
///   title: const Text('My App'),
///   actions: [
///     AppBarSearchButton(
///       onChanged: (query) => _controller.search(query),
///     ),
///     const SizedBox(width: 4),
///   ],
/// )
/// ```
///
/// ## With a controller
///
/// ```dart
/// AppBarSearchButton(
///   controller: _textController,
///   onChanged: (query) => _controller.search(query),
///   onSubmitted: (query) {
///     _controller.addToHistory(query);
///     _controller.searchImmediate(query);
///   },
///   expandedWidth: 260,
///   hintText: 'Search products…',
/// )
/// ```
class AppBarSearchButton extends StatefulWidget {
  /// Creates an [AppBarSearchButton].
  const AppBarSearchButton({
    super.key,
    this.onChanged,
    this.onSubmitted,
    this.onFocusChanged,
    this.controller,
    this.focusNode,
    this.hintText,
    this.expandedWidth = 220.0,
    this.inputHeight = 40.0,
    this.showClearButton = true,
    this.searchTooltip,
    this.animationDuration = const Duration(milliseconds: 280),
    this.animationCurve = Curves.easeOutCubic,
  });

  /// Called whenever the search text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the search query (e.g. presses Enter).
  final ValueChanged<String>? onSubmitted;

  /// Called when the internal focus state changes.
  final ValueChanged<bool>? onFocusChanged;

  /// External [TextEditingController]. A private instance is created when omitted.
  final TextEditingController? controller;

  /// External [FocusNode]. A private instance is created when omitted.
  final FocusNode? focusNode;

  /// Placeholder text shown inside the expanded input.
  ///
  /// Falls back to the nearest [SearchLocalizationsProvider] value, which
  /// defaults to `'Search...'`.
  final String? hintText;

  /// Width of the text input when fully expanded.
  ///
  /// Defaults to `220`. Consider increasing this on wider screens or if a
  /// long [hintText] is provided.
  final double expandedWidth;

  /// Height of the text input container.
  ///
  /// Defaults to `40`, which fits neatly inside a standard Material 3 AppBar
  /// without altering the AppBar's own height.
  final double inputHeight;

  /// Whether to show a clear (×) button when the field contains text.
  final bool showClearButton;

  /// Tooltip shown on the search icon. Defaults to `'Search'`.
  final String? searchTooltip;

  /// Duration of the expand / collapse animation. Defaults to `280 ms`.
  final Duration animationDuration;

  /// Easing curve for the expand / collapse animation.
  ///
  /// Defaults to [Curves.easeOutCubic], consistent with the rest of the
  /// package's animation defaults.
  final Curve animationCurve;

  @override
  State<AppBarSearchButton> createState() => _AppBarSearchButtonState();
}

class _AppBarSearchButtonState extends State<AppBarSearchButton>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  late final AnimationController _animController;
  late final CurvedAnimation _expandAnimation;

  bool _isHovered = false;
  bool _isFocused = false;
  bool _hasText = false;

  bool get _shouldExpand => _isHovered || _isFocused || _hasText;

  // ─────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _textController = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _hasText = _textController.text.isNotEmpty;

    _animController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: widget.animationCurve,
      reverseCurve: widget.animationCurve.flipped,
    );

    _focusNode.addListener(_handleFocusChange);
    _textController.addListener(_handleTextChange);

    // If the field already has text or focus (e.g. restored state), jump
    // directly to the expanded position without animating.
    _isFocused = _focusNode.hasFocus;
    if (_hasText || _isFocused) _animController.value = 1.0;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _textController.removeListener(_handleTextChange);
    if (widget.controller == null) _textController.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    _expandAnimation.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Event handlers
  // ─────────────────────────────────────────────────────────────────────────

  void _handleFocusChange() {
    final focused = _focusNode.hasFocus;
    if (focused == _isFocused) return;
    setState(() => _isFocused = focused);
    widget.onFocusChanged?.call(focused);
    _syncAnimation();
  }

  void _handleTextChange() {
    final hasText = _textController.text.isNotEmpty;
    if (hasText == _hasText) return;
    setState(() => _hasText = hasText);
    _syncAnimation();
  }

  void _handleHoverEnter() {
    if (_isHovered) return;
    setState(() => _isHovered = true);
    _syncAnimation();
  }

  void _handleHoverExit() {
    if (!_isHovered) return;
    setState(() => _isHovered = false);
    _syncAnimation();
  }

  void _handleIconPressed() {
    _animController.forward();
    _focusNode.requestFocus();
  }

  void _clear() {
    _textController.clear();
    widget.onChanged?.call('');
    _focusNode.requestFocus();
  }

  void _syncAnimation() {
    if (_shouldExpand) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final searchTheme = SearchTheme.of(context);
    final barTheme = searchTheme.searchBarTheme;
    final l10n = SearchLocalizationsProvider.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      // Fix: lock the widget to a constant height equal to the input height so
      // the search icon stays perfectly aligned with the search field at all
      // stages of the expand / collapse animation.
      height: widget.inputHeight,
      child: MouseRegion(
        onEnter: (_) => _handleHoverEnter(),
        onExit: (_) => _handleHoverExit(),
        child: AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, _) {
            final t = _expandAnimation.value;

            final iconColor = Color.lerp(
              barTheme.iconColor ?? colorScheme.onSurfaceVariant,
              barTheme.activeIconColor ?? colorScheme.primary,
              t,
            );

            return Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Animated text field ──────────────────────────────────────
                ClipRect(
                  child: SizeTransition(
                    sizeFactor: _expandAnimation,
                    axis: Axis.horizontal,
                    // axisAlignment 1.0 anchors to the trailing edge so the
                    // field appears to unfold from the direction of the icon.
                    axisAlignment: 1.0,
                    child: SizedBox(
                      width: widget.expandedWidth,
                      height: widget.inputHeight,
                      child: FadeTransition(
                        opacity: _expandAnimation,
                        child: _InputContainer(
                          barTheme: barTheme,
                          colorScheme: colorScheme,
                          l10n: l10n,
                          t: t,
                          isFocused: _isFocused,
                          hasText: _hasText,
                          showClearButton: widget.showClearButton,
                          inputHeight: widget.inputHeight,
                          hintText: widget.hintText,
                          textController: _textController,
                          focusNode: _focusNode,
                          onChanged: widget.onChanged,
                          onSubmitted: widget.onSubmitted,
                          onClear: _clear,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Search icon (always visible) ─────────────────────────────
                Tooltip(
                  message: widget.searchTooltip ?? 'Search',
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _handleIconPressed,
                      child: SizedBox(
                        width: widget.inputHeight,
                        height: widget.inputHeight,
                        child: Icon(
                          Icons.search_rounded,
                          color: iconColor,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Internal widget that renders the text field inside its styled container.
///
/// Extracted into its own [StatelessWidget] to keep [_AppBarSearchButtonState]
/// focused on state / animation logic only.
class _InputContainer extends StatelessWidget {
  const _InputContainer({
    required this.barTheme,
    required this.colorScheme,
    required this.l10n,
    required this.t,
    required this.isFocused,
    required this.hasText,
    required this.showClearButton,
    required this.inputHeight,
    required this.hintText,
    required this.textController,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final SearchBarThemeData barTheme;
  final ColorScheme colorScheme;
  final SearchLocalizations l10n;
  final double t;
  final bool isFocused;
  final bool hasText;
  final bool showClearButton;
  final double inputHeight;
  final String? hintText;
  final TextEditingController textController;
  final FocusNode focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final borderColor = Color.lerp(
      (barTheme.borderColor ?? colorScheme.outline).withValues(alpha: 0.2),
      isFocused
          ? (barTheme.focusedBorderColor ?? colorScheme.primary)
          : (barTheme.borderColor ?? colorScheme.outline).withValues(alpha: 0.4),
      t,
    );

    final bgColor = Color.lerp(
      Colors.transparent,
      isFocused
          ? (barTheme.focusedBackgroundColor ??
              barTheme.backgroundColor ??
              colorScheme.surfaceContainerHighest)
          : (barTheme.backgroundColor ?? colorScheme.surfaceContainerHighest),
      t,
    );

    return Container(
      height: inputHeight,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(inputHeight / 2),
        border: Border.all(
          color: borderColor ?? Colors.transparent,
          width: barTheme.borderWidth ?? 1.0,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: textController,
              focusNode: focusNode,
              textInputAction: TextInputAction.search,
              style: barTheme.textStyle,
              cursorColor: barTheme.cursorColor ?? colorScheme.primary,
              decoration: InputDecoration(
                hintText: hintText ?? l10n.hintText,
                hintStyle: barTheme.hintStyle,
                border: barTheme.textFieldBorder ?? InputBorder.none,
                enabledBorder: barTheme.textFieldBorder ?? InputBorder.none,
                focusedBorder:
                    barTheme.textFieldFocusedBorder ?? InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: onChanged,
              onSubmitted: onSubmitted,
            ),
          ),
          if (hasText && showClearButton)
            Semantics(
              label: l10n.clearSearchTooltip,
              button: true,
              child: GestureDetector(
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: barTheme.iconColor ?? colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 10),
        ],
      ),
    );
  }
}
