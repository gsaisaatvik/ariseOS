import 'dart:math' as math;

import '../services/hive_service.dart';

/// Adaptive Directive System (Phase 2)
///
/// - Tracks per-directive performance metrics (completions, aborts, streak)
/// - Stores adaptive state:
///   { baseDuration, currentDuration, difficultyLevel }
/// - Updates `currentDuration` only when the daily engine applies changes.
class AdaptiveDirectiveEngine {
  AdaptiveDirectiveEngine._();

  // Base durations (seconds) — derived from the original fixed Phase 1 setup.
  static const Map<String, int> _baseDurationSeconds = {
    'strength': 30 * 60,
    'deep_work': 90 * 60,
    'skill': 50 * 60,
  };

  static const String _hiveLastAppliedDateUtcKey =
      'adaptiveDirectiveLastAppliedDateUtc';
  static const String _hiveCoachBiasKey = 'adaptiveDirectiveCoachBiasFactor';

  static String _key(String directiveId, String field) =>
      'adaptiveDirective_${directiveId}_$field';

  static int _baseFor(String directiveId) =>
      _baseDurationSeconds[directiveId] ?? (90 * 60);

  static void _ensureSeeded(String directiveId) {
    final settings = HiveService.settings;

    final baseKey = _key(directiveId, 'baseSecs');
    final currentKey = _key(directiveId, 'currentSecs');
    final difficultyKey = _key(directiveId, 'difficultyLevel');

    final completionsKey = _key(directiveId, 'totalCompletions');
    final failuresKey = _key(directiveId, 'totalFailures');
    final completionTimeSumKey = _key(directiveId, 'completionTimeSumSecs');
    final completionTimeAvgKey = _key(directiveId, 'completionTimeAvgSecs');

    final successStreakKey = _key(directiveId, 'successStreak');
    final failureStreakKey = _key(directiveId, 'failureStreak');

    final baseSecs = _baseFor(directiveId);

    if (!settings.containsKey(baseKey)) settings.put(baseKey, baseSecs);
    if (!settings.containsKey(currentKey)) settings.put(currentKey, baseSecs);
    if (!settings.containsKey(difficultyKey)) settings.put(difficultyKey, 1);

    if (!settings.containsKey(completionsKey)) settings.put(completionsKey, 0);
    if (!settings.containsKey(failuresKey)) settings.put(failuresKey, 0);
    if (!settings.containsKey(completionTimeSumKey)) {
      settings.put(completionTimeSumKey, 0);
    }
    if (!settings.containsKey(completionTimeAvgKey)) {
      settings.put(completionTimeAvgKey, 0);
    }

    if (!settings.containsKey(successStreakKey)) settings.put(successStreakKey, 0);
    if (!settings.containsKey(failureStreakKey)) settings.put(failureStreakKey, 0);
  }

  static double coachBiasFactor() {
    final raw = HiveService.settings.get(_hiveCoachBiasKey, defaultValue: 1.0);
    if (raw is int) return raw.toDouble();
    if (raw is double) return raw;
    if (raw is num) return raw.toDouble();
    return 1.0;
  }

  static void setCoachBiasFactor(double factor) {
    HiveService.settings.put(_hiveCoachBiasKey, factor);
  }

  static int currentDurationSeconds(String directiveId) {
    _ensureSeeded(directiveId);
    return HiveService.settings.get(
      _key(directiveId, 'currentSecs'),
      defaultValue: _baseFor(directiveId),
    ) as int;
  }

  static int baseDurationSeconds(String directiveId) {
    _ensureSeeded(directiveId);
    return HiveService.settings.get(
      _key(directiveId, 'baseSecs'),
      defaultValue: _baseFor(directiveId),
    ) as int;
  }

  static int difficultyLevel(String directiveId) {
    _ensureSeeded(directiveId);
    return HiveService.settings.get(
      _key(directiveId, 'difficultyLevel'),
      defaultValue: 1,
    ) as int;
  }

  static int failureStreak(String directiveId) {
    _ensureSeeded(directiveId);
    return HiveService.settings.get(
      _key(directiveId, 'failureStreak'),
      defaultValue: 0,
    ) as int;
  }

  static bool isUnstable(String directiveId) {
    // "Repeated aborts" => failure streak threshold.
    return failureStreak(directiveId) >= 2;
  }

  static void recordCompletion({
    required String directiveId,
    required int completionMinutes,
  }) {
    _ensureSeeded(directiveId);
    final settings = HiveService.settings;

    final completionsKey = _key(directiveId, 'totalCompletions');
    final completionTimeSumKey = _key(directiveId, 'completionTimeSumSecs');
    final completionTimeAvgKey = _key(directiveId, 'completionTimeAvgSecs');
    final successStreakKey = _key(directiveId, 'successStreak');
    final failureStreakKey = _key(directiveId, 'failureStreak');

    final prevCompletions =
        settings.get(completionsKey, defaultValue: 0) as int;
    final prevSum = settings.get(completionTimeSumKey, defaultValue: 0) as int;

    final newCompletions = prevCompletions + 1;
    final newSum = prevSum + (completionMinutes * 60);
    settings.put(completionsKey, newCompletions);
    settings.put(completionTimeSumKey, newSum);
    settings.put(
      completionTimeAvgKey,
      newCompletions > 0 ? (newSum / newCompletions).floor() : 0,
    );

    // A completion breaks the failure streak and extends success streak.
    settings.put(successStreakKey, (settings.get(successStreakKey, defaultValue: 0) as int) + 1);
    settings.put(failureStreakKey, 0);
  }

