import 'package:flutter/material.dart';
import 'services/hive_service.dart';
import 'widgets/system_overlay.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  void buyReward(int cost) async {
    final settings = HiveService.settings;
    int wallet = settings.get('walletXP', defaultValue: 0);

    if (wallet < cost) return;

    wallet -= cost;
    await settings.put('walletXP', wallet);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final settings = HiveService.settings;
    int wallet = settings.get('walletXP', defaultValue: 0);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Rewards Store'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Text(
              "Wallet XP: $wallet",
              style: const TextStyle(color: Colors.amber, fontSize: 20),
            ),
            const SizedBox(height: 30),
            rewardTile("Watch Movie", 150),
            rewardTile("Favorite Meal", 120),
            rewardTile("Gaming Session", 200),
            rewardTile("Skip Dungeon Once", 300),
          ],
        ),
      ),
    );
  }

  Widget rewardTile(String title, int cost) {
    return Card(
      color: Colors.grey[900],
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text("$cost XP", style: const TextStyle(color: Colors.grey)),
        trailing: ElevatedButton(
          onPressed: () => buyReward(cost),
          child: const Text('Buy'),
        ),
      ),
    );
  }
}
