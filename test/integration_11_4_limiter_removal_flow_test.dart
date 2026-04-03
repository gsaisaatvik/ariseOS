import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:arise_os/player_provider.dart';
import 'package:arise_os/services/hive_service.dart';

/// Integration Test 11.4: Limiter Removal full flow
///
/// Validates: Requirements 7.1, 7.2, 7.3, 7.4
///
/// This integration test verifies the complete Limiter Removal flow:
/// - Triggering condition: All sub-tasks >= 200% of target
/// - Rewards: +5 stat points to availablePoints
/// - Title: overloadTitleAwarded flag set to true
/// - Idempotence: Can only trigger once per day
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Integration 11.4: Limiter Removal full flow', () {
    late PlayerProvider player;

    setUp(() async {
      await Hive.initFlutter();
      await Hive.openBox('settings');
      await Hive.openBox('monarch_state');
      await HiveService.init();
      
      player = PlayerProvider();
      await Future.delayed(const Duration(milliseconds: 100));
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
      await Hive.close();
    });

    test('triggers when all sub-tasks >= 200% of target', () {
      // Store initial available points
      final initialPoints = player.availablePoints;
      
      // Set all sub-tasks to exactly 200% of target
      player.logPhysicalProgress('Push-ups', 200); // 200% of 100
      player.logPhysicalProgress('Sit-ups', 200);  // 200% of 100
      player.logPhysicalProgress('Squats', 200);   // 200% of 100
      player.logPhysicalProgress('Running', 20);   // 200% of 10
      
      // Assert: limiterRemovedToday should be true
      expect(player.limiterRemovedToday, isTrue);
      
      // Assert: availablePoints should increase by exactly 5
      expect(player.availablePoints, equals(initialPoints + 5));
      
      // Assert: overloadTitleAwarded should be true
      expect(player.overloadTitleAwarded, isTrue);
      
      // Assert: monarchState should reflect the changes
      expect(HiveService.monarchState.get('limiterRemovedToday'), isTrue);
      expect(HiveService.monarchState.get('overloadTitleAwarded'), isTrue);
      expect(HiveService.settings.get('availablePoints'), equals(initialPoints + 5));
    });

    test('triggers with progress > 200% (overload)', () {
      final initialPoints = player.availablePoints;
      
      // Set all sub-tasks to > 200% of target
      player.logPhysicalProgress('Push-ups', 250); // 250% of 100
      player.logPhysicalProgress('Sit-ups', 300);  // 300% of 100
      player.logPhysicalProgress('Squats', 220);   // 220% of 100
      player.logPhysicalProgress('Running', 25);   // 250% of 10
      
      // Assert: Limiter Removal should trigger
      expect(player.limiterRemovedToday, isTrue);
      expect(player.availablePoints, equals(initialPoints + 5));
      expect(player.overloadTitleAwarded, isTrue);
    });

    test('does not trigger when one sub-task < 200%', () {
      final initialPoints = player.availablePoints;
      
      // Set three sub-tasks to 200%, but one to 199%
      player.logPhysicalProgress('Push-ups', 200);
      player.logPhysicalProgress('Sit-ups', 200);
      player.logPhysicalProgress('Squats', 199); // Just under 200%
      player.logPhysicalProgress('Running', 20);
      
      // Assert: Limiter Removal should NOT trigger
      expect(player.limiterRemovedToday, isFalse);
      expect(player.availablePoints, equals(initialPoints));
      expect(player.overloadTitleAwarded, isFalse);
    });

    test('idempotence: can only trigger once per day', () {
      final initialPoints = player.availablePoints;
      
      // Set all sub-tasks to 200% (first trigger)
      player.logPhysicalProgress('Push-ups', 200);
      player.logPhysicalProgress('Sit-ups', 200);
      player.logPhysicalProgress('Squats', 200);
      player.logPhysicalProgress('Running', 20);
      
      // Assert: First trigger successful
      expect(player.limiterRemovedToday, isTrue);
      expect(player.availablePoints, equals(initialPoints + 5));
      
      // Store points after first trigger
      final pointsAfterFirst = player.availablePoints;
      
      // Call checkLimiterRemoval again (manual call)
      player.checkLimiterRemoval();
      
      // Assert: availablePoints should NOT increase again
      expect(player.availablePoints, equals(pointsAfterFirst));
      expect(player.limiterRemovedToday, isTrue);
      
      // Increase progress even more and call again
      player.logPhysicalProgress('Push-ups', 300);
      player.logPhysicalProgress('Sit-ups', 300);
      player.logPhysicalProgress('Squats', 300);
      player.logPhysicalProgress('Running', 30);
      
      // Assert: Still no additional points
      expect(player.availablePoints, equals(pointsAfterFirst));
      expect(player.limiterRemovedToday, isTrue);
    });

    test('multiple calls to checkLimiterRemoval are safe', () {
      final initialPoints = player.availablePoints;
      
      // Set all sub-tasks to 200%
      player.logPhysicalProgress('Push-ups', 200);
      player.logPhysicalProgress('Sit-ups', 200);
      player.logPhysicalProgress('Squats', 200);
      player.logPhysicalProgress('Running', 20);
      
      // Assert: First trigger successful
      expect(player.limiterRemovedToday, isTrue);
      final pointsAfterFirst = player.availablePoints;
      
      // Call checkLimiterRemoval 10 more times
      for (int i = 0; i < 10; i++) {
        player.checkLimiterRemoval();
      }
      
      // Assert: Points should not change
      expect(player.availablePoints, equals(pointsAfterFirst));
      expect(player.availablePoints, equals(initialPoints + 5));
    });

    test('overloadTitleAwarded persists across triggers', () {
      // First trigger
      player.logPhysicalProgress('Push-ups', 200);
      player.logPhysicalProgress('Sit-ups', 200);
      player.logPhysicalProgress('Squats', 200);
      player.logPhysicalProgress('Running', 20);
      
      expect(player.overloadTitleAwarded, isTrue);
      
      // Simulate new day (reset limiterRemovedToday flag)
      HiveService.monarchState.put('limiterRemovedToday', false);
      player = PlayerProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Assert: overloadTitleAwarded should still be true
      expect(player.overloadTitleAwarded, isTrue);
      
      // Trigger again on new day
      player.logPhysicalProgress('Push-ups', 200);
      player.logPhysicalProgress('Sit-ups', 200);
      player.logPhysicalProgress('Squats', 200);
      player.logPhysicalProgress('Running', 20);
      
      // Assert: overloadTitleAwarded should remain true (not reset)
      expect(player.overloadTitleAwarded, isTrue);
    });

    test('system log contains limiter removal message', () {
      // Set all sub-tasks to 200%
      player.logPhysicalProgress('Push-ups', 200);
      player.logPhysicalProgress('Sit-ups', 200);
      player.logPhysicalProgress('Squats', 200);
      player.logPhysicalProgress('Running', 20);
      
      // Assert: System log should contain limiter removal message
      final logs = player.systemLogs;
      final hasLimiterLog = logs.any(
        (log) => log.contains('LIMITER REMOVED') && log.contains('+5 STAT POINTS'),
      );
      
      expect(hasLimiterLog, isTrue);
    });

    test('boundary case: exactly 200% on all sub-tasks', () {
      final initialPoints = player.availablePoints;
      
      // Set all sub-tasks to exactly 200%
      player.logPhysicalProgress('Push-ups', 200);
      player.logPhysicalProgress('Sit-ups', 200);
      player.logPhysicalProgress('Squats', 200);
      player.logPhysicalProgress('Running', 20);
      
      // Assert: Should trigger (>= 200%)
      expect(player.limiterRemovedToday, isTrue);
      expect(player.availablePoints, equals(initialPoints + 5));
    });

    test('boundary case: 199% on one sub-task (failure)', () {
      final initialPoints = player.availablePoints;
      
      // Set three to 200%, one to 199%
      player.logPhysicalProgress('Push-ups', 200);
      player.logPhysicalProgress('Sit-ups', 200);
      player.logPhysicalProgress('Squats', 200);
      player.logPhysicalProgress('Running', 19); // 190% of 10
      
      // Assert: Should NOT trigger (< 200% on one sub-task)
      expect(player.limiterRemovedToday, isFalse);
      expect(player.availablePoints, equals(initialPoints));
    });

    test('incremental progress triggers at correct moment', () {
      final initialPoints = player.availablePoints;
      
      // Set three sub-tasks to 200%
      player.logPhysicalProgress('Push-ups', 200);
      player.logPhysicalProgress('Sit-ups', 200);
      player.logPhysicalProgress('Squats', 200);
      
      // Assert: Not triggered yet (one sub-task missing)
      expect(player.limiterRemovedToday, isFalse);
      expect(player.availablePoints, equals(initialPoints));
      
      // Set fourth sub-task to 199% (still not enough)
      player.logPhysicalProgress('Running', 19);
      expect(player.limiterRemovedToday, isFalse);
      expect(player.availablePoints, equals(initialPoints));
      
      // Set fourth sub-task to 200% (should trigger now)
      player.logPhysicalProgress('Running', 20);
      expect(player.limiterRemovedToday, isTrue);
      expect(player.availablePoints, equals(initialPoints + 5));
    });
  });
}
