import 'dart:math' as math;

/// Attribute Effect System (Phase 3 - System Ownership foundation)
///
/// These functions convert player attributes into gameplay modifiers:
/// - FOCUS: reduces directive duration
/// - INTELLIGENCE: increases XP gained from completions
/// - DISCIPLINE: reduces wallet-only penalties
class AttributeEffects {
  AttributeEffects._();

  /// Focus reduces directive duration by up to 20%.
  static double focusDurationReductionFraction(int focus) {
    // 2% per focus point, capped at 20%.
    return (focus * 0.02).clamp(0.0, 0.20);
  }

  /// Intelligence increases earned XP by up to 25%.
  static double intelligenceXpGainMultiplier(int intelligence) {
    // 2% per intelligence point, capped at 25% bonus.
    final bonus = (intelligence * 0.02).clamp(0.0, 0.25);
    return 1.0 + bonus;
  }

  /// Discipline reduces penalties by up to 25%.
  static double disciplinePenaltyReductionFraction(int discipline) {
    // 2% per discipline point, capped at 25%.
    return (discipline * 0.02).clamp(0.0, 0.25);
  }

  static int applyPenaltyReduction(int baseAmount, int discipline) {
    if (baseAmount <= 0) return 0;
    final reduction = disciplinePenaltyReductionFraction(discipline);
    final effective = (baseAmount * (1.0 - reduction)).ceil();
    return math.max(0, effective);
  }
}

