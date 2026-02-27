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

  /// 🔥 REWARD XP FOR CORE QUEST
  Future<void> rewardCoreXP() async {
    if (penaltyActive) return;

    final rawXP = _settingsBox.get('lifetimeXP', defaultValue: 0);
    int xp = 0;
    if (rawXP is int) {
      xp = rawXP;
    } else if (rawXP is double) {
      xp = rawXP.toInt();
    }

    final rawWallet = _settingsBox.get('walletXP', defaultValue: 0);
    int wallet = 0;
    if (rawWallet is int) {
      wallet = rawWallet;
    } else if (rawWallet is double) {
      wallet = rawWallet.toInt();
    }

    xp += 5;
    wallet += 5;

    await _settingsBox.put('lifetimeXP', xp);
    await _settingsBox.put('walletXP', wallet);
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