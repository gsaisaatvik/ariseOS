class LevelUpEvent {
  LevelUpEvent({
    required this.fromLevel,
    required this.toLevel,
    required this.attributePointsGained,
    required this.systemVoiceLine,
    this.newlyUnlockedAbilityName,
    this.nextSystemAbilityUnlockLevel,
  });

  final int fromLevel;
  final int toLevel;
  final int attributePointsGained;
  final String systemVoiceLine;

  /// Optional system ability unlock (for the overlay).
  final String? newlyUnlockedAbilityName;

  /// Optional next system ability unlock preview.
  final int? nextSystemAbilityUnlockLevel;
}

