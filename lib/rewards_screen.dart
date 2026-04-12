import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'player_provider.dart';
import 'models/redemption_item.dart';
import 'system/mana_crystal_engine.dart';
import 'ui/theme/app_colors.dart';
import 'ui/theme/app_text_styles.dart';
import 'ui/widgets/widgets.dart';

// ── Safe icon lookup: avoids fragile hex-parse ───────────────────
IconData _iconForItem(String id) {
  switch (id) {
    case 'focus_tea':          return Icons.local_cafe;
    case 'strength_wrap':      return Icons.fitness_center;
    case 'nap_voucher':        return Icons.hotel;
    case 'social_escape':      return Icons.exit_to_app;
    case 'cheat_meal_pass':    return Icons.restaurant;
    case 'gaming_permit':      return Icons.sports_esports;
    case 'crystal_surge':      return Icons.bolt;
    case 'rune_stone':         return Icons.menu_book;
    case 'restoration_potion': return Icons.healing;
    default:                   return Icons.star_outline;
  }
}

// ============================================================
//  ARISE REWARDS TERMINAL — V2
//  Three sections:
//    1. Balance Header (WalletXP + Mana Crystals)
//    2. SIN CONFESSION PROTOCOL
//    3. SYSTEM REDEMPTION TERMINAL (WalletXP shop)
//    4. CRYSTAL EXCHANGE (Mana Crystal shop)
// ============================================================

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final isDebt = player.walletXP < 0;
    final walletColor = isDebt ? AppColors.danger : Colors.amber;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── BALANCE HEADER ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: HolographicPanel(
              header: const SystemHeaderBar(label: 'ARISE REWARDS TERMINAL'),
              emphasize: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wallet row
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet_rounded,
                          color: walletColor, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'WALLET XP',
                        style: AppTextStyles.systemLabel.copyWith(
                          color: walletColor.withValues(alpha: 0.7),
                          fontSize: 9,
                          letterSpacing: 2,
                        ),
                      ),
                      const Spacer(),
                      if (isDebt)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: AppColors.danger.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            'DEBT PROTOCOL',
                            style: AppTextStyles.systemLabel.copyWith(
                              color: AppColors.danger,
                              fontSize: 8,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${player.walletXP} XP',
                    style: AppTextStyles.headerLarge.copyWith(
                      color: walletColor,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, color: Colors.white12),
                  const SizedBox(height: 12),

                  // Crystal row
                  Row(
                    children: [
                      const Icon(Icons.diamond_outlined,
                          color: Color(0xFF00E5FF), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'MANA CRYSTALS',
                        style: AppTextStyles.systemLabel.copyWith(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.7),
                          fontSize: 9,
                          letterSpacing: 2,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        ManaCrystalEngine.crystalLabel(
                            player.manaCrystals, player.maxManaCrystals),
                        style: AppTextStyles.systemLabel.copyWith(
                          color: const Color(0xFF00E5FF),
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Crystal progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Stack(
                      children: [
                        Container(
                          height: 6,
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.10),
                        ),
                        FractionallySizedBox(
                          widthFactor: player.maxManaCrystals > 0
                              ? (player.manaCrystals / player.maxManaCrystals)
                                  .clamp(0.0, 1.0)
                              : 0,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E5FF),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF)
                                      .withValues(alpha: 0.5),
                                  blurRadius: 6,
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
            ),
          ),

          const SizedBox(height: 8),

          // ── TABS ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TabBar(
              controller: _tabCtrl,
              indicatorColor: AppColors.primaryBlue,
              indicatorWeight: 1.5,
              labelColor: AppColors.primaryBlue,
              unselectedLabelColor: AppColors.textDisabled,
              labelStyle: AppTextStyles.systemLabel.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
              tabs: const [
                Tab(text: 'REDEEM'),
                Tab(text: 'CRYSTALS'),
              ],
            ),
          ),

          // ── TAB BODIES ──────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _RedemptionTab(player: player),
                _CrystalTab(player: player),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  TAB 1 — SYSTEM REDEMPTION TERMINAL (WalletXP shop)
// ============================================================
class _RedemptionTab extends StatelessWidget {
  final PlayerProvider player;
  const _RedemptionTab({required this.player});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: kRedemptionItems.length,
      itemBuilder: (ctx, i) {
        final item = kRedemptionItems[i];
        final canAfford = player.walletXP >= item.costXP;
        final hasRank = meetsRankRequirement(player.rank, item.rankRequired);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _RedemptionItemCard(
            item: item,
            canAfford: canAfford,
            hasRank: hasRank,
            onPurchase: () => _onPurchase(context, player, item),
          ),
        );
      },
    );
  }

  void _onPurchase(
      BuildContext context, PlayerProvider player, RedemptionItem item) {
    showAriseNotificationDialog(
      context: context,
      title: 'CONFIRM PURCHASE',
      message:
          '${item.name}\n\nCost: ${item.costXP} XP\n\n${item.realLifeEffect}',
      type: SystemNotificationType.info,
      primaryLabel: '[PURCHASE]',
      secondaryLabel: 'CANCEL',
      onPrimary: () {
        final success = player.purchaseRedemptionItem(item);
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.9),
              content: Text(
                '${item.name} ACQUIRED.',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      onSecondary: () {},
    );
  }
}

