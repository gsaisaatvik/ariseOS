import 'package:flutter/material.dart';
import 'services/hive_service.dart';
import 'dashboard.dart';
import 'notification_sequence.dart';
import 'login_screen.dart';

class RootDecider extends StatelessWidget {
  const RootDecider({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = HiveService.settings;
    final bool isLoggedIn = settings.get('isLoggedIn', defaultValue: false);

    if (!isLoggedIn) {
      return const LoginScreen();
    }

    final bool hasAwakened =
        settings.get('hasAwakened', defaultValue: false);

    if (!hasAwakened) {
      return NotificationSequence();
      // your awakening screen
    }

    return Dashboard();
  }
}