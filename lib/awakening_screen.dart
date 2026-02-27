import 'package:flutter/material.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'dashboard.dart';

class AwakeningScreen extends StatelessWidget {
  const AwakeningScreen({super.key});

  Future<void> _completeAwakening(BuildContext context) async {
    final settings = HiveService.settings;

    await settings.put('hasAwakened', true);

    try {
      await NotificationService.scheduleDailyNotifications();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Syncing with System... (10s Wait)")),
        );
      }
    } catch (e) {
      print("Error scheduling notifications: $e");
    }

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Dashboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "You Have Awakened.",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "From today, your discipline defines you.\n"
              "Complete your Core Quests.\n"
              "Conquer your Dungeon.\n"
              "Rise in Level.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () => _completeAwakening(context),
              child: const Text("Begin My Journey"),
            ),
          ],
        ),
      ),
    );
  }
}