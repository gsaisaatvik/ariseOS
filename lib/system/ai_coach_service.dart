import '../system/health_system.dart';
import '../system/adaptive_directive_engine.dart';

enum CoachTone {
  praise,
  neutral,
  harsh,
}

class CoachOutput {
  CoachOutput({
    required this.title,
    required this.message,
    required this.tone,
    required this.durationBiasFactor,
  });

  final String title;
  final String message;
  final CoachTone tone;

  /// Multiplier applied during daily adaptive duration update.
  /// <1.0 makes directives shorter; >1.0 makes longer.
  final double durationBiasFactor;
}

class AICoachService {
  AICoachService._();

  static CoachOutput generateDailyCoach({
    required int streakDays,
    required HealthZone healthZone,
  }) {
    final totals = AdaptiveDirectiveEngine.aggregateTotals();
    final total = totals.completions + totals.failures;
    final completionRate =
        total <= 0 ? 0.50 : (totals.completions / total).clamp(0.0, 1.0);

    // Default: neutral, no bias.
    var bias = 1.0;
    CoachTone tone = CoachTone.neutral;
    String title = 'SYSTEM COACH';
    String msg = 'Baseline maintained. Continue execution.';

    // HP zone heavily influences coach stance.
    if (healthZone == HealthZone.collapse) {
      tone = CoachTone.harsh;
      bias = 0.90;
      msg = 'System collapse detected. Reducing expectations to restore stability.';
    } else if (healthZone == HealthZone.critical) {
      tone = CoachTone.harsh;
      bias = 0.92;
      msg = 'Vitals critical. Adjusting difficulty downward to prevent total failure.';
    }

    // Performance-based bias.
    if (completionRate < 0.50) {
      tone = CoachTone.harsh;
      bias = bias * 0.90;
      msg = 'Performance declining. Adjusting expectations.';
    } else if (completionRate > 0.80 && streakDays >= 3) {
      tone = CoachTone.praise;
      bias = bias * 1.08;
      msg = 'Consistency detected. Increasing difficulty.';
    } else if (completionRate > 0.65 && streakDays >= 2) {
      tone = CoachTone.neutral;
      bias = bias * 1.03;
      msg = 'Progress detected. Maintain pace.';
    }

    // Clamp to a safe envelope (extensible).
    bias = bias.clamp(0.85, 1.12);

    return CoachOutput(
      title: title,
      message: msg,
      tone: tone,
      durationBiasFactor: bias,
    );
  }
}

