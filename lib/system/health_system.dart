enum HealthZone {
  stable,
  warning,
  critical,
  collapse,
}

class HealthSystem {
  HealthSystem._();

  static const int defaultMaxHp = 100;
  static const int baseVitality = 10;
  static const int hpPerVitalityPoint = 5;

  // HP deltas (configurable constants).
  static const int lossOnAbort = 8;
  static const int lossOnSin = 6;
  static const int lossOnRedemption = 4;
  static const int lossOnMiss = 10;

  /// Computes the maximum HP based on the player's Vitality stat.
  ///
  /// Formula: MaxHP = 100 + (VIT - 10) × 5
  /// At VIT=10 (base): MaxHP = 100
  /// At VIT=20: MaxHP = 150
  /// At VIT=50: MaxHP = 300
  static int computeMaxHp(int vitality) {
    final bonus = (vitality - baseVitality).clamp(0, 200) * hpPerVitalityPoint;
    return defaultMaxHp + bonus;
  }

  static const int recoveryOnDirectiveComplete = 4;
  static const int recoveryOnStudyComplete = 2;
  static const int recoveryOnStreakExtend = 3;
  static const int recoveryOnPhysicalComplete = 10; // full physical quest cleared

  static HealthZone zoneFor(int hp, int maxHp) {
    // V1 visible states:
    // - Stable: >60
    // - Warning: 31–60
    // - Critical/Collapse: 0–30 and below
    if (maxHp <= 0) return HealthZone.collapse;
    if (hp <= 0) return HealthZone.collapse;
    if (hp <= 30) return HealthZone.critical;
    if (hp <= 60) return HealthZone.warning;
    return HealthZone.stable;
  }

  static double rewardMultiplier(HealthZone zone) {
    switch (zone) {
      case HealthZone.stable:
        return 1.00;
      case HealthZone.warning:
        return 0.92;
      case HealthZone.critical:
        return 0.80;
      case HealthZone.collapse:
        return 0.65;
    }
  }

  static double penaltyMultiplier(HealthZone zone) {
    switch (zone) {
      case HealthZone.stable:
        return 1.00;
      case HealthZone.warning:
        return 1.12;
      case HealthZone.critical:
        return 1.30;
      case HealthZone.collapse:
        return 1.45;
    }
  }

  static String zoneLabel(HealthZone zone) {
    switch (zone) {
      case HealthZone.stable:
        return 'STABLE';
      case HealthZone.warning:
        return 'WARNING';
      case HealthZone.critical:
        return 'CRITICAL';
      case HealthZone.collapse:
        return 'COLLAPSE';
    }
  }
}

