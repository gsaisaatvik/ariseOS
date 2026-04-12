import 'package:flutter/material.dart';
import 'dart:ui';

import '../../ui/theme/app_colors.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

// ============================================================
//  QUEST REWARD POPUP — Solo Leveling anime reference style
//  Matches image 1: QUEST INFO → rewards list → YES/NO
//  Followed by image 2: NOTIFICATION → delivery confirm
// ============================================================

class QuestRewardPayload {
  final int hpRecovery;
  final int statPoints;
  final int bonusXP;
  final String questName;

  const QuestRewardPayload({
    required this.hpRecovery,
    required this.statPoints,
    required this.bonusXP,
    required this.questName,
  });
}

/// Shows the two-step Solo Leveling reward sequence:
/// Step 1: QUEST INFO popup with YES/NO
/// Step 2: NOTIFICATION "rewards have been delivered" (auto-dismisses)
///
/// Returns true if user accepted the rewards, false if they declined.
Future<bool> showQuestRewardPopup({
  required BuildContext context,
  required QuestRewardPayload payload,
  required VoidCallback onAccept,
}) async {
  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.88),
    builder: (ctx) => _QuestInfoDialog(payload: payload),
  );

  if (accepted == true) {
    onAccept();
    if (context.mounted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.80),
        builder: (ctx) => _RewardDeliveredNotification(payload: payload),
      );
    }
    return true;
  }
  return false;
}

// ── Step 1: QUEST INFO dialog ───────────────────────────────────
class _QuestInfoDialog extends StatefulWidget {
  final QuestRewardPayload payload;
  const _QuestInfoDialog({required this.payload});

  @override
  State<_QuestInfoDialog> createState() => _QuestInfoDialogState();
}

class _QuestInfoDialogState extends State<_QuestInfoDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic),
    );
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payload;
    const accent = Color(0xFF00E5FF);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Main card
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
                    decoration: BoxDecoration(
                      color: const Color(0xFF000000).withValues(alpha: 0.95),
                      border: Border.all(color: accent, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.28),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // "You got rewards." line
                        Text(
                          '[You got rewards.]',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Reward list box — inner bordered container
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _RewardLine(
                                index: 1,
                                label: 'Full Recovery',
                                value: '+${p.hpRecovery} HP',
                                color: AppColors.success,
                              ),
                              const SizedBox(height: 8),
                              _RewardLine(
                                index: 2,
                                label: 'Ability Points',
                                value: '+${p.statPoints}',
                                color: Colors.amberAccent,
                              ),
                              if (p.bonusXP > 0) ...[
                                const SizedBox(height: 8),
                                _RewardLine(
                                  index: 3,
                                  label: 'Random Loot Box',
                                  value: '+${p.bonusXP} XP',
                                  color: accent,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Prompt
                        Text(
                          'Accept this rewards?',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // YES / NO buttons
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryActionButton(
                                label: 'YES',
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SecondaryActionButton(
                                label: 'NO',
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Floating badge "QUEST INFO"
          Positioned(
            top: -13,
            child: FadeTransition(
              opacity: _fade,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: accent, width: 1.5),
                ),
                child: Text(
                  'QUEST INFO',
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardLine extends StatelessWidget {
  final int index;
  final String label;
  final String value;
  final Color color;
  const _RewardLine({
    required this.index,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$index. ',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: color.withValues(alpha: 0.5), blurRadius: 8)],
          ),
        ),
      ],
    );
  }
}

// ── Step 2: NOTIFICATION delivery card (auto-dismisses in 2s) ───
class _RewardDeliveredNotification extends StatefulWidget {
  final QuestRewardPayload payload;
  const _RewardDeliveredNotification({required this.payload});

  @override
  State<_RewardDeliveredNotification> createState() =>
      _RewardDeliveredNotificationState();
}

class _RewardDeliveredNotificationState
    extends State<_RewardDeliveredNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _c.forward();

    // Auto-dismiss after 2.2s
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5FF);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Main card
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: FadeTransition(
                opacity: _fade,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 32, 22, 28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF000000).withValues(alpha: 0.95),
                    border: Border.all(color: accent, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.25),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Text(
                    'The rewards have been delivered.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // "NOTIFICATION" floating badge with [!] icon
          Positioned(
            top: -13,
            child: FadeTransition(
              opacity: _fade,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: accent, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        border: Border.all(color: accent, width: 1.2),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '!',
                        style: TextStyle(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'NOTIFICATION',
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
