import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/core_quest.dart';
import 'services/hive_service.dart';
import 'engine/core_engine.dart';
import 'engine/dynamic_engine.dart';
import 'player_provider.dart';
import 'widgets/system_overlay.dart';
import 'widgets/xp_floating_text.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  int? _lastLevel;
  String? _lastRank;
  bool? _lastPenalty;

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

  void _checkTriggers(
      BuildContext context, int level, String rank, bool penalty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final player = Provider.of<PlayerProvider>(context, listen: false);
      
      if (_lastLevel != null && level > _lastLevel!) {
        SystemOverlay.show(
          context,
          title: "SYSTEM EVOLUTION",
          message: "Level Up\nLevel $level",
        );
      }
      if (_lastRank != null && rank != _lastRank) {
        SystemOverlay.show(
          context,
          title: "RANK ADVANCEMENT",
          message: "New Rank Obtained\n$rank Rank",
        );
      }
      if (_lastPenalty != null && penalty && !_lastPenalty!) {
        // 🔥 PHASE 6: IRON RESOLVE CHECK
        if (player.ironActive) {
          final settings = HiveService.settings;
          final coreBox = HiveService.coreQuests;
          final engine = CoreEngine(coreBox, settings);
          engine.clearPenalty();
          player.consumeIron(); 
          
          SystemOverlay.show(
            context,
            title: "IRON RESOLVE",
            message: "Penalty Blocked\nAbility Expended",
          );
        } else {
          SystemOverlay.show(
            context,
            title: "SYSTEM PENALTY",
            message: "Penalty Activated\nTraining Failure",
          );
        }
      }

      // 🔥 PHASE 6: ABILITY UNLOCK DETECTION
      _checkNewUnlocks(context, player);

      _lastLevel = level;
      _lastRank = rank;
      _lastPenalty = penalty;
    });
  }

  bool _isProcessing = false;

  void _checkNewUnlocks(BuildContext context, PlayerProvider player) {
    if (player.flowUnlocked && !player.hasNotifiedFlow) {
      _showUnlock(context, "FLOW STATE");
      player.setNotified("FLOW STATE");
    }
    if (player.enduranceUnlocked && !player.hasNotifiedEndurance) {
      _showUnlock(context, "ENDURANCE BURST");
      player.setNotified("ENDURANCE BURST");
    }
    if (player.insightUnlocked && !player.hasNotifiedInsight) {
      _showUnlock(context, "TACTICAL INSIGHT");
      player.setNotified("TACTICAL INSIGHT");
    }
    if (player.ironUnlocked && !player.hasNotifiedIron) {
      _showUnlock(context, "IRON RESOLVE");
      player.setNotified("IRON RESOLVE");
    }
  }

  void _showUnlock(BuildContext context, String name) {
    SystemOverlay.show(
      context,
      title: "NEW ABILITY UNLOCKED",
      message: name,
    );
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

          // Update Triggers
          _checkTriggers(
              context, player.level, player.rank, engine.penaltyActive);

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
                  engine.penaltyActive ? "⚠ PENALTY ACTIVE" : "No Penalty",
                  style: TextStyle(
                    color: engine.penaltyActive ? Colors.red : Colors.grey,
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
                                  onPressed: _isProcessing
                                      ? null
                                      : () async {
                                          setState(() => _isProcessing = true);
                                          try {
                                            await engine.completeQuest(quest);

                                            // 🔥 ATTRIBUTE EFFECTS: Threshold-based Rebalance
                                            int baseXP = 10;

                                            // 🔥 PHASE 6: ACTIVE ABILITIES
                                            int abilityBonus = 0;
                                            bool consumed = false;

                                            if (quest.id == 'deep_work' &&
                                                player.flowActive) {
                                              abilityBonus += baseXP; // Double XP
                                              player.consumeFlow();
                                              consumed = true;
                                            }

                                            if (quest.id == 'strength' &&
                                                player.enduranceActive) {
                                              abilityBonus += 5;
                                              player.consumeEndurance();
                                              consumed = true;
                                            }

                                            if (consumed) {
                                              SystemOverlay.show(
                                                context,
                                                title: "ABILITY TRIGGERED",
                                                message: "Special Bonus Applied",
                                              );
                                            }

                                            int focusBonus = player.focus >= 20
                                                ? 2
                                                : (player.focus >= 10 ? 1 : 0);
                                            int strengthBonus =
                                                player.strength >= 20
                                                    ? 2
                                                    : (player.strength >= 10
                                                        ? 1
                                                        : 0);

                                            int totalXP = baseXP +
                                                focusBonus +
                                                strengthBonus +
                                                abilityBonus;

                                            // 🔥 FEEDBACK
                                            XPFloatingText.show(context,
                                                amount: totalXP);

                                            // 🔥 GIVE XP THROUGH PROVIDER
                                            player.addXP(totalXP);
                                          } finally {
                                            if (mounted) {
                                              setState(() => _isProcessing = false);
                                            }
                                          }
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
