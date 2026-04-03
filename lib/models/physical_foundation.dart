/// Physical Foundation model — compile-time constants and pure helper functions
/// for the hard-coded daily physical quest.
///
/// This model defines the immutable Physical Foundation targets and provides
/// utility functions for computing completion percentage and detecting
/// Limiter Removal conditions.
class PhysicalFoundation {
  /// The four fixed Physical Foundation sub-tasks with their target values.
  /// These targets are immutable and cannot be modified by any user action.
  static const Map<String, int> targets = {
    'Push-ups': 100,
    'Sit-ups': 100,
    'Squats': 100,
    'Running': 10, // km
  };

  /// Computes the aggregate completion percentage for the Physical Foundation.
  ///
  /// The completion percentage is calculated as the mean of the clamped ratios
  /// for each sub-task. Each ratio is computed as (progress / target) and
  /// clamped to the range [0.0, 1.0].
  ///
  /// Returns a value in the range [0.0, 1.0] where:
  /// - 0.0 = no progress on any sub-task
  /// - 1.0 = 100% completion (all targets met)
  /// - Values > 1.0 are not possible due to clamping
  ///
  /// Example:
  /// ```dart
  /// final progress = {'Push-ups': 50, 'Sit-ups': 100, 'Squats': 75, 'Running': 5};
  /// final pct = PhysicalFoundation.completionPct(progress);
  /// // pct = (0.5 + 1.0 + 0.75 + 0.5) / 4 = 0.6875
  /// ```
  static double completionPct(Map<String, int> progress) {
    if (targets.isEmpty) return 0.0;

    double sum = 0.0;
    for (final entry in targets.entries) {
      final progressValue = progress[entry.key] ?? 0;
      final ratio = (progressValue / entry.value).clamp(0.0, 1.0);
      sum += ratio;
    }

    return sum / targets.length;
  }

  /// Checks if the Limiter Removal condition is met.
  ///
  /// Returns true if and only if every Physical Foundation sub-task has
  /// progress >= 200% of its target value. This triggers the Secret Quest Event.
  ///
  /// Example:
  /// ```dart
  /// final progress = {'Push-ups': 200, 'Sit-ups': 210, 'Squats': 205, 'Running': 20};
  /// final removed = PhysicalFoundation.isLimiterRemoved(progress);
  /// // removed = true (all sub-tasks >= 200% of target)
  /// ```
  static bool isLimiterRemoved(Map<String, int> progress) {
    return targets.entries.every((entry) {
      final progressValue = progress[entry.key] ?? 0;
      return progressValue >= entry.value * 2;
    });
  }
}
