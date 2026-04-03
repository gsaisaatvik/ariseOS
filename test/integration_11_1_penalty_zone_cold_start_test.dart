import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:arise_os/player_provider.dart';
import 'package:arise_os/services/hive_service.dart';
import 'package:arise_os/dashboard.dart';
import 'package:arise_os/penalty_zone_screen.dart';

/// Integration Test 11.1: Cold start with active, unexpired Penalty Zone
///
/// Validates: Requirements 4.7, 4.8, 9.2, 9.5
///
/// This integration test verifies that when the app is launched with an
/// active penalty zone that hasn't expired yet, the PenaltyZoneScreen is
/// displayed and shows the correct remaining time.
///
/// Test scenario:
/// 1. Seed monarchState with inPenaltyZone=true and penaltyActivatedAt = 1 hour ago
/// 2. Launch the app (initialize PlayerProvider)
/// 3. Assert PenaltyZoneScreen is shown
/// 4. Assert Survival_Timer displays approximately 3 hours remaining
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Integration 11.1: Cold start with active, unexpired Penalty Zone', () {
    setUp(() async {
      // Initialize Hive with in-memory storage
      await Hive.initFlutter();
      await Hive.openBox('settings');
      await Hive.openBox('monarch_state');
      await HiveService.init();
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
      await Hive.close();
    });

    testWidgets('shows PenaltyZoneScreen with correct remaining time', (tester) async {
      // Seed monarchState with penalty zone activated 1 hour ago
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      HiveService.monarchState.put('inPenaltyZone', true);
      HiveService.monarchState.put('penaltyActivatedAt', oneHourAgo.toIso8601String());

      // Create PlayerProvider (simulates cold start)
      final player = PlayerProvider();
      await tester.pumpAndSettle();

      // Build the Dashboard widget tree
      await tester.pumpWidget(
        ChangeNotifierProvider<PlayerProvider>.value(
          value: player,
          child: const MaterialApp(
            home: Dashboard(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: PenaltyZoneScreen should be visible
      expect(
        find.byType(PenaltyZoneScreen),
        findsOneWidget,
        reason: 'PenaltyZoneScreen should be displayed when penalty zone is active',
      );

      // Assert: "PENALTY ZONE ACTIVE" text should be visible
      expect(
        find.text('PENALTY ZONE ACTIVE'),
        findsOneWidget,
        reason: 'Penalty zone header should be visible',
      );

      // Assert: Survival timer should be visible
      expect(
        find.text('SURVIVAL TIMER'),
        findsOneWidget,
        reason: 'Survival timer label should be visible',
      );

      // Assert: Timer should show approximately 3 hours remaining (03:XX:XX)
      // We use a regex to match the timer format
      final timerFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data != null &&
            RegExp(r'^03:\d{2}:\d{2}$').hasMatch(widget.data!),
      );
      
      expect(
        timerFinder,
        findsOneWidget,
        reason: 'Timer should display approximately 3 hours remaining (03:XX:XX)',
      );

      // Assert: PlayerProvider state reflects penalty zone
      expect(player.inPenaltyZone, isTrue);
      expect(player.penaltyActivatedAt, isNotNull);
      
      // Assert: Remaining duration is approximately 3 hours (within 5 minutes tolerance)
      final remaining = player.penaltyRemainingDuration;
      expect(remaining, isNotNull);
      expect(
        remaining!.inMinutes,
        greaterThanOrEqualTo(175), // 2h 55m
        reason: 'Remaining time should be at least 2h 55m',
      );
      expect(
        remaining.inMinutes,
        lessThanOrEqualTo(185), // 3h 5m
        reason: 'Remaining time should be at most 3h 5m',
      );

      // Assert: Navigation should be blocked (no back button, no nav bar visible)
      expect(
        find.byType(BottomNavigationBar),
        findsNothing,
        reason: 'Bottom navigation bar should be hidden during penalty zone',
      );
    });

    testWidgets('penalty zone state persists across widget rebuilds', (tester) async {
      // Seed monarchState with penalty zone activated 30 minutes ago
      final thirtyMinutesAgo = DateTime.now().subtract(const Duration(minutes: 30));
      HiveService.monarchState.put('inPenaltyZone', true);
      HiveService.monarchState.put('penaltyActivatedAt', thirtyMinutesAgo.toIso8601String());

      final player = PlayerProvider();
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        ChangeNotifierProvider<PlayerProvider>.value(
          value: player,
          child: const MaterialApp(
            home: Dashboard(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify penalty zone is active
      expect(find.byType(PenaltyZoneScreen), findsOneWidget);
      expect(player.inPenaltyZone, isTrue);

      // Trigger a rebuild
      await tester.pumpAndSettle();

      // Assert: Penalty zone should still be active after rebuild
      expect(find.byType(PenaltyZoneScreen), findsOneWidget);
      expect(player.inPenaltyZone, isTrue);

      // Assert: Remaining time should be approximately 3.5 hours
      final remaining = player.penaltyRemainingDuration;
      expect(remaining, isNotNull);
      expect(
        remaining!.inMinutes,
        greaterThanOrEqualTo(205), // 3h 25m
        reason: 'Remaining time should be at least 3h 25m',
      );
      expect(
        remaining.inMinutes,
        lessThanOrEqualTo(215), // 3h 35m
        reason: 'Remaining time should be at most 3h 35m',
      );
    });

    testWidgets('timer updates every second', (tester) async {
      // Seed monarchState with penalty zone activated 1 hour ago
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      HiveService.monarchState.put('inPenaltyZone', true);
      HiveService.monarchState.put('penaltyActivatedAt', oneHourAgo.toIso8601String());

      final player = PlayerProvider();
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        ChangeNotifierProvider<PlayerProvider>.value(
          value: player,
          child: const MaterialApp(
            home: Dashboard(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Get initial timer text
      final initialTimerFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data != null &&
            RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(widget.data!),
      );
      expect(initialTimerFinder, findsOneWidget);
      
      final initialTimerWidget = tester.widget<Text>(initialTimerFinder);
      final initialTimerText = initialTimerWidget.data!;

      // Wait 2 seconds
      await tester.pump(const Duration(seconds: 2));

      // Get updated timer text
      final updatedTimerFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data != null &&
            RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(widget.data!),
      );
      expect(updatedTimerFinder, findsOneWidget);
      
      final updatedTimerWidget = tester.widget<Text>(updatedTimerFinder);
      final updatedTimerText = updatedTimerWidget.data!;

      // Assert: Timer should have changed (countdown is active)
      expect(
        updatedTimerText,
        isNot(equals(initialTimerText)),
        reason: 'Timer should update every second',
      );
    });
  });
}
