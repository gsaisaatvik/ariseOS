import 'package:flutter/material.dart';
import 'status_screen.dart';
import 'skills_screen.dart';
import 'rewards_screen.dart';
import 'ui/widgets/widgets.dart';
import 'package:provider/provider.dart';
import 'player_provider.dart';
import 'ui/widgets/rank_up_overlay.dart';
import 'penalty_zone_screen.dart';
import 'ui/theme/app_colors.dart';

import 'quests_screen.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    const StatusScreen(),
    const QuestsScreen(),
    const SkillsScreen(),
    const RewardsScreen(),
  ];

  final List<HolographicNavItem> _navItems = const [
    HolographicNavItem(icon: Icons.analytics_outlined, label: 'Status'),
    HolographicNavItem(icon: Icons.flag_outlined, label: 'Quests'),
    HolographicNavItem(icon: Icons.history_edu_outlined, label: 'Chronicle'),
    HolographicNavItem(icon: Icons.card_giftcard_outlined, label: 'Rewards'),
  ];

  late AnimationController _flashController;
  late Animation<double> _flashOpacity;
  late AnimationController _tabEnterController;
  late Animation<double> _tabEnter;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _flashOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.15),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.15, end: 0.0),
        weight: 1,
      ),
    ]).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.linear),
    );

    _tabEnterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _tabEnter = CurvedAnimation(
      parent: _tabEnterController,
      curve: Curves.easeOutCubic,
    );

    _tabEnterController.value = 1.0;
  }

  @override
  void dispose() {
    _flashController.dispose();
    _tabEnterController.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    _flashController.forward(from: 0);
    _tabEnterController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12, top: 8),
                child: SystemHeaderBar(label: "ARISE OS"),
              ),

              Expanded(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_tabEnter, _flashOpacity]),
                  builder: (context, child) {
                    final t = _tabEnter.value;
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - t)),
                      child: Opacity(
                        opacity: t,
                        child: child,
                      ),
                    );
                  },
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _pages,
                  ),
                ),
              ),

              HolographicNavBar(
                items: _navItems,
                currentIndex: _currentIndex,
                onTap: _onTabTap,
              ),
            ],
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _flashOpacity,
                builder: (context, _) {
                  final o = _flashOpacity.value;
                  if (o <= 0) return const SizedBox.shrink();
                  return ColoredBox(
                    color: const Color(0xFF00FFFF).withValues(alpha: o),
                  );
                },
              ),
            ),
          ),

          // ── Rank-Up Overlay (fires AFTER level-up queue is empty) ──
          Consumer<PlayerProvider>(
            builder: (context, player, _) {
              // Only display when level-up queue is fully consumed
              if (player.nextLevelUpEvent != null) return const SizedBox.shrink();
              final rankEvt = player.nextRankUpEvent;
              if (rankEvt == null) return const SizedBox.shrink();

              return RankUpOverlay(
                event: rankEvt,
                onAcknowledge: () => player.consumeNextRankUpEvent(),
              );
            },
          ),
          Consumer<PlayerProvider>(
            builder: (context, player, _) {
              if (!player.inPenaltyZone) return const SizedBox.shrink();

              return Positioned.fill(
                child: IgnorePointer(
                  ignoring: false,
                  child: PenaltyZoneScreen(
                    onExpired: () => player.deactivatePenaltyZone(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
