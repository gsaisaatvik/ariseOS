import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'player_provider.dart';
import 'engine/dungeon_engine.dart';
import 'services/hive_service.dart';
import 'awakening_screen.dart';

class NotificationSequence extends StatefulWidget {
  const NotificationSequence({super.key});

  @override
  State<NotificationSequence> createState() => _NotificationSequenceState();
}

class _NotificationSequenceState extends State<NotificationSequence> {
  final List<String> _notifications = [
    '! NOTIFICATION The Secret Quest: Courage of the Weak.',
    '! NOTIFICATION You have acquired the qualifications to be a Player. Will you accept?',
    '! NOTIFICATION Your heart will stop in 0.02 seconds if you choose not to accept. Will you accept?',
    '! NOTIFICATION Congratulations on becoming a Player.',
    'NOTIFICATION You have unread messages.',
    '! NOTIFICATION Failure to comply with the system may result in a penalty.',
    'NOTIFICATION This system is designed to assist the development of the Player.',
  ];

  int _index = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final playerProvider =
          Provider.of<PlayerProvider>(context, listen: false);

      // 🔥 PASS PROVIDER DIRECTLY
      final engine = DungeonEngine(playerProvider);

      final dungeon = await engine.generateOrFetchToday();

      print("TODAY DUNGEON: ${dungeon?.subjectId}, XP: ${dungeon?.xpReward}");
    });

    _maybeAdvance();
  }

  void _maybeAdvance() {
    if (_requiresDecision(_notifications[_index])) return;
    Future.delayed(const Duration(seconds: 2), _next);
  }

  bool _requiresDecision(String text) =>
      text.contains('Will you accept?');

  Future<void> _next() async {
    if (_index < _notifications.length - 1) {
      setState(() {
        _index++;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AwakeningScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String current =
        _notifications[_index.clamp(0, _notifications.length - 1)];
    final bool decision = _requiresDecision(current);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[900],
                  border: Border.all(color: Colors.yellow, width: 3),
                ),
                child: Text(
                  current,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              if (decision)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      child: const Text('YES'),
                    ),
                    ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red),
                      child: const Text('NO'),
                    ),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey),
                  child: const Text('OK'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}