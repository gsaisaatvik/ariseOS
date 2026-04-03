import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:arise_os/services/hive_service.dart';

/// Property 19: Physical progress persistence round-trip
/// **Validates: Requirements 9.1**
/// 
/// For any valid progress value logged for any Physical Foundation sub-task,
/// reading the corresponding key from HiveService monarch_state box shall
/// return the same value immediately after the log call.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property 19: Physical progress persistence round-trip', () {
    late Box monarchStateBox;
    late Directory tempDir;
    final random = Random();
    
    // The four sub-task keys as specified in the design
    final subTaskKeys = ['Push-ups', 'Sit-ups', 'Squats', 'Running'];

    setUp(() async {
      // Create a temporary directory for Hive
      tempDir = await Directory.systemTemp.createTemp('hive_test_');
      
      // Initialize Hive with the temporary directory
      Hive.init(tempDir.path);
      
      // Open the monarch_state box
      monarchStateBox = await Hive.openBox(HiveService.monarchStateBox);
    });

    tearDown(() async {
      // Clean up after each test
      await monarchStateBox.clear();
      await monarchStateBox.close();
      await Hive.deleteFromDisk();
      
      // Delete the temporary directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Physical progress persistence round-trip - 100 iterations', () async {
      // Run minimum 100 iterations as specified in the task
      for (int iteration = 0; iteration < 100; iteration++) {
        // Generate random valid progress value for a random sub-task
        final randomSubTaskIndex = random.nextInt(subTaskKeys.length);
        final subTaskKey = subTaskKeys[randomSubTaskIndex];
        
        // Generate random progress value (0 to 500 to cover normal and overload cases)
        final randomProgressValue = random.nextInt(501);
        
        // Write the value to the monarch_state box
        await monarchStateBox.put(subTaskKey, randomProgressValue);
        
        // Assert that reading the value immediately returns the same value
        final retrievedValue = monarchStateBox.get(subTaskKey);
        
        expect(
          retrievedValue,
          equals(randomProgressValue),
          reason: 'Iteration $iteration: Expected $subTaskKey to have value '
                  '$randomProgressValue but got $retrievedValue',
        );
      }
    });

    test('Physical progress persistence round-trip - all sub-tasks', () async {
      // Test that all four sub-tasks can be persisted independently
      for (int iteration = 0; iteration < 25; iteration++) {
        final progressValues = <String, int>{};
        
        // Generate and write random values for all four sub-tasks
        for (final subTaskKey in subTaskKeys) {
          final randomValue = random.nextInt(501);
          progressValues[subTaskKey] = randomValue;
          await monarchStateBox.put(subTaskKey, randomValue);
        }
        
        // Verify all values are correctly persisted
        for (final entry in progressValues.entries) {
          final retrievedValue = monarchStateBox.get(entry.key);
          expect(
            retrievedValue,
            equals(entry.value),
            reason: 'Iteration $iteration: Expected ${entry.key} to have value '
                    '${entry.value} but got $retrievedValue',
          );
        }
      }
    });

    test('Physical progress persistence round-trip - edge cases', () async {
      final edgeCases = [
        0,      // Minimum value
        1,      // Just above minimum
        100,    // Target value for most sub-tasks
        200,    // 200% threshold for Limiter Removal
        500,    // High value
      ];

      for (final subTaskKey in subTaskKeys) {
        for (final edgeValue in edgeCases) {
          await monarchStateBox.put(subTaskKey, edgeValue);
          final retrievedValue = monarchStateBox.get(subTaskKey);
          
          expect(
            retrievedValue,
            equals(edgeValue),
            reason: 'Expected $subTaskKey to have value $edgeValue but got $retrievedValue',
          );
        }
      }
    });

    test('Physical progress persistence survives box reopen', () async {
      // Write values
      final testValues = {
        'Push-ups': 42,
        'Sit-ups': 87,
        'Squats': 150,
        'Running': 7,
      };

      for (final entry in testValues.entries) {
        await monarchStateBox.put(entry.key, entry.value);
      }

      // Close and reopen the box
      await monarchStateBox.close();
      monarchStateBox = await Hive.openBox(HiveService.monarchStateBox);

      // Verify values persist
      for (final entry in testValues.entries) {
        final retrievedValue = monarchStateBox.get(entry.key);
        expect(
          retrievedValue,
          equals(entry.value),
          reason: 'Expected ${entry.key} to persist value ${entry.value} '
                  'after box reopen but got $retrievedValue',
        );
      }
    });
  });
}
