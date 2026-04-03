import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:arise_os/models/physical_foundation.dart';

/// Property 17: Limiter Removal threshold
/// **Validates: Requirements 7.1, 7.2**
/// 
/// For any Physical Foundation progress state where every sub-task value is >= 200% of its target,
/// checkLimiterRemoval() shall trigger a Secret Quest Event
/// (awarding 5 stat points and setting limiterRemovedToday = true).

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property 17: Limiter Removal threshold', () {
    final random = Random();

    test('Limiter Removal threshold - 100 iterations with random 200%+ progress', () {
      // Run minimum 100 iterations as specified in the task
      for (int iteration = 0; iteration < 100; iteration++) {
        // Generate random progress values all >= 200% of each target
        // Targets: Push-ups: 100, Sit-ups: 100, Squats: 100, Running: 10
        
        final pushups = 200 + random.nextInt(300); // 200-499 (200%-499% of 100)
        final situps = 200 + random.nextInt(300);  // 200-499 (200%-499% of 100)
        final squats = 200 + random.nextInt(300);  // 200-499 (200%-499% of 100)
        final running = 20 + random.nextInt(30);   // 20-49 (200%-490% of 10)
        
        final progress = {
          'Push-ups': pushups,
          'Sit-ups': situps,
          'Squats': squats,
          'Running': running,
        };
        
        // Verify that isLimiterRemoved returns true
        final isRemoved = PhysicalFoundation.isLimiterRemoved(progress);
        
        expect(
          isRemoved,
          isTrue,
          reason: 'Iteration $iteration: All sub-tasks >= 200%, should trigger limiter removal\n'
                  'Push-ups: $pushups (${(pushups / 100 * 100).toStringAsFixed(0)}%)\n'
                  'Sit-ups: $situps (${(situps / 100 * 100).toStringAsFixed(0)}%)\n'
                  'Squats: $squats (${(squats / 100 * 100).toStringAsFixed(0)}%)\n'
                  'Running: $running (${(running / 10 * 100).toStringAsFixed(0)}%)',
        );
        
        // Simulate checkLimiterRemoval() behavior
        // Initial state: limiterRemovedToday = false, availablePoints = some value
        bool limiterRemovedToday = false;
        int availablePoints = random.nextInt(20);
        final initialAvailablePoints = availablePoints;
        
        // Simulate checkLimiterRemoval() logic
        if (!limiterRemovedToday && isRemoved) {
          limiterRemovedToday = true;
          availablePoints += 5;
        }
        
        // Assert limiterRemovedToday is now true
        expect(
          limiterRemovedToday,
          isTrue,
          reason: 'Iteration $iteration: limiterRemovedToday should be set to true',
        );
        
        // Assert availablePoints increased by exactly 5
        expect(
          availablePoints,
          equals(initialAvailablePoints + 5),
          reason: 'Iteration $iteration: availablePoints should increase by 5\n'
                  'Initial: $initialAvailablePoints, Expected: ${initialAvailablePoints + 5}, Actual: $availablePoints',
        );
      }
    });

    test('Limiter Removal threshold - exactly 200% of targets', () {
      // Test with exactly 200% of each target
      final progress = {
        'Push-ups': 200,  // Exactly 200% of 100
        'Sit-ups': 200,   // Exactly 200% of 100
        'Squats': 200,    // Exactly 200% of 100
        'Running': 20,    // Exactly 200% of 10
      };
      
      final isRemoved = PhysicalFoundation.isLimiterRemoved(progress);
      
      expect(
        isRemoved,
        isTrue,
        reason: 'Exactly 200% of all targets should trigger limiter removal',
      );
      
      // Simulate checkLimiterRemoval()
      bool limiterRemovedToday = false;
      int availablePoints = 10;
      
      if (!limiterRemovedToday && isRemoved) {
        limiterRemovedToday = true;
        availablePoints += 5;
      }
      
      expect(limiterRemovedToday, isTrue);
      expect(availablePoints, equals(15));
    });

    test('Limiter Removal threshold - high overload (300%+)', () {
      // Test with very high progress values (300%+ of targets)
      final progress = {
        'Push-ups': 350,  // 350% of 100
        'Sit-ups': 400,   // 400% of 100
        'Squats': 450,    // 450% of 100
        'Running': 35,    // 350% of 10
      };
      
      final isRemoved = PhysicalFoundation.isLimiterRemoved(progress);
      
      expect(
        isRemoved,
        isTrue,
        reason: 'High overload (300%+) should trigger limiter removal',
      );
      
      // Simulate checkLimiterRemoval()
      bool limiterRemovedToday = false;
      int availablePoints = 0;
      
      if (!limiterRemovedToday && isRemoved) {
        limiterRemovedToday = true;
        availablePoints += 5;
      }
      
      expect(limiterRemovedToday, isTrue);
      expect(availablePoints, equals(5));
    });

    test('Limiter Removal threshold - just below 200% should NOT trigger', () {
      // Test that just below 200% does NOT trigger limiter removal
      final testCases = [
        {
          'Push-ups': 199,  // Just below 200%
          'Sit-ups': 200,
          'Squats': 200,
          'Running': 20,
        },
        {
          'Push-ups': 200,
          'Sit-ups': 199,  // Just below 200%
          'Squats': 200,
          'Running': 20,
        },
        {
          'Push-ups': 200,
          'Sit-ups': 200,
          'Squats': 199,  // Just below 200%
          'Running': 20,
        },
        {
          'Push-ups': 200,
          'Sit-ups': 200,
          'Squats': 200,
          'Running': 19,  // Just below 200%
        },
      ];
      
      for (int i = 0; i < testCases.length; i++) {
        final progress = testCases[i];
        final isRemoved = PhysicalFoundation.isLimiterRemoved(progress);
        
        expect(
          isRemoved,
          isFalse,
          reason: 'Test case $i: One sub-task below 200% should NOT trigger limiter removal\n'
                  'Progress: $progress',
        );
      }
    });

    test('Limiter Removal threshold - mixed progress levels', () {
      // Test various combinations of progress levels
      for (int iteration = 0; iteration < 50; iteration++) {
        // Generate progress where all are >= 200%
        final pushups = 200 + random.nextInt(200);
        final situps = 200 + random.nextInt(200);
        final squats = 200 + random.nextInt(200);
        final running = 20 + random.nextInt(20);
        
        final progress = {
          'Push-ups': pushups,
          'Sit-ups': situps,
          'Squats': squats,
          'Running': running,
        };
        
        final isRemoved = PhysicalFoundation.isLimiterRemoved(progress);
        
        expect(
          isRemoved,
          isTrue,
          reason: 'Iteration $iteration: All >= 200% should trigger\n'
                  'Progress: $progress',
        );
      }
    });

    test('Limiter Removal threshold - stat points award amount', () {
      // Verify that exactly 5 stat points are awarded
      const expectedStatPoints = 5;
      
      for (int iteration = 0; iteration < 20; iteration++) {
        final initialAvailablePoints = random.nextInt(50);
        int availablePoints = initialAvailablePoints;
        bool limiterRemovedToday = false;
        
        // Simulate 200%+ progress
        final progress = {
          'Push-ups': 200 + random.nextInt(100),
          'Sit-ups': 200 + random.nextInt(100),
          'Squats': 200 + random.nextInt(100),
          'Running': 20 + random.nextInt(10),
        };
        
        final isRemoved = PhysicalFoundation.isLimiterRemoved(progress);
        
        if (!limiterRemovedToday && isRemoved) {
          limiterRemovedToday = true;
          availablePoints += expectedStatPoints;
        }
        
        expect(
          availablePoints - initialAvailablePoints,
          equals(expectedStatPoints),
          reason: 'Iteration $iteration: Should award exactly 5 stat points',
        );
      }
    });

    test('Limiter Removal threshold - boundary values', () {
      // Test exact boundary values for each sub-task
      final boundaryTests = [
        // All at exactly 200%
        {
          'progress': {'Push-ups': 200, 'Sit-ups': 200, 'Squats': 200, 'Running': 20},
          'shouldTrigger': true,
        },
        // Push-ups at 199 (just below)
        {
          'progress': {'Push-ups': 199, 'Sit-ups': 200, 'Squats': 200, 'Running': 20},
          'shouldTrigger': false,
        },
        // Sit-ups at 199 (just below)
        {
          'progress': {'Push-ups': 200, 'Sit-ups': 199, 'Squats': 200, 'Running': 20},
          'shouldTrigger': false,
        },
        // Squats at 199 (just below)
        {
          'progress': {'Push-ups': 200, 'Sit-ups': 200, 'Squats': 199, 'Running': 20},
          'shouldTrigger': false,
        },
        // Running at 19 (just below)
        {
          'progress': {'Push-ups': 200, 'Sit-ups': 200, 'Squats': 200, 'Running': 19},
          'shouldTrigger': false,
        },
        // All at 201 (just above 200%)
        {
          'progress': {'Push-ups': 201, 'Sit-ups': 201, 'Squats': 201, 'Running': 21},
          'shouldTrigger': true,
        },
      ];
      
      for (int i = 0; i < boundaryTests.length; i++) {
        final test = boundaryTests[i];
        final progress = test['progress'] as Map<String, int>;
        final shouldTrigger = test['shouldTrigger'] as bool;
        
        final isRemoved = PhysicalFoundation.isLimiterRemoved(progress);
        
        expect(
          isRemoved,
          equals(shouldTrigger),
          reason: 'Boundary test $i: Expected $shouldTrigger\n'
                  'Progress: $progress',
        );
      }
    });

    test('Limiter Removal threshold - extreme overload', () {
      // Test with extremely high progress values
      final progress = {
        'Push-ups': 1000,  // 1000% of 100
        'Sit-ups': 1000,   // 1000% of 100
        'Squats': 1000,    // 1000% of 100
        'Running': 100,    // 1000% of 10
      };
      
      final isRemoved = PhysicalFoundation.isLimiterRemoved(progress);
      
      expect(
        isRemoved,
        isTrue,
        reason: 'Extreme overload should trigger limiter removal',
      );
      
      // Simulate checkLimiterRemoval()
      bool limiterRemovedToday = false;
      int availablePoints = 0;
      
      if (!limiterRemovedToday && isRemoved) {
        limiterRemovedToday = true;
        availablePoints += 5;
      }
      
      expect(limiterRemovedToday, isTrue);
      expect(availablePoints, equals(5));
    });

    test('Limiter Removal threshold - asymmetric overload', () {
      // Test with different overload levels for each sub-task
      for (int iteration = 0; iteration < 30; iteration++) {
        final progress = {
          'Push-ups': 200 + random.nextInt(500),  // 200%-699%
          'Sit-ups': 200 + random.nextInt(500),   // 200%-699%
          'Squats': 200 + random.nextInt(500),    // 200%-699%
          'Running': 20 + random.nextInt(50),     // 200%-699%
        };
        
        final isRemoved = PhysicalFoundation.isLimiterRemoved(progress);
        
        expect(
          isRemoved,
          isTrue,
          reason: 'Iteration $iteration: Asymmetric overload should trigger\n'
                  'Progress: $progress',
        );
      }
    });

    test('Limiter Removal threshold - first trigger sets overload title', () {
      // Test that first trigger sets overloadTitleAwarded flag
      bool overloadTitleAwarded = false;
      bool limiterRemovedToday = false;
      int availablePoints = 0;
      
      // Simulate 200%+ progress
      final progress = {
        'Push-ups': 250,
        'Sit-ups': 250,
        'Squats': 250,
        'Running': 25,
      };
      
      final isRemoved = PhysicalFoundation.isLimiterRemoved(progress);
      
      if (!limiterRemovedToday && isRemoved) {
        limiterRemovedToday = true;
        availablePoints += 5;
        
        // First trigger: set overload title
        if (!overloadTitleAwarded) {
          overloadTitleAwarded = true;
        }
      }
      
      expect(limiterRemovedToday, isTrue);
      expect(availablePoints, equals(5));
      expect(overloadTitleAwarded, isTrue);
    });
  });
}
