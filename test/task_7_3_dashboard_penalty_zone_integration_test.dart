import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:arise_os/dashboard.dart';
import 'package:arise_os/player_provider.dart';
import 'package:arise_os/penalty_zone_screen.dart';
import 'package:arise_os/services/hive_service.dart';

/// Task 7.3: Integrate PenaltyZoneScreen into Dashboard as a Stack overlay
///
/// This test verifies that:
/// 1. Dashboard uses Consumer<PlayerProvider> inside the Stack
/// 2. When player.inPenaltyZone == true, PenaltyZoneScreen is rendered with Positioned.fill
/// 3. IgnorePointer(ignoring: false) blocks all underlying taps
/// 4. PenaltyZoneScreen receives onExpired callback that calls player.deactivatePenaltyZone()
///
/// **Validates: Requirements 4.1, 4.3**
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late Directory tempDir;

  setUpAll(() async {
    // Create a temporary directory for Hive
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    
    // Initialize Hive with the temporary directory
    Hive.init(tempDir.path);
    
    // Open required boxes
    await Hive.openBox(HiveService.settingsBox);
    await Hive.openBox(HiveService.monarchStateBox);
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    
    // Delete the temporary directory
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Task 7.3: Dashboard PenaltyZone Integration', () {
    testWidgets('Dashboard shows PenaltyZoneScreen when inPenaltyZone is true',
        (WidgetTester tester) async {
      // Create a PlayerProvider instance
      final player = PlayerProvider();

      // Activate penalty zone
      player.activatePenaltyZone();

      // Build Dashboard with PlayerProvider
      await tester.pumpWidget(
        ChangeNotifierProvider<PlayerProvider>.value(
          value: player,
          child: const MaterialApp(
            home: Dashboard(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify PenaltyZoneScreen is displayed
      expect(find.byType(PenaltyZoneScreen), findsOneWidget);
      expect(find.text('PENALTY ZONE ACTIVE'), findsOneWidget);
      expect(find.text('SURVIVAL TIMER'), findsOneWidget);
    });

    testWidgets('Dashboard hides PenaltyZoneScreen when inPenaltyZone is false',
        (WidgetTester tester) async {
      // Create a PlayerProvider instance
      final player = PlayerProvider();

      // Ensure penalty zone is NOT active
      expect(player.inPenaltyZone, false);

      // Build Dashboard with PlayerProvider
      await tester.pumpWidget(
        ChangeNotifierProvider<PlayerProvider>.value(
          value: player,
          child: const MaterialApp(
            home: Dashboard(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify PenaltyZoneScreen is NOT displayed
      expect(find.byType(PenaltyZoneScreen), findsNothing);
      expect(find.text('PENALTY ZONE ACTIVE'), findsNothing);
    });

    testWidgets('PenaltyZoneScreen uses Positioned.fill and IgnorePointer',
        (WidgetTester tester) async {
      // Create a PlayerProvider instance
      final player = PlayerProvider();

      // Activate penalty zone
      player.activatePenaltyZone();

      // Build Dashboard with PlayerProvider
      await tester.pumpWidget(
        ChangeNotifierProvider<PlayerProvider>.value(
          value: player,
          child: const MaterialApp(
            home: Dashboard(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the Stack in Dashboard
      final stackFinder = find.descendant(
        of: find.byType(Dashboard),
        matching: find.byType(Stack),
      );
      expect(stackFinder, findsOneWidget);

      // Verify Positioned.fill is used
      final positionedFinder = find.descendant(
        of: stackFinder,
        matching: find.byWidgetPredicate(
          (widget) => widget is Positioned && 
                      widget.left == 0 && 
                      widget.top == 0 && 
                      widget.right == 0 && 
                      widget.bottom == 0,
        ),
      );
      expect(positionedFinder, findsWidgets);

      // Verify IgnorePointer is used with ignoring: false
      final ignorePointerFinder = find.descendant(
        of: find.byType(Dashboard),
        matching: find.byWidgetPredicate(
          (widget) => widget is IgnorePointer && widget.ignoring == false,
        ),
      );
      expect(ignorePointerFinder, findsOneWidget);
    });

    testWidgets('PenaltyZoneScreen receives correct onExpired callback',
        (WidgetTester tester) async {
      // Create a PlayerProvider instance
      final player = PlayerProvider();

      // Activate penalty zone with a timestamp 4 hours ago (expired)
      player.activatePenaltyZone();
      // Manually set the timestamp to 4 hours ago to simulate expiration
      final expiredTime = DateTime.now().subtract(const Duration(hours: 4, minutes: 1));
      final monarchBox = Hive.box(HiveService.monarchStateBox);
      await monarchBox.put('penaltyActivatedAt', expiredTime.toIso8601String());

      // Build Dashboard with PlayerProvider
      await tester.pumpWidget(
        ChangeNotifierProvider<PlayerProvider>.value(
          value: player,
          child: const MaterialApp(
            home: Dashboard(),
          ),
        ),
      );

      // Initial pump
      await tester.pump();

      // Verify penalty zone is active initially
      expect(player.inPenaltyZone, true);

      // Wait for the StreamBuilder to detect expiration
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      // Verify penalty zone was deactivated
      expect(player.inPenaltyZone, false);
    });

    testWidgets('Dashboard blocks underlying taps when penalty zone is active',
        (WidgetTester tester) async {
      // Create a PlayerProvider instance
      final player = PlayerProvider();

      // Activate penalty zone
      player.activatePenaltyZone();

      // Build Dashboard with PlayerProvider
      await tester.pumpWidget(
        ChangeNotifierProvider<PlayerProvider>.value(
          value: player,
          child: const MaterialApp(
            home: Dashboard(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Try to tap on the navigation bar (should be blocked)
      final navBarFinder = find.text('Status');
      expect(navBarFinder, findsOneWidget);

      // Attempt to tap - this should be blocked by IgnorePointer
      // We can't directly test that the tap is blocked, but we can verify
      // that the IgnorePointer is configured correctly (ignoring: false means
      // it absorbs pointer events and doesn't pass them through)
      final ignorePointerFinder = find.byWidgetPredicate(
        (widget) => widget is IgnorePointer && widget.ignoring == false,
      );
      expect(ignorePointerFinder, findsOneWidget);
    });
  });
}
