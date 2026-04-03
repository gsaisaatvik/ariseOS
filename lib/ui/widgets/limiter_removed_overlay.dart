import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Full-screen overlay displayed when the hunter achieves 200% completion
/// on all Physical Foundation sub-tasks (Limiter Removal event).
///
/// Shows "LIMITER REMOVED" with dramatic cyan glow effect and auto-dismisses
/// after 3 seconds.
///
/// Usage: Wrap with `Positioned.fill` inside a `Stack` for full-screen overlay:
/// ```dart
/// Stack(
///   children: [
///     // Your main content
///     if (showLimiterOverlay)
///       Positioned.fill(
///         child: LimiterRemovedOverlay(onDismiss: () => setState(() => showLimiterOverlay = false)),
///       ),
///   ],
/// )
/// ```
///
/// **Validates: Requirements 7.5, 8.2**
class LimiterRemovedOverlay extends StatefulWidget {
  const LimiterRemovedOverlay({
    super.key,
    required this.onDismiss,
  });

  final VoidCallback onDismiss;

  @override
  State<LimiterRemovedOverlay> createState() => _LimiterRemovedOverlayState();
}

class _LimiterRemovedOverlayState extends State<LimiterRemovedOverlay> {
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    // Auto-dismiss after 3 seconds
    _dismissTimer = Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
      child: Container(
        color: AppColors.monarchBackground,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 48,
              vertical: 32,
            ),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(
                color: AppColors.cyanGlow,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyanGlow.withOpacity(0.5),
                  blurRadius: 20.0,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: AppColors.cyanGlow.withOpacity(0.3),
                  blurRadius: 40.0,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Text(
              'LIMITER REMOVED',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.cyanGlow,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 2.0,
                shadows: [
                  Shadow(
                    blurRadius: 25,
                    color: AppColors.cyanGlow.withOpacity(0.8),
                    offset: const Offset(0, 0),
                  ),
                  Shadow(
                    blurRadius: 50,
                    color: AppColors.cyanGlow.withOpacity(0.4),
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
