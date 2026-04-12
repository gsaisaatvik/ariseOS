import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'player_provider.dart';
import 'models/chronicle_entry.dart';
import 'ui/theme/app_colors.dart';
import 'ui/widgets/widgets.dart';

// ============================================================
//  SHADOW CHRONICLE SCREEN — replaces Skills Screen
//  A mission/activity log showing all player actions.
// ============================================================

class SkillsScreen extends StatelessWidget {
  const SkillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final chronicle = player.chronicle;
    final now = DateTime.now();

    // Today's XP delta
    int todayXP = chronicle
        .where((e) =>
            e.timestamp.year == now.year &&
            e.timestamp.month == now.month &&
            e.timestamp.day == now.day &&
            (e.xpDelta ?? 0) > 0)
        .fold(0, (sum, e) => sum + (e.xpDelta ?? 0));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER: Today's Summary ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: HolographicPanel(
              header: const SystemHeaderBar(label: 'SHADOW CHRONICLE'),
              emphasize: true,
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Today's record row
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.04),
                      border: Border.all(
                          color: AppColors.primaryBlue.withValues(alpha: 0.18)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SummaryCell(
                          label: 'XP TODAY',
                          value: '+$todayXP',
                          color: Colors.amberAccent,
                        ),
                        _vDivider(),
                        _SummaryCell(
                          label: 'COMPLETED',
                          value: '${player.totalQuestsCompleted}',
                          color: AppColors.success,
                        ),
                        _vDivider(),
                        _SummaryCell(
                          label: 'FAILED',
                          value: '${player.totalQuestsFailed}',
                          color: AppColors.danger,
                        ),
                        _vDivider(),
                        _SummaryCell(
                          label: 'STREAK',
                          value: '${player.streakDays}D',
                          color: AppColors.primaryBlue,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Completion rate bar
                  Row(
                    children: [
                      Text(
                        'COMPLETION RATE',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 8,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(player.questCompletionRate * 100).round()}%',
                        style: TextStyle(
                          color: player.questCompletionRate > 0.75
                              ? AppColors.success
                              : AppColors.warning,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Stack(
                      children: [
                        Container(
                          height: 4,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                        FractionallySizedBox(
                          widthFactor: player.questCompletionRate.clamp(0.0, 1.0),
                          child: Container(
                            height: 4,
                            color: player.questCompletionRate > 0.75
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── LOG ENTRIES ──────────────────────────────────────
          Expanded(
            child: chronicle.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_edu_outlined,
                            color: Colors.white12, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'NO RECORDS FOUND',
                          style: TextStyle(
                            color: AppColors.textDisabled,
                            fontSize: 11,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'System awaiting first directive.',
                          style: TextStyle(
                            color: Colors.white24,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                    itemCount: chronicle.length,
                    itemBuilder: (ctx, i) {
                      final entry = chronicle[i];
                      // Date separator
                      final showDate = i == 0 ||
                          _dateStr(chronicle[i].timestamp) !=
                              _dateStr(chronicle[i - 1].timestamp);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showDate) _DateSeparator(entry.timestamp),
                          _ChronicleRow(entry: entry),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _dateStr(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  Widget _vDivider() => Container(
        width: 1,
        height: 28,
        color: Colors.white.withValues(alpha: 0.08),
      );
}

// Type → icon/color mapping
IconData _iconForType(String type) {
  switch (type) {
    case ChronicleType.questComplete:   return Icons.check_circle_outline;
    case ChronicleType.questFail:       return Icons.cancel_outlined;
    case ChronicleType.customQuestLock: return Icons.lock_outline;
    case ChronicleType.levelUp:         return Icons.bolt_rounded;
    case ChronicleType.xpGain:          return Icons.arrow_upward_rounded;
    case ChronicleType.xpLoss:          return Icons.arrow_downward_rounded;
    case ChronicleType.penaltyTrigger:  return Icons.warning_amber_rounded;
    case ChronicleType.penaltyRecovery: return Icons.shield_outlined;
    case ChronicleType.rewardRedeemed:  return Icons.diamond_outlined;
    case ChronicleType.premiumUpgrade:  return Icons.star_outline;
    default:                            return Icons.circle_outlined;
  }
}

Color _colorForType(String type) {
  switch (type) {
    case ChronicleType.questComplete:   return AppColors.success;
    case ChronicleType.questFail:       return AppColors.danger;
    case ChronicleType.customQuestLock: return AppColors.primaryViolet;
    case ChronicleType.levelUp:         return AppColors.primaryBlue;
    case ChronicleType.xpGain:          return Colors.amberAccent;
    case ChronicleType.xpLoss:          return AppColors.danger;
    case ChronicleType.penaltyTrigger:  return AppColors.warning;
    case ChronicleType.penaltyRecovery: return AppColors.success;
    case ChronicleType.rewardRedeemed:  return const Color(0xFF00E5FF);
    case ChronicleType.premiumUpgrade:  return Colors.amber;
    default:                            return Colors.white38;
  }
}

class _ChronicleRow extends StatelessWidget {
  final ChronicleEntry entry;
  const _ChronicleRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(entry.type);
    final icon = _iconForType(entry.type);
    final xpLabel = entry.xpDelta == null
        ? null
        : entry.xpDelta! > 0
            ? '+${entry.xpDelta} XP'
            : '${entry.xpDelta} XP';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.03),
        border: Border(
          left: BorderSide(color: color.withValues(alpha: 0.5), width: 2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time
          SizedBox(
            width: 38,
            child: Text(
              entry.timeLabel,
              style: TextStyle(
                color: Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Icon
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                if (entry.detail.isNotEmpty)
                  Text(
                    entry.detail,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
              ],
            ),
          ),
          // XP delta
          if (xpLabel != null)
            Text(
              xpLabel,
              style: TextStyle(
                color: entry.xpDelta! > 0 ? Colors.amberAccent : AppColors.danger,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator(this.date);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String label;
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      label = 'TODAY';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      label = 'YESTERDAY';
    } else {
      label =
          '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: Colors.white10)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white30,
                fontSize: 8,
                letterSpacing: 2.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: Container(height: 1, color: Colors.white10)),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryCell(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: color.withValues(alpha: 0.4), blurRadius: 8)],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.55),
            fontSize: 7,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
