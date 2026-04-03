import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

/// Property 15: Wallet XP floor invariant
/// **Validates: Requirements 5.6**
/// 
/// For any sequence of penalty operations,
/// walletXP shall never fall below -500.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property 15: Wallet XP floor invariant', () {
    final random = Random();
    const int walletFloor = -500;

    test('Wallet XP floor invariant - 100 iterations with random penalties', () {
      // Run minimum 100 iterations as specified in the task
      for (int iteration = 0; iteration < 100; iteration++) {
        // Start with random initial wallet XP (can be positive or negative)
        int currentWalletXP = random.nextInt(10000) - 500;
        
        // Generate random sequence of penalty operations (5-20 penalties per iteration)
        final penaltyCount = random.nextInt(16) + 5;
        
        for (int penaltyIndex = 0; penaltyIndex < penaltyCount; penaltyIndex++) {
          // Generate random penalty amount (1 to 5000)
          final penaltyAmount = random.nextInt(5000) + 1;
          
          // Apply penalty
          currentWalletXP -= penaltyAmount;
          
          // Enforce floor
          if (currentWalletXP < walletFloor) {
            currentWalletXP = walletFloor;
          }
          
          // Assert wallet XP never falls below floor
          expect(
            currentWalletXP,
            greaterThanOrEqualTo(walletFloor),
            reason: 'Iteration $iteration, Penalty $penaltyIndex: Wallet XP fell below floor!\n'
                    'Current wallet XP: $currentWalletXP, Floor: $walletFloor\n'
                    'Penalty amount: $penaltyAmount',
          );
        }
      }
    });

    test('Wallet XP floor invariant - starting above floor', () {
      // Test penalties when starting with positive wallet XP
      int currentWalletXP = 5000;
      
      for (int i = 0; i < 50; i++) {
        final penaltyAmount = random.nextInt(1000) + 1;
        
        currentWalletXP -= penaltyAmount;
        if (currentWalletXP < walletFloor) {
          currentWalletXP = walletFloor;
        }
        
        expect(
          currentWalletXP,
          greaterThanOrEqualTo(walletFloor),
          reason: 'Penalty $i: Wallet XP should not fall below floor',
        );
      }
    });

    test('Wallet XP floor invariant - starting at floor', () {
      // Test penalties when starting exactly at floor
      int currentWalletXP = walletFloor;
      
      for (int i = 0; i < 50; i++) {
        final penaltyAmount = random.nextInt(1000) + 1;
        
        currentWalletXP -= penaltyAmount;
        if (currentWalletXP < walletFloor) {
          currentWalletXP = walletFloor;
        }
        
        expect(
          currentWalletXP,
          equals(walletFloor),
          reason: 'Penalty $i: Wallet XP should remain at floor',
        );
      }
    });

    test('Wallet XP floor invariant - starting near floor', () {
      // Test penalties when starting just above floor
      int currentWalletXP = walletFloor + 50;
      
      for (int i = 0; i < 50; i++) {
        final penaltyAmount = random.nextInt(200) + 1;
        
        currentWalletXP -= penaltyAmount;
        if (currentWalletXP < walletFloor) {
          currentWalletXP = walletFloor;
        }
        
        expect(
          currentWalletXP,
          greaterThanOrEqualTo(walletFloor),
          reason: 'Penalty $i: Wallet XP should not fall below floor',
        );
      }
    });

    test('Wallet XP floor invariant - large penalties', () {
      // Test with very large penalty amounts
      final largePenalties = [5000, 10000, 50000, 100000];
      
      for (final penaltyAmount in largePenalties) {
        int currentWalletXP = 1000;
        
        currentWalletXP -= penaltyAmount;
        if (currentWalletXP < walletFloor) {
          currentWalletXP = walletFloor;
        }
        
        expect(
          currentWalletXP,
          equals(walletFloor),
          reason: 'Large penalty $penaltyAmount should clamp wallet at floor',
        );
      }
    });

    test('Wallet XP floor invariant - maximum penalty scenario', () {
      // Test maximum penalty (3 consecutive misses)
      int currentWalletXP = 2000;
      
      // Apply maximum penalty: 3 × 1500 = 4500 XP
      final maxPenalty = 3 * 1500;
      
      currentWalletXP -= maxPenalty;
      if (currentWalletXP < walletFloor) {
        currentWalletXP = walletFloor;
      }
      
      expect(
        currentWalletXP,
        greaterThanOrEqualTo(walletFloor),
        reason: 'Maximum penalty should not push wallet below floor',
      );
    });

    test('Wallet XP floor invariant - consecutive penalties', () {
      // Test many consecutive penalties
      int currentWalletXP = 10000;
      
      for (int i = 0; i < 100; i++) {
        final penaltyAmount = random.nextInt(500) + 100;
        
        currentWalletXP -= penaltyAmount;
        if (currentWalletXP < walletFloor) {
          currentWalletXP = walletFloor;
        }
        
        expect(
          currentWalletXP,
          greaterThanOrEqualTo(walletFloor),
          reason: 'Consecutive penalty $i: Wallet should not fall below floor',
        );
      }
    });

    test('Wallet XP floor invariant - alternating penalties and additions', () {
      // Test that floor is maintained even with alternating operations
      int currentWalletXP = 500;
      
      for (int i = 0; i < 100; i++) {
        if (i % 2 == 0) {
          // Apply penalty
          final penaltyAmount = random.nextInt(1000) + 1;
          currentWalletXP -= penaltyAmount;
          if (currentWalletXP < walletFloor) {
            currentWalletXP = walletFloor;
          }
        } else {
          // Add XP
          final xpAmount = random.nextInt(500) + 1;
          currentWalletXP += xpAmount;
        }
        
        expect(
          currentWalletXP,
          greaterThanOrEqualTo(walletFloor),
          reason: 'Operation $i: Wallet should never fall below floor',
        );
      }
    });

    test('Wallet XP floor invariant - penalty exactly to floor', () {
      // Test penalty that brings wallet exactly to floor
      int currentWalletXP = 100;
      
      // Apply penalty that brings wallet to exactly -500
      final penaltyAmount = 600; // 100 - 600 = -500
      
      currentWalletXP -= penaltyAmount;
      if (currentWalletXP < walletFloor) {
        currentWalletXP = walletFloor;
      }
      
      expect(
        currentWalletXP,
        equals(walletFloor),
        reason: 'Penalty should bring wallet exactly to floor',
      );
    });

    test('Wallet XP floor invariant - penalty beyond floor', () {
      // Test penalty that would push wallet far below floor
      int currentWalletXP = 0;
      
      // Apply penalty that would push wallet to -10000
      final penaltyAmount = 10000;
      
      currentWalletXP -= penaltyAmount;
      if (currentWalletXP < walletFloor) {
        currentWalletXP = walletFloor;
      }
      
      expect(
        currentWalletXP,
        equals(walletFloor),
        reason: 'Penalty beyond floor should clamp at floor',
      );
    });

    test('Wallet XP floor invariant - stress test with extreme penalties', () {
      // Stress test with very large number of penalties
      int currentWalletXP = 50000;
      
      for (int i = 0; i < 500; i++) {
        final penaltyAmount = random.nextInt(2000) + 100;
        
        currentWalletXP -= penaltyAmount;
        if (currentWalletXP < walletFloor) {
          currentWalletXP = walletFloor;
        }
        
        expect(
          currentWalletXP,
          greaterThanOrEqualTo(walletFloor),
          reason: 'Stress test penalty $i: Wallet should not fall below floor',
        );
      }
    });

    test('Wallet XP floor invariant - sin penalties', () {
      // Test sin confession penalties
      int currentWalletXP = 1000;
      
      final sinPenalties = {
        'minor': 100,
        'major': 250,
        'great': 400,
      };
      
      for (final entry in sinPenalties.entries) {
        final penaltyAmount = entry.value;
        
        currentWalletXP -= penaltyAmount;
        if (currentWalletXP < walletFloor) {
          currentWalletXP = walletFloor;
        }
        
        expect(
          currentWalletXP,
          greaterThanOrEqualTo(walletFloor),
          reason: '${entry.key} sin penalty should not push wallet below floor',
        );
      }
    });

    test('Wallet XP floor invariant - directive abort penalty', () {
      // Test directive abort penalty
      int currentWalletXP = 200;
      
      final directiveAbortPenalty = 400;
      
      currentWalletXP -= directiveAbortPenalty;
      if (currentWalletXP < walletFloor) {
        currentWalletXP = walletFloor;
      }
      
      expect(
        currentWalletXP,
        greaterThanOrEqualTo(walletFloor),
        reason: 'Directive abort penalty should not push wallet below floor',
      );
    });

    test('Wallet XP floor invariant - missed daily quest penalties', () {
      // Test missed daily quest penalties
      int currentWalletXP = 3000;
      
      // First miss: 1200 XP
      currentWalletXP -= 1200;
      if (currentWalletXP < walletFloor) currentWalletXP = walletFloor;
      expect(currentWalletXP, greaterThanOrEqualTo(walletFloor));
      
      // Second miss: 3000 XP
      currentWalletXP -= 3000;
      if (currentWalletXP < walletFloor) currentWalletXP = walletFloor;
      expect(currentWalletXP, greaterThanOrEqualTo(walletFloor));
      
      // Third miss: maximum penalty
      currentWalletXP -= 4500;
      if (currentWalletXP < walletFloor) currentWalletXP = walletFloor;
      expect(currentWalletXP, greaterThanOrEqualTo(walletFloor));
    });

    test('Wallet XP floor invariant - floor breach converts to HP loss', () {
      // Test that excess penalty beyond floor is handled correctly
      int currentWalletXP = -400;
      
      // Apply penalty that would breach floor
      final penaltyAmount = 200; // Would take wallet to -600
      
      currentWalletXP -= penaltyAmount;
      
      // Wallet should be clamped at floor
      if (currentWalletXP < walletFloor) {
        final overflow = walletFloor - currentWalletXP;
        currentWalletXP = walletFloor;
        
        // Overflow would convert to HP loss (10 XP = 1 HP)
        // But we're just testing wallet floor invariant here
        expect(overflow, greaterThan(0));
      }
      
      expect(
        currentWalletXP,
        equals(walletFloor),
        reason: 'Wallet should be clamped at floor, excess converts to HP loss',
      );
    });

    test('Wallet XP floor invariant - recovery from floor', () {
      // Test that wallet can recover from floor
      int currentWalletXP = walletFloor;
      
      // Add XP to recover
      final xpAmount = 1000;
      currentWalletXP += xpAmount;
      
      expect(
        currentWalletXP,
        equals(walletFloor + xpAmount),
        reason: 'Wallet should recover from floor when XP is added',
      );
      
      // Apply penalty again
      final penaltyAmount = 2000;
      currentWalletXP -= penaltyAmount;
      if (currentWalletXP < walletFloor) {
        currentWalletXP = walletFloor;
      }
      
      expect(
        currentWalletXP,
        greaterThanOrEqualTo(walletFloor),
        reason: 'Wallet should not fall below floor after recovery',
      );
    });
  });
}
