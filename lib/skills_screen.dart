import 'package:flutter/material.dart';
import 'dart:math';
import '../services/hive_service.dart';

class SkillsScreen extends StatelessWidget {
  const SkillsScreen({super.key});

  String getRank(int xp) {
    if (xp >= 5000) return 'S';
    if (xp >= 2500) return 'A';
    if (xp >= 1000) return 'B';
    if (xp >= 400) return 'C';
    if (xp >= 100) return 'D';
    return 'E';
  }

  @override
  Widget build(BuildContext context) {
    final settings = HiveService.settings;
    final rawXP = settings.get('lifetimeXP', defaultValue: 0);
    int lifetimeXP = 0;
    if (rawXP is int) {
      lifetimeXP = rawXP;
    } else if (rawXP is double) {
      lifetimeXP = rawXP.toInt();
    }

    int streak = settings.get('streak', defaultValue: 0);
    bool penalty = settings.get('penaltyActive', defaultValue: false);

    double level = lifetimeXP > 0 ? sqrt(lifetimeXP.toDouble()) : 0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Hunter Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Rank: ${getRank(lifetimeXP)}",
              style: const TextStyle(color: Colors.amber, fontSize: 26),
            ),
            const SizedBox(height: 20),
            Text(
              "Level: ${level.toStringAsFixed(1)}",
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(height: 20),
            Text(
              "Lifetime XP: $lifetimeXP",
              style: const TextStyle(color: Colors.grey, fontSize: 18),
            ),
            const SizedBox(height: 20),
            Text(
              "Current Streak: $streak days",
              style: const TextStyle(color: Colors.green, fontSize: 18),
            ),
            const SizedBox(height: 20),
            Text(
              penalty ? "Penalty Active" : "No Penalty",
              style: TextStyle(
                color: penalty ? Colors.red : Colors.blue,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
