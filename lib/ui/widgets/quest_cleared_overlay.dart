import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Full-screen overlay displayed when a quest is completed.
///
/// Shows "QUEST CLEARED.\nREWARDS DISTRIBUTED." with holographic styling
/// and auto-dismisses after 2.5 seconds.
///
/// Usage: Wrap with `Positioned.fill` inside a `Stack` for full-screen overlay:
/// ```dart
/// Stack(
///   children: [
///     // Your main content
///     if (showOverlay)
///       Positioned.fill(
///         child: QuestClearedOverlay(onDismiss: () => setState(() => showOverlay = false)),
///       ),
///   ],
/// )
/// ```
///
/// **Validates: Requirements 8.3, 8.4**
class QuestClearedOverlay extends StatefulWidget {
  const QuestClearedOverlay({
    super.key,
    required this.onDismiss,
  });

  final VoidCallback onDismiss;

  @override
  State<QuestClearedOverlay> createState() => _QuestClearedOverlayState();
}

class _QuestClearedOverlayState extends State<QuestClearedOverlay> {
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    // Auto-dismiss after 2.5 seconds
    _dismissTimer = Timer(const Duration(milliseconds: 2500), () {
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
              horizontal: 32,
              vertical: 24,
            ),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(
                color: AppColors.cyanGlow,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyanGlow.withOpacity(0.35),
                  blurRadius: 15.0,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              'QUEST CLEARED.\nREWARDS DISTRIBUTED.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.cyanGlow,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 1.5,
                height: 1.4,
                shadows: [
                  Shadow(
                    blurRadius: 20,
                    color: AppColors.cyanGlow.withOpacity(0.6),
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
