import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:arise_os/services/hive_service.dart';
import 'package:arise_os/player_provider.dart';

/// Property 10: Penalty Zone state recovery
/// **Validates: Requirements 4.7, 4.8, 9.2**
/// 
/// For any penalty activation timestamp T where DateTime.now().difference(T) < Duration(hours: 4),
/// app initialization shall set inPenaltyZone = true and penaltyRemainingDuration shall equal
/// Duration(hours: 4) - (now - T) within a 1-second tolerance.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property 10: Penalty Zone state recovery', () {
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

    test('Penalty Zone state recovery - 100 iterations with random timestamps', () async {
      // Run minimum 100 iterations as specified in the task
      for (int iteration = 0; iteration < 100; iteration++) {
        // Generate random timestamp T where now - T < 4h
        // Random elapsed time between 1 second and 4 hours minus 1 second
        final maxElapsedSeconds = (4 * 60 * 60) - 1; // 4 hours - 1 second
        final randomElapsedSeconds = random.nextInt(maxElapsedSeconds) + 1;
        final randomElapsedDuration = Duration(seconds: randomElapsedSeconds);
        
        // Calculate the activation timestamp
        final now = DateTime.now();
        final activationTimestamp = now.subtract(randomElapsedDuration);
        
        // Persist the penalty zone state to monarch_state box
        await monarchStateBox.put('inPenaltyZone', true);
        await monarchStateBox.put('penaltyActivatedAt', activationTimestamp.toIso8601String());
        
        // Simulate app initialization by creating a new PlayerProvider
        final player = PlayerProvider();
        
        // Calculate expected remaining duration
        final expectedRemaining = const Duration(hours: 4) - randomElapsedDuration;
        
        // Assert inPenaltyZone is true
        expect(
          player.inPenaltyZone,
          isTrue,
          reason: 'Iteration $iteration: Expected inPenaltyZone to be true when '
                  'timestamp is within 4-hour window (elapsed: ${randomElapsedDuration.inSeconds}s)',
        );
        
        // Assert penaltyRemainingDuration is not null
        expect(
          player.penaltyRemainingDuration,
          isNotNull,
          reason: 'Iteration $iteration: Expected penaltyRemainingDuration to be non-null',
        );
        
        // Assert penaltyRemainingDuration equals expected within 1-second tolerance
        final actualRemaining = player.penaltyRemainingDuration!;
        final difference = (actualRemaining.inSeconds - expectedRemaining.inSeconds).abs();
        
        expect(
          difference,
          lessThanOrEqualTo(1),
          reason: 'Iteration $iteration: Expected remaining duration to be within 1 second '
                  'of ${expectedRemaining.inSeconds}s, but got ${actualRemaining.inSeconds}s '
                  '(difference: ${difference}s)',
        );
        
        // Clean up for next iteration
        await monarchStateBox.clear();
      }
    });

    test('Penalty Zone state recovery - edge cases within 4-hour window', () async {
      final edgeCases = [
        Duration(seconds: 1),           // Just activated (1 second ago)
        Duration(minutes: 1),           // 1 minute ago
        Duration(minutes: 30),          // 30 minutes ago
        Duration(hours: 1),             // 1 hour ago
        Duration(hours: 2),             // 2 hours ago
        Duration(hours: 3),             // 3 hours ago
        Duration(hours: 3, minutes: 59), // Almost 4 hours (3h 59m)
        Duration(hours: 4) - Duration(seconds: 1), // 1 second before expiry
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
        
        // Calculate expected remaining duration
        final expectedRemaining = const Duration(hours: 4) - elapsed;
        
        // Assert inPenaltyZone is true
        expect(
          player.inPenaltyZone,
          isTrue,
          reason: 'Expected inPenaltyZone to be true for elapsed time: ${elapsed.inSeconds}s',
        );
        
        // Assert penaltyRemainingDuration is correct within 1-second tolerance
        final actualRemaining = player.penaltyRemainingDuration!;
        final difference = (actualRemaining.inSeconds - expectedRemaining.inSeconds).abs();
        
        expect(
          difference,
          lessThanOrEqualTo(1),
          reason: 'Expected remaining duration to be within 1 second of ${expectedRemaining.inSeconds}s '
                  'for elapsed time ${elapsed.inSeconds}s, but got ${actualRemaining.inSeconds}s '
                  '(difference: ${difference}s)',
        );
        
        // Clean up for next iteration
        await monarchStateBox.clear();
      }
    });

    test('Penalty Zone state recovery - verify timestamp persistence', () async {
      // Test that the activation timestamp is correctly read from Hive
      final testTimestamp = DateTime.now().subtract(const Duration(hours: 2));
      
      await monarchStateBox.put('inPenaltyZone', true);
      await monarchStateBox.put('penaltyActivatedAt', testTimestamp.toIso8601String());
      
      final player = PlayerProvider();
      
      expect(player.inPenaltyZone, isTrue);
      expect(player.penaltyActivatedAt, isNotNull);
      
      // Verify the timestamp is within 1 second of the original
      final timestampDifference = player.penaltyActivatedAt!.difference(testTimestamp).abs();
      expect(
        timestampDifference.inSeconds,
        lessThanOrEqualTo(1),
        reason: 'Expected penaltyActivatedAt to match the persisted timestamp within 1 second',
      );
    });

    test('Penalty Zone state recovery - multiple rapid initializations', () async {
      // Test that multiple PlayerProvider initializations in quick succession
      // all correctly recover the penalty zone state
      final activationTimestamp = DateTime.now().subtract(const Duration(hours: 1));
      
      await monarchStateBox.put('inPenaltyZone', true);
      await monarchStateBox.put('penaltyActivatedAt', activationTimestamp.toIso8601String());
      
      // Create multiple PlayerProvider instances
      for (int i = 0; i < 10; i++) {
        final player = PlayerProvider();
        
        expect(
          player.inPenaltyZone,
          isTrue,
          reason: 'Initialization $i: Expected inPenaltyZone to be true',
        );
        
        expect(
          player.penaltyRemainingDuration,
          isNotNull,
          reason: 'Initialization $i: Expected penaltyRemainingDuration to be non-null',
        );
        
        // Verify remaining duration is approximately 3 hours (within 2 seconds tolerance
        // to account for multiple initializations)
        final expectedSeconds = 3 * 60 * 60; // 3 hours
        final actualSeconds = player.penaltyRemainingDuration!.inSeconds;
        final difference = (actualSeconds - expectedSeconds).abs();
        
        expect(
          difference,
          lessThanOrEqualTo(2),
          reason: 'Initialization $i: Expected remaining duration to be approximately 3 hours',
        );
      }
    });
  });
}
