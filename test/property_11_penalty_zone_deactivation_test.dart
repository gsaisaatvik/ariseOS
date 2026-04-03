import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:arise_os/services/hive_service.dart';
import 'package:arise_os/player_provider.dart';

/// Property 11: Penalty Zone deactivation
/// **Validates: Requirements 4.6**
/// 
/// For any penalty zone state where the elapsed time since penaltyActivatedAt is >= 4 hours,
/// the system shall set inPenaltyZone = false.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property 11: Penalty Zone deactivation', () {
    late Box settingsBox;
    late Box monarchStateBox;
    late Directory tempDir;
    final random = Random();

    setUp(() async {
      // Create a temporary directory for Hive
      tempDir = await Directory.systemTemp.createTemp('hive_test_');
      
      // Initialize Hive with the temporary directory
      Hive.init(tempDir.path);
      
      // Open both required boxes
      settingsBox = await Hive.openBox(HiveService.settingsBox);
      monarchStateBox = await Hive.openBox(HiveService.monarchStateBox);
    });

    tearDown(() async {
      // Clean up after each test
      await settingsBox.clear();
      await monarchStateBox.clear();
      await settingsBox.close();
      await monarchStateBox.close();
      await Hive.deleteFromDisk();
      
      // Delete the temporary directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Penalty Zone deactivation - 100 iterations with random expired timestamps', () async {
      // Run minimum 100 iterations as specified in the task
      for (int iteration = 0; iteration < 100; iteration++) {
        // Generate random timestamp T where now - T >= 4h
        // Random elapsed time between 4 hours and 48 hours (2 days)
        final minElapsedSeconds = 4 * 60 * 60; // 4 hours
        final maxElapsedSeconds = 48 * 60 * 60; // 48 hours
        final randomElapsedSeconds = random.nextInt(maxElapsedSeconds - minElapsedSeconds) + minElapsedSeconds;
        final randomElapsedDuration = Duration(seconds: randomElapsedSeconds);
        
        // Calculate the activation timestamp (in the past, >= 4 hours ago)
        final now = DateTime.now();
        final activationTimestamp = now.subtract(randomElapsedDuration);
        
        // Persist the penalty zone state to monarch_state box
        await monarchStateBox.put('inPenaltyZone', true);
        await monarchStateBox.put('penaltyActivatedAt', activationTimestamp.toIso8601String());
        
        // Simulate app initialization by creating a new PlayerProvider
        final player = PlayerProvider();
        
        // Assert inPenaltyZone is false (auto-deactivated)
        expect(
          player.inPenaltyZone,
          isFalse,
          reason: 'Iteration $iteration: Expected inPenaltyZone to be false when '
                  'timestamp is >= 4 hours ago (elapsed: ${randomElapsedDuration.inHours}h ${randomElapsedDuration.inMinutes % 60}m)',
        );
        
        // Assert penaltyRemainingDuration is null (no remaining time)
        expect(
          player.penaltyRemainingDuration,
          isNull,
          reason: 'Iteration $iteration: Expected penaltyRemainingDuration to be null when penalty zone is deactivated',
        );
        
        // Verify the state was persisted correctly (inPenaltyZone should be false in Hive)
        final persistedInPenaltyZone = monarchStateBox.get('inPenaltyZone', defaultValue: false);
        expect(
          persistedInPenaltyZone,
          isFalse,
          reason: 'Iteration $iteration: Expected persisted inPenaltyZone to be false after auto-deactivation',
        );
        
        // Clean up for next iteration
        await monarchStateBox.clear();
      }
    });

    test('Penalty Zone deactivation - edge cases at and beyond 4-hour threshold', () async {
      final edgeCases = [
        Duration(hours: 4),                    // Exactly 4 hours
        Duration(hours: 4, seconds: 1),        // 1 second past 4 hours
        Duration(hours: 4, minutes: 1),        // 1 minute past 4 hours
        Duration(hours: 5),                    // 5 hours
        Duration(hours: 8),                    // 8 hours
        Duration(hours: 12),                   // 12 hours
        Duration(hours: 24),                   // 1 day
        Duration(hours: 48),                   // 2 days
        Duration(days: 7),                     // 1 week
      ];

      for (final elapsed in edgeCases) {
        // Calculate the activation timestamp
        final now = DateTime.now();
        final activationTimestamp = now.subtract(elapsed);
        
        // Persist the penalty zone state
        await monarchStateBox.put('inPenaltyZone', true);
        await monarchStateBox.put('penaltyActivatedAt', activationTimestamp.toIso8601String());
        
        // Simulate app initialization
        final player = PlayerProvider();
        
        // Assert inPenaltyZone is false
        expect(
          player.inPenaltyZone,
          isFalse,
          reason: 'Expected inPenaltyZone to be false for elapsed time: ${elapsed.inHours}h ${elapsed.inMinutes % 60}m',
        );
        
        // Assert penaltyRemainingDuration is null
        expect(
          player.penaltyRemainingDuration,
          isNull,
          reason: 'Expected penaltyRemainingDuration to be null for elapsed time: ${elapsed.inHours}h ${elapsed.inMinutes % 60}m',
        );
        
        // Verify persistence
        final persistedInPenaltyZone = monarchStateBox.get('inPenaltyZone', defaultValue: false);
        expect(
          persistedInPenaltyZone,
          isFalse,
          reason: 'Expected persisted inPenaltyZone to be false for elapsed time: ${elapsed.inHours}h ${elapsed.inMinutes % 60}m',
        );
        
        // Clean up for next iteration
        await monarchStateBox.clear();
      }
    });

    test('Penalty Zone deactivation - verify timestamp cleanup', () async {
      // Test that the activation timestamp is deleted from Hive after deactivation
      final testTimestamp = DateTime.now().subtract(const Duration(hours: 5));
      
      await monarchStateBox.put('inPenaltyZone', true);
      await monarchStateBox.put('penaltyActivatedAt', testTimestamp.toIso8601String());
      
      // Verify the timestamp is present before initialization
      expect(monarchStateBox.containsKey('penaltyActivatedAt'), isTrue);
      
      final player = PlayerProvider();
      
      // Verify penalty zone is deactivated
      expect(player.inPenaltyZone, isFalse);
      expect(player.penaltyActivatedAt, isNull);
      
      // Verify the timestamp was deleted from Hive
      expect(
        monarchStateBox.containsKey('penaltyActivatedAt'),
        isFalse,
        reason: 'Expected penaltyActivatedAt to be deleted from Hive after auto-deactivation',
      );
    });

    test('Penalty Zone deactivation - multiple rapid initializations with expired timestamp', () async {
      // Test that multiple PlayerProvider initializations in quick succession
      // all correctly deactivate an expired penalty zone
      final activationTimestamp = DateTime.now().subtract(const Duration(hours: 6));
      
      await monarchStateBox.put('inPenaltyZone', true);
      await monarchStateBox.put('penaltyActivatedAt', activationTimestamp.toIso8601String());
      
      // Create multiple PlayerProvider instances
      for (int i = 0; i < 10; i++) {
        final player = PlayerProvider();
        
        expect(
          player.inPenaltyZone,
          isFalse,
          reason: 'Initialization $i: Expected inPenaltyZone to be false',
        );
        
        expect(
          player.penaltyRemainingDuration,
          isNull,
          reason: 'Initialization $i: Expected penaltyRemainingDuration to be null',
        );
        
        expect(
          player.penaltyActivatedAt,
          isNull,
          reason: 'Initialization $i: Expected penaltyActivatedAt to be null',
        );
      }
    });

    test('Penalty Zone deactivation - boundary test at exactly 4 hours', () async {
      // Test the exact boundary condition: elapsed time = 4 hours
      // According to the requirement: elapsed >= 4 hours should deactivate
      final activationTimestamp = DateTime.now().subtract(const Duration(hours: 4));
      
      await monarchStateBox.put('inPenaltyZone', true);
      await monarchStateBox.put('penaltyActivatedAt', activationTimestamp.toIso8601String());
      
      final player = PlayerProvider();
      
      // At exactly 4 hours, the penalty zone should be deactivated
      expect(
        player.inPenaltyZone,
        isFalse,
        reason: 'Expected inPenaltyZone to be false at exactly 4 hours elapsed',
      );
      
      expect(
        player.penaltyRemainingDuration,
        isNull,
        reason: 'Expected penaltyRemainingDuration to be null at exactly 4 hours elapsed',
      );
    });

    test('Penalty Zone deactivation - contrast with unexpired penalty zone', () async {
      // Verify that a penalty zone that has NOT expired remains active
      // This is a sanity check to ensure the deactivation logic is working correctly
      final activationTimestamp = DateTime.now().subtract(const Duration(hours: 3, minutes: 59));
      
      await monarchStateBox.put('inPenaltyZone', true);
      await monarchStateBox.put('penaltyActivatedAt', activationTimestamp.toIso8601String());
      
      final player = PlayerProvider();
      
      // Should still be in penalty zone (not yet 4 hours)
      expect(
        player.inPenaltyZone,
        isTrue,
        reason: 'Expected inPenaltyZone to be true when elapsed time is less than 4 hours',
      );
      
      expect(
        player.penaltyRemainingDuration,
        isNotNull,
        reason: 'Expected penaltyRemainingDuration to be non-null when penalty zone is active',
      );
      
      // Now test with an expired timestamp
      await monarchStateBox.clear();
      final expiredTimestamp = DateTime.now().subtract(const Duration(hours: 4, minutes: 1));
      await monarchStateBox.put('inPenaltyZone', true);
      await monarchStateBox.put('penaltyActivatedAt', expiredTimestamp.toIso8601String());
      
      final player2 = PlayerProvider();
      
      // Should be deactivated (past 4 hours)
      expect(
        player2.inPenaltyZone,
        isFalse,
        reason: 'Expected inPenaltyZone to be false when elapsed time is greater than 4 hours',
      );
      
      expect(
        player2.penaltyRemainingDuration,
        isNull,
        reason: 'Expected penaltyRemainingDuration to be null when penalty zone is deactivated',
      );
    });
  });
}
