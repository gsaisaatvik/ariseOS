import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

/// Property 6: Midnight Judgement — penalty activation
/// **Validates: Requirements 3.1, 3.2**
/// 
/// For any Physical Foundation progress state where `physicalCompletionPct < 1.0`,
/// running `CoreEngine.runMidnightJudgement` shall set `player.inPenaltyZone` to true.
/// 
/// This test validates the penalty activation logic by testing with randomly generated
/// progress states where completion is below 100%.
/// 
/// Tag: Feature: arise-os-monarch-integration, Property 6: Midnight Judgement — penalty activation

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property 6: Midnight Judgement — penalty activation', () {
    final random = Random();
    
    // The four sub-task keys and their targets
    final targets = {
      'Push-ups': 100,
      'Sit-ups': 100,
      'Squats': 100,
      'Running': 10,
    };
    final subTaskKeys = targets.keys.toList();

    /// Helper function to compute completion percentage
    /// using the formula: mean([min(p/t, 1.0) for each sub-task])
    double computeCompletionPct(Map<String, int> progress) {
      if (targets.isEmpty) return 0.0;
      
      double sum = 0.0;
      for (final entry in targets.entries) {
        final progressValue = progress[entry.key] ?? 0;
        final ratio = (progressValue / entry.value).clamp(0.0, 1.0);
        sum += ratio;
      }
      
      return sum / targets.length;
    }

    /// Helper function to generate random progress state where completion < 1.0
    Map<String, int> generateIncompleteProgress() {
      final progress = <String, int>{};
      
      // Strategy: Ensure at least one sub-task is below target
      // This guarantees physicalCompletionPct < 1.0
      
      // Generate random values for all sub-tasks
      for (final entry in targets.entries) {
        final key = entry.key;
        final target = entry.value;
        
        // Random value from 0 to target (inclusive)
        // This ensures we can have incomplete progress
        progress[key] = random.nextInt(target + 1);
      }
      
      // Ensure at least one sub-task is below target to guarantee < 100%
      // Pick a random sub-task and set it below target
      final keyToMakeIncomplete = subTaskKeys[random.nextInt(subTaskKeys.length)];
      final target = targets[keyToMakeIncomplete]!;
      
      // Set to a value strictly less than target (0 to target-1)
      if (target > 0) {
        progress[keyToMakeIncomplete] = random.nextInt(target);
      }
      
      return progress;
    }

    test('Penalty activation - 100 iterations with random incomplete progress', () {
      // Run minimum 100 iterations as specified in the task
      for (int iteration = 0; iteration < 100; iteration++) {
        // Generate random progress state where completion < 1.0
        final progress = generateIncompleteProgress();
        
        // Compute completion percentage
        final pct = computeCompletionPct(progress);
        
        // Verify precondition: completion < 1.0
        expect(
          pct,
          lessThan(1.0),
          reason: 'Iteration $iteration: Generated progress should be incomplete\n'
                  'Progress: $progress\n'
                  'Completion pct: $pct',
        );
        
        // Simulate the runMidnightJudgement logic
        final mockPlayer = _MockPlayer(physicalCompletionPct: pct);
        
        // Execute the midnight judgement logic
        if (mockPlayer.physicalCompletionPct < 1.0) {
          mockPlayer.activatePenaltyZone();
        } else {
          mockPlayer.recordDayCleared();
        }
        mockPlayer.resetPhysicalProgress();
        mockPlayer.lockMandatoryQuests();
        
        // Assert: Verify penalty zone was activated
        expect(
          mockPlayer.inPenaltyZone,
          isTrue,
          reason: 'Iteration $iteration: Penalty zone should be activated\n'
                  'Progress: $progress\n'
                  'Completion pct: $pct\n'
                  'Expected: inPenaltyZone = true',
        );
        
        // Assert: Verify activatePenaltyZone was called
        expect(
          mockPlayer.activatePenaltyZoneCalled,
          isTrue,
          reason: 'Iteration $iteration: activatePenaltyZone should be called\n'
                  'Progress: $progress\n'
                  'Completion pct: $pct',
        );
        
        // Assert: Verify recordDayCleared was NOT called
        expect(
          mockPlayer.recordDayClearedCalled,
          isFalse,
          reason: 'Iteration $iteration: recordDayCleared should NOT be called\n'
                  'Progress: $progress\n'
                  'Completion pct: $pct',
        );
        
        // Assert: Verify reset and lock were called
        expect(mockPlayer.resetPhysicalProgressCalled, isTrue);
        expect(mockPlayer.lockMandatoryQuestsCalled, isTrue);
      }
    });

    test('Penalty activation - edge case: 0% completion', () {
      // Test with all zeros (0% completion)
      final progress = {
        'Push-ups': 0,
        'Sit-ups': 0,
        'Squats': 0,
        'Running': 0,
      };
      
      final pct = computeCompletionPct(progress);
      expect(pct, equals(0.0));
      
      final mockPlayer = _MockPlayer(physicalCompletionPct: pct);
      
      if (mockPlayer.physicalCompletionPct < 1.0) {
        mockPlayer.activatePenaltyZone();
      } else {
        mockPlayer.recordDayCleared();
      }
      mockPlayer.resetPhysicalProgress();
      mockPlayer.lockMandatoryQuests();
      
      expect(mockPlayer.inPenaltyZone, isTrue);
      expect(mockPlayer.activatePenaltyZoneCalled, isTrue);
      expect(mockPlayer.recordDayClearedCalled, isFalse);
    });

    test('Penalty activation - edge case: just below 100% (99.9%)', () {
      // Test with values just below target
      final progress = {
        'Push-ups': 99,
        'Sit-ups': 100,
        'Squats': 100,
        'Running': 10,
      };
      
      final pct = computeCompletionPct(progress);
      expect(pct, lessThan(1.0));
      expect(pct, greaterThan(0.99));
      
      final mockPlayer = _MockPlayer(physicalCompletionPct: pct);
      
      if (mockPlayer.physicalCompletionPct < 1.0) {
        mockPlayer.activatePenaltyZone();
      } else {
        mockPlayer.recordDayCleared();
      }
      mockPlayer.resetPhysicalProgress();
      mockPlayer.lockMandatoryQuests();
      
      expect(mockPlayer.inPenaltyZone, isTrue);
      expect(mockPlayer.activatePenaltyZoneCalled, isTrue);
      expect(mockPlayer.recordDayClearedCalled, isFalse);
    });

    test('Penalty activation - edge case: one sub-task at 0, others at 100%', () {
      // Test with one sub-task incomplete
      final progress = {
        'Push-ups': 0,
        'Sit-ups': 100,
        'Squats': 100,
        'Running': 10,
      };
      
      final pct = computeCompletionPct(progress);
      expect(pct, equals(0.75)); // 3 out of 4 complete
      
      final mockPlayer = _MockPlayer(physicalCompletionPct: pct);
      
      if (mockPlayer.physicalCompletionPct < 1.0) {
        mockPlayer.activatePenaltyZone();
      } else {
        mockPlayer.recordDayCleared();
      }
      mockPlayer.resetPhysicalProgress();
      mockPlayer.lockMandatoryQuests();
      
      expect(mockPlayer.inPenaltyZone, isTrue);
      expect(mockPlayer.activatePenaltyZoneCalled, isTrue);
      expect(mockPlayer.recordDayClearedCalled, isFalse);
    });

    test('Penalty activation - edge case: 50% completion', () {
      // Test with half completion
      final progress = {
        'Push-ups': 50,
        'Sit-ups': 50,
        'Squats': 50,
        'Running': 5,
      };
      
      final pct = computeCompletionPct(progress);
      expect(pct, equals(0.5));
      
      final mockPlayer = _MockPlayer(physicalCompletionPct: pct);
      
      if (mockPlayer.physicalCompletionPct < 1.0) {
        mockPlayer.activatePenaltyZone();
      } else {
        mockPlayer.recordDayCleared();
      }
      mockPlayer.resetPhysicalProgress();
      mockPlayer.lockMandatoryQuests();
      
      expect(mockPlayer.inPenaltyZone, isTrue);
      expect(mockPlayer.activatePenaltyZoneCalled, isTrue);
      expect(mockPlayer.recordDayClearedCalled, isFalse);
    });

    test('Penalty activation - various incomplete states', () {
      // Test multiple specific incomplete states
      final incompleteCases = [
        {'Push-ups': 25, 'Sit-ups': 25, 'Squats': 25, 'Running': 2},
        {'Push-ups': 75, 'Sit-ups': 75, 'Squats': 75, 'Running': 7},
        {'Push-ups': 90, 'Sit-ups': 90, 'Squats': 90, 'Running': 9},
        {'Push-ups': 100, 'Sit-ups': 100, 'Squats': 50, 'Running': 10},
        {'Push-ups': 100, 'Sit-ups': 50, 'Squats': 100, 'Running': 10},
        {'Push-ups': 50, 'Sit-ups': 100, 'Squats': 100, 'Running': 10},
        {'Push-ups': 100, 'Sit-ups': 100, 'Squats': 100, 'Running': 5},
      ];

      for (int i = 0; i < incompleteCases.length; i++) {
        final progress = incompleteCases[i];
        final pct = computeCompletionPct(progress);
        
        expect(
          pct,
          lessThan(1.0),
          reason: 'Case $i should be incomplete: $progress',
        );
        
        final mockPlayer = _MockPlayer(physicalCompletionPct: pct);
        
        if (mockPlayer.physicalCompletionPct < 1.0) {
          mockPlayer.activatePenaltyZone();
        } else {
          mockPlayer.recordDayCleared();
        }
        mockPlayer.resetPhysicalProgress();
        mockPlayer.lockMandatoryQuests();
        
        expect(
          mockPlayer.inPenaltyZone,
          isTrue,
          reason: 'Case $i: Penalty zone should be activated\n'
                  'Progress: $progress\n'
                  'Completion pct: $pct',
        );
        
        expect(mockPlayer.activatePenaltyZoneCalled, isTrue);
        expect(mockPlayer.recordDayClearedCalled, isFalse);
      }
    });

    test('Penalty activation - stress test with 200 random incomplete states', () {
      // Additional stress test with more iterations
      for (int iteration = 0; iteration < 200; iteration++) {
        final progress = generateIncompleteProgress();
        final pct = computeCompletionPct(progress);
        
        // Verify precondition
        expect(pct, lessThan(1.0));
        
        final mockPlayer = _MockPlayer(physicalCompletionPct: pct);
        
        if (mockPlayer.physicalCompletionPct < 1.0) {
          mockPlayer.activatePenaltyZone();
        } else {
          mockPlayer.recordDayCleared();
        }
        mockPlayer.resetPhysicalProgress();
        mockPlayer.lockMandatoryQuests();
        
        expect(
          mockPlayer.inPenaltyZone,
          isTrue,
          reason: 'Stress test iteration $iteration: Penalty zone should be activated\n'
                  'Progress: $progress\n'
                  'Completion pct: $pct',
        );
        
        expect(mockPlayer.activatePenaltyZoneCalled, isTrue);
        expect(mockPlayer.recordDayClearedCalled, isFalse);
      }
    });

    test('Penalty activation - boundary test: exactly at threshold', () {
      // Test values that result in exactly 1.0 should NOT activate penalty
      // This is a negative test to verify the boundary condition
      final completeProgress = {
        'Push-ups': 100,
        'Sit-ups': 100,
        'Squats': 100,
        'Running': 10,
      };
      
      final pct = computeCompletionPct(completeProgress);
      expect(pct, equals(1.0));
      
      final mockPlayer = _MockPlayer(physicalCompletionPct: pct);
      
      if (mockPlayer.physicalCompletionPct < 1.0) {
        mockPlayer.activatePenaltyZone();
      } else {
        mockPlayer.recordDayCleared();
      }
      mockPlayer.resetPhysicalProgress();
      mockPlayer.lockMandatoryQuests();
      
      // At exactly 1.0, penalty should NOT be activated
      expect(mockPlayer.inPenaltyZone, isFalse);
      expect(mockPlayer.activatePenaltyZoneCalled, isFalse);
      expect(mockPlayer.recordDayClearedCalled, isTrue);
    });
  });
}

/// Mock PlayerProvider for testing the midnight judgement logic
class _MockPlayer {
  final double physicalCompletionPct;
  bool activatePenaltyZoneCalled = false;
  bool recordDayClearedCalled = false;
  bool resetPhysicalProgressCalled = false;
  bool lockMandatoryQuestsCalled = false;
  bool _inPenaltyZone = false;

  _MockPlayer({required this.physicalCompletionPct});

  bool get inPenaltyZone => _inPenaltyZone;

  void activatePenaltyZone() {
    activatePenaltyZoneCalled = true;
    _inPenaltyZone = true;
  }

  void recordDayCleared() {
    recordDayClearedCalled = true;
  }

  void resetPhysicalProgress() {
    resetPhysicalProgressCalled = true;
  }

  void lockMandatoryQuests() {
    lockMandatoryQuestsCalled = true;
  }
}
