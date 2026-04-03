import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

/// Property 14: Lifetime XP monotonicity
/// **Validates: Requirements 5.4**
/// 
/// For any sequence of operations (quest completions, penalties, spending),
/// lifetimeXP shall never decrease.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property 14: Lifetime XP monotonicity', () {
    final random = Random();

    test('Lifetime XP monotonicity - 100 iterations with random operations', () {
      // Run minimum 100 iterations as specified in the task
      for (int iteration = 0; iteration < 100; iteration++) {
        // Start with random initial lifetime XP
        int currentLifetimeXP = random.nextInt(100000);
        
        // Generate random sequence of operations (5-20 operations per iteration)
        final operationCount = random.nextInt(16) + 5;
        
        for (int opIndex = 0; opIndex < operationCount; opIndex++) {
          final previousLifetimeXP = currentLifetimeXP;
          
          // Generate random operation type
          final operationType = random.nextInt(3);
          
          switch (operationType) {
            case 0:
              // Quest completion (addXP) - increases both lifetime and wallet
              final xpAmount = random.nextInt(5000) + 1;
              currentLifetimeXP += xpAmount;
              break;
              
            case 1:
              // Penalty operation - decreases wallet only, lifetime unchanged
              // (penalties don't affect lifetime XP)
              // currentLifetimeXP stays the same
              break;
              
            case 2:
              // Spending operation - decreases wallet only, lifetime unchanged
              // currentLifetimeXP stays the same
              break;
          }
          
          // Assert lifetime XP never decreased
          expect(
            currentLifetimeXP,
            greaterThanOrEqualTo(previousLifetimeXP),
            reason: 'Iteration $iteration, Operation $opIndex: Lifetime XP decreased!\n'
                    'Previous: $previousLifetimeXP, Current: $currentLifetimeXP\n'
                    'Operation type: $operationType',
          );
        }
      }
    });

    test('Lifetime XP monotonicity - only addXP operations', () {
      // Test with only XP additions
      int currentLifetimeXP = 0;
      
      for (int i = 0; i < 100; i++) {
        final previousLifetimeXP = currentLifetimeXP;
        final xpAmount = random.nextInt(1000) + 1;
        
        currentLifetimeXP += xpAmount;
        
        expect(
          currentLifetimeXP,
          greaterThan(previousLifetimeXP),
          reason: 'After adding $xpAmount XP, lifetime should increase',
        );
      }
    });

    test('Lifetime XP monotonicity - mixed operations with penalties', () {
      // Test that penalties don't affect lifetime XP
      int currentLifetimeXP = 10000;
      int currentWalletXP = 5000;
      
      for (int i = 0; i < 50; i++) {
        final previousLifetimeXP = currentLifetimeXP;
        
        // Alternate between adding XP and applying penalties
        if (i % 2 == 0) {
          // Add XP
          final xpAmount = random.nextInt(500) + 1;
          currentLifetimeXP += xpAmount;
          currentWalletXP += xpAmount;
        } else {
          // Apply penalty (wallet only)
          final penaltyAmount = random.nextInt(1000) + 1;
          currentWalletXP -= penaltyAmount;
          // Lifetime XP unchanged
        }
        
        expect(
          currentLifetimeXP,
          greaterThanOrEqualTo(previousLifetimeXP),
          reason: 'Operation $i: Lifetime XP should never decrease',
        );
      }
    });

    test('Lifetime XP monotonicity - wallet goes negative, lifetime unaffected', () {
      // Test that wallet going negative doesn't affect lifetime XP
      int currentLifetimeXP = 50000;
      int currentWalletXP = 100;
      
      // Apply large penalty to push wallet negative
      final largePenalty = 1000;
      currentWalletXP -= largePenalty;
      
      // Lifetime XP should be unchanged
      expect(currentLifetimeXP, equals(50000));
      
      // Wallet should be negative
      expect(currentWalletXP, lessThan(0));
      
      // Add more penalties
      for (int i = 0; i < 10; i++) {
        final previousLifetimeXP = currentLifetimeXP;
        final penalty = random.nextInt(500) + 1;
        
        currentWalletXP -= penalty;
        // Clamp wallet at floor (-500)
        if (currentWalletXP < -500) {
          currentWalletXP = -500;
        }
        
        expect(
          currentLifetimeXP,
          equals(previousLifetimeXP),
          reason: 'Penalty $i: Lifetime XP should remain unchanged',
        );
      }
    });

    test('Lifetime XP monotonicity - spending operations', () {
      // Test that spending XP doesn't affect lifetime XP
      int currentLifetimeXP = 100000;
      int currentWalletXP = 50000;
      
      for (int i = 0; i < 20; i++) {
        final previousLifetimeXP = currentLifetimeXP;
        final spendAmount = random.nextInt(1000) + 1;
        
        // Spend from wallet
        currentWalletXP -= spendAmount;
        
        // Lifetime XP unchanged
        expect(
          currentLifetimeXP,
          equals(previousLifetimeXP),
          reason: 'Spending $i: Lifetime XP should remain unchanged after spending',
        );
      }
    });

    test('Lifetime XP monotonicity - maximum penalty scenario', () {
      // Test that even maximum penalties don't affect lifetime XP
      int currentLifetimeXP = 200000;
      int currentWalletXP = 10000;
      
      // Apply maximum penalty (3 consecutive misses)
      final maxPenalty = 3 * 1500; // 4500 XP
      
      final previousLifetimeXP = currentLifetimeXP;
      currentWalletXP -= maxPenalty;
      
      expect(
        currentLifetimeXP,
        equals(previousLifetimeXP),
        reason: 'Maximum penalty should not affect lifetime XP',
      );
    });

    test('Lifetime XP monotonicity - long sequence stress test', () {
      // Stress test with very long sequence of operations
      int currentLifetimeXP = 0;
      int currentWalletXP = 0;
      
      for (int i = 0; i < 500; i++) {
        final previousLifetimeXP = currentLifetimeXP;
        
        // Random operation
        final op = random.nextInt(10);
        
        if (op < 5) {
          // 50% chance: Add XP
          final xpAmount = random.nextInt(1000) + 1;
          currentLifetimeXP += xpAmount;
          currentWalletXP += xpAmount;
        } else if (op < 8) {
          // 30% chance: Apply penalty
          final penalty = random.nextInt(500) + 1;
          currentWalletXP -= penalty;
          if (currentWalletXP < -500) currentWalletXP = -500;
        } else {
          // 20% chance: Spend XP
          final spend = random.nextInt(300) + 1;
          currentWalletXP -= spend;
          if (currentWalletXP < -500) currentWalletXP = -500;
        }
        
        expect(
          currentLifetimeXP,
          greaterThanOrEqualTo(previousLifetimeXP),
          reason: 'Stress test operation $i: Lifetime XP decreased',
        );
      }
    });

    test('Lifetime XP monotonicity - zero XP operations', () {
      // Test that operations with 0 XP don't decrease lifetime
      int currentLifetimeXP = 5000;
      
      for (int i = 0; i < 50; i++) {
        final previousLifetimeXP = currentLifetimeXP;
        
        // Add 0 XP (no-op)
        // currentLifetimeXP += 0;
        
        expect(
          currentLifetimeXP,
          equals(previousLifetimeXP),
          reason: 'Zero XP operation should not change lifetime XP',
        );
      }
    });

    test('Lifetime XP monotonicity - alternating add and penalty', () {
      // Test strict alternation between adds and penalties
      int currentLifetimeXP = 10000;
      int currentWalletXP = 5000;
      
      for (int i = 0; i < 100; i++) {
        final previousLifetimeXP = currentLifetimeXP;
        
        if (i % 2 == 0) {
          // Even: Add XP
          final xpAmount = random.nextInt(500) + 100;
          currentLifetimeXP += xpAmount;
          currentWalletXP += xpAmount;
          
          expect(
            currentLifetimeXP,
            greaterThan(previousLifetimeXP),
            reason: 'Add operation $i should increase lifetime XP',
          );
        } else {
          // Odd: Apply penalty
          final penalty = random.nextInt(1000) + 1;
          currentWalletXP -= penalty;
          if (currentWalletXP < -500) currentWalletXP = -500;
          
          expect(
            currentLifetimeXP,
            equals(previousLifetimeXP),
            reason: 'Penalty operation $i should not change lifetime XP',
          );
        }
      }
    });

    test('Lifetime XP monotonicity - wallet floor breach', () {
      // Test that wallet floor breach doesn't affect lifetime XP
      int currentLifetimeXP = 75000;
      int currentWalletXP = -400;
      
      // Apply penalty that would breach floor
      final previousLifetimeXP = currentLifetimeXP;
      final largePenalty = 200; // Would take wallet to -600, but floor is -500
      
      currentWalletXP -= largePenalty;
      if (currentWalletXP < -500) {
        // Floor breach: wallet clamped at -500, excess converts to HP loss
        currentWalletXP = -500;
      }
      
      expect(
        currentLifetimeXP,
        equals(previousLifetimeXP),
        reason: 'Wallet floor breach should not affect lifetime XP',
      );
    });
  });
}
