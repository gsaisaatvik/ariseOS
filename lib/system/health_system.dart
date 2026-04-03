enum HealthZone {
  stable,
  warning,
  critical,
  collapse,
}

class HealthSystem {
  HealthSystem._();

  static const int defaultMaxHp = 100;

  // HP deltas (configurable constants).
  static const int lossOnAbort = 8;
  static const int lossOnSin = 6;
  static const int lossOnRedemption = 4;
  static const int lossOnMiss = 10;

  static const int recoveryOnDirectiveComplete = 4;
  static const int recoveryOnStudyComplete = 2;
  static const int recoveryOnStreakExtend = 3;

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

