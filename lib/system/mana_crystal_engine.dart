// ============================================================
//  MANA CRYSTAL ENGINE — Arise OS
//
//  Mana Crystals are elite hard currency earned ONLY through
//  extreme discipline feats. They are rank-gated + PER-scaled.
//
//  Earn sources:
//    1. Limiter Removal (≥200% physical): +1 crystal
//    2. 7-day perfect streak milestone:   +5 crystals
//    3. Every 10th technical completion:  +3 crystals
//
//  Capacity rules:
//    Base capacity is rank-gated.
//    PER stat adds +1 per point above 10.
// ============================================================

/// Event fired when a Mana Crystal is awarded.
class CrystalAwardEvent {
  final int amount;
  final String reason;
  final bool wasCapHit;

  const CrystalAwardEvent({
    required this.amount,
    required this.reason,
    this.wasCapHit = false,
  });
}

class ManaCrystalEngine {
  ManaCrystalEngine._();

  // Rank-gated base capacities
  static const Map<String, int> _rankBaseCap = {
    'E': 5,
    'D': 15,
    'C': 30,
    'B': 50,
    'A': 75,
    'S': 100,
    'GOD': 150,
  };

  /// Computes the maximum Mana Crystals a player can hold.
  ///
  /// MaxCrystals = rankBaseCap + max(0, PER - 10)
  static int computeMaxCrystals({
    required String rank,
    required int per,
  }) {
    final base = _rankBaseCap[rank] ?? 5;
    final perBonus = (per - 10).clamp(0, 50); // extra from PER
    return base + perBonus;
  }

  /// Crystal earn amounts per source.
  static const int limiterRemovalAward = 1;
  static const int weekStreakAward = 5;
  static const int technicalMilestoneAward = 3;

  /// Crystal spending costs.
  static const int restorationPotionCost = 10;
  static const int runeStonneCost = 5;
  static const int crystalSurgeCost = 3;

  /// Returns the label for a crystal count display.
  static String crystalLabel(int current, int max) =>
      '$current / $max';
}
