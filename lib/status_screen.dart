import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/core_quest.dart';
import 'services/hive_service.dart';
import 'engine/core_engine.dart';
import 'engine/dynamic_engine.dart';
import 'player_provider.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {

  @override
  void initState() {
    super.initState();

    final coreBox = HiveService.coreQuests;
    final settings = HiveService.settings;
    final engine = CoreEngine(coreBox, settings);

    engine.checkAndEvaluateNewDay();

    final dynamicEngine = DynamicEngine();
    dynamicEngine.assignTodayDungeon();
  }

  @override
  Widget build(BuildContext context) {

    final coreBox = HiveService.coreQuests;
    final settings = HiveService.settings;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("ARISE OS"),
      ),
      body: ValueListenableBuilder(
        valueListenable: coreBox.listenable(),
        builder: (context, Box<CoreQuest> box, _) {

          final engine = CoreEngine(box, settings);

          // 🔥 LISTEN TO PLAYER PROVIDER
          final player = Provider.of<PlayerProvider>(context);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// 🔥 RANK (UPDATED)
                Text(
                  "RANK: ${player.rank} Rank",
                  style: const TextStyle(
                    color: Colors.purpleAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                /// 🔥 LEVEL
                Text(
                  "Level: ${player.level}",
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 16),

                /// 🔥 LIFETIME XP (Hive based)
                Text(
                  "XP: ${(() {
                    final raw = settings.get('lifetimeXP', defaultValue: 0);
                    return raw is double ? raw.toInt() : raw;
                  })()}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 4),

                /// 🔥 WALLET XP
                Text(
                  "Wallet XP: ${(() {
                    final raw = settings.get('walletXP', defaultValue: 0);
                    return raw is double ? raw.toInt() : raw;
                  })()}",
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 12),

                /// 🔥 STREAK
                Text(
                  "Streak: ${engine.streak}",
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 8),

                /// 🔥 PENALTY STATUS
                Text(
                  engine.penaltyActive
                      ? "⚠ PENALTY ACTIVE"
                      : "No Penalty",
                  style: TextStyle(
                    color: engine.penaltyActive
                        ? Colors.red
                        : Colors.grey,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "CORE QUESTS",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: ListView(
                    children: box.values.map((quest) {
                      return Card(
                        color: Colors.grey[900],
                        child: ListTile(
                          title: Text(
                            quest.name,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          trailing: quest.completed
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.green,
                                )
                              : ElevatedButton(
                                  onPressed: () async {
                                    await engine.completeQuest(quest);

                                    // 🔥 GIVE XP THROUGH PROVIDER
                                    player.addXP(10);

                                    setState(() {});
                                  },
                                  child: const Text("Complete"),
                                ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}