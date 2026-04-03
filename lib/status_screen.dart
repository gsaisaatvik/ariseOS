import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'player_provider.dart';
import 'ui/theme/app_text_styles.dart';
import 'ui/theme/app_colors.dart';
import 'ui/widgets/widgets.dart';

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final isDebt = player.walletXP < 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔥 QUEST INFO PANEL
            HolographicPanel(
              header: const SystemHeaderBar(label: 'QUEST INFO'),
              emphasize: true,
              child: _buildQuestUI(context, player),
            ),

            /// ⚔️ SOLO LEVELING STATUS WINDOW
            HolographicPanel(
              header: const SystemHeaderBar(label: 'STATUS'),
              emphasize: true,
              child: _buildStatusWindow(player),
            ),

            HolographicPanel(
              header: const SystemHeaderBar(label: 'WALLET XP ECONOMY'),
              child: _buildEconomyTerminal(player, isDebt),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  SOLO LEVELING STATUS WINDOW
  // ============================================================
  Widget _buildStatusWindow(PlayerProvider player) {
    final job = _jobLabel(player.rank);
    final title = _titleLabel(player.level);

    // XP progress to next level
    // Formula: level = floor(sqrt(totalXP) / 10) + 1
    // currentThreshold = ((level-1)*10)^2
    // nextThreshold    = (level*10)^2
    final currentThreshold = math.pow((player.level - 1) * 10, 2).toInt();
    final nextThreshold = math.pow(player.level * 10, 2).toInt();
    final xpRange = (nextThreshold - currentThreshold).clamp(1, 999999999);
    final xpInLevel = (player.totalXP - currentThreshold).clamp(0, xpRange);
    final xpProgress = (xpInLevel / xpRange).clamp(0.0, 1.0);

    final hpProgress = player.maxHp > 0
        ? (player.hp / player.maxHp).clamp(0.0, 1.0)
        : 1.0;

    return Column(
      children: [
        // ── Level + JOB/TITLE row ──────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Big level number
              Text(
                '${player.level}',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'LEVEL',
                  style: AppTextStyles.systemLabel.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // JOB / TITLE column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _JobTitleLine(label: 'JOB', value: job),
                    const SizedBox(height: 4),
                    _JobTitleLine(label: 'TITLE', value: title),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── HP / XP bars ───────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            children: [
              _StatBar(
                label: 'HP',
                progress: hpProgress,
                color: AppColors.success,
                valueText: '${player.hp} / ${player.maxHp}',
              ),
              const SizedBox(height: 10),
              _StatBar(
                label: 'XP',
                progress: xpProgress,
                color: AppColors.primaryBlue,
                valueText: '$xpInLevel / $xpRange',
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── STR / VIT / AGI / INT / PER ───────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _StatEntry(label: 'STR', value: player.Strength),
                  const SizedBox(width: 40),
                  _StatEntry(label: 'VIT', value: player.Vitality),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatEntry(label: 'AGI', value: player.Agility),
                  const SizedBox(width: 40),
                  _StatEntry(label: 'INT', value: player.Intelligence),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatEntry(label: 'PER', value: player.Perception),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _jobLabel(String rank) {
    switch (rank) {
      case 'E': return 'NONE';
      case 'D': return 'APPRENTICE';
      case 'C': return 'HUNTER';
      case 'B': return 'ELITE HUNTER';
      case 'A': return 'MASTER';
      case 'S': return 'SHADOW MONARCH';
      case 'GOD': return 'THE ABSOLUTE';
      default:   return 'NONE';
    }
  }

  String _titleLabel(int level) {
    if (level >= 50) return 'MONARCH';
    if (level >= 26) return 'SOVEREIGN';
    if (level >= 11) return 'AWAKENED';
    return 'NONE';
  }

  // ============================================================
  //  QUEST UI
  // ============================================================
  Widget _buildQuestUI(BuildContext context, PlayerProvider player) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),

        Text(
          "Daily Quest: Strength Training has received.",
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyPrimary.copyWith(fontSize: 14),
        ),

        const SizedBox(height: 20),

        Text(
          "GOAL",
          style: AppTextStyles.headerMedium.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),

        const SizedBox(height: 20),

        _questRow(context, "Push-ups", player.pushUps, 100),
        _questRow(context, "Sit-ups", player.sitUps, 100),
        _questRow(context, "Squats", player.squatsCount, 100),
        _questRow(context, "Running", player.running, 10),

        const SizedBox(height: 24),

        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTextStyles.bodyPrimary,
            children: [
              const TextSpan(
                text: "WARNING: Failure to fulfill quest will result in an appropriate ",
              ),
              TextSpan(
                text: "penalty",
                style: TextStyle(color: AppColors.danger),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white70, width: 2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.check, color: Colors.greenAccent, size: 24),
        ),
      ],
    );
  }

  Widget _questRow(BuildContext context, String label, int current, int max) {
    return GestureDetector(
      onTap: () => _logReps(context, label),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.bodyPrimary.copyWith(fontSize: 16)),
            Text(
              "[$current/$max]",
              style: AppTextStyles.bodyPrimary.copyWith(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _logReps(BuildContext context, String type) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        int value = 10;
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Log $type", style: AppTextStyles.headerMedium),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () =>
                            setState(() => value = (value - 5).clamp(0, 100)),
                        icon: const Icon(Icons.remove),
                      ),
                      Text("$value", style: const TextStyle(fontSize: 24)),
                      IconButton(
                        onPressed: () => setState(() => value += 5),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      Provider.of<PlayerProvider>(context, listen: false)
                          .addReps(type, value);
                      Navigator.pop(context);
                    },
                    child: const Text("CONFIRM"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEconomyTerminal(PlayerProvider player, bool isDebt) {
    final walletColor = isDebt ? AppColors.danger : Colors.amber;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${player.walletXP} XP",
          style: AppTextStyles.headerLarge.copyWith(
            color: walletColor,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isDebt ? "DEBT PROTOCOL ACTIVE" : "SYSTEM BALANCE STABLE",
          style: AppTextStyles.systemLabel.copyWith(
            color: walletColor.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ============================================================
//  SUB-WIDGETS
// ============================================================

class _JobTitleLine extends StatelessWidget {
  final String label;
  final String value;
  const _JobTitleLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: AppTextStyles.bodySecondary.copyWith(fontSize: 13, letterSpacing: 0.5),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(color: Color(0xFF9FA7CC)),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  final String label;
  final double progress;
  final Color color;
  final String valueText;
  const _StatBar({
    required this.label,
    required this.progress,
    required this.color,
    required this.valueText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            label,
            style: AppTextStyles.systemLabel.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Stack(
              children: [
                Container(height: 10, color: color.withOpacity(0.12)),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.85),
                      boxShadow: [
                        BoxShadow(color: color.withOpacity(0.45), blurRadius: 6),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          valueText,
          style: AppTextStyles.systemLabel.copyWith(
            color: color.withOpacity(0.75),
            fontSize: 8,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _StatEntry extends StatelessWidget {
  final String label;
  final int value;
  const _StatEntry({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$label: ',
          style: AppTextStyles.systemLabel.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value.toString(),
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}