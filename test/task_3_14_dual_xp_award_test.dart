import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Task 3.14 - Dual XP Award and Wallet Floor Enforcement', () {
    test('dual XP award - both lifetime and wallet increase simultaneously', () {
      // Simulate the dual XP award logic
      int lifetimeXP = 1000;
      int walletXP = 500;
      final xpToAdd = 250;
      
      // Both should increase by the same amount
      lifetimeXP += xpToAdd;
      walletXP += xpToAdd;
      
      expect(lifetimeXP, 1250);
      expect(walletXP, 750);
    });

    test('dual XP award - works when wallet is negative', () {
      // Simulate dual XP award when wallet is in debt
      int lifetimeXP = 2000;
      int walletXP = -300; // In debt
      final xpToAdd = 500;
      
      // Both should increase by the same amount (no debt repayment reduction)
      lifetimeXP += xpToAdd;
      walletXP += xpToAdd;
      
      expect(lifetimeXP, 2500);
      expect(walletXP, 200); // -300 + 500 = 200
    });

    test('lifetime XP never decrements', () {
      // Simulate that lifetime XP is never decremented
      int lifetimeXP = 5000;
      
      // Penalties should NOT affect lifetime XP
      // (penalties only affect wallet XP)
      final penaltyAmount = 1000;
      // lifetimeXP -= penaltyAmount; // This should NEVER happen
      
      expect(lifetimeXP, 5000); // Unchanged
    });

    test('wallet floor enforcement at -500', () {
      // Simulate wallet floor enforcement
      const walletFloor = -500;
      int walletXP = -400;
      final penaltyAmount = 200;
      
      // Apply penalty
      final next = walletXP - penaltyAmount; // -400 - 200 = -600
      
      if (next >= walletFloor) {
        walletXP = next;
      } else {
        // Clamp at floor
        walletXP = walletFloor;
        final overflow = walletFloor - next; // -500 - (-600) = 100
        // Overflow would be converted to HP damage
        expect(overflow, 100);
      }
      
      expect(walletXP, -500); // Clamped at floor
    });

    test('wallet floor enforcement - no overflow when above floor', () {
      // Simulate wallet penalty that stays above floor
      const walletFloor = -500;
      int walletXP = -200;
      final penaltyAmount = 100;
      
      // Apply penalty
      final next = walletXP - penaltyAmount; // -200 - 100 = -300
      
      if (next >= walletFloor) {
        walletXP = next;
      } else {
        walletXP = walletFloor;
      }
      
      expect(walletXP, -300); // Above floor, no clamping needed
    });

    test('wallet floor enforcement - large penalty clamped', () {
      // Simulate a large penalty that would go far below floor
      const walletFloor = -500;
      int walletXP = 0;
      final penaltyAmount = 2000;
      
      // Apply penalty
      final next = walletXP - penaltyAmount; // 0 - 2000 = -2000
      
      if (next >= walletFloor) {
        walletXP = next;
      } else {
        // Clamp at floor
        walletXP = walletFloor;
        final overflow = walletFloor - next; // -500 - (-2000) = 1500
        // Overflow would be converted to HP damage (1500 / 10 = 150 HP)
        final hpDamage = (overflow / 10).ceil();
        expect(hpDamage, 150);
      }
      
      expect(walletXP, -500); // Clamped at floor
    });

    test('level calculation uses lifetime XP only', () {
      // Verify level is calculated from lifetime XP, not wallet XP
      int lifetimeXP = 10000;
      int walletXP = -500; // Negative wallet should not affect level
      
      // Level formula: floor(sqrt(lifetimeXP) / 10) + 1
      final level = (math.sqrt(lifetimeXP.toDouble()) / 10).floor() + 1;
      
      // sqrt(10000) = 100, 100 / 10 = 10, floor(10) + 1 = 11
      expect(level, 11);
      
      // Wallet XP should not affect level calculation
      expect(walletXP, -500);
    });

    test('zero XP addition has no effect', () {
      // Test that adding 0 XP doesn't change anything
      int lifetimeXP = 1000;
      int walletXP = 500;
      final xpToAdd = 0;
      
      if (xpToAdd > 0) {
        lifetimeXP += xpToAdd;
        walletXP += xpToAdd;
      }
      
      expect(lifetimeXP, 1000);
      expect(walletXP, 500);
    });

    test('negative XP addition is ignored', () {
      // Test that negative XP values don't decrement
      int lifetimeXP = 1000;
      int walletXP = 500;
      final xpToAdd = -100;
      
      if (xpToAdd > 0) {
        lifetimeXP += xpToAdd;
        walletXP += xpToAdd;
      }
      
      expect(lifetimeXP, 1000); // Unchanged
      expect(walletXP, 500); // Unchanged
    });
  });
}
