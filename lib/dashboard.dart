import 'package:flutter/material.dart';
import 'status_screen.dart';
import 'quests_screen.dart';
import 'skills_screen.dart';
import 'rewards_screen.dart';
import 'ui/widgets/widgets.dart';
import 'ui/widgets/holographic_nav_bar.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    StatusScreen(),
    QuestsScreen(),
    SkillsScreen(),
    RewardsScreen(),
  ];

  final List<HolographicNavItem> _navItems = const [
    HolographicNavItem(icon: Icons.analytics_outlined, label: 'Status'),
    HolographicNavItem(icon: Icons.flag_outlined, label: 'Quests'),
    HolographicNavItem(icon: Icons.auto_awesome_outlined, label: 'Skills'),
    HolographicNavItem(icon: Icons.card_giftcard_outlined, label: 'Rewards'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SystemHeaderBar(label: "ARISE OS"),

          Expanded(
            child: IndexedStack(index: _currentIndex, children: _pages),
          ),

          HolographicNavBar(
            items: _navItems,
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ],
      ),
    );
  }
}
