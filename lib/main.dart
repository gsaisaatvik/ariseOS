import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'player_provider.dart';
import 'login_screen.dart';
import 'dashboard.dart';
import 'services/hive_service.dart';
import 'root_decider.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Initialize Hive before app starts
  await HiveService.init();

  try {
    await NotificationService.init();
    // Notification test moved to Awakening Screen button only
  } catch (e) {
    print("Notification error: $e");
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

        // 🔥 Dark RPG-style theme
        theme: ThemeData.dark().copyWith(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurpleAccent,
            brightness: Brightness.dark,
          ),
        ),

        // Use RootDecider to decide initial screen
        home: RootDecider(),
      ),
    );
  }
}