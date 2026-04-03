import 'dart:ui';

import 'package:flutter/material.dart';

import '../../services/xp_feedback.dart';
import '../../system/level_up_event.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../player_provider.dart';

/// Full-screen system interruption (Phase 4).
///
/// Designed to be responsive: no overflow on small screens.
class SystemInterruptionOverlay extends StatefulWidget {
  const SystemInterruptionOverlay({
    super.key,
    required this.event,
    required this.player,
    required this.onDefer,
    required this.onAllocationDone,
    required this.onAllocationOpened,
  });

  final LevelUpEvent event;
  final PlayerProvider player;
  final VoidCallback onDefer;
  final VoidCallback onAllocationDone;
  final VoidCallback onAllocationOpened;

  @override
  State<SystemInterruptionOverlay> createState() =>
      _SystemInterruptionOverlayState();
}

class _SystemInterruptionOverlayState extends State<SystemInterruptionOverlay>
    with TickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;
  late Animation<double> _scale;

  bool _actionsReady = false;
  bool _allocateOpen = false;

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
      await XpFeedback.playLevelUpChime();
      if (!mounted) return;
      setState(() => _actionsReady = true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _openAllocate() {
    widget.onAllocationOpened();
    setState(() => _allocateOpen = true);
  }

  void _closeAllocate() {
    setState(() => _allocateOpen = false);
  }

  void _onAllocationDone() {
    _closeAllocate();
    widget.onAllocationDone();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final player = widget.player;

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
                  // Block interaction behind the interruption.
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {},
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.82),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 18,
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: 620,
                                minHeight: constraints.maxHeight * 0.55,
                              ),
                              child: IntrinsicHeight(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildHeader(e),
                                    const SizedBox(height: 14),
                                    _buildCore(e),
                                    const SizedBox(height: 14),
                                    if (_actionsReady) _buildActions(player),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_allocateOpen)
                    _AllocatePointsModal(
                      player: player,
                      onClose: _closeAllocate,
                      onDone: _onAllocationDone,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(LevelUpEvent e) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'SYSTEM INTERRUPTION',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.4,
            ),
          ),
        ),
        Text(
          'LEVEL ${e.toLevel}',
          style: TextStyle(
            color: AppColors.primaryBlue.withValues(alpha: 0.9),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }

  Widget _buildCore(LevelUpEvent e) {
    final subtitle = e.newlyUnlockedAbilityName != null
        ? 'New ability unlocked: ${e.newlyUnlockedAbilityName}'
        : (e.nextSystemAbilityUnlockLevel != null
            ? 'Next ability unlock at Level ${e.nextSystemAbilityUnlockLevel}'
            : 'New potential unlocked');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.26),
            blurRadius: 28,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: const Color(0xFF7B61FF).withValues(alpha: 0.16),
            blurRadius: 22,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
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
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Hunter has evolved',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 16,
              fontWeight: FontWeight.w700,
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
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.15)),
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

  Widget _buildActions(PlayerProvider player) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        _ActionButton(
          label: 'ALLOCATE NOW',
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF18F3FF), Color(0xFF7B61FF)],
          ),
          onTap: _openAllocate,
        ),
        const SizedBox(height: 12),
        _ActionButton(
          label: 'DEFER',
          gradient: null,
          outline: true,
          onTap: widget.onDefer,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    this.gradient,
    this.outline = false,
  });

  final String label;
  final VoidCallback onTap;
  final LinearGradient? gradient;
  final bool outline;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: outline
                  ? Colors.white.withValues(alpha: 0.35)
                  : const Color(0xFF00E5FF).withValues(alpha: 0.75),
              width: 1.2,
            ),
            gradient: outline ? null : gradient,
            color: outline ? Colors.black.withValues(alpha: 0.35) : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.button.copyWith(
              color: outline ? Colors.white70 : AppColors.background,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _AllocatePointsModal extends StatelessWidget {
  const _AllocatePointsModal({
    required this.player,
    required this.onClose,
    required this.onDone,
  });

  final PlayerProvider player;
  final VoidCallback onClose;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.78),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF050716).withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'ATTRIBUTE ALLOCATION',
                                  style: TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.8,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: onClose,
                                child: Text(
                                  'CLOSE',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.55),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Points available: ${player.availablePoints}',
                            style: TextStyle(
                              color: Colors.amberAccent.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _allocRow(
                            context,
                            label: 'STRENGTH',
                            value: player.Strength,
                            onAdd: player.availablePoints > 0
                                ? player.increaseStrength
                                : null,
                          ),
                          _allocRow(
                            context,
                            label: 'AGILITY',
                            value: player.Agility,
                            onAdd: player.availablePoints > 0
                                ? player.increaseAgility
                                : null,
                          ),
                          _allocRow(
                            context,
                            label: 'VITALITY',
                            value: player.Vitality,
                            onAdd: player.availablePoints > 0
                                ? player.increaseVitality
                                : null,
                          ),
                          _allocRow(
                            context,
                            label: 'INTELLIGENCE',
                            value: player.Intelligence,
                            onAdd: player.availablePoints > 0
                                ? player.increaseIntelligence
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _ActionButton(
                            label: player.availablePoints > 0 ? 'DONE' : 'DONE',
                            onTap: onDone,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF18F3FF), Color(0xFF7B61FF)],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _allocRow(
    BuildContext context, {
    required String label,
    required int value,
    required VoidCallback? onAdd,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label: $value',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: onAdd == null
                    ? Colors.transparent
                    : AppColors.primaryBlue.withValues(alpha: 0.12),
                side: BorderSide(
                  color: onAdd == null
                      ? Colors.white10
                      : AppColors.primaryBlue.withValues(alpha: 0.7),
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                '+',
                style: TextStyle(
                  color: onAdd == null
                      ? Colors.white24
                      : AppColors.primaryBlue,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

