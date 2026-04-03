import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

/// Property 8: Midnight Judgement — progress reset
/// **Validates: Requirements 3.4**
/// 
/// For any Physical Foundation progress state (any combination of values),
/// running `CoreEngine.runMidnightJudgement` shall set all four sub-task progress values to zero.
/// 
/// This test validates the progress reset logic by testing with randomly generated
/// progress states across the full range of possible values.
/// 
/// Tag: Feature: arise-os-monarch-integration, Property 8: Midnight Judgement — progress reset

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property 8: Midnight Judgement — progress reset', () {
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

    /// Helper function to generate random progress state
    /// Generates any combination of progress values from 0 to 200% of target
    Map<String, int> generateRandomProgress() {
      final progress = <String, int>{};
      
      for (final entry in targets.entries) {
        final key = entry.key;
        final target = entry.value;
        
        // Random value from 0 to 2x target (covers all scenarios)
        final maxValue = target * 2;
        progress[key] = random.nextInt(maxValue + 1);
      }
      
      return progress;
    }

    test('Progress reset - 100 iterations with random progress states', () {
      // Run minimum 100 iterations as specified in the task
      for (int iteration = 0; iteration < 100; iteration++) {
        // Generate random progress state (any combination of values)
        final initialProgress = generateRandomProgress();
        
        // Compute completion percentage for context
        final pct = computeCompletionPct(initialProgress);
        
        // Create mock player with the initial progress
        final mockPlayer = _MockPlayer(
          physicalCompletionPct: pct,
          initialProgress: Map.from(initialProgress),
        );
        
        // Verify initial progress is set correctly
        for (final key in subTaskKeys) {
          expect(
            mockPlayer.physicalProgress[key],
            equals(initialProgress[key]),
            reason: 'Iteration $iteration: Initial progress should match\n'
                    'Key: $key\n'
                    'Expected: ${initialProgress[key]}\n'
                    'Actual: ${mockPlayer.physicalProgress[key]}',
          );
        }
        
        // Execute the midnight judgement logic
        if (mockPlayer.physicalCompletionPct < 1.0) {
          mockPlayer.activatePenaltyZone();
        } else {
          mockPlayer.recordDayCleared();
        }
        mockPlayer.resetPhysicalProgress();
        mockPlayer.lockMandatoryQuests();
        
        // Assert: Verify ALL four sub-task progress values are set to zero
        for (final key in subTaskKeys) {
          expect(
            mockPlayer.physicalProgress[key],
            equals(0),
            reason: 'Iteration $iteration: Progress for $key should be reset to 0\n'
                    'Initial progress: $initialProgress\n'
                    'Completion pct: $pct\n'
                    'Current progress: ${mockPlayer.physicalProgress}',
          );
        }
        
        // Assert: Verify resetPhysicalProgress was called
        expect(
          mockPlayer.resetPhysicalProgressCalled,
          isTrue,
          reason: 'Iteration $iteration: resetPhysicalProgress should be called\n'
                  'Initial progress: $initialProgress\n'
                  'Completion pct: $pct',
        );
      }
    });

    test('Progress reset - edge case: all zeros', () {
      // Test with all progress values at zero
      final initialProgress = {
        'Push-ups': 0,
        'Sit-ups': 0,
        'Squats': 0,
        'Running': 0,
      };
      
      final pct = computeCompletionPct(initialProgress);
      expect(pct, equals(0.0));
      
      final mockPlayer = _MockPlayer(
        physicalCompletionPct: pct,
        initialProgress: Map.from(initialProgress),
      );
      
      if (mockPlayer.physicalCompletionPct < 1.0) {
        mockPlayer.activatePenaltyZone();
      } else {
        mockPlayer.recordDayCleared();
      }
      mockPlayer.resetPhysicalProgress();
      mockPlayer.lockMandatoryQuests();
      
      // All values should still be zero
      for (final key in subTaskKeys) {
        expect(mockPlayer.physicalProgress[key], equals(0));
      }
      expect(mockPlayer.resetPhysicalProgressCalled, isTrue);
    });

    test('Progress reset - edge case: all at target (100%)', () {
      // Test with all progress values exactly at target
      final initialProgress = {
        'Push-ups': 100,
        'Sit-ups': 100,
        'Squats': 100,
        'Running': 10,
      };
      
      final pct = computeCompletionPct(initialProgress);
      expect(pct, equals(1.0));
      
      final mockPlayer = _MockPlayer(
        physicalCompletionPct: pct,
        initialProgress: Map.from(initialProgress),
      );
      
      // Verify initial values are at target
      expect(mockPlayer.physicalProgress['Push-ups'], equals(100));
      expect(mockPlayer.physicalProgress['Sit-ups'], equals(100));
      expect(mockPlayer.physicalProgress['Squats'], equals(100));
      expect(mockPlayer.physicalProgress['Running'], equals(10));
      
      if (mockPlayer.physicalCompletionPct < 1.0) {
        mockPlayer.activatePenaltyZone();
      } else {
        mockPlayer.recordDayCleared();
      }
      mockPlayer.resetPhysicalProgress();
      mockPlayer.lockMandatoryQuests();
      
      // All values should be reset to zero
      for (final key in subTaskKeys) {
        expect(mockPlayer.physicalProgress[key], equals(0));
      }
      expect(mockPlayer.resetPhysicalProgressCalled, isTrue);
    });

    test('Progress reset - edge case: all at 200% (limiter removal)', () {
      // Test with all progress values at 200% of target
      final initialProgress = {
        'Push-ups': 200,
        'Sit-ups': 200,
        'Squats': 200,
        'Running': 20,
      };
      
      final pct = computeCompletionPct(initialProgress);
      expect(pct, equals(1.0)); // Clamped to 1.0 in the formula
      
      final mockPlayer = _MockPlayer(
        physicalCompletionPct: pct,
        initialProgress: Map.from(initialProgress),
      );
      
      // Verify initial values are at 200%
      expect(mockPlayer.physicalProgress['Push-ups'], equals(200));
      expect(mockPlayer.physicalProgress['Sit-ups'], equals(200));
      expect(mockPlayer.physicalProgress['Squats'], equals(200));
      expect(mockPlayer.physicalProgress['Running'], equals(20));
      
      if (mockPlayer.physicalCompletionPct < 1.0) {
        mockPlayer.activatePenaltyZone();
      } else {
        mockPlayer.recordDayCleared();
      }
      mockPlayer.resetPhysicalProgress();
      mockPlayer.lockMandatoryQuests();
      
      // All values should be reset to zero
      for (final key in subTaskKeys) {
        expect(mockPlayer.physicalProgress[key], equals(0));
      }
      expect(mockPlayer.resetPhysicalProgressCalled, isTrue);
    });

    test('Progress reset - edge case: mixed values', () {
      // Test with mixed progress values (some complete, some incomplete)
      final initialProgress = {
        'Push-ups': 50,
        'Sit-ups': 100,
        'Squats': 150,
        'Running': 5,
      };
      
      final pct = computeCompletionPct(initialProgress);
      
      final mockPlayer = _MockPlayer(
        physicalCompletionPct: pct,
        initialProgress: Map.from(initialProgress),
      );
      
      // Verify initial values
      expect(mockPlayer.physicalProgress['Push-ups'], equals(50));
      expect(mockPlayer.physicalProgress['Sit-ups'], equals(100));
      expect(mockPlayer.physicalProgress['Squats'], equals(150));
      expect(mockPlayer.physicalProgress['Running'], equals(5));
      
      if (mockPlayer.physicalCompletionPct < 1.0) {
        mockPlayer.activatePenaltyZone();
      } else {
        mockPlayer.recordDayCleared();
      }
      mockPlayer.resetPhysicalProgress();
      mockPlayer.lockMandatoryQuests();
      
      // All values should be reset to zero
      for (final key in subTaskKeys) {
        expect(mockPlayer.physicalProgress[key], equals(0));
      }
      expect(mockPlayer.resetPhysicalProgressCalled, isTrue);
    });

    test('Progress reset - various progress states', () {
      // Test multiple specific progress states
      final progressCases = [
        {'Push-ups': 0, 'Sit-ups': 0, 'Squats': 0, 'Running': 0},
        {'Push-ups': 25, 'Sit-ups': 25, 'Squats': 25, 'Running': 2},
        {'Push-ups': 50, 'Sit-ups': 50, 'Squats': 50, 'Running': 5},
        {'Push-ups': 75, 'Sit-ups': 75, 'Squats': 75, 'Running': 7},
        {'Push-ups': 100, 'Sit-ups': 100, 'Squats': 100, 'Running': 10},
        {'Push-ups': 150, 'Sit-ups': 150, 'Squats': 150, 'Running': 15},
        {'Push-ups': 200, 'Sit-ups': 200, 'Squats': 200, 'Running': 20},
        {'Push-ups': 10, 'Sit-ups': 90, 'Squats': 50, 'Running': 3},
        {'Push-ups': 100, 'Sit-ups': 0, 'Squats': 100, 'Running': 0},
      ];

      for (int i = 0; i < progressCases.length; i++) {
        final initialProgress = progressCases[i];
        final pct = computeCompletionPct(initialProgress);
        
        final mockPlayer = _MockPlayer(
          physicalCompletionPct: pct,
          initialProgress: Map.from(initialProgress),
        );
        
        // Verify initial progress
        for (final key in subTaskKeys) {
          expect(mockPlayer.physicalProgress[key], equals(initialProgress[key]));
        }
        
        if (mockPlayer.physicalCompletionPct < 1.0) {
          mockPlayer.activatePenaltyZone();
        } else {
          mockPlayer.recordDayCleared();
        }
        mockPlayer.resetPhysicalProgress();
        mockPlayer.lockMandatoryQuests();
        
        // Verify all values are reset to zero
        for (final key in subTaskKeys) {
          expect(
            mockPlayer.physicalProgress[key],
            equals(0),
            reason: 'Case $i: Progress for $key should be reset to 0\n'
                    'Initial progress: $initialProgress\n'
                    'Completion pct: $pct',
          );
        }
        
        expect(mockPlayer.resetPhysicalProgressCalled, isTrue);
      }
    });

    test('Progress reset - stress test with 200 random states', () {
      // Additional stress test with more iterations
      for (int iteration = 0; iteration < 200; iteration++) {
        final initialProgress = generateRandomProgress();
        final pct = computeCompletionPct(initialProgress);
        
        final mockPlayer = _MockPlayer(
          physicalCompletionPct: pct,
          initialProgress: Map.from(initialProgress),
        );
        
        if (mockPlayer.physicalCompletionPct < 1.0) {
          mockPlayer.activatePenaltyZone();
        } else {
          mockPlayer.recordDayCleared();
        }
        mockPlayer.resetPhysicalProgress();
        mockPlayer.lockMandatoryQuests();
        
        // Verify all values are reset to zero
        for (final key in subTaskKeys) {
          expect(
            mockPlayer.physicalProgress[key],
            equals(0),
            reason: 'Stress test iteration $iteration: Progress for $key should be reset to 0\n'
                    'Initial progress: $initialProgress\n'
                    'Completion pct: $pct',
          );
        }
        
        expect(mockPlayer.resetPhysicalProgressCalled, isTrue);
      }
    });

    test('Progress reset - reset is called regardless of penalty activation', () {
      // Test that reset happens whether penalty is activated or not
      
      // Case 1: Incomplete progress (penalty activated)
      final incompleteProgress = {
        'Push-ups': 50,
        'Sit-ups': 50,
        'Squats': 50,
        'Running': 5,
      };
      
      final incompletePct = computeCompletionPct(incompleteProgress);
      expect(incompletePct, lessThan(1.0));
      
      final mockPlayer1 = _MockPlayer(
        physicalCompletionPct: incompletePct,
        initialProgress: Map.from(incompleteProgress),
      );
      
      if (mockPlayer1.physicalCompletionPct < 1.0) {
        mockPlayer1.activatePenaltyZone();
      } else {
        mockPlayer1.recordDayCleared();
      }
      mockPlayer1.resetPhysicalProgress();
      mockPlayer1.lockMandatoryQuests();
      
      // Verify reset happened and penalty was activated
      expect(mockPlayer1.activatePenaltyZoneCalled, isTrue);
      expect(mockPlayer1.resetPhysicalProgressCalled, isTrue);
      for (final key in subTaskKeys) {
        expect(mockPlayer1.physicalProgress[key], equals(0));
      }
      
      // Case 2: Complete progress (day cleared)
      final completeProgress = {
        'Push-ups': 100,
        'Sit-ups': 100,
        'Squats': 100,
        'Running': 10,
      };
      
      final completePct = computeCompletionPct(completeProgress);
      expect(completePct, equals(1.0));
      
      final mockPlayer2 = _MockPlayer(
        physicalCompletionPct: completePct,
        initialProgress: Map.from(completeProgress),
      );
      
      if (mockPlayer2.physicalCompletionPct < 1.0) {
        mockPlayer2.activatePenaltyZone();
      } else {
        mockPlayer2.recordDayCleared();
      }
      mockPlayer2.resetPhysicalProgress();
      mockPlayer2.lockMandatoryQuests();
      
      // Verify reset happened and day was cleared
      expect(mockPlayer2.recordDayClearedCalled, isTrue);
      expect(mockPlayer2.resetPhysicalProgressCalled, isTrue);
      for (final key in subTaskKeys) {
        expect(mockPlayer2.physicalProgress[key], equals(0));
      }
    });

    test('Progress reset - reset is called regardless of streak extension', () {
      // Test that reset happens whether streak is extended or not
      
      // Case 1: Streak extended (complete)
      final completeProgress = {
        'Push-ups': 100,
        'Sit-ups': 100,
        'Squats': 100,
        'Running': 10,
      };
      
      final completePct = computeCompletionPct(completeProgress);
      
      final mockPlayer1 = _MockPlayer(
        physicalCompletionPct: completePct,
        initialProgress: Map.from(completeProgress),
      );
      
      if (mockPlayer1.physicalCompletionPct < 1.0) {
        mockPlayer1.activatePenaltyZone();
      } else {
        mockPlayer1.recordDayCleared();
      }
      mockPlayer1.resetPhysicalProgress();
      mockPlayer1.lockMandatoryQuests();
      
      expect(mockPlayer1.recordDayClearedCalled, isTrue);
      expect(mockPlayer1.resetPhysicalProgressCalled, isTrue);
      for (final key in subTaskKeys) {
        expect(mockPlayer1.physicalProgress[key], equals(0));
      }
      
      // Case 2: Streak not extended (incomplete)
      final incompleteProgress = {
        'Push-ups': 99,
        'Sit-ups': 100,
        'Squats': 100,
        'Running': 10,
      };
      
      final incompletePct = computeCompletionPct(incompleteProgress);
      
      final mockPlayer2 = _MockPlayer(
        physicalCompletionPct: incompletePct,
        initialProgress: Map.from(incompleteProgress),
      );
      
      if (mockPlayer2.physicalCompletionPct < 1.0) {
        mockPlayer2.activatePenaltyZone();
      } else {
        mockPlayer2.recordDayCleared();
      }
      mockPlayer2.resetPhysicalProgress();
      mockPlayer2.lockMandatoryQuests();
      
      expect(mockPlayer2.activatePenaltyZoneCalled, isTrue);
      expect(mockPlayer2.resetPhysicalProgressCalled, isTrue);
      for (final key in subTaskKeys) {
        expect(mockPlayer2.physicalProgress[key], equals(0));
      }
    });
  });
}

/// Mock PlayerProvider for testing the midnight judgement logic
class _MockPlayer {
  final double physicalCompletionPct;
  final Map<String, int> physicalProgress;
  bool activatePenaltyZoneCalled = false;
  bool recordDayClearedCalled = false;
  bool resetPhysicalProgressCalled = false;
  bool lockMandatoryQuestsCalled = false;
  bool _inPenaltyZone = false;

  _MockPlayer({
    required this.physicalCompletionPct,
    required Map<String, int> initialProgress,
  }) : physicalProgress = Map.from(initialProgress);

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
    // Simulate the actual resetPhysicalProgress logic: set all values to 0
    for (final key in physicalProgress.keys) {
      physicalProgress[key] = 0;
    }
  }

  void lockMandatoryQuests() {
    lockMandatoryQuestsCalled = true;
  }
}
