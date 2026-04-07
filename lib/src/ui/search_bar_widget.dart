import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/search_localizations.dart';
import '../theme/search_theme.dart';

/// A highly customizable, generic Material 3 search bar widget.
///
/// [SearchPlusBar] is a standalone, drop-in search input that works in any
/// Flutter screen — from a product catalog to a settings page. It adapts to
/// its context through generous customization hooks while providing sensible
/// Material 3 defaults out of the box.
///
/// ## Key capabilities
///
/// * **Animated focus state** — elevation, border color, and icon color
///   animate when the bar receives or loses focus.
/// * **Clear / voice / filter action buttons** — each conditionally shown
///   based on callbacks you provide.
/// * **Debounce indicator** — optional linear progress bar that shows while
///   the user is still typing.
/// * **Fully generic** — works with *any* data type via the parent
///   [SearchPlusController<T>], or can be used standalone with just
///   [onChanged] / [onSubmitted].
/// * **Tap-to-navigate** — set [readOnly] + [onTap] to create a search bar
///   that opens a dedicated search page when tapped.
/// * **Direct style overrides** — pass [textStyle], [hintStyle], [height],
///   or [contentPadding] without wrapping in a [SearchTheme].
///
/// ## Minimal example
///
/// ```dart
/// SearchPlusBar(
///   onChanged: (query) => controller.search(query),
///   hintText: 'Search products...',
///   leading: Icon(Icons.search),
/// )
/// ```
///
/// ## Tap-to-navigate example
///
/// ```dart
/// SearchPlusBar(
///   readOnly: true,
///   onTap: () => Navigator.push(context,
///     MaterialPageRoute(builder: (_) => FullSearchPage())),
///   hintText: 'Tap to search…',
/// )
/// ```
class SearchPlusBar extends StatefulWidget {
  /// Creates a search bar.
  const SearchPlusBar({
    super.key,
    this.onChanged,
    this.onSubmitted,
    this.onFocusChanged,
    this.onTap,
    this.controller,
    this.focusNode,
    this.hintText,
    this.leading,
    this.trailing,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.showClearButton = true,
    this.onVoiceSearch,
    this.textInputAction = TextInputAction.search,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType,
    this.inputFormatters,
    this.onFilterPressed,
    this.showDebounceIndicator = false,
    this.borderRadius,
    this.elevation,
    this.backgroundColor,
    this.textStyle,
    this.hintStyle,
    this.height,
    this.contentPadding,
  });

  /// Called when the search text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the search.
  final ValueChanged<String>? onSubmitted;

  /// Called when focus changes.
  final ValueChanged<bool>? onFocusChanged;

  /// Called when the search bar is tapped.
  ///
  /// Useful for "tap to navigate" patterns where tapping the bar opens
  /// a dedicated search page. Combine with [readOnly] = `true`.
  final VoidCallback? onTap;

  /// Text editing controller.
  final TextEditingController? controller;

  /// Focus node.
  final FocusNode? focusNode;

  /// Placeholder text. Falls back to localization default.
  final String? hintText;

  /// Leading widget (typically a search icon).
  final Widget? leading;

  /// Trailing widget(s).
  final Widget? trailing;

  /// Whether the search bar should request focus on mount.
  final bool autofocus;

  /// Whether the search bar is enabled.
  final bool enabled;

  /// Whether the search bar is read-only.
  ///
  /// When `true`, the text field does not accept keyboard input. Use together
  /// with [onTap] to create a search bar that navigates to a search page.
  final bool readOnly;

  /// Whether to show the clear button when text is present.
  final bool showClearButton;

  /// Callback for voice search button. If null, voice button is hidden.
  final VoidCallback? onVoiceSearch;

  /// Text input action.
  final TextInputAction textInputAction;

  /// Text capitalization.
  final TextCapitalization textCapitalization;

  /// Keyboard type for the text field.
  ///
  /// Defaults to the platform default. Set to [TextInputType.url] or
  /// [TextInputType.emailAddress] for specialised search contexts.
  final TextInputType? keyboardType;

  /// Optional input formatters applied to the text field.
  ///
  /// Useful for restricting characters (e.g. digits only) or limiting length.
  final List<TextInputFormatter>? inputFormatters;

  /// Callback for the filter button. If null, filter button is hidden.
  final VoidCallback? onFilterPressed;

  /// Whether to show a debounce progress indicator below the search bar.
  final bool showDebounceIndicator;

  /// Custom border radius. If null, uses the theme's default.
  final BorderRadius? borderRadius;

  /// Custom elevation. If null, uses the theme's default.
  final double? elevation;

  /// Custom background color. If null, uses the theme's default.
  final Color? backgroundColor;

  /// Direct text style override. If null, uses the theme's default.
  final TextStyle? textStyle;

  /// Direct hint text style override. If null, uses the theme's default.
  final TextStyle? hintStyle;

  /// Direct height override. If null, uses the theme's default (56).
  final double? height;

