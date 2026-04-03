import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:arise_os/player_provider.dart';

/// Property 12: Level formula correctness
/// **Validates: Requirements 5.2**
/// 
/// For any non-negative integer lifetimeXP,
/// PlayerProvider.calculateLevel(lifetimeXP) shall equal (sqrt(lifetimeXP) / 10).floor() + 1.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property 12: Level formula correctness', () {
    final random = Random();

    /// Helper function to compute the expected level using the formula
    /// Level = floor(sqrt(LifetimeXP) / 10) + 1
    int computeExpectedLevel(int lifetimeXP) {
      return (sqrt(lifetimeXP.toDouble()) / 10).floor() + 1;
    }

    test('Level formula correctness - 100 iterations', () {
      // Run minimum 100 iterations as specified in the task
      for (int iteration = 0; iteration < 100; iteration++) {
        // Generate random non-negative int
        // Use a reasonable range: 0 to 10,000,000 (covers levels 1 to ~316)
        final xp = random.nextInt(10000001);
        
        // Compute the actual level using PlayerProvider.calculateLevel
        final actualLevel = PlayerProvider.calculateLevel(xp);
        
        // Compute the expected level using the formula
        final expectedLevel = computeExpectedLevel(xp);
        
        // Assert they are equal
        expect(
          actualLevel,
          equals(expectedLevel),
          reason: 'Iteration $iteration: XP: $xp\n'
                  'Expected level: $expectedLevel\n'
                  'Actual level: $actualLevel',
        );
      }
    });

    test('Level formula correctness - edge cases', () {
      final edgeCases = [
        // Minimum XP (0)
        0,
        
        // XP for level 1 (0-99)
        1,
        50,
        99,
        
        // XP for level 2 (100-399)
        100,
        200,
        399,
        
        // XP for level 3 (400-899)
        400,
        500,
        899,
        
        // XP for level 10 (8100-9999)
        8100,
        9000,
        9999,
        
        // XP for level 50 (240100-250000)
        240100,
        245000,
        249999,
        
        // XP for level 100 (990100-1000000)
        990100,
        995000,
        999999,
        
        // Large XP values
        1000000,
        5000000,
        10000000,
      ];

      for (int i = 0; i < edgeCases.length; i++) {
        final xp = edgeCases[i];
        final actualLevel = PlayerProvider.calculateLevel(xp);
        final expectedLevel = computeExpectedLevel(xp);
        
        expect(
          actualLevel,
          equals(expectedLevel),
          reason: 'Edge case $i: XP: $xp\n'
                  'Expected level: $expectedLevel\n'
                  'Actual level: $actualLevel',
        );
      }
    });

    test('Level formula correctness - boundary values', () {
      // Test exact boundary values where level changes
      // Level 1: XP 0-99 (sqrt(0)/10 = 0, sqrt(99)/10 = 0.99...)
      expect(PlayerProvider.calculateLevel(0), equals(1));
      expect(PlayerProvider.calculateLevel(99), equals(1));
      
      // Level 2: XP 100-399 (sqrt(100)/10 = 1.0, sqrt(399)/10 = 1.99...)
      expect(PlayerProvider.calculateLevel(100), equals(2));
      expect(PlayerProvider.calculateLevel(399), equals(2));
      
      // Level 3: XP 400-899 (sqrt(400)/10 = 2.0, sqrt(899)/10 = 2.99...)
      expect(PlayerProvider.calculateLevel(400), equals(3));
      expect(PlayerProvider.calculateLevel(899), equals(3));
      
      // Level 10: XP 8100-9999 (sqrt(8100)/10 = 9.0, sqrt(9999)/10 = 9.99...)
      expect(PlayerProvider.calculateLevel(8100), equals(10));
      expect(PlayerProvider.calculateLevel(9999), equals(10));
      
      // Level 11: XP 10000-12099 (sqrt(10000)/10 = 10.0)
      expect(PlayerProvider.calculateLevel(10000), equals(11));
      expect(PlayerProvider.calculateLevel(12099), equals(11));
    });

    test('Level formula correctness - monotonicity', () {
      // Verify that level never decreases as XP increases
      int previousLevel = 1;
      
      for (int iteration = 0; iteration < 100; iteration++) {
        // Generate increasing XP values
        final xp = iteration * 1000;
        final level = PlayerProvider.calculateLevel(xp);
        
        expect(
          level,
          greaterThanOrEqualTo(previousLevel),
          reason: 'Level should never decrease as XP increases.\n'
                  'XP: $xp, Level: $level, Previous Level: $previousLevel',
        );
        
        previousLevel = level;
      }
    });

    test('Level formula correctness - minimum level is 1', () {
      // Verify that level is always at least 1, even with 0 XP
      for (int xp = 0; xp < 100; xp++) {
        final level = PlayerProvider.calculateLevel(xp);
        
        expect(
          level,
          greaterThanOrEqualTo(1),
          reason: 'Level should always be at least 1.\n'
                  'XP: $xp, Level: $level',
        );
      }
    });

    test('Level formula correctness - random stress test', () {
      // Additional stress test with completely random values
      for (int iteration = 0; iteration < 200; iteration++) {
        // Generate random XP from 0 to 100,000,000 (covers levels 1 to ~1000)
        final xp = random.nextInt(100000001);
        
        final actualLevel = PlayerProvider.calculateLevel(xp);
        final expectedLevel = computeExpectedLevel(xp);
        
        // Verify the result is at least 1
        expect(
          actualLevel,
          greaterThanOrEqualTo(1),
          reason: 'Level must be at least 1',
        );
        
        // Verify formula correctness
        expect(
          actualLevel,
          equals(expectedLevel),
          reason: 'Stress test iteration $iteration: XP: $xp\n'
                  'Expected level: $expectedLevel\n'
                  'Actual level: $actualLevel',
        );
      }
    });

    test('Level formula correctness - specific level thresholds', () {
      // Test specific XP values that should produce known levels
      final levelThresholds = {
        // Level 1: 0 <= XP < 100
        1: [0, 50, 99],
        
        // Level 2: 100 <= XP < 400
        2: [100, 250, 399],
        
        // Level 5: 1600 <= XP < 2500
        5: [1600, 2000, 2499],
        
        // Level 10: 8100 <= XP < 10000
        10: [8100, 9000, 9999],
        
        // Level 20: 36100 <= XP < 40000
        20: [36100, 38000, 39999],
        
        // Level 50: 240100 <= XP < 250000
        50: [240100, 245000, 249999],
        
        // Level 100: 990100 <= XP < 1000000
        100: [990100, 995000, 999999],
      };

      levelThresholds.forEach((expectedLevel, xpValues) {
        for (final xp in xpValues) {
          final actualLevel = PlayerProvider.calculateLevel(xp);
          
          expect(
            actualLevel,
            equals(expectedLevel),
            reason: 'XP $xp should produce level $expectedLevel, got $actualLevel',
          );
        }
      });
    });

    test('Level formula correctness - formula verification', () {
      // Explicitly verify the formula: Level = floor(sqrt(LifetimeXP) / 10) + 1
      // by testing the mathematical relationship
      
      for (int level = 1; level <= 100; level++) {
        // Calculate the minimum XP required for this level
        // From: level = floor(sqrt(xp) / 10) + 1
        // => level - 1 = floor(sqrt(xp) / 10)
        // => (level - 1) * 10 = floor(sqrt(xp))
        // => ((level - 1) * 10)^2 = xp (minimum)
        final minXP = ((level - 1) * 10) * ((level - 1) * 10);
        
        // Calculate the maximum XP for this level (just before next level)
        final maxXP = (level * 10) * (level * 10) - 1;
        
        // Verify minimum XP produces this level
        expect(
          PlayerProvider.calculateLevel(minXP),
          equals(level),
          reason: 'Minimum XP $minXP should produce level $level',
        );
        
        // Verify maximum XP produces this level
        expect(
          PlayerProvider.calculateLevel(maxXP),
          equals(level),
          reason: 'Maximum XP $maxXP should produce level $level',
        );
        
        // Verify next XP produces next level
        if (level < 100) {
          expect(
            PlayerProvider.calculateLevel(maxXP + 1),
            equals(level + 1),
            reason: 'XP ${maxXP + 1} should produce level ${level + 1}',
          );
        }
      }
    });
  });
}
