import 'package:flutter/material.dart';

import '../l10n/search_localizations.dart';
import '../theme/search_theme.dart';

/// A highly customizable Material 3 search bar widget.
///
/// Features animated focus state, clear button, and leading/trailing icon slots.
///
/// ```dart
/// SearchPlusBar(
///   onChanged: (query) => controller.search(query),
///   hintText: 'Search products...',
///   leading: Icon(Icons.search),
/// )
/// ```
class SearchPlusBar extends StatefulWidget {
  /// Creates a search bar.
  const SearchPlusBar({
    super.key,
    this.onChanged,
    this.onSubmitted,
    this.onFocusChanged,
    this.controller,
    this.focusNode,
    this.hintText,
    this.leading,
    this.trailing,
    this.autofocus = false,
    this.enabled = true,
    this.showClearButton = true,
    this.onVoiceSearch,
    this.textInputAction = TextInputAction.search,
    this.textCapitalization = TextCapitalization.none,
  });

  /// Called when the search text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the search.
  final ValueChanged<String>? onSubmitted;

  /// Called when focus changes.
  final ValueChanged<bool>? onFocusChanged;

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

  /// Whether to show the clear button when text is present.
  final bool showClearButton;

  /// Callback for voice search button. If null, voice button is hidden.
  final VoidCallback? onVoiceSearch;

  /// Text input action.
  final TextInputAction textInputAction;

  /// Text capitalization.
  final TextCapitalization textCapitalization;

  @override
  State<SearchPlusBar> createState() => _SearchPlusBarState();
}

class _SearchPlusBarState extends State<SearchPlusBar>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _elevationAnimation;
  bool _isFocused = false;
  bool _hasText = false;

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
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
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

    return AnimatedBuilder(
      animation: _elevationAnimation,
      builder: (context, child) {
        final elevation = barTheme.elevation! +
            (_elevationAnimation.value *
                (barTheme.focusedElevation! - barTheme.elevation!));

        return Material(
          elevation: elevation,
          shadowColor: barTheme.shadowColor,
          borderRadius: barTheme.borderRadius,
          color: _isFocused
              ? barTheme.focusedBackgroundColor
              : barTheme.backgroundColor,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            height: barTheme.height,
            decoration: BoxDecoration(
              borderRadius: barTheme.borderRadius,
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
                    textInputAction: widget.textInputAction,
                    textCapitalization: widget.textCapitalization,
                    style: barTheme.textStyle,
                    cursorColor: barTheme.cursorColor,
                    decoration: InputDecoration(
                      hintText: widget.hintText ?? l10n.hintText,
                      hintStyle: barTheme.hintStyle,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                  ),
                ),
                if (_hasText && widget.showClearButton)
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
