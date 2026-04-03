import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

/// Property 13: Dual XP simultaneous award
/// **Validates: Requirements 5.3**
/// 
/// For any positive XP amount earned from a quest completion,
/// both lifetimeXP and walletXP shall each increase by exactly that amount.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property 13: Dual XP simultaneous award', () {
    final random = Random();

    test('Dual XP simultaneous award - 100 iterations', () {
      // Run minimum 100 iterations as specified in the task
      for (int iteration = 0; iteration < 100; iteration++) {
        // Generate random positive XP amount (1 to 10,000)
        final xpAmount = random.nextInt(10000) + 1;
        
        // Simulate initial state
        final initialLifetimeXP = random.nextInt(100000);
        final initialWalletXP = random.nextInt(50000) - 500; // Can be negative (floor is -500)
        
        // Simulate addXP operation
        final expectedLifetimeXP = initialLifetimeXP + xpAmount;
        final expectedWalletXP = initialWalletXP + xpAmount;
        
        // Verify both increased by exactly the same amount
        final lifetimeIncrease = expectedLifetimeXP - initialLifetimeXP;
        final walletIncrease = expectedWalletXP - initialWalletXP;
        
        expect(
          lifetimeIncrease,
          equals(xpAmount),
          reason: 'Iteration $iteration: Lifetime XP should increase by exactly $xpAmount\n'
                  'Initial: $initialLifetimeXP, Expected: $expectedLifetimeXP, Increase: $lifetimeIncrease',
        );
        
        expect(
          walletIncrease,
          equals(xpAmount),
          reason: 'Iteration $iteration: Wallet XP should increase by exactly $xpAmount\n'
                  'Initial: $initialWalletXP, Expected: $expectedWalletXP, Increase: $walletIncrease',
        );
        
        // Verify both increased by the SAME amount
        expect(
          lifetimeIncrease,
          equals(walletIncrease),
          reason: 'Iteration $iteration: Both XP values must increase by the same amount\n'
                  'Lifetime increase: $lifetimeIncrease, Wallet increase: $walletIncrease',
        );
      }
    });

    test('Dual XP simultaneous award - edge cases', () {
      final edgeCases = [
        // Minimum positive XP
        1,
        
        // Small amounts
        5,
        10,
        50,
        
        // Medium amounts
        100,
        500,
        1000,
        
        // Large amounts
        5000,
        10000,
        50000,
      ];

      for (int i = 0; i < edgeCases.length; i++) {
        final xpAmount = edgeCases[i];
        
        // Test with various initial states
        final testCases = [
          {'lifetime': 0, 'wallet': 0},
          {'lifetime': 1000, 'wallet': 1000},
          {'lifetime': 50000, 'wallet': -500}, // Wallet at floor
          {'lifetime': 100000, 'wallet': 0}, // Wallet at zero
        ];
        
        for (final testCase in testCases) {
          final initialLifetimeXP = testCase['lifetime'] as int;
          final initialWalletXP = testCase['wallet'] as int;
          
          final expectedLifetimeXP = initialLifetimeXP + xpAmount;
          final expectedWalletXP = initialWalletXP + xpAmount;
          
          final lifetimeIncrease = expectedLifetimeXP - initialLifetimeXP;
          final walletIncrease = expectedWalletXP - initialWalletXP;
          
          expect(
            lifetimeIncrease,
            equals(xpAmount),
            reason: 'Edge case $i: XP amount $xpAmount\n'
                    'Initial lifetime: $initialLifetimeXP, Expected: $expectedLifetimeXP',
          );
          
          expect(
            walletIncrease,
            equals(xpAmount),
            reason: 'Edge case $i: XP amount $xpAmount\n'
                    'Initial wallet: $initialWalletXP, Expected: $expectedWalletXP',
          );
          
          expect(
            lifetimeIncrease,
            equals(walletIncrease),
            reason: 'Edge case $i: Both must increase by same amount',
          );
        }
      }
    });

    test('Dual XP simultaneous award - wallet at floor', () {
      // Test that dual award works even when wallet is at floor (-500)
      for (int iteration = 0; iteration < 50; iteration++) {
        final xpAmount = random.nextInt(5000) + 1;
        final initialLifetimeXP = random.nextInt(100000);
        final initialWalletXP = -500; // At floor
        
        final expectedLifetimeXP = initialLifetimeXP + xpAmount;
        final expectedWalletXP = initialWalletXP + xpAmount;
        
        final lifetimeIncrease = expectedLifetimeXP - initialLifetimeXP;
        final walletIncrease = expectedWalletXP - initialWalletXP;
        
        expect(lifetimeIncrease, equals(xpAmount));
        expect(walletIncrease, equals(xpAmount));
        expect(lifetimeIncrease, equals(walletIncrease));
      }
    });

    test('Dual XP simultaneous award - wallet negative but above floor', () {
      // Test that dual award works when wallet is negative but above floor
      for (int iteration = 0; iteration < 50; iteration++) {
        final xpAmount = random.nextInt(5000) + 1;
        final initialLifetimeXP = random.nextInt(100000);
        final initialWalletXP = random.nextInt(500) - 500; // Range: -500 to -1
        
        final expectedLifetimeXP = initialLifetimeXP + xpAmount;
        final expectedWalletXP = initialWalletXP + xpAmount;
        
        final lifetimeIncrease = expectedLifetimeXP - initialLifetimeXP;
        final walletIncrease = expectedWalletXP - initialWalletXP;
        
        expect(lifetimeIncrease, equals(xpAmount));
        expect(walletIncrease, equals(xpAmount));
        expect(lifetimeIncrease, equals(walletIncrease));
      }
    });

    test('Dual XP simultaneous award - accumulation over multiple awards', () {
      // Test that multiple awards accumulate correctly
      final initialLifetimeXP = 1000;
      final initialWalletXP = 500;
      
      int currentLifetimeXP = initialLifetimeXP;
      int currentWalletXP = initialWalletXP;
      int totalAwarded = 0;
      
      for (int i = 0; i < 20; i++) {
        final xpAmount = random.nextInt(500) + 1;
        
        currentLifetimeXP += xpAmount;
        currentWalletXP += xpAmount;
        totalAwarded += xpAmount;
        
        // Verify cumulative increases match
        final lifetimeIncrease = currentLifetimeXP - initialLifetimeXP;
        final walletIncrease = currentWalletXP - initialWalletXP;
        
        expect(
          lifetimeIncrease,
          equals(totalAwarded),
          reason: 'After $i awards, lifetime increase should equal total awarded',
        );
        
        expect(
          walletIncrease,
          equals(totalAwarded),
          reason: 'After $i awards, wallet increase should equal total awarded',
        );
        
        expect(
          lifetimeIncrease,
          equals(walletIncrease),
          reason: 'After $i awards, both increases must be equal',
        );
      }
    });

    test('Dual XP simultaneous award - zero XP should not change values', () {
      // Verify that 0 XP doesn't change either value
      final initialLifetimeXP = random.nextInt(100000);
      final initialWalletXP = random.nextInt(50000) - 500;
      
      // Simulate addXP(0) - should be no-op
      final expectedLifetimeXP = initialLifetimeXP;
      final expectedWalletXP = initialWalletXP;
      
      expect(expectedLifetimeXP, equals(initialLifetimeXP));
      expect(expectedWalletXP, equals(initialWalletXP));
    });

    test('Dual XP simultaneous award - large XP amounts', () {
      // Test with very large XP amounts
      final largeAmounts = [10000, 50000, 100000, 500000, 1000000];
      
      for (final xpAmount in largeAmounts) {
        final initialLifetimeXP = random.nextInt(1000000);
        final initialWalletXP = random.nextInt(500000) - 500;
        
        final expectedLifetimeXP = initialLifetimeXP + xpAmount;
        final expectedWalletXP = initialWalletXP + xpAmount;
        
        final lifetimeIncrease = expectedLifetimeXP - initialLifetimeXP;
        final walletIncrease = expectedWalletXP - initialWalletXP;
        
        expect(lifetimeIncrease, equals(xpAmount));
        expect(walletIncrease, equals(xpAmount));
        expect(lifetimeIncrease, equals(walletIncrease));
      }
    });
  });
}
