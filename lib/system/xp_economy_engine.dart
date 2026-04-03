import 'dart:math' as math;

import 'health_system.dart';

class XpEconomyEngine {
  XpEconomyEngine._();

  // Config (extensible).
  static const double maxStreakBonus = 0.30;
  static const double streakBonusPerDay = 0.02;

  static const int inflationSoftCapWallet = 12000;
  static const double inflationMinFactor = 0.60;

  static double streakMultiplier(int streakDays) {
    if (streakDays <= 0) return 1.0;
    final bonus = (streakDays * streakBonusPerDay).clamp(0.0, maxStreakBonus);
    return 1.0 + bonus;
  }

  static double inflationGuardFactor(int walletXp) {
    if (walletXp <= inflationSoftCapWallet) return 1.0;
    final over = walletXp - inflationSoftCapWallet;
    // Smooth decay: asymptotically approaches min factor.
    final decay = 1.0 / (1.0 + (over / 20000.0));
    return math.max(inflationMinFactor, decay);
  }

  static int computeDirectiveXp({
    required int baseXp,
    required int minutes,
    required double timeMultiplier,
    required double intelligenceMultiplier,
    required bool intelBurst,
    required int streakDays,
    required HealthZone healthZone,
    required int walletXp,
  }) {
    var raw = (baseXp * timeMultiplier).ceil();
    raw = (raw * intelligenceMultiplier).round();
    if (intelBurst) raw *= 2;

    raw = (raw * streakMultiplier(streakDays)).round();
    raw = (raw * HealthSystem.rewardMultiplier(healthZone)).round();
    raw = (raw * inflationGuardFactor(walletXp)).round();
    return math.max(0, raw);
  }

  static int computeStudyXp({
    required int minutes,
    required int sessionsToday,
    required double intelligenceMultiplier,
    required int streakDays,
    required HealthZone healthZone,
    required int walletXp,
  }) {
    double rate;
    if (sessionsToday == 0) {
      rate = 10;
    } else if (sessionsToday == 1) {
      rate = 5;
    } else {
      rate = 2.5;
    }

    var raw = (minutes * rate).ceil();
    raw = (raw * intelligenceMultiplier).round();
    raw = (raw * streakMultiplier(streakDays)).round();
    raw = (raw * HealthSystem.rewardMultiplier(healthZone)).round();
    raw = (raw * inflationGuardFactor(walletXp)).round();
    return math.max(0, raw);
  }
}

