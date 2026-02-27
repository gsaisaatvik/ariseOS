import 'package:flutter/material.dart';
import '../engine/dynamic_engine.dart';
import '../services/hive_service.dart';

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
                        setState(() {});
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