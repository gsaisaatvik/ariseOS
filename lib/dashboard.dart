import 'package:flutter/material.dart';
import 'status_screen.dart';
import 'quests_screen.dart';
import 'skills_screen.dart';
import 'rewards_screen.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;

  // ✅ NOT static / NOT const
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // Pages created at runtime so Provider rebuild works
    _pages = [
      const StatusScreen(),
      const QuestsScreen(),
      const SkillsScreen(),
      const RewardsScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      // ✅ IndexedStack preserves page state while allowing rebuilds
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.grey.shade900,
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Status',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Quests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flash_on),
            label: 'Skills',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Rewards',
          ),
        ],
      ),
    );
  }
}