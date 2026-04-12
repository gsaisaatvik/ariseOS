import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';

import 'player_provider.dart';
import 'system/mana_crystal_engine.dart';
import 'ui/theme/app_text_styles.dart';
import 'ui/theme/app_colors.dart';
import 'ui/widgets/widgets.dart';

// ============================================================
//  STATUS SCREEN — Full V2
//  Section 1: Identity Block (name, rank badge, job, title)
//  Section 2: Level + XP Progress Bar
//  Section 3: HP + VIT-linked HP bar
//  Section 4: Core Stats Grid (STR VIT AGI INT PER)
//  Section 5: Currency Row (WalletXP + Mana Crystals)
//  Section 6: Streak + Discipline Stats
// ============================================================

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // STATUS WINDOW is the ONLY panel on this screen.
            // Quest Info lives on the Quests tab.
            HolographicPanel(
              header: const SystemHeaderBar(label: 'STATUS WINDOW'),
              emphasize: true,
              child: _buildStatusWindow(player),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _titleLabel(PlayerProvider p) {
    final lv = p.level;
    String base;
    if (lv < 5) {
      base = '—';
    } else if (lv < 10) {
      base = 'NOVICE';
    } else if (lv < 16) {
      base = 'AWAKENED';
    } else if (lv < 25) {
      base = 'HUNTER';
    } else if (lv < 40) {
      base = 'SOVEREIGN';
    } else if (lv < 50) {
      base = 'SHADOW BLADE';
    } else {
      base = 'MONARCH';
    }
    if (p.overloadTitleAwarded && base != '—') base += ' OF EXCESS';
    return base;
  }

  Color _rankColor(String rank) {
    switch (rank) {
      case 'GOD': return const Color(0xFFE040FB);
      case 'S':   return const Color(0xFF00E5FF);
      case 'A':   return const Color(0xFFFFCA28);
      case 'B':   return const Color(0xFF66BB6A);
      case 'C':   return const Color(0xFF26C6DA);
      case 'D':   return const Color(0xFF78909C);
      default:    return Colors.white38;
    }
  }

  // ────────────────────────────────────────────────────────────
  //  STATUS WINDOW
  // ────────────────────────────────────────────────────────────
  Widget _buildStatusWindow(PlayerProvider player) {
    final rank = player.rank;
    final job = PlayerProvider.jobLabelForRank(rank);
    final title = _titleLabel(player);
    final rankCol = _rankColor(rank);
    final isDebt = player.walletXP < 0;

    // XP math (level XP bar)
    final currentThreshold = math.pow((player.level - 1) * 10, 2).toInt();
    final nextThreshold = math.pow(player.level * 10, 2).toInt();
    final xpRange = (nextThreshold - currentThreshold).clamp(1, 999999999);
    final xpInLevel = (player.totalXP - currentThreshold).clamp(0, xpRange);
    final xpProgress = (xpInLevel / xpRange).clamp(0.0, 1.0);

    final hpProgress = player.maxHp > 0
        ? (player.hp / player.maxHp).clamp(0.0, 1.0)
        : 1.0;

    final crystalProgress = player.maxManaCrystals > 0
        ? (player.manaCrystals / player.maxManaCrystals).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      children: [
        // ── SECTION 1: IDENTITY BLOCK ──────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: rankCol.withValues(alpha: 0.04),
            border: Border.all(color: rankCol.withValues(alpha: 0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rank badge
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  border: Border.all(color: rankCol, width: 1.5),
                  color: rankCol.withValues(alpha: 0.10),
                  boxShadow: [
                    BoxShadow(
                      color: rankCol.withValues(alpha: 0.35),
                      blurRadius: 12,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  rank,
                  style: TextStyle(
                    color: rankCol,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      job,
                      style: TextStyle(
                        color: rankCol.withValues(alpha: 0.85),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (player.streakDays >= 7)
                          _Tag('[STREAKING]', AppColors.success),
                        if (isDebt)
                          _Tag('[DEBT]', AppColors.danger),
                        if (title != '—')
                          _Tag(title, rankCol.withValues(alpha: 0.7)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ── PHYSICAL QUEST MINI-STRIP (compact — full info on Quests tab) ─
        _PhysicalQuestStrip(player: player),

        const SizedBox(height: 12),

        // ── SECTION 2: LEVEL + XP BAR ─────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'LEVEL',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _BarRow(
          label: 'EXP',
          progress: xpProgress,
          color: AppColors.primaryBlue,
          trailingText: '$xpInLevel / $xpRange',
        ),
        const SizedBox(height: 4),
        Text(
          'LifetimeXP: ${player.totalXP}',
          style: AppTextStyles.systemLabel.copyWith(
            color: Colors.white30,
            fontSize: 8,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 14),

        // ── SECTION 3: HP BAR ──────────────────────────────────
        _BarRow(
          label: 'HP',
          progress: hpProgress,
          color: _hpBarColor(hpProgress),
          trailingText: '${player.hp} / ${player.maxHp}',
        ),
        const SizedBox(height: 4),
        Text(
          'VIT BONUS: +${(player.vitality - 10).clamp(0, 999) * 5} MAX HP',
          style: AppTextStyles.systemLabel.copyWith(
            color: Colors.white30,
            fontSize: 8,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 14),

        // ── SECTION 4: STATS GRID ──────────────────────────────
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _StatCell('STR', player.strength, AppColors.danger)),
                  const SizedBox(width: 8),
                  Expanded(child: _StatCell('VIT', player.vitality, AppColors.success)),
                  const SizedBox(width: 8),
                  Expanded(child: _StatCell('AGI', player.agility, AppColors.warning)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _StatCell('INT', player.intelligence, AppColors.primaryBlue)),
                  const SizedBox(width: 8),
                  Expanded(child: _StatCell('PER', player.perception, const Color(0xFFE040FB))),
                  const SizedBox(width: 8),
                  // Stat points available
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amberAccent.withValues(alpha: 0.05),
                        border: Border.all(
                          color: Colors.amberAccent.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${player.availablePoints}',
                            style: const TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'FREE',
                            style: AppTextStyles.systemLabel.copyWith(
                              color: Colors.amberAccent.withValues(alpha: 0.6),
                              fontSize: 7,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (!player.canAllocateStats) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.40)),
                  ),
                  child: Text(
                    'DEBT PROTOCOL: STAT ALLOCATION SUSPENDED',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.systemLabel.copyWith(
                      color: AppColors.danger,
                      fontSize: 8,
                      letterSpacing: 1.3,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── SECTION 5: CURRENCY ROW ────────────────────────────
        Row(
          children: [
            Expanded(
              child: _CurrencyCell(
                icon: Icons.account_balance_wallet_rounded,
                label: 'WALLET XP',
                value: '${player.walletXP}',
                color: player.walletXP >= 0 ? Colors.amber : AppColors.danger,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CurrencyCell(
                    icon: Icons.diamond_outlined,
                    label: 'MANA CRYSTALS',
                    value: ManaCrystalEngine.crystalLabel(
                        player.manaCrystals, player.maxManaCrystals),
                    color: const Color(0xFF00E5FF),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Stack(
                      children: [
                        Container(
                          height: 3,
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.10),
                        ),
                        FractionallySizedBox(
                          widthFactor: crystalProgress,
                          child: Container(
                            height: 3,
                            color: const Color(0xFF00E5FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── SECTION 6: STREAK STATS ────────────────────────────
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _StreakCell('STREAK', '${player.streakDays}D', AppColors.success),
              ),
              _vDivider(),
              Expanded(
                child: _StreakCell('BEST', '${player.bestStreak}D', AppColors.primaryBlue),
              ),
              _vDivider(),
              Expanded(
                child: _StreakCell('MISSES', '${player.consecutiveMisses}', AppColors.danger),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── SECTION 7: PERFORMANCE RECORD (NEW) ─────────────────
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PERFORMANCE RECORD',
                style: AppTextStyles.systemLabel.copyWith(
                  color: Colors.white38,
                  fontSize: 8,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _StreakCell(
                      'COMPLETED',
                      '${player.totalQuestsCompleted}',
                      AppColors.success,
                    ),
                  ),
                  _vDivider(),
                  Expanded(
                    child: _StreakCell(
                      'FAILED',
                      '${player.totalQuestsFailed}',
                      AppColors.danger,
                    ),
                  ),
                  _vDivider(),
                  Expanded(
                    child: _StreakCell(
                      'RATE',
                      '${(player.questCompletionRate * 100).round()}%',
                      player.questCompletionRate > 0.75
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _hpBarColor(double progress) {
    if (progress > 0.60) return AppColors.success;
    if (progress > 0.35) return AppColors.warning;
    return AppColors.danger;
  }

  Widget _vDivider() => Container(
        width: 1,
        height: 40,
        color: Colors.white.withValues(alpha: 0.08),
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );

}

// ────────────────────────────────────────────────────────────────
//  PHYSICAL QUEST MINI-STRIP
//  Compact single-row widget shown on Status Screen.
//  Tap redirects mentally to Quests tab — no full content here.
// ────────────────────────────────────────────────────────────────
class _PhysicalQuestStrip extends StatelessWidget {
  final PlayerProvider player;
  const _PhysicalQuestStrip({required this.player});

  @override
  Widget build(BuildContext context) {
    final pct = player.physicalCompletionPct;
    final allDone = player.isDailyPhysicalCompleted;
    final color = allDone ? AppColors.success : AppColors.primaryBlue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            allDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allDone
                      ? 'DAILY PHYSICAL QUEST — CLEARED'
                      : 'DAILY PHYSICAL QUEST — IN PROGRESS',
                  style: TextStyle(
                    color: color,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(1),
                  child: Stack(
                    children: [
                      Container(height: 3, color: color.withValues(alpha: 0.10)),
                      FractionallySizedBox(
                        widthFactor: pct.clamp(0.0, 1.0),
                        child: Container(height: 3, color: color),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(pct * 100).round()}%',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}


// ────────────────────────────────────────────────────────────────
//  REUSABLE MICRO-WIDGETS
// ────────────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.60)),
          color: color.withValues(alpha: 0.07),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 7,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final double progress;
  final Color color;
  final String trailingText;
  const _BarRow({
    required this.label,
    required this.progress,
    required this.color,
    required this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Stack(
              children: [
                Container(height: 14, color: color.withValues(alpha: 0.08)),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.75),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.40),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          trailingText,
          style: TextStyle(
            color: color.withValues(alpha: 0.80),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final String stat;
  final int value;
  final Color color;
  const _StatCell(this.stat, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(color: color.withValues(alpha: 0.4), blurRadius: 10)],
            ),
          ),
          Text(
            stat,
            style: TextStyle(
              color: color.withValues(alpha: 0.65),
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _CurrencyCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.60),
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: color.withValues(alpha: 0.4), blurRadius: 8)],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StreakCell(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: color.withValues(alpha: 0.4), blurRadius: 8)],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.55),
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}