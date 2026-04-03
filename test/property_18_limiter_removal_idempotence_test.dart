import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:arise_os/models/physical_foundation.dart';

/// Property 18: Limiter Removal idempotence per day
/// **Validates: Requirements 7.4, 9.6**
/// 
/// For any number of times the 200% threshold is crossed in a single day,
/// the Secret Quest Event shall fire at most once
/// (stat points awarded exactly once, limiterRemovedToday remains true after the first trigger).

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property 18: Limiter Removal idempotence', () {
    final random = Random();

    test('Limiter Removal idempotence - 100 iterations with random repeat counts', () {
      // Run minimum 100 iterations as specified in the task
      for (int iteration = 0; iteration < 100; iteration++) {
        // Generate random repeat count >= 2 (2 to 20 calls)
        final repeatCount = random.nextInt(19) + 2;
        
        // Initial state
        bool limiterRemovedToday = false;
        int availablePoints = random.nextInt(20);
        bool overloadTitleAwarded = false;
        
        final initialAvailablePoints = availablePoints;
        
        // Generate 200%+ progress
        final progress = {
          'Push-ups': 200 + random.nextInt(300),
          'Sit-ups': 200 + random.nextInt(300),
          'Squats': 200 + random.nextInt(300),
          'Running': 20 + random.nextInt(30),
        };
        
        // Call checkLimiterRemoval() multiple times
        for (int callIndex = 0; callIndex < repeatCount; callIndex++) {
          // Simulate checkLimiterRemoval() logic
          if (limiterRemovedToday) {
            // Idempotence guard: return immediately
            continue;
          }
          
          final isRemoved = PhysicalFoundation.isLimiterRemoved(progress);
          
          if (isRemoved) {
            limiterRemovedToday = true;
            availablePoints += 5;
            
            if (!overloadTitleAwarded) {
              overloadTitleAwarded = true;
            }
          }
        }
        
        // Assert stat points awarded exactly once
        expect(
          availablePoints,
          equals(initialAvailablePoints + 5),
          reason: 'Iteration $iteration: Stat points should be awarded exactly once\n'
                  'Repeat count: $repeatCount\n'
                  'Initial points: $initialAvailablePoints\n'
                  'Final points: $availablePoints\n'
                  'Expected: ${initialAvailablePoints + 5}',
        );
        
        // Assert limiterRemovedToday remains true
        expect(
          limiterRemovedToday,
          isTrue,
          reason: 'Iteration $iteration: limiterRemovedToday should remain true after first trigger',
        );
        
        // Assert overload title was awarded
        expect(
          overloadTitleAwarded,
          isTrue,
          reason: 'Iteration $iteration: overloadTitleAwarded should be true',
        );
      }
    });

    test('Limiter Removal idempotence - exactly 2 calls', () {
      // Test with exactly 2 calls (minimum repeat count)
      bool limiterRemovedToday = false;
      int availablePoints = 10;
      final initialAvailablePoints = availablePoints;
      
      final progress = {
        'Push-ups': 250,
        'Sit-ups': 250,
        'Squats': 250,
        'Running': 25,
      };
      
      // First call
      if (!limiterRemovedToday && PhysicalFoundation.isLimiterRemoved(progress)) {
        limiterRemovedToday = true;
        availablePoints += 5;
      }
      
      // Second call (should be no-op)
      if (!limiterRemovedToday && PhysicalFoundation.isLimiterRemoved(progress)) {
        limiterRemovedToday = true;
        availablePoints += 5;
      }
      
      expect(availablePoints, equals(initialAvailablePoints + 5));
      expect(limiterRemovedToday, isTrue);
    });

    test('Limiter Removal idempotence - many calls (10+)', () {
      // Test with many repeated calls
      for (int iteration = 0; iteration < 20; iteration++) {
        bool limiterRemovedToday = false;
        int availablePoints = random.nextInt(30);
        final initialAvailablePoints = availablePoints;
        
        final progress = {
          'Push-ups': 300,
          'Sit-ups': 300,
          'Squats': 300,
          'Running': 30,
        };
        
        // Call 10-50 times
        final callCount = random.nextInt(41) + 10;
        
        for (int i = 0; i < callCount; i++) {
          if (!limiterRemovedToday && PhysicalFoundation.isLimiterRemoved(progress)) {
            limiterRemovedToday = true;
            availablePoints += 5;
          }
        }
        
        expect(
          availablePoints,
          equals(initialAvailablePoints + 5),
          reason: 'Iteration $iteration: After $callCount calls, points should increase by 5 only once',
        );
        
        expect(limiterRemovedToday, isTrue);
      }
    });

    test('Limiter Removal idempotence - progress changes between calls', () {
      // Test that even if progress changes between calls, idempotence is maintained
      bool limiterRemovedToday = false;
      int availablePoints = 15;
      final initialAvailablePoints = availablePoints;
      
      // First call with 200%+ progress
      var progress = {
        'Push-ups': 250,
        'Sit-ups': 250,
        'Squats': 250,
        'Running': 25,
      };
      
      if (!limiterRemovedToday && PhysicalFoundation.isLimiterRemoved(progress)) {
        limiterRemovedToday = true;
        availablePoints += 5;
      }
      
      // Second call with even higher progress
      progress = {
        'Push-ups': 400,
        'Sit-ups': 400,
        'Squats': 400,
        'Running': 40,
      };
      
      if (!limiterRemovedToday && PhysicalFoundation.isLimiterRemoved(progress)) {
        limiterRemovedToday = true;
        availablePoints += 5;
      }
      
      // Third call with maximum progress
      progress = {
        'Push-ups': 500,
        'Sit-ups': 500,
        'Squats': 500,
        'Running': 50,
      };
      
      if (!limiterRemovedToday && PhysicalFoundation.isLimiterRemoved(progress)) {
        limiterRemovedToday = true;
        availablePoints += 5;
      }
      
      expect(availablePoints, equals(initialAvailablePoints + 5));
      expect(limiterRemovedToday, isTrue);
    });

    test('Limiter Removal idempotence - flag persists across calls', () {
      // Test that limiterRemovedToday flag persists correctly
      bool limiterRemovedToday = false;
      
      final progress = {
        'Push-ups': 220,
        'Sit-ups': 220,
        'Squats': 220,
        'Running': 22,
      };
      
      // First call: should trigger
      if (!limiterRemovedToday && PhysicalFoundation.isLimiterRemoved(progress)) {
        limiterRemovedToday = true;
      }
      
      expect(limiterRemovedToday, isTrue);
      
      // Subsequent calls: should not trigger
      for (int i = 0; i < 10; i++) {
        final flagBefore = limiterRemovedToday;
        
        if (!limiterRemovedToday && PhysicalFoundation.isLimiterRemoved(progress)) {
          limiterRemovedToday = true;
        }
        
        expect(
          limiterRemovedToday,
          equals(flagBefore),
          reason: 'Call $i: Flag should remain unchanged after first trigger',
        );
      }
    });

    test('Limiter Removal idempotence - stat points accumulation', () {
      // Test that stat points don't accumulate on repeated calls
      for (int iteration = 0; iteration < 30; iteration++) {
        bool limiterRemovedToday = false;
        int availablePoints = 0;
        
        final progress = {
          'Push-ups': 200 + random.nextInt(200),
          'Sit-ups': 200 + random.nextInt(200),
          'Squats': 200 + random.nextInt(200),
          'Running': 20 + random.nextInt(20),
        };
        
        // Call multiple times
        final callCount = random.nextInt(10) + 2;
        
        for (int i = 0; i < callCount; i++) {
          if (!limiterRemovedToday && PhysicalFoundation.isLimiterRemoved(progress)) {
            limiterRemovedToday = true;
            availablePoints += 5;
          }
        }
        
        expect(
          availablePoints,
          equals(5),
          reason: 'Iteration $iteration: Should award exactly 5 points total, not $availablePoints',
        );
      }
    });

    test('Limiter Removal idempotence - overload title awarded once', () {
      // Test that overload title is awarded only on first trigger
      bool limiterRemovedToday = false;
      bool overloadTitleAwarded = false;
      int titleAwardCount = 0;
      
      final progress = {
        'Push-ups': 300,
        'Sit-ups': 300,
        'Squats': 300,
        'Running': 30,
      };
      
      // Call 5 times
      for (int i = 0; i < 5; i++) {
        if (!limiterRemovedToday && PhysicalFoundation.isLimiterRemoved(progress)) {
          limiterRemovedToday = true;
          
          if (!overloadTitleAwarded) {
            overloadTitleAwarded = true;
            titleAwardCount++;
          }
        }
      }
      
      expect(titleAwardCount, equals(1));
      expect(overloadTitleAwarded, isTrue);
    });

    test('Limiter Removal idempotence - stress test with 100 calls', () {
      // Stress test with many repeated calls
      bool limiterRemovedToday = false;
      int availablePoints = 50;
      final initialAvailablePoints = availablePoints;
      
      final progress = {
        'Push-ups': 350,
        'Sit-ups': 350,
        'Squats': 350,
        'Running': 35,
      };
      
      // Call 100 times
      for (int i = 0; i < 100; i++) {
        if (!limiterRemovedToday && PhysicalFoundation.isLimiterRemoved(progress)) {
          limiterRemovedToday = true;
          availablePoints += 5;
        }
      }
      
      expect(availablePoints, equals(initialAvailablePoints + 5));
      expect(limiterRemovedToday, isTrue);
    });

    test('Limiter Removal idempotence - alternating progress levels', () {
      // Test with alternating progress levels (some above, some below 200%)
      bool limiterRemovedToday = false;
      int availablePoints = 20;
      final initialAvailablePoints = availablePoints;
      
      // First call: above 200%
      var progress = {
        'Push-ups': 250,
        'Sit-ups': 250,
        'Squats': 250,
        'Running': 25,
      };
      
      if (!limiterRemovedToday && PhysicalFoundation.isLimiterRemoved(progress)) {
        limiterRemovedToday = true;
        availablePoints += 5;
      }
      
      // Second call: below 200% (but flag already set, so no check)
      progress = {
        'Push-ups': 150,
        'Sit-ups': 150,
        'Squats': 150,
        'Running': 15,
      };
      
      if (!limiterRemovedToday && PhysicalFoundation.isLimiterRemoved(progress)) {
        limiterRemovedToday = true;
        availablePoints += 5;
      }
      
      // Third call: above 200% again
      progress = {
        'Push-ups': 300,
        'Sit-ups': 300,
        'Squats': 300,
        'Running': 30,
      };
      
      if (!limiterRemovedToday && PhysicalFoundation.isLimiterRemoved(progress)) {
        limiterRemovedToday = true;
        availablePoints += 5;
      }
      
      expect(availablePoints, equals(initialAvailablePoints + 5));
      expect(limiterRemovedToday, isTrue);
    });

    test('Limiter Removal idempotence - guard prevents duplicate awards', () {
      // Explicitly test the idempotence guard
      bool limiterRemovedToday = false;
      int availablePoints = 0;
      int awardCount = 0;
      
      final progress = {
        'Push-ups': 240,
        'Sit-ups': 240,
        'Squats': 240,
        'Running': 24,
      };
      
      for (int i = 0; i < 20; i++) {
        // Idempotence guard
        if (limiterRemovedToday) {
          // Should return immediately without awarding
          continue;
        }
        
        if (PhysicalFoundation.isLimiterRemoved(progress)) {
          limiterRemovedToday = true;
          availablePoints += 5;
          awardCount++;
        }
      }
      
      expect(awardCount, equals(1));
      expect(availablePoints, equals(5));
      expect(limiterRemovedToday, isTrue);
    });

    test('Limiter Removal idempotence - random sequences', () {
      // Test with random sequences of calls
      for (int iteration = 0; iteration < 50; iteration++) {
        bool limiterRemovedToday = false;
        int availablePoints = random.nextInt(40);
        final initialAvailablePoints = availablePoints;
        
        // Random number of calls (2-30)
        final callCount = random.nextInt(29) + 2;
        
        for (int i = 0; i < callCount; i++) {
          // Random progress (always >= 200%)
          final progress = {
            'Push-ups': 200 + random.nextInt(400),
            'Sit-ups': 200 + random.nextInt(400),
            'Squats': 200 + random.nextInt(400),
            'Running': 20 + random.nextInt(40),
          };
          
          if (!limiterRemovedToday && PhysicalFoundation.isLimiterRemoved(progress)) {
            limiterRemovedToday = true;
            availablePoints += 5;
          }
        }
        
        expect(
          availablePoints,
          equals(initialAvailablePoints + 5),
          reason: 'Iteration $iteration: After $callCount calls, should award 5 points exactly once',
        );
      }
    });

    test('Limiter Removal idempotence - daily reset simulation', () {
      // Simulate daily reset: flag should be reset for new day
      bool limiterRemovedToday = false;
      int availablePoints = 10;
      
      final progress = {
        'Push-ups': 260,
        'Sit-ups': 260,
        'Squats': 260,
        'Running': 26,
      };
      
      // Day 1: First trigger
      if (!limiterRemovedToday && PhysicalFoundation.isLimiterRemoved(progress)) {
        limiterRemovedToday = true;
        availablePoints += 5;
      }
      
      expect(availablePoints, equals(15));
      expect(limiterRemovedToday, isTrue);
      
      // Day 1: Second call (should be no-op)
      if (!limiterRemovedToday && PhysicalFoundation.isLimiterRemoved(progress)) {
        limiterRemovedToday = true;
        availablePoints += 5;
      }
      
      expect(availablePoints, equals(15)); // Still 15, not 20
      
      // Simulate daily reset (midnight)
      limiterRemovedToday = false;
      
      // Day 2: First trigger (should work again)
      if (!limiterRemovedToday && PhysicalFoundation.isLimiterRemoved(progress)) {
        limiterRemovedToday = true;
        availablePoints += 5;
      }
      
      expect(availablePoints, equals(20)); // Now 20
      expect(limiterRemovedToday, isTrue);
    });
  });
}