  /// Padding inside the text field. If null, uses [EdgeInsets.zero].
  final EdgeInsets? contentPadding;

  @override
  State<SearchPlusBar> createState() => _SearchPlusBarState();
}

/// Default duration for the debounce indicator timer.
const Duration _kDebounceIndicatorDuration = Duration(milliseconds: 350);

class _SearchPlusBarState extends State<SearchPlusBar>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _elevationAnimation;
  bool _isFocused = false;
  bool _hasText = false;
  bool _isDebouncing = false;
  Timer? _debounceIndicatorTimer;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onTextChanged);
    _hasText = _controller.text.isNotEmpty;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _elevationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    if (_isFocused) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    widget.onFocusChanged?.call(_isFocused);
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
    if (widget.showDebounceIndicator) {
      _debounceIndicatorTimer?.cancel();
      if (!_isDebouncing) {
        setState(() {
          _isDebouncing = true;
        });
      }
      _debounceIndicatorTimer = Timer(_kDebounceIndicatorDuration, () {
        if (mounted) {
          setState(() {
            _isDebouncing = false;
          });
        }
      });
    }
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _debounceIndicatorTimer?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    _controller.removeListener(_onTextChanged);
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchTheme = SearchTheme.of(context);
    final barTheme = searchTheme.searchBarTheme;
    final l10n = SearchLocalizationsProvider.of(context);
    final effectiveBorderRadius =
        widget.borderRadius ?? barTheme.borderRadius!;

    return AnimatedBuilder(
      animation: _elevationAnimation,
      builder: (context, child) {
        final baseElevation = widget.elevation ?? barTheme.elevation!;
        final elevation = baseElevation +
            (_elevationAnimation.value *
                (barTheme.focusedElevation! - baseElevation));

        final effectiveBackgroundColor = _isFocused
            ? barTheme.focusedBackgroundColor
            : (widget.backgroundColor ?? barTheme.backgroundColor);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              elevation: elevation,
              shadowColor: barTheme.shadowColor,
              borderRadius: effectiveBorderRadius,
              color: effectiveBackgroundColor,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                height: widget.height ?? barTheme.height,
                decoration: BoxDecoration(
                  borderRadius: effectiveBorderRadius,
                  border: Border.all(
                    color: _isFocused
                        ? barTheme.focusedBorderColor!
                        : barTheme.borderColor!,
                    width: barTheme.borderWidth!,
                  ),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: widget.leading ??
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.search_rounded,
                              key: ValueKey(_isFocused),
                              color: _isFocused
                                  ? barTheme.focusedBorderColor
                                  : barTheme.iconColor,
                            ),
                          ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        autofocus: widget.autofocus,
                        enabled: widget.enabled,
                        readOnly: widget.readOnly,
                        onTap: widget.onTap,
                        textInputAction: widget.textInputAction,
                        textCapitalization: widget.textCapitalization,
                        keyboardType: widget.keyboardType,
                        inputFormatters: widget.inputFormatters,
                        style: widget.textStyle ?? barTheme.textStyle,
                        cursorColor: barTheme.cursorColor,
                        decoration: InputDecoration(
                          hintText: widget.hintText ?? l10n.hintText,
                          hintStyle: widget.hintStyle ?? barTheme.hintStyle,
                          border: InputBorder.none,
                          contentPadding:
                              widget.contentPadding ?? EdgeInsets.zero,
                          isDense: true,
                        ),
                        onChanged: widget.onChanged,
                        onSubmitted: widget.onSubmitted,
                      ),
                    ),
                    if (_hasText && widget.showClearButton && !widget.readOnly)
                      _buildIconButton(
                        icon: Icons.close_rounded,
                        tooltip: l10n.clearSearchTooltip,
                        onPressed: _clear,
                        color: barTheme.iconColor,
                      ),
                    if (widget.onVoiceSearch != null && !_hasText)
                      _buildIconButton(
                        icon: Icons.mic_rounded,
                        tooltip: l10n.voiceSearchTooltip,
                        onPressed: widget.onVoiceSearch!,
                        color: barTheme.iconColor,
                      ),
                    if (widget.onFilterPressed != null)
                      _buildIconButton(
                        icon: Icons.tune_rounded,
                        tooltip: 'Filter',
                        onPressed: widget.onFilterPressed!,
                        color: barTheme.iconColor,
                      ),
                    if (widget.trailing != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: widget.trailing!,
                      )
                    else
                      const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
            if (widget.showDebounceIndicator && _isDebouncing)
              ClipRRect(
                borderRadius: BorderRadius.only(
                  bottomLeft:
                      Radius.circular(effectiveBorderRadius.bottomLeft.x),
                  bottomRight:
                      Radius.circular(effectiveBorderRadius.bottomRight.x),
                ),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    barTheme.cursorColor ??
                        Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Semantics(
      label: tooltip,
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
        splashRadius: 20,
      ),
    );
  }
}
