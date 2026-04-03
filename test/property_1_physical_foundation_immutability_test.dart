import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:arise_os/models/physical_foundation.dart';

/// Property 1: Physical Foundation sub-task immutability
/// **Validates: Requirements 1.4**
/// 
/// For any sequence of user interactions on the Status Screen, the four Physical
/// Foundation sub-tasks (Push-ups, Sit-ups, Squats, Running) shall always be
/// present, in the same order, with the same targets.
/// 
/// This test asserts that `PhysicalFoundation.targets.keys.toList()` always equals
/// `['Push-ups', 'Sit-ups', 'Squats', 'Running']` and values are unchanged
/// regardless of any external state.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property 1: Physical Foundation sub-task immutability', () {
    // Expected immutable values as specified in the design
    const expectedKeys = ['Push-ups', 'Sit-ups', 'Squats', 'Running'];
    const expectedTargets = {
      'Push-ups': 100,
      'Sit-ups': 100,
      'Squats': 100,
      'Running': 10,
    };

    test('Sub-task keys are immutable - 100 iterations', () {
      // Run minimum 100 iterations as specified in the task
      for (int iteration = 0; iteration < 100; iteration++) {
        // Access the targets map
        final targets = PhysicalFoundation.targets;
        final actualKeys = targets.keys.toList();
        
        // Assert keys match expected keys exactly
        expect(
          actualKeys,
          equals(expectedKeys),
          reason: 'Iteration $iteration: Sub-task keys must always be '
                  '${expectedKeys.toString()} in that exact order',
        );
        
        // Assert the number of sub-tasks is always 4
        expect(
          actualKeys.length,
          equals(4),
          reason: 'Iteration $iteration: There must always be exactly 4 sub-tasks',
        );
      }
    });

    test('Sub-task target values are immutable - 100 iterations', () {
      // Run minimum 100 iterations as specified in the task
      for (int iteration = 0; iteration < 100; iteration++) {
        // Access the targets map
        final targets = PhysicalFoundation.targets;
        
        // Assert each target value matches the expected value
        for (final entry in expectedTargets.entries) {
          expect(
            targets[entry.key],
            equals(entry.value),
            reason: 'Iteration $iteration: Target for ${entry.key} must always be ${entry.value}',
          );
        }
        
        // Assert the entire map matches
        expect(
          targets,
          equals(expectedTargets),
          reason: 'Iteration $iteration: All target values must remain unchanged',
        );
      }
    });

    test('Sub-task immutability across simulated external state changes', () {
      final random = Random();
      
      // Simulate 100 iterations of "external state changes" that might
      // theoretically affect the targets (but shouldn't)
      for (int iteration = 0; iteration < 100; iteration++) {
        // Simulate various external operations that should NOT affect immutability
        
        // 1. Create random progress maps (simulating user input)
        final randomProgress = <String, int>{};
        for (final key in expectedKeys) {
          randomProgress[key] = random.nextInt(500);
        }
        
        // 2. Call PhysicalFoundation methods with random data
        PhysicalFoundation.completionPct(randomProgress);
        PhysicalFoundation.isLimiterRemoved(randomProgress);
        
        // 3. Access targets multiple times
        final targets1 = PhysicalFoundation.targets;
        final targets2 = PhysicalFoundation.targets;
        final targets3 = PhysicalFoundation.targets;
        
        // Assert all accesses return the same immutable values
        expect(targets1, equals(expectedTargets));
        expect(targets2, equals(expectedTargets));
        expect(targets3, equals(expectedTargets));
        
        // Assert keys remain in the correct order
        expect(targets1.keys.toList(), equals(expectedKeys));
        expect(targets2.keys.toList(), equals(expectedKeys));
        expect(targets3.keys.toList(), equals(expectedKeys));
      }
    });

    test('Sub-task keys order is preserved', () {
      // Verify that the keys are always in the exact order specified
      for (int iteration = 0; iteration < 100; iteration++) {
        final keys = PhysicalFoundation.targets.keys.toList();
        
        // Check each position individually
        expect(keys[0], equals('Push-ups'), reason: 'First sub-task must be Push-ups');
        expect(keys[1], equals('Sit-ups'), reason: 'Second sub-task must be Sit-ups');
        expect(keys[2], equals('Squats'), reason: 'Third sub-task must be Squats');
        expect(keys[3], equals('Running'), reason: 'Fourth sub-task must be Running');
      }
    });

    test('Sub-task map is truly const and cannot be modified', () {
      // Verify that the targets map is a const and cannot be modified
      final targets = PhysicalFoundation.targets;
      
      // Attempt to modify should throw (this is a compile-time guarantee,
      // but we verify the runtime behavior)
      expect(
        () => (targets as dynamic)['Push-ups'] = 200,
        throwsA(isA<UnsupportedError>()),
        reason: 'Targets map must be immutable and reject modification attempts',
      );
    });

    test('Sub-task immutability - no additional keys can be added', () {
      // Verify that no additional keys exist beyond the expected four
      for (int iteration = 0; iteration < 100; iteration++) {
        final targets = PhysicalFoundation.targets;
        
        // Assert only the expected keys exist
        expect(
          targets.keys.toSet(),
          equals(expectedKeys.toSet()),
          reason: 'Iteration $iteration: Only the four expected sub-tasks should exist',
        );
        
        // Assert no unexpected keys
        for (final key in targets.keys) {
          expect(
            expectedKeys.contains(key),
            isTrue,
            reason: 'Iteration $iteration: Unexpected key found: $key',
          );
        }
      }
    });

    test('Sub-task immutability - values are positive integers', () {
      // Verify that all target values are positive integers as expected
      for (int iteration = 0; iteration < 100; iteration++) {
        final targets = PhysicalFoundation.targets;
        
        for (final entry in targets.entries) {
          expect(
            entry.value,
            isPositive,
            reason: 'Iteration $iteration: Target for ${entry.key} must be positive',
          );
          
          expect(
            entry.value,
            isA<int>(),
            reason: 'Iteration $iteration: Target for ${entry.key} must be an integer',
          );
        }
      }
    });

    test('Sub-task immutability - stress test with concurrent access', () {
      // Simulate concurrent access patterns that might occur in a real app
      final random = Random();
      
      for (int iteration = 0; iteration < 100; iteration++) {
        // Simulate multiple "threads" accessing targets simultaneously
        final accesses = <Map<String, int>>[];
        
        for (int i = 0; i < 10; i++) {
          accesses.add(PhysicalFoundation.targets);
          
          // Interleave with other operations
          final randomProgress = <String, int>{};
          for (final key in expectedKeys) {
            randomProgress[key] = random.nextInt(300);
          }
          PhysicalFoundation.completionPct(randomProgress);
        }
        
        // Verify all accesses returned the same immutable map
        for (final access in accesses) {
          expect(access, equals(expectedTargets));
          expect(access.keys.toList(), equals(expectedKeys));
        }
      }
    });

    test('Sub-task immutability - edge case with empty progress map', () {
      // Verify immutability even when called with edge case inputs
      for (int iteration = 0; iteration < 100; iteration++) {
        // Call methods with empty progress map
        PhysicalFoundation.completionPct({});
        PhysicalFoundation.isLimiterRemoved({});
        
        // Verify targets remain unchanged
        final targets = PhysicalFoundation.targets;
        expect(targets, equals(expectedTargets));
        expect(targets.keys.toList(), equals(expectedKeys));
      }
    });

    test('Sub-task immutability - verification after extreme progress values', () {
      // Verify immutability after processing extreme progress values
      final extremeCases = [
        // All zeros
        {'Push-ups': 0, 'Sit-ups': 0, 'Squats': 0, 'Running': 0},
        
        // Maximum reasonable values
        {'Push-ups': 1000, 'Sit-ups': 1000, 'Squats': 1000, 'Running': 100},
        
        // Negative values (invalid but should not affect immutability)
        {'Push-ups': -100, 'Sit-ups': -100, 'Squats': -100, 'Running': -10},
        
        // Mixed extreme values
        {'Push-ups': 0, 'Sit-ups': 1000, 'Squats': -50, 'Running': 500},
      ];

      for (int i = 0; i < extremeCases.length; i++) {
        final progress = extremeCases[i];
        
        // Process the extreme values
        PhysicalFoundation.completionPct(progress);
        PhysicalFoundation.isLimiterRemoved(progress);
        
        // Verify targets remain unchanged
        final targets = PhysicalFoundation.targets;
        expect(
          targets,
          equals(expectedTargets),
          reason: 'Extreme case $i: Targets must remain unchanged after processing $progress',
        );
        expect(
          targets.keys.toList(),
          equals(expectedKeys),
          reason: 'Extreme case $i: Keys must remain unchanged after processing $progress',
        );
      }
    });
  });
}
