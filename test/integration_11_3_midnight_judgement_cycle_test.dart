import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:arise_os/player_provider.dart';
import 'package:arise_os/services/hive_service.dart';
import 'package:arise_os/engine/core_engine.dart';

/// Integration Test 11.3: Full Midnight Judgement cycle
///
/// Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5
///
/// This integration test verifies the complete Midnight Judgement flow:
/// - Failure case: Physical completion < 100% triggers penalty zone
/// - Success case: Physical completion >= 100% extends streak
/// - Both cases: Progress is reset and quests are locked
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Integration 11.3: Full Midnight Judgement cycle', () {
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

    test('failure case: < 100% completion triggers penalty zone', () {
      // Set physical progress to < 100%
      player.logPhysicalProgress('Push-ups', 50);
      player.logPhysicalProgress('Sit-ups', 60);
      player.logPhysicalProgress('Squats', 40);
      player.logPhysicalProgress('Running', 5);
      
      // Verify completion is < 100%
      expect(player.physicalCompletionPct, lessThan(1.0));
      
      // Set pending quests
      player.setPendingCognitiveQuest(60);
      player.setPendingTechnicalQuest('Practice Flutter');
      
      // Store initial streak
      final initialStreak = player.streakDays;
      
      // Run Midnight Judgement
      CoreEngine.runMidnightJudgement(player);
      
      // Assert: Penalty zone should be activated
      expect(player.inPenaltyZone, isTrue);
      expect(player.penaltyActivatedAt, isNotNull);
      
      // Assert: All progress should be reset to 0
      expect(player.questProgress['Push-ups'], equals(0));
      expect(player.questProgress['Sit-ups'], equals(0));
      expect(player.questProgress['Squats'], equals(0));
      expect(player.questProgress['Running'], equals(0));
      
      // Assert: Quests should be locked
      expect(player.cognitiveLocked, isTrue);
      expect(player.technicalLocked, isTrue);
      expect(player.lockedCognitiveDurationMinutes, equals(60));
      expect(player.lockedTechnicalTask, equals('Practice Flutter'));
      
      // Assert: Streak should NOT be incremented (failure)
      expect(player.streakDays, equals(initialStreak));
    });

    test('success case: >= 100% completion extends streak', () {
      // Set physical progress to >= 100%
      player.logPhysicalProgress('Push-ups', 100);
      player.logPhysicalProgress('Sit-ups', 100);
      player.logPhysicalProgress('Squats', 100);
      player.logPhysicalProgress('Running', 10);
      
      // Verify completion is >= 100%
      expect(player.physicalCompletionPct, greaterThanOrEqualTo(1.0));
      
      // Set pending quests
      player.setPendingCognitiveQuest(120);
      player.setPendingTechnicalQuest('Study Dart');
      
      // Store initial streak
      final initialStreak = player.streakDays;
      
      // Run Midnight Judgement
      CoreEngine.runMidnightJudgement(player);
      
      // Assert: Penalty zone should NOT be activated
      expect(player.inPenaltyZone, isFalse);
      expect(player.penaltyActivatedAt, isNull);
      
      // Assert: All progress should be reset to 0
      expect(player.questProgress['Push-ups'], equals(0));
      expect(player.questProgress['Sit-ups'], equals(0));
      expect(player.questProgress['Squats'], equals(0));
      expect(player.questProgress['Running'], equals(0));
      
      // Assert: Quests should be locked
      expect(player.cognitiveLocked, isTrue);
      expect(player.technicalLocked, isTrue);
      expect(player.lockedCognitiveDurationMinutes, equals(120));
      expect(player.lockedTechnicalTask, equals('Study Dart'));
      
      // Assert: Streak should be incremented by exactly 1
      expect(player.streakDays, equals(initialStreak + 1));
    });

    test('progress reset is idempotent', () {
      // Set physical progress
      player.logPhysicalProgress('Push-ups', 75);
      player.logPhysicalProgress('Sit-ups', 80);
      player.logPhysicalProgress('Squats', 70);
      player.logPhysicalProgress('Running', 8);
      
      // Set pending quests
      player.setPendingCognitiveQuest(90);
      player.setPendingTechnicalQuest('Test task');
      
      // Run Midnight Judgement
      CoreEngine.runMidnightJudgement(player);
      
      // Verify progress is reset
      expect(player.questProgress['Push-ups'], equals(0));
      expect(player.questProgress['Sit-ups'], equals(0));
      expect(player.questProgress['Squats'], equals(0));
      expect(player.questProgress['Running'], equals(0));
      
      // Run Midnight Judgement again (should be safe)
      CoreEngine.runMidnightJudgement(player);
      
      // Assert: Progress should still be 0 (idempotent)
      expect(player.questProgress['Push-ups'], equals(0));
      expect(player.questProgress['Sit-ups'], equals(0));
      expect(player.questProgress['Squats'], equals(0));
      expect(player.questProgress['Running'], equals(0));
    });

    test('quest locking copies pending to locked fields', () {
      // Set pending quests with specific values
      player.setPendingCognitiveQuest(240);
      player.setPendingTechnicalQuest('Advanced Flutter Patterns');
      
      // Verify pending values are set
      expect(player.pendingCognitiveDurationMinutes, equals(240));
      expect(player.pendingTechnicalTask, equals('Advanced Flutter Patterns'));
      
      // Set some physical progress (doesn't matter for this test)
      player.logPhysicalProgress('Push-ups', 50);
      
      // Run Midnight Judgement
      CoreEngine.runMidnightJudgement(player);
      
      // Assert: Locked fields should match pending fields
      expect(player.lockedCognitiveDurationMinutes, equals(240));
      expect(player.lockedTechnicalTask, equals('Advanced Flutter Patterns'));
      
      // Assert: Locked flags should be true
      expect(player.cognitiveLocked, isTrue);
      expect(player.technicalLocked, isTrue);
      
      // Assert: Completed flags should be false (new day)
      expect(player.cognitiveCompleted, isFalse);
      expect(player.technicalCompleted, isFalse);
    });

    test('streak extension updates best streak', () {
      // Set initial streak to 5
      HiveService.settings.put('streakDays', 5);
      HiveService.settings.put('bestStreak', 5);
      
      // Reinitialize player to load the streak
      player = PlayerProvider();
      
      // Set physical progress to 100%
      player.logPhysicalProgress('Push-ups', 100);
      player.logPhysicalProgress('Sit-ups', 100);
      player.logPhysicalProgress('Squats', 100);
      player.logPhysicalProgress('Running', 10);
      
      // Set pending quests
      player.setPendingCognitiveQuest(60);
      player.setPendingTechnicalQuest('Task');
      
      // Run Midnight Judgement
      CoreEngine.runMidnightJudgement(player);
      
      // Assert: Streak should be 6
      expect(player.streakDays, equals(6));
      
      // Assert: Best streak should be updated to 6
      expect(player.bestStreak, equals(6));
    });

    test('boundary case: exactly 100% completion', () {
      // Set physical progress to exactly 100%
      player.logPhysicalProgress('Push-ups', 100);
      player.logPhysicalProgress('Sit-ups', 100);
      player.logPhysicalProgress('Squats', 100);
      player.logPhysicalProgress('Running', 10);
      
      // Verify completion is exactly 1.0
      expect(player.physicalCompletionPct, equals(1.0));
      
      // Set pending quests
      player.setPendingCognitiveQuest(30);
      player.setPendingTechnicalQuest('Boundary test');
      
      final initialStreak = player.streakDays;
      
      // Run Midnight Judgement
      CoreEngine.runMidnightJudgement(player);
      
      // Assert: Should be treated as success (>= 1.0)
      expect(player.inPenaltyZone, isFalse);
      expect(player.streakDays, equals(initialStreak + 1));
    });

    test('boundary case: 99.9% completion (failure)', () {
      // Set physical progress to just under 100%
      player.logPhysicalProgress('Push-ups', 100);
      player.logPhysicalProgress('Sit-ups', 100);
      player.logPhysicalProgress('Squats', 100);
      player.logPhysicalProgress('Running', 9); // 90% of 10
      
      // Verify completion is < 1.0
      expect(player.physicalCompletionPct, lessThan(1.0));
      
      // Set pending quests
      player.setPendingCognitiveQuest(45);
      player.setPendingTechnicalQuest('Almost there');
      
      final initialStreak = player.streakDays;
      
      // Run Midnight Judgement
      CoreEngine.runMidnightJudgement(player);
      
      // Assert: Should be treated as failure (< 1.0)
      expect(player.inPenaltyZone, isTrue);
      expect(player.streakDays, equals(initialStreak));
    });
  });
}
