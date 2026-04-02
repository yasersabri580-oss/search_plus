import 'dart:ui';

import 'package:flutter/material.dart';

/// A container with a glassmorphism (frosted glass) effect.
///
/// Creates a modern, translucent container with blur, opacity,
/// and a subtle border that mimics the look of frosted glass.
///
/// ```dart
/// GlassmorphismContainer(
///   borderRadius: 16,
///   blur: 10,
///   opacity: 0.15,
///   child: Padding(
///     padding: EdgeInsets.all(16),
///     child: Text('Glassmorphism!'),
///   ),
/// )
/// ```
class GlassmorphismContainer extends StatelessWidget {
  /// Creates a glassmorphism container.
  const GlassmorphismContainer({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.blur = 10,
    this.opacity = 0.15,
    this.color,
    this.borderColor,
    this.borderWidth = 1.0,
    this.padding,
    this.margin,
    this.width,
    this.height,
  });

  /// The child widget to display inside the glass container.
  final Widget child;

  /// Border radius of the glass container.
  final double borderRadius;

  /// Amount of blur for the glass effect.
  final double blur;

  /// Opacity of the glass background (0.0 = transparent, 1.0 = opaque).
  final double opacity;

  /// Background color of the glass. Defaults to white in light mode,
  /// dark grey in dark mode.
  final Color? color;

  /// Border color. Defaults to a semi-transparent white.
  final Color? borderColor;

  /// Width of the border.
  final double borderWidth;

  /// Padding inside the container.
  final EdgeInsetsGeometry? padding;

  /// Margin around the container.
  final EdgeInsetsGeometry? margin;

  /// Optional fixed width.
  final double? width;

  /// Optional fixed height.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = color ??
        (isDark
            ? Colors.grey.shade900.withValues(alpha: opacity)
            : Colors.white.withValues(alpha: opacity));
    final border = borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.3));

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: border, width: borderWidth),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
