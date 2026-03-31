import 'package:flutter/material.dart';

enum Breakpoint {
  compact,
  medium,
  expanded,
}

class ResponsiveLayout {
  ResponsiveLayout._();

  static Breakpoint breakpointOf(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 900) return Breakpoint.expanded;
    if (w >= 600) return Breakpoint.medium;
    return Breakpoint.compact;
  }

  static double maxContentWidth(
    BuildContext context, {
    double compactFactor = 0.92,
    double mediumMax = 640,
    double expandedMax = 720,
  }) {
    final size = MediaQuery.sizeOf(context);
    final bp = breakpointOf(context);
    switch (bp) {
      case Breakpoint.compact:
        return size.width * compactFactor;
      case Breakpoint.medium:
        return mediumMax;
      case Breakpoint.expanded:
        return expandedMax;
    }
  }
}

class ContentConstrained extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const ContentConstrained({
    super.key,
    required this.child,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final w = maxWidth ?? ResponsiveLayout.maxContentWidth(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: w),
        child: child,
      ),
    );
  }
}

