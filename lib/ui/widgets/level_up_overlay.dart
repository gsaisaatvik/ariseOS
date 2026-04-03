import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/xp_feedback.dart';
import '../../widgets/xp_floating_text.dart';
import '../../system/level_up_event.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../ui/theme/app_colors.dart';

class LevelUpOverlay extends StatefulWidget {
  const LevelUpOverlay({
    super.key,
    required this.event,
    required this.onAllocatePoints,
  });

  final LevelUpEvent event;
  final VoidCallback onAllocatePoints;

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay>
    with TickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;
  late Animation<double> _scale;

  bool _buttonReady = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic),
    );

    _c.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Stronger chime for the addiction anchor.
      await XpFeedback.playLevelUpChime();
      _spawnXpParticles();
      setState(() => _buttonReady = true);
    });
  }

  void _spawnXpParticles() {
    final size = MediaQuery.of(context).size;
    final center = Offset(size.width / 2, size.height / 2);
    final rng = math.Random();

    for (int i = 0; i < 6; i++) {
      final dx = (rng.nextDouble() * 220) - 110;
      final dy = (rng.nextDouble() * 160) - 80;
      final amount = 6 + rng.nextInt(8);
      XPFloatingText.show(
        context,
        amount: amount,
        position: center + Offset(dx, dy),
      );
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Opacity(
            opacity: _fade.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {},
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.2),
                        radius: 0.9,
                        colors: [
                          const Color(0xFF18F3FF).withValues(alpha: 0.22),
                          const Color(0xFF7B61FF).withValues(alpha: 0.14),
                          Colors.black.withValues(alpha: 0.86),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 520,
                      ),
                      child: _buildCard(context, e),
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: 24,
                          left: 18,
                          right: 18,
                        ),
                        child: _buttonReady
                            ? SizedBox(
                                width: double.infinity,
                                child: _buildAllocateButton(),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context, LevelUpEvent e) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.55),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.28),
            blurRadius: 28,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: const Color(0xFF7B61FF).withValues(alpha: 0.18),
            blurRadius: 22,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LEVEL UP',
            style: AppTextStyles.headerMedium.copyWith(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.8,
              color: AppColors.primaryBlue,
              shadows: [
                Shadow(
                  blurRadius: 20,
                  color: AppColors.primaryBlue.withValues(alpha: 0.6),
                  offset: const Offset(0, 0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Hunter has evolved',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'LEVEL ${e.fromLevel} → LEVEL ${e.toLevel}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '+${e.attributePointsGained} ATTRIBUTE POINTS',
            style: TextStyle(
              color: Colors.amberAccent.withValues(alpha: 0.95),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  blurRadius: 16,
                  color: Colors.amberAccent.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            e.newlyUnlockedAbilityName != null
                ? 'New ability unlocked: ${e.newlyUnlockedAbilityName}'
                : (e.nextSystemAbilityUnlockLevel != null
                    ? 'Next ability unlock at Level ${e.nextSystemAbilityUnlockLevel}'
                    : 'New potential unlocked'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Divider(
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 10),
          Text(
            e.systemVoiceLine,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllocateButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onAllocatePoints,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.75),
              width: 1.2,
            ),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF18F3FF),
                Color(0xFF7B61FF),
              ],
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            'ALLOCATE POINTS',
            style: AppTextStyles.button.copyWith(
              color: AppColors.background,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

