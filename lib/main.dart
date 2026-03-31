import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'player_provider.dart';
import 'services/hive_service.dart';
import 'root_decider.dart';
import 'services/notification_service.dart';
import 'ui/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Initialize Hive before app starts
  await HiveService.init();

  try {
    await NotificationService.init();
  } catch (e) {
    // Notification initialization error
  }

  runApp(const ARISEApp());
}

class ARISEApp extends StatelessWidget {
  const ARISEApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PlayerProvider>(
      create: (_) => PlayerProvider(),
      child: MaterialApp(
        title: 'ARISE OS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.ariseDarkTheme,

        // Use RootDecider to decide initial screen
        home: RootDecider(),
      ),
    );
  }
}