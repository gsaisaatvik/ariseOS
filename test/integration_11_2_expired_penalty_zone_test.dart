import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:arise_os/player_provider.dart';
import 'package:arise_os/services/hive_service.dart';
import 'package:arise_os/dashboard.dart';
import 'package:arise_os/penalty_zone_screen.dart';

/// Integration Test 11.2: Cold start with expired Penalty Zone
///
/// Validates: Requirements 4.6, 4.8
///
/// This integration test verifies that when the app is launched with a
/// penalty zone that has already expired (>= 4 hours elapsed), the
/// penalty zone is automatically deactivated and the Dashboard is shown
/// normally (not PenaltyZoneScreen).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Integration 11.2: Cold start with expired Penalty Zone', () {
    setUp(() async {
      await Hive.initFlutter();
      await Hive.openBox('settings');
      await Hive.openBox('monarch_state');
      await HiveService.init();
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
      await Hive.close();
    });

    testWidgets('auto-deactivates expired penalty zone on cold start', (tester) async {
      final fiveHoursAgo = DateTime.now().subtract(const Duration(hours: 5));
      HiveService.monarchState.put('inPenaltyZone', true);
      HiveService.monarchState.put('penaltyActivatedAt', fiveHoursAgo.toIso8601String());

      final player = PlayerProvider();
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        ChangeNotifierProvider<PlayerProvider>.value(
          value: player,
          child: const MaterialApp(home: Dashboard()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PenaltyZoneScreen), findsNothing);
      expect(find.byType(Dashboard), findsOneWidget);
      expect(player.inPenaltyZone, isFalse);
      expect(player.penaltyActivatedAt, isNull);
      expect(player.penaltyRemainingDuration, isNull);
      expect(HiveService.monarchState.get('inPenaltyZone', defaultValue: false), isFalse);
      expect(HiveService.monarchState.get('penaltyActivatedAt'), isNull);
    });

    testWidgets('handles exactly 4 hours elapsed (boundary case)', (tester) async {
      final fourHoursAgo = DateTime.now().subtract(const Duration(hours: 4));
      HiveService.monarchState.put('inPenaltyZone', true);
      HiveService.monarchState.put('penaltyActivatedAt', fourHoursAgo.toIso8601String());

      final player = PlayerProvider();
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        ChangeNotifierProvider<PlayerProvider>.value(
          value: player,
          child: const MaterialApp(home: Dashboard()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PenaltyZoneScreen), findsNothing);
      expect(player.inPenaltyZone, isFalse);
      expect(player.penaltyActivatedAt, isNull);
    });
  });
}
