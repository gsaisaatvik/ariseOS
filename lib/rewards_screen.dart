import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'player_provider.dart';
import 'widgets/system_overlay.dart';
import 'ui/widgets/widgets.dart';
import 'ui/theme/app_text_styles.dart';

// ============================================================
// Reward Definitions
// ============================================================
class _RewardItem {
  final String name;
  final int cost;
  final int minTier; // 1 = Rank D+, 2 = Rank C+
  _RewardItem(this.name, this.cost, this.minTier);
}

final _rewards = [
  _RewardItem('MINOR LUXURY (SNACK / SHORT VIDEO)', 400, 1),
  _RewardItem('MAJOR LUXURY (MOVIE / GAMING SESSION)', 1200, 2),
  _RewardItem('GREAT LUXURY (CHEAT DAY)', 2500, 2),
  _RewardItem('SKIP DUNGEON ONCE', 1500, 2),
];

// ============================================================
// Sin Definitions
// ============================================================
class _SinItem {
  final String label;
  final String tier;
  final int cost;
  _SinItem(this.label, this.tier, this.cost);
}

final _sins = [
  _SinItem('MINOR TREAT (SNACK / SHORT VIDEO)', 'minor', 400),
  _SinItem('MAJOR SIN (MEAL / GAMING)', 'major', 1200),
  _SinItem('GREAT SIN (FAST FOOD / CHEAT DAY)', 'great', 2500),
];

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, child) {
        final int tier = player.rewardTier;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              HolographicPanel(
                header: const SystemHeaderBar(label: 'REDEMPTION OVERVIEW'),
                emphasize: true,
                child: _buildHeader(player),
              ),
              HolographicPanel(
                header: const SystemHeaderBar(label: 'CONFESS SIN'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Convert indulgences into debt the system can track.',
                      style: AppTextStyles.bodySecondary,
                    ),
                    const SizedBox(height: 12),
                    ..._sins.map((sin) => _buildSinCard(player, sin)),
                  ],
                ),
              ),
              HolographicPanel(
                header: const SystemHeaderBar(label: 'REDEMPTION TERMINAL'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tier == 0) _buildRankEPrison(),
                    if (tier > 0)
                      ..._rewards.map(
                        (r) => _buildRewardCard(player, r, tier),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ────────────────────────────────────────────────────────────
  // Header
  // ────────────────────────────────────────────────────────────
  Widget _buildHeader(PlayerProvider player) {
    final bool inDebt = player.isRestricted;
    final walletColor = inDebt ? Colors.redAccent : Colors.amberAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          'REDEMPTION TERMINAL',
          style: TextStyle(
            color: Colors.cyanAccent,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              'XP BALANCE:',
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${player.walletXP} XP',
              style: TextStyle(
                color: walletColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (inDebt)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: const Text(
              '[STATUS: IN DEBT - STATS FROZEN]',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              'STREAK: ${player.streakDays.toString().padLeft(3,'0')} DAYS',
              style: TextStyle(
                color: const Color(0xFF00E5FF).withOpacity(0.6),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'RANK: ${player.rank}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          height: 1,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.cyanAccent.withOpacity(0.4),
                Colors.cyanAccent.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────
  // Sin Card (always active)
  // ────────────────────────────────────────────────────────────
  Widget _buildSinCard(PlayerProvider player, _SinItem sin) {
    int finalCost = sin.cost;
    
    if (player.rank == 'E') {
      if (sin.tier == 'major') finalCost = 800;
      else if (sin.tier == 'great') finalCost = 2000;
    }



    final int daysOfWork = (finalCost / 400).ceil();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0000),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sin.label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '≈ $daysOfWork DAYS ERASED',
                  style: TextStyle(
                    color: Colors.redAccent.withOpacity(0.6),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isProcessing ? null : () => _confirmSin(context, player, sin, finalCost),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.redAccent.withOpacity(0.7)),
                color: Colors.redAccent.withOpacity(0.08),
              ),
              child: Text(
                '-$finalCost XP',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Rank E Prison
  // ────────────────────────────────────────────────────────────
  Widget _buildRankEPrison() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16, top: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white10),
        color: Colors.white.withOpacity(0.02),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock, color: Colors.white12, size: 40),
          const SizedBox(height: 12),
          const Text(
            'RANK E HUNTERS HAVE NO RIGHTS.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white24,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'REACH RANK D:\n12,000 XP + LEVEL 10 + 50-DAY STREAK',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.15),
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Reward Card
  // ────────────────────────────────────────────────────────────
  Widget _buildRewardCard(PlayerProvider player, _RewardItem reward, int playerTier) {
    final bool canAfford = player.walletXP >= reward.cost;
    final bool tierOk = playerTier >= reward.minTier;
    final bool enabled = canAfford && tierOk && !_isProcessing;
    final int daysOfWork = (reward.cost / 400).ceil();

    String statusText;
    Color statusColor;
    if (!tierOk) {
      statusText = 'STATUS: RANK ${reward.minTier == 1 ? 'D' : 'C'} REQUIRED';
      statusColor = Colors.white24;
    } else if (!canAfford) {
      statusText = 'STATUS: INSUFFICIENT XP';
      statusColor = Colors.redAccent.withOpacity(0.8);
    } else {
      statusText = 'STATUS: AVAILABLE';
      statusColor = Colors.greenAccent;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        border: Border.all(
          color: enabled
              ? const Color(0xFF00E5FF).withOpacity(0.3)
              : Colors.white10,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  reward.name,
                  style: TextStyle(
                    color: enabled ? Colors.white : Colors.white24,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (!tierOk)
                const Icon(Icons.lock_outline, color: Colors.white24, size: 18)
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.08),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${reward.cost} XP',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '≈ $daysOfWork DAYS OF WORK',
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: enabled
                      ? () => _confirmRedemption(context, player, reward)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white10,
                    disabledBackgroundColor: Colors.transparent,
                    side: BorderSide(
                      color: enabled ? const Color(0xFF00E5FF) : Colors.white10,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    elevation: 0,
                  ),
                  child: Text(
                    'REDEEM',
                    style: TextStyle(
                      color: enabled ? const Color(0xFF00E5FF) : Colors.white10,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Confirmation Dialogs
  // ────────────────────────────────────────────────────────────

  void _confirmSin(BuildContext context, PlayerProvider player, _SinItem sin, int finalCost) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F0000),
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Colors.redAccent, width: 1),
        ),
        title: const Text(
          'CONFESS SIN',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
            letterSpacing: 2,
          ),
        ),
        content: Text(
          'ADMIT: ${sin.label}\n\nPENALTY: -$finalCost XP from Wallet.\nThe System will not forget.',
          style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('DENY', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              player.logCustomSin(finalCost, sin.label);
              Navigator.pop(context);
              SystemOverlay.show(
                context,
                title: 'DEBT DETECTED',
                message: '-$finalCost XP\nWallet: ${player.walletXP} XP',
              );
            },
            child: const Text('ADMIT', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmRedemption(BuildContext context, PlayerProvider player, _RewardItem reward) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF050505),
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Color(0xFF00E5FF), width: 1),
        ),
        title: const Text(
          'CONFIRM EXCHANGE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
            letterSpacing: 2,
          ),
        ),
        content: Text(
          '${reward.name}\n\nCOST: ${reward.cost} XP from Wallet.',
          style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (_isProcessing) return;
              setState(() => _isProcessing = true);
              try {
                player.spendXP(reward.cost);
                Navigator.pop(context);
                SystemOverlay.show(
                  context,
                  title: 'REWARD REDEEMED',
                  message: reward.name,
                );
              } finally {
                if (mounted) setState(() => _isProcessing = false);
              }
            },
            child: const Text(
              'CONFIRM',
              style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