  static void recordAbort({
    required String directiveId,
  }) {
    _ensureSeeded(directiveId);
    final settings = HiveService.settings;

    final failuresKey = _key(directiveId, 'totalFailures');
    final successStreakKey = _key(directiveId, 'successStreak');
    final failureStreakKey = _key(directiveId, 'failureStreak');

    final prevFailures = settings.get(failuresKey, defaultValue: 0) as int;
    final prevFailureStreak =
        settings.get(failureStreakKey, defaultValue: 0) as int;

    settings.put(failuresKey, prevFailures + 1);
    settings.put(successStreakKey, 0);
    settings.put(failureStreakKey, prevFailureStreakStreakSafe(prevFailureStreak));
  }

  // Small helper to keep recordAbort logic readable.
  static int prevFailureStreakStreakSafe(int prevFailureStreak) => prevFailureStreak + 1;

  /// Applies adaptation daily (once per UTC day).
  /// Returns whether any directive duration changed.
  static bool applyDailyDirectiveAdaptationIfDue() {
    final now = DateTime.now().toUtc();
    final dayStr = now.toIso8601String().substring(0, 10); // YYYY-MM-DD
    final settings = HiveService.settings;

    final lastApplied =
        settings.get(_hiveLastAppliedDateUtcKey, defaultValue: '') as String;
    if (lastApplied == dayStr) return false;

    bool changedAny = false;

    for (final directiveId in _baseDurationSeconds.keys) {
      _ensureSeeded(directiveId);

      final completionsKey = _key(directiveId, 'totalCompletions');
      final failuresKey = _key(directiveId, 'totalFailures');
      final completionTimeSumKey = _key(directiveId, 'completionTimeSumSecs');

      final successStreakKey = _key(directiveId, 'successStreak');
      final failureStreakKey = _key(directiveId, 'failureStreak');

      final currentKey = _key(directiveId, 'currentSecs');
      final difficultyKey = _key(directiveId, 'difficultyLevel');
      final baseKey = _key(directiveId, 'baseSecs');

      final completions =
          settings.get(completionsKey, defaultValue: 0) as int;
      final failures = settings.get(failuresKey, defaultValue: 0) as int;

      final total = completions + failures;
      if (total <= 0) continue;

      final completionRate = completions / total;

      final successStreak =
          settings.get(successStreakKey, defaultValue: 0) as int;
      final failureStreak =
          settings.get(failureStreakKey, defaultValue: 0) as int;

      final currentSecs =
          settings.get(currentKey, defaultValue: _baseFor(directiveId)) as int;
      final baseSecs =
          settings.get(baseKey, defaultValue: _baseFor(directiveId)) as int;
      final difficulty =
          settings.get(difficultyKey, defaultValue: 1) as int;

      // Track average completion time (not used yet, but stored as required).
      // This is intentionally computed here to keep metrics consistent.
      final completionSum =
          settings.get(completionTimeSumKey, defaultValue: 0) as int;
      final avgCompletionSecs =
          completions > 0 ? (completionSum / completions).floor() : 0;

      double newDurationSecs = currentSecs.toDouble();
      int newDifficulty = difficulty;

      // Rule A: completion rate low -> reduce duration by 20%
      if (completionRate < 0.50) {
        newDurationSecs = newDurationSecs * 0.8;
        newDifficulty = math.max(0, newDifficulty - 1);
      }

      // Rule B: high completion rate + streak -> increase duration 10-15%
      if (completionRate > 0.80 && successStreak >= 3) {
        final factor = successStreak >= 5
            ? 1.15
            : successStreak >= 4
                ? 1.13
                : 1.10;
        newDurationSecs = newDurationSecs * factor;
        newDifficulty = newDifficulty + 1;
      }

      // Rule C: repeated aborts -> reduce duration OR mark unstable
      if (failureStreak >= 2) {
        newDurationSecs = newDurationSecs * 0.85;
        newDifficulty = math.max(0, newDifficulty - 1);
      }

      // Coach bias (daily): system-wide multiplier that reflects observed behavior.
      final coach = coachBiasFactor();
      if (coach != 1.0) {
        newDurationSecs = newDurationSecs * coach;
      }

      // Safety bounds: keep it within a reasonable envelope.
      final minSecs = (baseSecs * 0.40).round();
      final maxSecs = (baseSecs * 1.50).round();
      final clampedSecs =
          newDurationSecs.clamp(minSecs.toDouble(), maxSecs.toDouble()).round();

      if (clampedSecs != currentSecs) {
        settings.put(currentKey, clampedSecs);
        changedAny = true;
      }

      if (newDifficulty != difficulty) {
        settings.put(difficultyKey, math.max(0, newDifficulty));
      }

      // If directives go unstable repeatedly, difficulty will keep collapsing
      // (system-wise "unstable" behavior is reflected in lower durations).
      // Metric is tracked via sum+count; computed here to satisfy "average
      // completion time" tracking without changing adaptation logic.
      avgCompletionSecs;
    }

    settings.put(_hiveLastAppliedDateUtcKey, dayStr);
    return changedAny;
  }

  static ({int completions, int failures}) aggregateTotals() {
    int c = 0;
    int f = 0;
    final settings = HiveService.settings;
    for (final directiveId in _baseDurationSeconds.keys) {
      _ensureSeeded(directiveId);
      c += settings.get(_key(directiveId, 'totalCompletions'),
              defaultValue: 0) as int;
      f += settings.get(_key(directiveId, 'totalFailures'),
              defaultValue: 0) as int;
    }
    return (completions: c, failures: f);
  }
}


