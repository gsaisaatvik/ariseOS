import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dungeon_template.dart';
import '../services/hive_service.dart';
import '../player_provider.dart';

class DynamicEngine {

  final Box stateBox = HiveService.dynamicState;
  final Box<DungeonTemplate> templateBox =
      HiveService.dungeonTemplates;
  final Box settings = HiveService.settings;

  DungeonTemplate? get todayDungeon {
    final id = stateBox.get('todayDungeonId');
    if (id == null) return null;

    try {
      return templateBox.values.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> assignTodayDungeon() async {
    // Use UTC date and only assign when moving forward in time
    final now = DateTime.now().toUtc();
    final todayUtcString = now.toIso8601String().substring(0, 10); // YYYY-MM-DD

    final lastAssignedUtcString = stateBox.get('assignedDateUtc');

    if (lastAssignedUtcString != null) {
      final lastDate = DateTime.parse(lastAssignedUtcString);
      
      // ✅ Same day check: If today is NOT later than last assigned date, skip.
      if (now.year < lastDate.year ||
          (now.year == lastDate.year && now.month < lastDate.month) ||
          (now.year == lastDate.year && now.month == lastDate.month && now.day <= lastDate.day)) {
        return;
      }
    }

    // First run or new day – assign a new dungeon
    await _assignNewDungeon(todayUtcString);
  }

  // Helper to pick a dungeon template and store assignment info
  Future<void> _assignNewDungeon(String todayUtcString) async {
    final templates = templateBox.values.toList();
    if (templates.isEmpty) return;

    final todayWeekday = DateTime.now().toUtc().weekday;
    final selected = templates[(todayWeekday - 1) % templates.length];

    await stateBox.put('todayDungeonId', selected.id);
    await stateBox.put('status', 'pending');
    await stateBox.put('assignedDateUtc', todayUtcString);
  }

  String get status =>
      stateBox.get('status', defaultValue: 'pending');

  bool get completed => status == 'completed';

  /// ✅ XP handled ONLY by PlayerProvider
  Future<void> completeDungeon(BuildContext context) async {
    // Ensure we only act on a pending dungeon
    if (status != 'pending') return;

    // LOCK FIRST – mark as completed before any XP is granted
    await stateBox.put('status', 'completed');

    // If a penalty is active, abort XP reward
    if (settings.get('penaltyActive', defaultValue: false)) return;

    // Grant XP via PlayerProvider
    Provider.of<PlayerProvider>(context, listen: false).addXP(15);
  }

  Future<void> failDungeon() async {
    if (status != 'pending') return;
    await stateBox.put('status', 'failed');
  }
}