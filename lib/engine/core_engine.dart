import 'package:hive/hive.dart';
import '../models/core_quest.dart';

class CoreEngine {
  final Box<CoreQuest> _coreBox;
  final Box _settingsBox;

  // Phase 1.5: Guard to prevent double-reset in same session
  bool _questsResetToday = false;

  CoreEngine(this._coreBox, this._settingsBox);

  // Phase 1.5: penaltyActive getter removed as source of truth.
  // Kept as read-only for backward compat — always returns false now.
  bool get penaltyActive => false;

  // Phase 1.5: streak getter removed as source of truth.
  // PlayerProvider.streakDays is the single source. Returns 0 for safety.
  int get streak => 0;

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

  /// 🔥 AUTO CHECK IF NEW DAY — Phase 1.5: neutralized streak/penalty evaluation
  /// Only triggers quest reset via resetForNextDay().
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
      // Phase 1.5: Only reset quests, no streak/penalty evaluation
      _questsResetToday = false; // New day detected — allow reset
      await _resetIfNeeded();
      await _settingsBox.put('lastEvaluationDateUtc', todayUtcString);
    }
  }

  /// Phase 1.5: Guarded quest reset — only fires once per day per session
  Future<void> _resetIfNeeded() async {
    if (_questsResetToday) return; // Already reset this session
    await resetForNextDay();
    _questsResetToday = true;
  }

  /// 🔥 RESET QUESTS
  Future<void> resetForNextDay() async {
    await _coreBox.clear();

    await _coreBox.addAll([
      CoreQuest(
        id: 'strength',
        name: 'Strength / Physical',
        date: DateTime.now(),
      ),
      CoreQuest(
        id: 'deep_work',
        name: 'Deep Work (90 min)',
        date: DateTime.now(),
      ),
      CoreQuest(
        id: 'skill',
        name: 'Skill (DSA / Study)',
        date: DateTime.now(),
      ),
    ]);
  }

  Future<void> clearPenalty() async {
    // Phase 1.5: No-op — penaltyActive no longer managed by CoreEngine.
    // Penalty state is derived from PlayerProvider.isRestricted (walletXP < 0).
  }

  /// 🔥 MIDNIGHT JUDGEMENT — Monarch Integration (Task 4.1)
  /// 
  /// Called at 00:00 local time to evaluate Physical Foundation completion
  /// and apply consequences/rewards.
  /// 
  /// Flow:
  /// 1. Compute physicalCompletionPct from PlayerProvider
  /// 2. If < 1.0 (100%): activate Penalty Zone (4-hour lockout)
  /// 3. If >= 1.0: record day as cleared (extend streak)
  /// 4. Reset all Physical Foundation progress to 0
  /// 5. Lock Cognitive and Technical quests for the new day
  /// 
  /// Requirements: 3.1, 3.2, 3.3, 3.4, 3.5
  Future<void> runMidnightJudgement(dynamic player) async {
    // Compute Physical Foundation completion percentage
    final pct = player.physicalCompletionPct;
    
    // Apply penalty or reward based on completion
    if (pct < 1.0) {
      // Physical Foundation not complete — activate Penalty Zone
      player.activatePenaltyZone();
    } else {
      // Physical Foundation complete — record day cleared
      player.recordDayCleared();
    }
    
    // Reset Physical Foundation progress for the new day
    player.resetPhysicalProgress();
    
    // Lock mandatory quests for the new day
    player.lockMandatoryQuests();
  }
}