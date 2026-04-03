import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'player_provider.dart';
import 'ui/theme/app_colors.dart';
import 'ui/theme/app_text_styles.dart';
import 'ui/widgets/widgets.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final isDebt = player.walletXP < 0;
    final economyColor = isDebt ? AppColors.danger : Colors.amber;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HolographicPanel(
              header: const SystemHeaderBar(label: 'ARISE REWARDS TERMINAL'),
              emphasize: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "BALANCE STATUS",
                    style: AppTextStyles.systemLabel.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${player.walletXP} XP",
                    style: AppTextStyles.headerLarge.copyWith(
                      color: economyColor,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            HolographicPanel(
              header: const SystemHeaderBar(label: 'SIN CONFESSION PROTOCOL'),
              child: _buildSinTerminal(player),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSinTerminal(PlayerProvider player) {
    return Column(
      children: [
        _TerminalItem(
          label: "MINOR INDULGENCE",
          cost: 400,
          color: AppColors.danger,
          onTap: () => player.logCustomSin(400, "MINOR SIN"),
        ),
        const SizedBox(height: 12),
        _TerminalItem(
          label: "MAJOR INDULGENCE",
          cost: 1200,
          color: AppColors.danger,
          onTap: () => player.logCustomSin(1200, "MAJOR SIN"),
        ),
      ],
    );
  }
}

class _TerminalItem extends StatelessWidget {
  final String label;
  final int cost;
  final Color color;
  final VoidCallback onTap;
  const _TerminalItem(
      {required this.label,
      required this.cost,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.toUpperCase(),
              style: AppTextStyles.bodyPrimary.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "-${cost} XP",
              style: AppTextStyles.headerSmall.copyWith(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

