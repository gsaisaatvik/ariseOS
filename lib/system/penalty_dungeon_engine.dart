// ============================================================
//  PENALTY DUNGEON ENGINE — maps failed quests to recovery challenges
// ============================================================

import '../models/daily_quest.dart';

class PenaltyChallenge {
  final String questId;       // which quest triggered this
  final String title;         // e.g. 'IRON PENANCE'
  final String description;   // readable task
  final String unit;          // 'reps' | 'min'
  final int targetReps;       // completion target
  final int xpRecovery;       // XP regained on completion (50% of lost)

  const PenaltyChallenge({
    required this.questId,
    required this.title,
    required this.description,
    required this.unit,
    required this.targetReps,
    required this.xpRecovery,
  });
}

class PenaltyDungeonEngine {
  static PenaltyChallenge forQuest(DailyQuest failed) {
    switch (failed.id) {
      case 'pushups':
        return PenaltyChallenge(
          questId: failed.id,
          title: 'IRON PENANCE',
          description: 'Complete burpees to prove your will.',
          unit: 'reps',
          targetReps: 20,
          xpRecovery: (failed.xpPenalty * 0.5).round(),
        );
      case 'situps':
        return PenaltyChallenge(
          questId: failed.id,
          title: 'CORE RECKONING',
          description: 'Complete leg raises to reclaim your discipline.',
          unit: 'reps',
          targetReps: 30,
          xpRecovery: (failed.xpPenalty * 0.5).round(),
        );
      case 'squats':
        return PenaltyChallenge(
          questId: failed.id,
          title: 'SHADOW DESCENT',
          description: 'Complete jump squats — embrace the burn.',
          unit: 'reps',
          targetReps: 25,
          xpRecovery: (failed.xpPenalty * 0.5).round(),
        );
      case 'running':
        return PenaltyChallenge(
          questId: failed.id,
          title: 'FORCED MARCH',
          description: 'Walk briskly for the required duration.',
          unit: 'min',
          targetReps: 20,
          xpRecovery: (failed.xpPenalty * 0.5).round(),
        );
      default:
        return PenaltyChallenge(
          questId: failed.id,
          title: 'SYSTEM PENANCE',
          description: 'Complete this challenge to recover lost XP.',
          unit: 'reps',
          targetReps: 20,
          xpRecovery: (failed.xpPenalty * 0.5).round(),
        );
    }
  }

  /// Generate challenges for multiple failed quests
  static List<PenaltyChallenge> forFailedQuests(List<DailyQuest> failed) =>
      failed.where((q) => q.failed).map(forQuest).toList();
}
