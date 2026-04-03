import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Holographic card decoration helper for ARISE OS Monarch Integration.
///
/// Creates a glowing cyan-bordered card with a black fill, simulating
/// the holographic system interface aesthetic from Solo Leveling.
BoxDecoration glowCardDecoration({bool penalty = false}) => BoxDecoration(
  color: Colors.black,
  border: Border.all(
    color: penalty ? AppColors.danger : AppColors.cyanGlow,
    width: 1.2,
  ),
  boxShadow: [
    BoxShadow(
      color: (penalty ? AppColors.danger : AppColors.cyanGlow).withOpacity(0.2),
      blurRadius: 15.0,
      spreadRadius: 0,
    ),
  ],
);

/// National Level Hunter holographic panel with glassmorphism.
BoxDecoration holographicPanel({
  Color glowColor = AppColors.cyanGlow,
  double glowIntensity = 0.2,
}) => BoxDecoration(
  color: Colors.black.withOpacity(0.6),
  border: Border.all(color: glowColor.withOpacity(0.5), width: 1.2),
  boxShadow: [
    BoxShadow(
      color: glowColor.withOpacity(glowIntensity),
      blurRadius: 15.0,
      spreadRadius: 0,
    ),
  ],
);

/// Locked quest state decoration with frosted blue effect.
BoxDecoration lockedQuestDecoration() => BoxDecoration(
  color: const Color(0xFF001133).withOpacity(0.4),
  border: Border.all(color: AppColors.warning.withOpacity(0.6), width: 1.2),
  boxShadow: [
    BoxShadow(color: AppColors.warning.withOpacity(0.15), blurRadius: 12.0),
  ],
);

/// Input mode decoration with cyan glow.
BoxDecoration inputModeDecoration() => BoxDecoration(
  color: Colors.black,
  border: Border.all(color: AppColors.cyanGlow.withOpacity(0.4), width: 1.2),
  boxShadow: [
    BoxShadow(color: AppColors.cyanGlow.withOpacity(0.1), blurRadius: 8.0),
  ],
);

/// Glassmorphism backdrop filter widget.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final double blur;

  const GlassPanel({super.key, required this.child, this.blur = 5.0});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: child,
      ),
    );
  }
}

/// Scanline overlay for digital display effect.
class ScanlineOverlay extends StatelessWidget {
  const ScanlineOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.02),
              Colors.transparent,
              Colors.white.withOpacity(0.02),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}
