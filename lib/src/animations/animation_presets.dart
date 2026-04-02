import 'package:flutter/material.dart';

/// Predefined animation configurations for search transitions.
enum SearchAnimationPreset {
  /// No animation.
  none,

  /// Simple fade in/out.
  fade,

  /// Slide from bottom.
  slideUp,

  /// Slide from right.
  slideRight,

  /// Scale from center.
  scale,

  /// Combined fade and slide.
  fadeSlideUp,

  /// Staggered list animation for result items.
  staggered,
}

/// Configuration for search animations.
class SearchAnimationConfig {
  /// Creates animation configuration.
  const SearchAnimationConfig({
    this.preset = SearchAnimationPreset.fadeSlideUp,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.enabled = true,
  });

  /// The animation preset to use.
  final SearchAnimationPreset preset;

  /// Duration of the animation.
  final Duration duration;

  /// Animation curve.
  final Curve curve;

  /// Delay between items in staggered animations.
  final Duration staggerDelay;

  /// Whether animations are enabled.
  final bool enabled;

  /// A config with no animations.
  static const none = SearchAnimationConfig(
    preset: SearchAnimationPreset.none,
    enabled: false,
  );
}

/// Wraps a child widget with the specified animation preset.
class AnimatedSearchItem extends StatefulWidget {
  /// Creates an animated search item.
  const AnimatedSearchItem({
    super.key,
    required this.child,
    this.index = 0,
    this.config = const SearchAnimationConfig(),
    this.show = true,
  });

  /// The child widget to animate.
  final Widget child;

  /// Index in the list (for stagger calculations).
  final int index;

  /// Animation configuration.
  final SearchAnimationConfig config;

  /// Whether to show or hide the item.
  final bool show;

  @override
  State<AnimatedSearchItem> createState() => _AnimatedSearchItemState();
}

class _AnimatedSearchItemState extends State<AnimatedSearchItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.config.duration,
      vsync: this,
    );

    _setupAnimations();

    if (!widget.config.enabled ||
        widget.config.preset == SearchAnimationPreset.none) {
      _controller.value = widget.show ? 1.0 : 0.0;
    } else if (widget.show) {
      final staggerDelay = widget.config.staggerDelay * widget.index;
      Future.delayed(staggerDelay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  void _setupAnimations() {
    final curve = CurvedAnimation(
      parent: _controller,
      curve: widget.config.curve,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(curve);

    switch (widget.config.preset) {
      case SearchAnimationPreset.slideUp:
      case SearchAnimationPreset.fadeSlideUp:
      case SearchAnimationPreset.staggered:
        _slideAnimation = Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(curve);
      case SearchAnimationPreset.slideRight:
        _slideAnimation = Tween<Offset>(
          begin: const Offset(-0.1, 0),
          end: Offset.zero,
        ).animate(curve);
      default:
        _slideAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: Offset.zero,
        ).animate(curve);
    }
  }

  @override
  void didUpdateWidget(AnimatedSearchItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show != oldWidget.show) {
      if (widget.show) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.config.enabled ||
        widget.config.preset == SearchAnimationPreset.none) {
      return widget.child;
    }

    Widget child = widget.child;

    switch (widget.config.preset) {
      case SearchAnimationPreset.fade:
        child = FadeTransition(
          opacity: _fadeAnimation,
          child: child,
        );
      case SearchAnimationPreset.slideUp:
      case SearchAnimationPreset.slideRight:
        child = SlideTransition(
          position: _slideAnimation,
          child: child,
        );
      case SearchAnimationPreset.scale:
        child = ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: child,
          ),
        );
      case SearchAnimationPreset.fadeSlideUp:
      case SearchAnimationPreset.staggered:
        child = FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: child,
          ),
        );
      case SearchAnimationPreset.none:
        break;
    }

    return child;
  }
}

/// A shimmer/skeleton loading effect widget.
class ShimmerLoading extends StatefulWidget {
  /// Creates a shimmer loading widget.
  const ShimmerLoading({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 72,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.baseColor,
    this.highlightColor,
  });

  /// Number of skeleton items to show.
  final int itemCount;

  /// Height of each skeleton item.
  final double itemHeight;

  /// Padding around the shimmer list.
  final EdgeInsets padding;

  /// Base color of the shimmer.
  final Color? baseColor;

  /// Highlight color of the shimmer sweep.
  final Color? highlightColor;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = widget.baseColor ??
        colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final highlightColor = widget.highlightColor ??
        colorScheme.surfaceContainerHighest;

    return ListView.builder(
      padding: widget.padding,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: widget.itemCount,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              height: widget.itemHeight,
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  _ShimmerBox(
                    controller: _controller,
                    width: 48,
                    height: 48,
                    borderRadius: BorderRadius.circular(8),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ShimmerBox(
                          controller: _controller,
                          width: double.infinity,
                          height: 16,
                          borderRadius: BorderRadius.circular(4),
                          baseColor: baseColor,
                          highlightColor: highlightColor,
                        ),
                        const SizedBox(height: 8),
                        _ShimmerBox(
                          controller: _controller,
                          width: 160,
                          height: 12,
                          borderRadius: BorderRadius.circular(4),
                          baseColor: baseColor,
                          highlightColor: highlightColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.controller,
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.baseColor,
    required this.highlightColor,
  });

  final AnimationController controller;
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final Color baseColor;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                (controller.value - 0.3).clamp(0.0, 1.0),
                controller.value,
                (controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

