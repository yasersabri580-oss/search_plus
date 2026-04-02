import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A floating button that appears when the user scrolls down,
/// allowing them to quickly scroll back to the top.
///
/// Wrap your scroll view with this widget:
/// ```dart
/// ScrollToTopButton(
///   scrollController: myScrollController,
///   child: ListView.builder(...),
/// )
/// ```
class ScrollToTopButton extends StatefulWidget {
  /// Creates a scroll-to-top button.
  const ScrollToTopButton({
    super.key,
    required this.scrollController,
    required this.child,
    this.showAfterOffset = 200.0,
    this.icon = Icons.arrow_upward_rounded,
    this.duration = const Duration(milliseconds: 400),
    this.position = const Offset(16, 16),
  });

  /// The scroll controller to monitor and control.
  final ScrollController scrollController;

  /// The child widget (typically a scrollable).
  final Widget child;

  /// Scroll offset after which the button appears.
  final double showAfterOffset;

  /// The icon to display on the button.
  final IconData icon;

  /// Duration of the scroll-to-top animation.
  final Duration duration;

  /// Position offset from bottom-right.
  final Offset position;

  @override
  State<ScrollToTopButton> createState() => _ScrollToTopButtonState();
}

class _ScrollToTopButtonState extends State<ScrollToTopButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showButton = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final shouldShow =
        widget.scrollController.offset > widget.showAfterOffset;
    if (shouldShow != _showButton) {
      _showButton = shouldShow;
      if (_showButton) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  void _scrollToTop() {
    widget.scrollController.animateTo(
      0,
      duration: widget.duration,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          right: widget.position.dx,
          bottom: widget.position.dy,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _fadeAnimation,
              child: FloatingActionButton.small(
                heroTag: 'search_plus_scroll_to_top',
                onPressed: _scrollToTop,
                child: Icon(widget.icon),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
