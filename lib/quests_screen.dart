import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import 'player_provider.dart';
import 'models/custom_quest.dart';
import 'models/monarch_rewards.dart';
import 'system/daily_quest_engine.dart';

import 'system/premium_service.dart';
import 'ui/theme/app_colors.dart';
import 'ui/widgets/widgets.dart';

// ============================================================
//  QUESTS SCREEN — V3: Commitment-Driven Quest System
//  Order: Quest Info → Warning/Timer → Add Quest → Side/Custom
// ============================================================

class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {
  Timer? _dailyTimer;

  @override
  void initState() {
    super.initState();
    _dailyTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _dailyTimer?.cancel();
    super.dispose();
  }

  String _formatDailyTimer() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final diff = tomorrow.difference(now);
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _triggerPhysicalRewardPopup(PlayerProvider player) async {
    if (!mounted) return;
    player.completeDailyPhysicalReward();
    final rng = math.Random();
    final bonusXP = 50 + rng.nextInt(151);
    await showQuestRewardPopup(
      context: context,
      payload: QuestRewardPayload(
        questName: 'Daily Physical Quest',
        hpRecovery: 10,
        statPoints: MonarchRewards.strPerPhysicalCompletion,
        bonusXP: bonusXP,
      ),
      onAccept: () {
        player.addXP(bonusXP);
        player.setDailyQuestCleared();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 5, 0, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── SECTION 1: QUEST INFO ────────────────────────
            _buildQuestInfo(player),

            // ── SECTION 2: WARNING + TIMER ───────────────────
            _buildWarningTimerCard(player),

            // ── SECTION 3: ADD QUEST BUTTON ──────────────────
            _buildAddQuestButton(player),

            // ── SECTION 4: SIDE + CUSTOM QUESTS ─────────────
            _buildSideQuestsSection(player),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  SECTION 1: QUEST INFO
  // ──────────────────────────────────────────────────────────

  Widget _buildQuestInfo(PlayerProvider player) {
    if (player.isRestDay && player.dailyQuests.isEmpty) {
      return HolographicPanel(
        header: const SystemHeaderBar(label: 'QUEST INFO'),
        emphasize: true,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.nights_stay_outlined,
                color: AppColors.primaryBlue, size: 32),
            const SizedBox(height: 12),
            Text(
              'REST DAY',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'System standing by.\nNo directives scheduled.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.6),
            ),
          ],
        ),
      );
    }

    final quests = player.dailyQuests;
    final allDone = player.allDailyQuestsDone;
    final rewardClaimed = player.physicalStatAwarded;

    return HolographicPanel(
      header: const SystemHeaderBar(label: 'QUEST INFO'),
      emphasize: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quest flavor text
          Text(
            '[Daily Quest: Strength Training has been received.]',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'GOAL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 5,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Quest rows
          ...quests.map((q) => _buildQuestRow(player, q)),

          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white10),
          const SizedBox(height: 14),

          // Claim / completion area
          Center(
            child: GestureDetector(
              onTap: (allDone && !rewardClaimed)
                  ? () => _triggerPhysicalRewardPopup(player)
                  : null,
              child: Icon(
                allDone ? Icons.check_box : Icons.check_box_outline_blank,
                color: allDone
                    ? (rewardClaimed
                        ? AppColors.success.withValues(alpha: 0.4)
                        : AppColors.success)
                    : Colors.white30,
                size: 32,
              ),
            ),
          ),

          if (allDone && rewardClaimed) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'REWARD CLAIMED  ✓',
                style: TextStyle(
                  color: AppColors.success.withValues(alpha: 0.65),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestRow(PlayerProvider player, quest) {
    final bool done = quest.completed;
    final bool failed = quest.failed;
    final Color statusColor = failed
        ? AppColors.danger
        : done
            ? AppColors.success
            : AppColors.primaryBlue;

    final String progressLabel = quest.unit == '0.1km'
        ? DailyQuestEngine.runLabel(quest.progress, quest.target)
        : '${quest.progress}/${quest.target} ${quest.unit}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                  boxShadow: done || failed
                      ? [BoxShadow(color: statusColor.withValues(alpha: 0.6), blurRadius: 6)]
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  quest.title,
                  style: TextStyle(
                    color: failed ? AppColors.danger : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (failed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    'FAILED ✗',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                )
              else ...[
                Text(
                  progressLabel,
                  style: TextStyle(
                    color: done ? AppColors.success : Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!done) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => player.logQuestProgress(
                        quest.id, DailyQuestEngine.incrementFor(quest.id)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.12),
                        border: Border.all(
                            color: AppColors.primaryBlue.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        '+${DailyQuestEngine.incrementFor(quest.id)}',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Stack(
              children: [
                Container(
                  height: 4,
                  color: statusColor.withValues(alpha: 0.08),
                ),
                FractionallySizedBox(
                  widthFactor: quest.progressFraction,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.75),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  SECTION 2: WARNING + TIMER CARD
  // ──────────────────────────────────────────────────────────

  Widget _buildWarningTimerCard(PlayerProvider player) {
    final allDone = player.allDailyQuestsDone;
    if (allDone && player.dailyQuests.isNotEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: HolographicPanel(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // Warning banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.06),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
              ),
              child: RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.6),
                  children: [
                    TextSpan(text: '⚠  WARNING: '),
                    TextSpan(
                      text: 'Failure to complete directives\nwill result in XP loss and penalty.',
                      style: TextStyle(color: Color(0xFFFF4B81), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'RESETS IN  ',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _formatDailyTimer(),
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    shadows: [
                      Shadow(color: AppColors.primaryBlue.withValues(alpha: 0.5), blurRadius: 10),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  SECTION 3: ADD QUEST BUTTON
  // ──────────────────────────────────────────────────────────

  Widget _buildAddQuestButton(PlayerProvider player) {
    // Hide button when limit reached
    if (player.isPremium && !player.canAddCustomQuest) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Text(
            'QUEST LIMIT REACHED',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 9,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: GestureDetector(
          onTap: () {
            if (player.isFreeTier) {
              _showUpgradeDialog();
            } else {
              _showAddQuestSheet(player);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(
                color: player.isFreeTier
                    ? Colors.white24
                    : AppColors.primaryViolet.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add,
                  size: 14,
                  color: player.isFreeTier ? Colors.white38 : AppColors.primaryViolet,
                ),
                const SizedBox(width: 6),
                Text(
                  'ADD QUEST',
                  style: TextStyle(
                    color: player.isFreeTier ? Colors.white38 : AppColors.primaryViolet,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                if (player.isFreeTier) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      'PREMIUM',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUpgradeDialog() {
    final player = Provider.of<PlayerProvider>(context, listen: false);
    showAriseNotificationDialog(
      context: context,
      title: '⚡  AWAKEN FULL POTENTIAL',
      message:
          'PREMIUM UNLOCKS:\n\n'
          '· 2 custom locked quests/day\n'
          '· Commitment locking system\n'
          '· Double crystal earn rate\n\n'
          'Upgrade now to forge your own directives.',
      type: SystemNotificationType.warning,
      primaryLabel: '[UPGRADE NOW]',
      secondaryLabel: 'CANCEL',
      onPrimary: () async {
        await PremiumService.initiatePurchase(
          context: context,
          player: player,
        );
        if (mounted) setState(() {});
      },
      onSecondary: () {},
    );
  }

  void _showAddQuestSheet(PlayerProvider player) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AddQuestSheet(player: player),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  SECTION 4: SIDE + CUSTOM QUESTS
  // ──────────────────────────────────────────────────────────

  Widget _buildSideQuestsSection(PlayerProvider player) {
    return HolographicPanel(
      header: const SystemHeaderBar(label: 'SIDE QUESTS'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sideQuestItem(player, 0, 'Drink 3L water', 10),
          _sideQuestItem(player, 1, 'Read 10 pages', 15),
          _sideQuestItem(player, 2, 'Walk 5000 steps', 20),

          // Custom quests section
          if (player.customQuests.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(height: 1, color: Colors.white10),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.lock_outline,
                    color: AppColors.primaryViolet, size: 12),
                const SizedBox(width: 6),
                Text(
                  'CUSTOM DIRECTIVES',
                  style: TextStyle(
                    color: AppColors.primaryViolet.withValues(alpha: 0.7),
                    fontSize: 9,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...player.customQuests.map((cq) => _customQuestItem(player, cq)),
          ],
        ],
      ),
    );
  }

  Widget _sideQuestItem(PlayerProvider player, int index, String label, int xp) {
    final done = player.sideQuestDone(index);
    return GestureDetector(
      onTap: done ? null : () => player.completeSideQuest(index, xp),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: done
              ? AppColors.success.withValues(alpha: 0.04)
              : Colors.transparent,
          border: done
              ? Border.all(color: AppColors.success.withValues(alpha: 0.18))
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_box : Icons.check_box_outline_blank,
              color: done ? AppColors.success : Colors.white38,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: done ? Colors.white54 : Colors.white,
                  fontSize: 13,
                  decoration:
                      done ? TextDecoration.lineThrough : TextDecoration.none,
                  decorationColor: Colors.white38,
                ),
              ),
            ),
            Text(
              done ? 'DONE' : '+$xp XP',
              style: TextStyle(
                color: done ? AppColors.success : Colors.amberAccent,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _customQuestItem(PlayerProvider player, cq) {
    final done = cq.completed;
    final failed = cq.failed;
    final Color accent = failed ? AppColors.danger : AppColors.primaryViolet;

    return GestureDetector(
      onTap: (!done && !failed) ? () => player.completeCustomQuest(cq.id) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.04),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lock,
              color: accent.withValues(alpha: 0.7),
              size: 13,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cq.title,
                    style: TextStyle(
                      color: failed
                          ? AppColors.danger
                          : done
                              ? Colors.white54
                              : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      decoration: done
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: Colors.white38,
                    ),
                  ),
                  Text(
                    cq.targetDesc,
                    style: TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (failed)
                  Text(
                    'FAILED ✗',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  )
                else if (done)
                  Text(
                    'DONE ✓',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  )
                else
                  Text(
                    '+${cq.xpReward} XP',
                    style: TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                Text(
                  '🔒 LOCKED',
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 8,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  ADD QUEST BOTTOM SHEET
// ============================================================

class _AddQuestSheet extends StatefulWidget {
  final PlayerProvider player;
  const _AddQuestSheet({required this.player});

  @override
  State<_AddQuestSheet> createState() => _AddQuestSheetState();
}

class _AddQuestSheetState extends State<_AddQuestSheet> {
  final _titleCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  bool _confirmed = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining =
        widget.player.customQuestLimit - widget.player.customQuestsUsedToday;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 12, right: 12, top: 0,
      ),
      child: HolographicPanel(
        header: const SystemHeaderBar(label: 'CREATE DIRECTIVE'),
        emphasize: true,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Slots remaining
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 11, color: AppColors.primaryViolet),
                const SizedBox(width: 5),
                Text(
                  '$remaining SLOT${remaining == 1 ? '' : 'S'} REMAINING TODAY',
                  style: TextStyle(
                    color: AppColors.primaryViolet,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Warning about locking
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.06),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
              ),
              child: Text(
                '⚠  Once confirmed, this quest CANNOT be edited or deleted. Choose wisely.',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quest Name
            Text(
              'DIRECTIVE NAME',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 9,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g. Meditate, Cold shower...',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: AppColors.primaryViolet.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.zero,
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primaryViolet),
                  borderRadius: BorderRadius.zero,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.all(10),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            // Target
            Text(
              'TARGET / DESCRIPTION',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 9,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _targetCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g. 30 min, 10 pages, 5km...',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: AppColors.primaryViolet.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.zero,
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primaryViolet),
                  borderRadius: BorderRadius.zero,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.all(10),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 16),

            // XP preview
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amberAccent.withValues(alpha: 0.04),
                border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reward',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  Text(
                    '+25 XP on completion  /  -50 XP on failure',
                    style: TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Lock button
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _titleCtrl.text.trim().isEmpty || _confirmed
                    ? null
                    : _lockQuest,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _titleCtrl.text.trim().isEmpty
                        ? Colors.white.withValues(alpha: 0.04)
                        : AppColors.primaryViolet.withValues(alpha: 0.15),
                    border: Border.all(
                      color: _titleCtrl.text.trim().isEmpty
                          ? Colors.white12
                          : AppColors.primaryViolet,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock,
                        size: 14,
                        color: _titleCtrl.text.trim().isEmpty
                            ? Colors.white24
                            : AppColors.primaryViolet,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'LOCK IN QUEST',
                        style: TextStyle(
                          color: _titleCtrl.text.trim().isEmpty
                              ? Colors.white24
                              : AppColors.primaryViolet,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'CANCEL',
                  style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _lockQuest() {
    setState(() => _confirmed = true);
    final now = DateTime.now();
    final q = CustomQuest(
      id: '${now.millisecondsSinceEpoch}',
      title: _titleCtrl.text.trim(),
      targetDesc: _targetCtrl.text.trim().isEmpty
          ? 'Complete this directive'
          : _targetCtrl.text.trim(),
      createdDate:
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
    );
    widget.player.addCustomQuest(q);
    Navigator.pop(context);
  }
}
