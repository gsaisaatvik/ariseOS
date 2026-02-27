import 'package:hive/hive.dart';
import '../models/core_quest.dart';

class CoreEngine {
  final Box<CoreQuest> _coreBox;
  final Box _settingsBox;

  CoreEngine(this._coreBox, this._settingsBox);

  bool get penaltyActive =>
      _settingsBox.get('penaltyActive', defaultValue: false);

  int get streak =>
      _settingsBox.get('streak', defaultValue: 0);

  /// 🔥 COMPLETE QUEST
  Future<void> completeQuest(CoreQuest quest) async {
    if (quest.completed) return;

    quest.completed = true;
    await quest.save();

    await rewardCoreXP();
  }

  /// 🔥 REWARD XP FOR CORE QUEST (Handled by PlayerProvider in UI for stability)
  Future<void> rewardCoreXP() async {
    // Moved to PlayerProvider.addXP in UI layer to ensure single source of truth
    // and correctly handle Level Up point allocation.
  }

  /// 🔥 AUTO CHECK IF NEW DAY
  Future<void> checkAndEvaluateNewDay() async {
    final now = DateTime.now().toUtc();
    final todayUtcString = now.toIso8601String().substring(0, 10); // YYYY-MM-DD

    final lastEvaluationDateUtcString =
        _settingsBox.get('lastEvaluationDateUtc');

    if (lastEvaluationDateUtcString == null) {
      await _settingsBox.put('lastEvaluationDateUtc', todayUtcString);
      return;
    }

    final lastEvaluationDate = DateTime.parse(lastEvaluationDateUtcString);

    // If today's UTC date is after the last evaluated UTC date, then a new day has started.
    if (now.year > lastEvaluationDate.year ||
        (now.year == lastEvaluationDate.year && now.month > lastEvaluationDate.month) ||
        (now.year == lastEvaluationDate.year && now.month == lastEvaluationDate.month && now.day > lastEvaluationDate.day)) {
      await evaluateDay();
      await _settingsBox.put('lastEvaluationDateUtc', todayUtcString);
    }
  }

  /// 🔥 EVALUATE DAY
  Future<void> evaluateDay() async {
    bool allCompleted =
        _coreBox.values.every((q) => q.completed);

    if (allCompleted) {
      int currentStreak = streak;
      await _settingsBox.put(
          'streak', currentStreak + 1);
      await _settingsBox.put(
          'penaltyActive', false);
    } else {
      await _settingsBox.put('streak', 0);
      await _settingsBox.put(
          'penaltyActive', true);
    }

    await resetForNextDay();
  }

  /// 🔥 RESET QUESTS
  Future<void> resetForNextDay() async {
    await _coreBox.clear();

    await _coreBox.addAll([
      CoreQuest(
        id: 'strength',
        name: 'Strength Training',
        date: DateTime.now(),
      ),
      CoreQuest(
        id: 'deep_work',
        name: '90 Min Deep Work',
        date: DateTime.now(),
      ),
      CoreQuest(
        id: 'dsa',
        name: '2 DSA Problems',
        date: DateTime.now(),
      ),
    ]);
  }

  Future<void> clearPenalty() async {
    await _settingsBox.put('penaltyActive', false);
  }
}