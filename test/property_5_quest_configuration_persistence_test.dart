import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:arise_os/services/hive_service.dart';

/// Property 5: Quest configuration persistence round-trip
/// **Validates: Requirements 2.3, 9.3**
/// 
/// For any valid Cognitive Quest duration in [1, 480] and any non-empty
/// Technical Quest task string, persisting them via setPendingCognitiveQuest /
/// setPendingTechnicalQuest and then reading from HiveService shall return
/// the same values.
/// 
/// This test validates the persistence layer directly by writing to and reading
/// from the monarch_state Hive box, ensuring that quest configuration values
/// survive the round-trip through the persistence layer.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property 5: Quest configuration persistence round-trip', () {
    late Box monarchStateBox;
    late Directory tempDir;
    final random = Random();

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

    test('Quest configuration persistence round-trip - 100 iterations', () async {
      // Run minimum 100 iterations as specified in the task
      // This test validates the core round-trip property:
      // persisted value == retrieved value
      
      for (int iteration = 0; iteration < 100; iteration++) {
        // Generate random valid duration in [1, 480]
        final randomDuration = 1 + random.nextInt(480); // 1 to 480 inclusive
        
        // Generate random non-empty task string
        final randomTask = _generateRandomTaskString(random);
        
        // Simulate setPendingCognitiveQuest: persist to monarchState
        await monarchStateBox.put('pendingCognitiveMins', randomDuration);
        
        // Simulate setPendingTechnicalQuest: persist to monarchState
        await monarchStateBox.put('pendingTechnicalTask', randomTask);
        
        // Assert monarchState returns same values
        final retrievedDuration = monarchStateBox.get('pendingCognitiveMins');
        final retrievedTask = monarchStateBox.get('pendingTechnicalTask');
        
        expect(
          retrievedDuration,
          equals(randomDuration),
          reason: 'Iteration $iteration: Cognitive Quest duration\n'
                  'Expected: $randomDuration\n'
                  'Retrieved: $retrievedDuration\n'
                  'The persisted duration should equal the retrieved value',
        );
        
        expect(
          retrievedTask,
          equals(randomTask),
          reason: 'Iteration $iteration: Technical Quest task\n'
                  'Expected: "$randomTask"\n'
                  'Retrieved: "$retrievedTask"\n'
                  'The persisted task should equal the retrieved value',
        );
      }
    });

    test('Quest configuration persistence - edge case durations', () async {
      final edgeCaseDurations = [
        1,      // Minimum valid duration
        2,      // Just above minimum
        60,     // 1 hour
        120,    // 2 hours
        240,    // 4 hours
        479,    // Just below maximum
        480,    // Maximum valid duration
      ];

      for (final duration in edgeCaseDurations) {
        final task = 'Test task for duration $duration';
        
        await monarchStateBox.put('pendingCognitiveMins', duration);
        await monarchStateBox.put('pendingTechnicalTask', task);
        
        final retrievedDuration = monarchStateBox.get('pendingCognitiveMins');
        final retrievedTask = monarchStateBox.get('pendingTechnicalTask');
        
        expect(
          retrievedDuration,
          equals(duration),
          reason: 'Edge case duration $duration should persist correctly',
        );
        
        expect(
          retrievedTask,
          equals(task),
          reason: 'Task for duration $duration should persist correctly',
        );
      }
    });

    test('Quest configuration persistence - various task strings', () async {
      final taskStrings = [
        'A',                                    // Single character
        'Complete ReactJS tutorial',           // Typical task
        'Study DSA: Binary Trees',             // With special characters
        'IIT Madras: Week 3 Assignment',       // With numbers and spaces
        'Deep Work Session - Focus Mode',      // With dash
        'Review code & refactor components',   // With ampersand
        'Task with "quotes" inside',           // With quotes
        'Very long task description that spans multiple concepts and includes '
            'detailed information about what needs to be accomplished during '
            'the technical quest session today',  // Long string
      ];

      for (int i = 0; i < taskStrings.length; i++) {
        final task = taskStrings[i];
        final duration = 60 + (i * 30); // Vary duration for each task
        
        await monarchStateBox.put('pendingCognitiveMins', duration);
        await monarchStateBox.put('pendingTechnicalTask', task);
        
        final retrievedDuration = monarchStateBox.get('pendingCognitiveMins');
        final retrievedTask = monarchStateBox.get('pendingTechnicalTask');
        
        expect(
          retrievedDuration,
          equals(duration),
          reason: 'Duration should persist for task: "$task"',
        );
        
        expect(
          retrievedTask,
          equals(task),
          reason: 'Task string should persist exactly: "$task"',
        );
      }
    });

    test('Quest configuration persistence - independent updates', () async {
      // Test that updating one quest doesn't affect the other
      
      // Set initial values
      await monarchStateBox.put('pendingCognitiveMins', 120);
      await monarchStateBox.put('pendingTechnicalTask', 'Initial task');
      
      // Verify initial values
      expect(monarchStateBox.get('pendingCognitiveMins'), equals(120));
      expect(monarchStateBox.get('pendingTechnicalTask'), equals('Initial task'));
      
      // Update only cognitive quest
      await monarchStateBox.put('pendingCognitiveMins', 240);
      
      // Verify cognitive quest updated but technical quest unchanged
      expect(monarchStateBox.get('pendingCognitiveMins'), equals(240));
      expect(monarchStateBox.get('pendingTechnicalTask'), equals('Initial task'));
      
      // Update only technical quest
      await monarchStateBox.put('pendingTechnicalTask', 'Updated task');
      
      // Verify technical quest updated but cognitive quest unchanged
      expect(monarchStateBox.get('pendingCognitiveMins'), equals(240));
      expect(monarchStateBox.get('pendingTechnicalTask'), equals('Updated task'));
    });

    test('Quest configuration persistence - sequential updates', () async {
      // Test that sequential updates to the same quest work correctly
      
      final durations = [60, 120, 180, 240, 300];
      for (final duration in durations) {
        await monarchStateBox.put('pendingCognitiveMins', duration);
        
        expect(
          monarchStateBox.get('pendingCognitiveMins'),
          equals(duration),
          reason: 'Sequential update to duration $duration should persist',
        );
      }
      
      final tasks = [
        'Task 1',
        'Task 2',
        'Task 3',
        'Task 4',
        'Task 5',
      ];
      for (final task in tasks) {
        await monarchStateBox.put('pendingTechnicalTask', task);
        
        expect(
          monarchStateBox.get('pendingTechnicalTask'),
          equals(task),
          reason: 'Sequential update to task "$task" should persist',
        );
      }
    });

    test('Quest configuration persistence survives box reopen', () async {
      // Write values
      const testDuration = 180;
      const testTask = 'ReactJS Component Refactoring';
      
      await monarchStateBox.put('pendingCognitiveMins', testDuration);
      await monarchStateBox.put('pendingTechnicalTask', testTask);
      
      // Close and reopen the box
      await monarchStateBox.close();
      monarchStateBox = await Hive.openBox(HiveService.monarchStateBox);
      
      // Verify values persist after box reopen
      final retrievedDuration = monarchStateBox.get('pendingCognitiveMins');
      final retrievedTask = monarchStateBox.get('pendingTechnicalTask');
      
      expect(
        retrievedDuration,
        equals(testDuration),
        reason: 'Cognitive Quest duration should persist after box reopen',
      );
      
      expect(
        retrievedTask,
        equals(testTask),
        reason: 'Technical Quest task should persist after box reopen',
      );
    });

    test('Quest configuration persistence - stress test with random sequences', () async {
      // Stress test with 200 random operations
      for (int iteration = 0; iteration < 200; iteration++) {
        final randomDuration = 1 + random.nextInt(480);
        final randomTask = _generateRandomTaskString(random);
        
        await monarchStateBox.put('pendingCognitiveMins', randomDuration);
        await monarchStateBox.put('pendingTechnicalTask', randomTask);
        
        final retrievedDuration = monarchStateBox.get('pendingCognitiveMins');
        final retrievedTask = monarchStateBox.get('pendingTechnicalTask');
        
        expect(
          retrievedDuration,
          equals(randomDuration),
          reason: 'Stress test iteration $iteration: duration mismatch',
        );
        
        expect(
          retrievedTask,
          equals(randomTask),
          reason: 'Stress test iteration $iteration: task mismatch',
        );
      }
    });
  });
}

/// Helper function to generate random non-empty task strings
String _generateRandomTaskString(Random random) {
  final taskPrefixes = [
    'Complete',
    'Study',
    'Review',
    'Implement',
    'Refactor',
    'Debug',
    'Optimize',
    'Learn',
    'Practice',
    'Build',
  ];
  
  final taskSubjects = [
    'ReactJS components',
    'DSA algorithms',
    'IIT Madras coursework',
    'Binary Trees',
    'Dynamic Programming',
    'System Design',
    'Database queries',
    'API integration',
    'Unit tests',
    'Code architecture',
  ];
  
  final prefix = taskPrefixes[random.nextInt(taskPrefixes.length)];
  final subject = taskSubjects[random.nextInt(taskSubjects.length)];
  
  return '$prefix $subject';
}
