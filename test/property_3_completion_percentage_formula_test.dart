import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:arise_os/models/physical_foundation.dart';

/// Property 3: Physical completion percentage formula
/// **Validates: Requirements 1.6**
/// 
/// For any four non-negative progress values (pushups, situps, squats, running),
/// the displayed completion percentage shall equal mean([min(p/t, 1.0) for each sub-task]),
/// where t is the target for each sub-task.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property 3: Physical completion percentage formula', () {
    final random = Random();
    
    // The four sub-task keys and their targets as specified in the design
    final targets = PhysicalFoundation.targets;
    final subTaskKeys = targets.keys.toList();

    /// Helper function to compute the expected completion percentage
    /// using the formula: mean([min(p/t, 1.0) for each sub-task])
    double computeExpectedCompletionPct(Map<String, int> progress) {
      if (targets.isEmpty) return 0.0;
      
      double sum = 0.0;
      for (final entry in targets.entries) {
        final progressValue = progress[entry.key] ?? 0;
        final ratio = (progressValue / entry.value).clamp(0.0, 1.0);
        sum += ratio;
      }
      
      return sum / targets.length;
    }

    test('Completion percentage formula - 100 iterations', () {
      // Run minimum 100 iterations as specified in the task
      for (int iteration = 0; iteration < 100; iteration++) {
        // Generate 4 random ints in [0, 300] as specified in the task
        final progress = <String, int>{};
        for (final key in subTaskKeys) {
          progress[key] = random.nextInt(301); // 0 to 300 inclusive
        }
        
        // Compute the actual completion percentage using PhysicalFoundation
        final actualPct = PhysicalFoundation.completionPct(progress);
        
        // Compute the expected completion percentage using the formula
        final expectedPct = computeExpectedCompletionPct(progress);
        
        // Assert they are equal (with floating point tolerance)
        expect(
          actualPct,
          closeTo(expectedPct, 0.0001),
          reason: 'Iteration $iteration: Progress values: $progress\n'
                  'Expected completion pct: $expectedPct\n'
                  'Actual completion pct: $actualPct',
        );
      }
    });

    test('Completion percentage formula - edge cases', () {
      final edgeCases = [
        // All zeros
        {'Push-ups': 0, 'Sit-ups': 0, 'Squats': 0, 'Running': 0},
        
        // All at target (100%)
        {'Push-ups': 100, 'Sit-ups': 100, 'Squats': 100, 'Running': 10},
        
        // All at 200% (Limiter Removal threshold)
        {'Push-ups': 200, 'Sit-ups': 200, 'Squats': 200, 'Running': 20},
        
        // All at 300% (maximum test range)
        {'Push-ups': 300, 'Sit-ups': 300, 'Squats': 300, 'Running': 30},
        
        // Mixed values - some below, some at, some above target
        {'Push-ups': 50, 'Sit-ups': 100, 'Squats': 150, 'Running': 5},
        
        // One at target, rest at zero
        {'Push-ups': 100, 'Sit-ups': 0, 'Squats': 0, 'Running': 0},
        
        // One above target, rest at zero
        {'Push-ups': 0, 'Sit-ups': 0, 'Squats': 0, 'Running': 20},
        
        // All just below target
        {'Push-ups': 99, 'Sit-ups': 99, 'Squats': 99, 'Running': 9},
        
        // All just above target
        {'Push-ups': 101, 'Sit-ups': 101, 'Squats': 101, 'Running': 11},
      ];

      for (int i = 0; i < edgeCases.length; i++) {
        final progress = edgeCases[i];
        final actualPct = PhysicalFoundation.completionPct(progress);
        final expectedPct = computeExpectedCompletionPct(progress);
        
        expect(
          actualPct,
          closeTo(expectedPct, 0.0001),
          reason: 'Edge case $i: Progress values: $progress\n'
                  'Expected completion pct: $expectedPct\n'
                  'Actual completion pct: $actualPct',
        );
      }
    });

    test('Completion percentage formula - clamping behavior', () {
      // Test that values above target are clamped to 1.0 in the ratio calculation
      final overloadProgress = {
        'Push-ups': 500,  // 500% of target
        'Sit-ups': 500,   // 500% of target
        'Squats': 500,    // 500% of target
        'Running': 50,    // 500% of target
      };
      
      final actualPct = PhysicalFoundation.completionPct(overloadProgress);
      
      // Expected: each ratio is clamped to 1.0, so mean = (1.0 + 1.0 + 1.0 + 1.0) / 4 = 1.0
      expect(
        actualPct,
        equals(1.0),
        reason: 'Overload progress should result in 100% completion (1.0) due to clamping',
      );
    });

    test('Completion percentage formula - partial progress', () {
      // Test various partial completion scenarios
      final partialCases = [
        // 25% average completion
        {'Push-ups': 25, 'Sit-ups': 25, 'Squats': 25, 'Running': 2},
        
        // 50% average completion
        {'Push-ups': 50, 'Sit-ups': 50, 'Squats': 50, 'Running': 5},
        
        // 75% average completion
        {'Push-ups': 75, 'Sit-ups': 75, 'Squats': 75, 'Running': 7},
        
        // Uneven distribution - still averages to ~50%
        {'Push-ups': 100, 'Sit-ups': 100, 'Squats': 0, 'Running': 0},
      ];

      for (int i = 0; i < partialCases.length; i++) {
        final progress = partialCases[i];
        final actualPct = PhysicalFoundation.completionPct(progress);
        final expectedPct = computeExpectedCompletionPct(progress);
        
        expect(
          actualPct,
          closeTo(expectedPct, 0.0001),
          reason: 'Partial case $i: Progress values: $progress\n'
                  'Expected completion pct: $expectedPct\n'
                  'Actual completion pct: $actualPct',
        );
      }
    });

    test('Completion percentage formula - missing keys', () {
      // Test behavior when some keys are missing from the progress map
      final incompleteMaps = [
        // Empty map
        <String, int>{},
        
        // Only one key
        {'Push-ups': 50},
        
        // Two keys
        {'Push-ups': 100, 'Sit-ups': 100},
        
        // Three keys
        {'Push-ups': 100, 'Sit-ups': 100, 'Squats': 100},
      ];

      for (int i = 0; i < incompleteMaps.length; i++) {
        final progress = incompleteMaps[i];
        final actualPct = PhysicalFoundation.completionPct(progress);
        final expectedPct = computeExpectedCompletionPct(progress);
        
        expect(
          actualPct,
          closeTo(expectedPct, 0.0001),
          reason: 'Incomplete map case $i: Progress values: $progress\n'
                  'Expected completion pct: $expectedPct\n'
                  'Actual completion pct: $actualPct\n'
                  'Missing keys should be treated as 0',
        );
      }
    });

    test('Completion percentage formula - random stress test', () {
      // Additional stress test with completely random values
      for (int iteration = 0; iteration < 200; iteration++) {
        final progress = <String, int>{};
        
        // Generate random values with wider range to test edge behaviors
        for (final key in subTaskKeys) {
          // Random value from 0 to 1000 to test extreme overload cases
          progress[key] = random.nextInt(1001);
        }
        
        final actualPct = PhysicalFoundation.completionPct(progress);
        final expectedPct = computeExpectedCompletionPct(progress);
        
        // Verify the result is in valid range [0.0, 1.0]
        expect(
          actualPct,
          inInclusiveRange(0.0, 1.0),
          reason: 'Completion percentage must be in range [0.0, 1.0]',
        );
        
        // Verify formula correctness
        expect(
          actualPct,
          closeTo(expectedPct, 0.0001),
          reason: 'Stress test iteration $iteration: Progress values: $progress\n'
                  'Expected completion pct: $expectedPct\n'
                  'Actual completion pct: $actualPct',
        );
      }
    });
  });
}
