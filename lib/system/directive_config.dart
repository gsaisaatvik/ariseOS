import 'adaptive_directive_engine.dart';

/// Single active directive + per-type durations (system authority).
///
/// Phase 2: durations are adaptive (see `AdaptiveDirectiveEngine`).
class DirectiveConfig {
  DirectiveConfig._();

  /// Target session length in seconds (must match Hive timer progress).
  static int durationSeconds(String questId) {
    return AdaptiveDirectiveEngine.currentDurationSeconds(questId);
  }

  /// Human-readable for UI (commitment dialog + timer hint).
  static String durationLabel(String questId) {
    final secs = durationSeconds(questId);
    final mins = (secs / 60).round();
    final unstable = AdaptiveDirectiveEngine.isUnstable(questId);
    return unstable ? '$mins min (UNSTABLE)' : '$mins min';
  }

  static const String hiveLockKey = 'systemActiveDirectiveId';
}
