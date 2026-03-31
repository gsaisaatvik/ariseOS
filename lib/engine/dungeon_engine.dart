import 'package:intl/intl.dart';
import '../models/dungeon.dart';
//import '../models/subject.dart';
import '../services/hive_service.dart';
import '../player_provider.dart';

class DungeonEngine {
  final PlayerProvider _player;
  DungeonEngine(this._player);

  /// Generates today's dungeon if it doesn't exist, otherwise returns the existing one.
  Future<Dungeon?> generateOrFetchToday() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final box = HiveService.dungeons;

    // ✅ SAFE CHECK (no null casting)
    final existingList =
        box.values.where((d) => d.date == today).toList();

    if (existingList.isNotEmpty) {
      return existingList.first;
    }

    // No dungeon for today – generate one from a random subject.
    final subjectsBox = HiveService.subjects;
    if (subjectsBox.isEmpty) {
      throw Exception('No subjects defined in Hive.');
    }

    final subject = (subjectsBox.values.toList()..shuffle()).first;

    final difficulty = subject.baseDifficulty *
        (1 + subject.scalingFactor * _player.penaltyDebt);

    final xpReward = difficulty * 10;

    final dungeon = Dungeon(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: today,
      subjectId: subject.id,
      difficulty: difficulty,
      xpReward: xpReward,
    );

    await box.add(dungeon);
    return dungeon;
  }

  /// Marks the dungeon as completed, awards XP and reduces penalty.
  Future<void> clearDungeon(Dungeon dungeon) async {
    dungeon.completed = true;
    await dungeon.save();
    _player.addXP(dungeon.xpReward.toInt());
    _player.decreasePenalty();
  }

  /// Marks the dungeon as failed and increases penalty.
  Future<void> failDungeon(Dungeon dungeon) async {
    dungeon.completed = false;
    await dungeon.save();
    _player.increasePenalty();
  }
}