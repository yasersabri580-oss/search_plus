import 'package:flutter/material.dart';

/// A skeleton/shimmer loading widget for search results.
///
/// Displays animated placeholder items that mimic the layout of real
/// search results, providing a premium loading experience.
///
/// ```dart
/// SearchSkeletonLoading(
///   itemCount: 5,
///   density: SearchSkeletonDensity.comfortable,
/// )
/// ```
class SearchSkeletonLoading extends StatefulWidget {
  /// Creates a skeleton loading widget.
  const SearchSkeletonLoading({
    super.key,
    this.itemCount = 5,
    this.density = SearchSkeletonDensity.comfortable,
    this.animate = true,
    this.shimmerBaseColor,
    this.shimmerHighlightColor,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  /// Number of skeleton items to show.
  final int itemCount;

  /// Visual density of skeleton items.
  final SearchSkeletonDensity density;

  /// Whether to animate the shimmer effect.
  final bool animate;

  /// Base color for the shimmer effect.
  final Color? shimmerBaseColor;

  /// Highlight color for the shimmer effect.
  final Color? shimmerHighlightColor;

  /// Border radius of skeleton items.
  final double borderRadius;

  /// Padding around each skeleton item.
  final EdgeInsetsGeometry padding;

  @override
  State<SearchSkeletonLoading> createState() => _SearchSkeletonLoadingState();
}

class _SearchSkeletonLoadingState extends State<SearchSkeletonLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: widget.itemCount,
          itemBuilder: (context, index) => _buildSkeletonItem(context, index),
        );
      },
    );
  }

  Widget _buildSkeletonItem(BuildContext context, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final baseColor = widget.shimmerBaseColor ??
        colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
    final highlightColor = widget.shimmerHighlightColor ??
        colorScheme.surfaceContainerHighest.withValues(alpha: 0.2);

    return Padding(
      padding: widget.padding,
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: Duration(milliseconds: 200 + (index * 50)),
        child: _SkeletonItemLayout(
          density: widget.density,
          borderRadius: widget.borderRadius,
          baseColor: baseColor,
          highlightColor: highlightColor,
          animationValue: _animation.value,
        ),
      ),
    );
  }
}

/// A single animated skeleton shimmer box.
class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.baseColor,
    required this.highlightColor,
    required this.animationValue,
  });

  final double width;
  final double height;
  final double borderRadius;
  final Color baseColor;
  final Color highlightColor;
  final double animationValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [baseColor, highlightColor, baseColor],
          stops: [
            (animationValue - 0.3).clamp(0.0, 1.0),
            animationValue.clamp(0.0, 1.0),
            (animationValue + 0.3).clamp(0.0, 1.0),
          ],
        ),
      ),
    );
  }
}

class _SkeletonItemLayout extends StatelessWidget {
  const _SkeletonItemLayout({
    required this.density,
    required this.borderRadius,
    required this.baseColor,
    required this.highlightColor,
    required this.animationValue,
  });

  final SearchSkeletonDensity density;
  final double borderRadius;
  final Color baseColor;
  final Color highlightColor;
  final double animationValue;

  @override
  Widget build(BuildContext context) {
    return switch (density) {
      SearchSkeletonDensity.compact => _buildCompact(),
      SearchSkeletonDensity.comfortable => _buildComfortable(),
      SearchSkeletonDensity.rich => _buildRich(),
    };
  }

  Widget _buildCompact() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _ShimmerBox(
            width: 24,
            height: 24,
            borderRadius: 12,
            baseColor: baseColor,
            highlightColor: highlightColor,
            animationValue: animationValue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ShimmerBox(
              width: double.infinity,
              height: 16,
              borderRadius: 4,
              baseColor: baseColor,
              highlightColor: highlightColor,
              animationValue: animationValue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComfortable() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _ShimmerBox(
            width: 40,
            height: 40,
            borderRadius: 20,
            baseColor: baseColor,
            highlightColor: highlightColor,
            animationValue: animationValue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(
                  width: double.infinity,
                  height: 16,
                  borderRadius: 4,
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  animationValue: animationValue,
                ),
                const SizedBox(height: 8),
                _ShimmerBox(
                  width: 180,
                  height: 12,
                  borderRadius: 4,
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  animationValue: animationValue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRich() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: baseColor.withValues(alpha: 0.3),
      ),
      child: Row(
        children: [
          _ShimmerBox(
            width: 64,
            height: 64,
            borderRadius: 8,
            baseColor: baseColor,
            highlightColor: highlightColor,
            animationValue: animationValue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(
                  width: double.infinity,
                  height: 18,
                  borderRadius: 4,
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  animationValue: animationValue,
                ),
                const SizedBox(height: 8),
                _ShimmerBox(
                  width: 200,
                  height: 14,
                  borderRadius: 4,
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  animationValue: animationValue,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ShimmerBox(
                      width: 60,
                      height: 10,
                      borderRadius: 4,
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                      animationValue: animationValue,
                    ),
                    const SizedBox(width: 8),
                    _ShimmerBox(
                      width: 80,
                      height: 10,
                      borderRadius: 4,
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                      animationValue: animationValue,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Visual density levels for skeleton loading.
enum SearchSkeletonDensity {
  /// Minimal — just a title bar.
  compact,

  /// Title + subtitle with avatar.
  comfortable,

  /// Full card with image, title, subtitle, and metadata.
  rich,
}
