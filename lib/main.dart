import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'player_provider.dart';
import 'services/hive_service.dart';
import 'services/firebase_service.dart';
import 'root_decider.dart';
import 'services/notification_service.dart';
import 'ui/theme/app_theme.dart';
import 'ui/widgets/scanline_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Initialize Hive before app starts
  await HiveService.init();

  try {
    await FirebaseService.init();
  } catch (e) {
    // Firebase initialization error
  }

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PlayerProvider>(create: (_) => PlayerProvider()),
      ],
      child: MaterialApp(
        title: 'ARISE OS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.ariseDarkTheme,

        builder: (context, child) {
          return ScanlineOverlay(child: child!);
        },

        // Use RootDecider to decide initial screen
        home: RootDecider(),
      ),
    );
  }
}
