// ============================================================
//  DAILY QUEST ENGINE — generates 4 quests from HunterProfile
// ============================================================

import '../models/daily_quest.dart';
import '../models/hunter_profile.dart';

class DailyQuestEngine {
  // Base targets by experience level
  static const Map<String, Map<String, num>> _baseTargets = {
    'beginner': {
      'pushups': 50,
      'situps': 50,
      'squats': 50,
      'running': 3.0,
    },
    'intermediate': {
      'pushups': 100,
      'situps': 100,
      'squats': 100,
      'running': 5.0,
    },
    'advanced': {
      'pushups': 150,
      'situps': 150,
      'squats': 150,
      'running': 10.0,
    },
  };

  // XP rewards per experience level
  static const Map<String, int> _xpMultiplier = {
    'beginner': 50,
    'intermediate': 75,
    'advanced': 100,
  };

  /// Generates exactly 4 quests from the profile.
  /// Returns empty list on rest days.
  static List<DailyQuest> generate(HunterProfile profile) {
    if (!profile.isTrainingDay) return [];

    final lvl = profile.experienceLevel;
    final base = Map<String, num>.from(_baseTargets[lvl] ?? _baseTargets['beginner']!);
    final baseXP = _xpMultiplier[lvl] ?? 50;

    // Goal modifiers
    double pushMod = 1.0, squatMod = 1.0, runMod = 1.0;
    switch (profile.fitnessGoal) {
      case 'strength':
        pushMod = 1.2;
        squatMod = 1.2;
        break;
      case 'endurance':
        runMod = 1.3;
        break;
      case 'weight_loss':
        pushMod = 1.1;
        squatMod = 1.1;
        runMod = 1.1;
        break;
      case 'balance':
      default:
        break;
    }

    final pushTarget = (base['pushups']! * pushMod).round();
    final sitTarget  = base['situps']!.round();
    final squatTarget = (base['squats']! * squatMod).round();
    final runTarget  = double.parse(
        (base['running']! * runMod).toStringAsFixed(1));
    final runTargetInt = (runTarget * 10).round(); // store as 0.1km units

    return [
      DailyQuest(
        id: 'pushups',
        title: 'Push-ups',
        statAffected: 'STR',
        target: pushTarget,
        unit: 'reps',
        xpReward: baseXP,
        xpPenalty: (baseXP * 1.5).round(),
      ),
      DailyQuest(
        id: 'situps',
        title: 'Sit-ups',
        statAffected: 'VIT',
        target: sitTarget,
        unit: 'reps',
        xpReward: baseXP,
        xpPenalty: (baseXP * 1.5).round(),
      ),
      DailyQuest(
        id: 'squats',
        title: 'Squats',
        statAffected: 'AGI',
        target: squatTarget,
        unit: 'reps',
        xpReward: baseXP,
        xpPenalty: (baseXP * 1.5).round(),
      ),
      DailyQuest(
        id: 'running',
        title: 'Running',
        statAffected: 'AGI',
        target: runTargetInt, // stored as 0.1km units for integer precision
        unit: '0.1km',
        xpReward: (baseXP * 1.2).round(),
        xpPenalty: (baseXP * 2.0).round(),
      ),
    ];
  }

  /// Display label for running progress (converts internal 0.1km to km string)
  static String runLabel(int progress, int target) {
    final p = (progress / 10).toStringAsFixed(1);
    final t = (target / 10).toStringAsFixed(1);
    return '$p / ${t}km';
  }

  /// Increment amount per tap for a quest
  static int incrementFor(String questId) {
    switch (questId) {
      case 'running': return 5;  // +0.5km per tap
      default: return 10;        // +10 reps per tap
    }
  }
}
