import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/hive_service.dart';
import 'services/firebase_service.dart';
import 'root_decider.dart';
import 'player_provider.dart';
import 'ui/widgets/widgets.dart';
import 'ui/theme/app_text_styles.dart';

class HunterProfileScreen extends StatelessWidget {
  const HunterProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(child: SystemHeaderBar(label: 'HUNTER PROFILE')),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              HolographicPanel(
                header: const SystemHeaderBar(label: 'IDENTITY'),
                emphasize: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name.toUpperCase(),
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      player.title,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final rank = _kv('RANK', player.rank);
                        final level = _kv('LEVEL', '${player.level}');
                        if (constraints.maxWidth < 360) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              rank,
                              const SizedBox(height: 8),
                              level,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: rank),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: level,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              HolographicPanel(
                header: const SystemHeaderBar(label: 'PROGRESSION'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _kv('LIFETIME XP', '${player.totalXP}'),
                    const SizedBox(height: 10),
                    _kv('WALLET XP', '${player.walletXP}'),
                    const SizedBox(height: 10),
                    _kv('STREAK', '${player.streakDays} DAYS'),
                    const SizedBox(height: 10),
                    _kv('BEST STREAK', '${player.bestStreak} DAYS'),
                  ],
                ),
              ),
              HolographicPanel(
                header: const SystemHeaderBar(label: 'SYSTEM NOTE'),
                child: Text(
                  'Rank is determined by lifetime progress, consistency, and reliability.\n'
                  'Level represents raw experience curve and governs attribute growth.',
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 4,
                  style: AppTextStyles.bodySecondary,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: PrimaryActionButton(
                    label: 'LOGOUT',
                    dangerTone: true,
                    onPressed: () async {
                      final settings = HiveService.settings;
                      try {
                        await FirebaseService.signOut();
                      } catch (e) {
                        debugPrint('Firebase sign out failed: $e');
                      }
                      if (!context.mounted) return;
                      settings.put('isLoggedIn', false);
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const RootDecider(),
                        ),
                        (_) => false,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: SecondaryActionButton(
                    label: 'BACK',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _kv(String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          k,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          v,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

