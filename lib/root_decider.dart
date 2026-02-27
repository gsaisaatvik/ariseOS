import 'package:flutter/material.dart';
import 'services/hive_service.dart';
import 'login_screen.dart';
import 'dashboard.dart';
import 'notification_sequence.dart';

class RootDecider extends StatelessWidget {
  const RootDecider({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = HiveService.settings;

    final bool isLoggedIn =
        settings.get('isLoggedIn', defaultValue: false);

    final bool hasAwakened =
        settings.get('hasAwakened', defaultValue: false);

    if (!isLoggedIn) {
      return LoginScreen();
    }

    if (!hasAwakened) {
      return NotificationSequence(); 
      // your awakening screen
    }

    return Dashboard();
  }
}