class _RedemptionItemCard extends StatelessWidget {
  final RedemptionItem item;
  final bool canAfford;
  final bool hasRank;
  final VoidCallback onPurchase;
  const _RedemptionItemCard({
    required this.item,
    required this.canAfford,
    required this.hasRank,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final available = canAfford && hasRank;
    final borderColor = available
        ? AppColors.primaryBlue.withValues(alpha: 0.45)
        : Colors.white.withValues(alpha: 0.08);
    final bgColor = available
        ? AppColors.primaryBlue.withValues(alpha: 0.04)
        : Colors.white.withValues(alpha: 0.015);

    return Opacity(
      opacity: available ? 1.0 : 0.45,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: available ? onPurchase : null,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Icon box
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.08),
                      border: Border.all(
                          color: AppColors.primaryBlue.withValues(alpha: 0.30)),
                    ),
                    child: Icon(
                      _iconForItem(item.id),
                      color: available ? AppColors.primaryBlue : Colors.white38,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name,
                            style: AppTextStyles.bodyPrimary.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            )),
                        const SizedBox(height: 2),
                        Text(item.description,
                            style: AppTextStyles.bodySecondary.copyWith(
                              fontSize: 10,
                              color: Colors.white54,
                            )),
                        if (!hasRank)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              'REQUIRES RANK ${item.rankRequired}',
                              style: AppTextStyles.systemLabel.copyWith(
                                color: AppColors.danger,
                                fontSize: 8,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item.costXP} XP',
                        style: AppTextStyles.headerSmall.copyWith(
                          color: canAfford ? Colors.amber : AppColors.danger,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (!canAfford)
                        Text(
                          '[INSUFFICIENT]',
                          style: AppTextStyles.systemLabel.copyWith(
                            color: AppColors.danger,
                            fontSize: 7,
                            letterSpacing: 1,
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
    );
  }
}

// ============================================================
//  TAB 3 — CRYSTAL EXCHANGE
// ============================================================
class _CrystalTab extends StatelessWidget {
  final PlayerProvider player;
  const _CrystalTab({required this.player});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        // Earn methods info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.04),
            border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HOW TO EARN CRYSTALS',
                style: AppTextStyles.systemLabel.copyWith(
                  color: const Color(0xFF00E5FF),
                  fontSize: 9,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _EarnLine('Limiter Removal (200% physical)', '+1 Crystal'),
              _EarnLine('7-Day Streak Milestone', '+5 Crystals'),
              _EarnLine('Every 10th Technical Completion', '+3 Crystals'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        ...kCrystalItems.map((item) {
          final canAfford = player.manaCrystals >= item.costCrystals;
          final hasRank = meetsRankRequirement(player.rank, item.rankRequired);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _CrystalItemCard(
              item: item,
              canAfford: canAfford,
              hasRank: hasRank,
              onPurchase: () => _onPurchase(context, player, item),
            ),
          );
        }),
      ],
    );
  }

  void _onPurchase(
      BuildContext context, PlayerProvider player, RedemptionItem item) {
    showAriseNotificationDialog(
      context: context,
      title: 'CRYSTAL EXCHANGE',
      message:
          '${item.name}\n\nCost: ${item.costCrystals} Mana Crystals\n\n${item.realLifeEffect}',
      type: SystemNotificationType.info,
      primaryLabel: '[EXCHANGE]',
      secondaryLabel: 'CANCEL',
      onPrimary: () {
        final success = player.purchaseCrystalItem(item);
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor:
                  const Color(0xFF00E5FF).withValues(alpha: 0.9),
              content: Text(
                '${item.name} EXCHANGED.',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      onSecondary: () {},
    );
  }
}

class _EarnLine extends StatelessWidget {
  final String label;
  final String value;
  const _EarnLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.chevron_right,
              color: Color(0xFF00E5FF), size: 12),
          const SizedBox(width: 4),
          Expanded(
            child: Text(label,
                style: AppTextStyles.bodySecondary.copyWith(
                  fontSize: 11,
                  color: Colors.white70,
                )),
          ),
          Text(value,
              style: TextStyle(
                color: const Color(0xFF00E5FF),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              )),
        ],
      ),
    );
  }
}

class _CrystalItemCard extends StatelessWidget {
  final RedemptionItem item;
  final bool canAfford;
  final bool hasRank;
  final VoidCallback onPurchase;
  const _CrystalItemCard({
    required this.item,
    required this.canAfford,
    required this.hasRank,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5FF);
    final available = canAfford && hasRank;

    return Opacity(
      opacity: available ? 1.0 : 0.45,
      child: Container(
        decoration: BoxDecoration(
          color: accent.withValues(alpha: available ? 0.04 : 0.01),
          border: Border.all(
              color: accent.withValues(alpha: available ? 0.45 : 0.10)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: available ? onPurchase : null,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.08),
                      border: Border.all(
                          color: accent.withValues(alpha: 0.30)),
                    ),
                    child: Icon(
                      _iconForItem(item.id),
                      color: available ? accent : Colors.white38,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name,
                            style: AppTextStyles.bodyPrimary.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            )),
                        const SizedBox(height: 2),
                        Text(item.description,
                            style: AppTextStyles.bodySecondary.copyWith(
                              fontSize: 10,
                              color: Colors.white54,
                            )),
                        if (!hasRank)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              'REQUIRES RANK ${item.rankRequired}',
                              style: AppTextStyles.systemLabel.copyWith(
                                color: AppColors.danger,
                                fontSize: 8,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      const Icon(Icons.diamond_outlined,
                          color: accent, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${item.costCrystals}',
                        style: TextStyle(
                          color: canAfford ? accent : AppColors.danger,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
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
    );
  }
}
