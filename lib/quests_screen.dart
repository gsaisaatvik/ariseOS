import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'engine/dynamic_engine.dart';
import 'services/hive_service.dart';
import 'widgets/system_overlay.dart';
import 'widgets/xp_floating_text.dart';
import 'player_provider.dart';

class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {

  late DynamicEngine engine;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    engine = DynamicEngine();

    // ✅ assign ONLY once
    _initDungeon();
  }

  Future<void> _initDungeon() async {
    await engine.assignTodayDungeon();

    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    if (!_initialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final dungeon = engine.todayDungeon;
    final penalty =
        HiveService.settings.get('penaltyActive', defaultValue: false);

    if (dungeon == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "No Dungeon Assigned",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Daily Dungeon"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 20),

            Text(
              dungeon.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              dungeon.description,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 30),

            if (penalty)
              const Text(
                "⚠ XP Locked Due To Penalty",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),

            const SizedBox(height: 20),

            if (engine.status == 'completed')
              const Text(
                "✔ Dungeon Completed",
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              )
            else if (engine.status == 'failed')
              const Text(
                "✖ Dungeon Failed",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              )
            else ...[
              ElevatedButton(
                onPressed: penalty
                    ? null
                    : () async {
                        await engine.completeDungeon(context);
                        if (mounted) {
                          // 🔥 ATTRIBUTE EFFECTS: Intelligence Bonus Rebalance
                          final player = Provider.of<PlayerProvider>(context,
                              listen: false);
                          
                          int baseDungeonXP = 15;
                          int intBonus = player.intelligence >= 20
                              ? 4
                              : (player.intelligence >= 10 ? 2 : 0);
                          
                          // 🔥 PHASE 6: TACTICAL INSIGHT
                          int insightBonus = 0;
                          if (player.insightActive) {
                            insightBonus = 5;
                            player.consumeInsight();
                            SystemOverlay.show(
                                context,
                                title: "ABILITY TRIGGERED",
                                message: "Tactical Insight Applied",
                              );
                          }

                          int finalXP = baseDungeonXP + intBonus + insightBonus;

                          // Only add the bonus part here because engine already added baseXP
                          int extraXP = intBonus + insightBonus;
                          if (extraXP > 0) {
                            player.addXP(extraXP);
                          }

                          SystemOverlay.show(
                            context,
                            title: "DUNGEON CLEAR",
                            message: "Success\nBonus XP: +$extraXP",
                          );
                          XPFloatingText.show(context, amount: finalXP);
                          setState(() {});
                        }
                      },
                child: const Text("Complete Dungeon"),
              ),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: () async {
                  await engine.failDungeon();
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text("Fail Dungeon"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}