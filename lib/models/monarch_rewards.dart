/// Monarch Integration reward constants and quest lock states.
///
/// This file defines the stat reward amounts for completing each growth pillar,
/// the penalty zone duration, and the quest lock state enum.
class MonarchRewards {
  /// STR stat points awarded per Physical Foundation completion.
  static const int strPerPhysicalCompletion = 3;

  /// INT stat points awarded per Technical Quest completion.
  static const int intPerTechnicalCompletion = 3;

  /// PER stat points awarded per Cognitive Quest completion.
  static const int perPerCognitiveCompletion = 3;

  /// Stat points awarded when Limiter Removal is triggered (200% overload).
  static const int statPointsPerLimiterRemoval = 5;

  /// Duration in hours for the Penalty Zone lockout.
  static const int penaltyZoneDurationHours = 4;
}

/// Quest lock state for Cognitive and Technical quests.
///
/// - [unlocked]: Quest is in Input Mode, user can configure it.
/// - [locked]: Quest has been locked at midnight and cannot be edited.
/// - [completed]: Quest has been completed by the Hunter.
enum QuestLockState {
  unlocked,
  locked,
  completed,
}
