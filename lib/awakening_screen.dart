import 'package:flutter/material.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'dashboard.dart';
import 'ui/widgets/widgets.dart';
import 'ui/theme/app_text_styles.dart';

class AwakeningScreen extends StatefulWidget {
  const AwakeningScreen({super.key});

  @override
  State<AwakeningScreen> createState() => _AwakeningScreenState();
}

class _AwakeningScreenState extends State<AwakeningScreen> {
  final TextEditingController _nameController = TextEditingController();

  Future<void> _completeAwakening(BuildContext context) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must name your soul.")),
      );
      return;
    }

    final settings = HiveService.settings;
    final now = DateTime.now().toUtc();

    await settings.put('hasAwakened', true);
    await settings.put('playerName', name);
    await settings.put('awakeningDate', now.toIso8601String());

    try {
      await NotificationService.scheduleDailyNotifications();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Syncing with System...")),
        );
      }
    } catch (e) {
      // Notification scheduling error
    }

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Dashboard()),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: HolographicPanel(
            header: const SystemHeaderBar(label: 'PLAYER REGISTRATION'),
            emphasize: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icons/app_icon.png',
                      height: 64,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'You have Awakened.',
                      style: AppTextStyles.headerMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  "From today, your discipline defines you.\n"
                  "Complete your Core Quests.\n"
                  "Conquer your Dungeon.\n"
                  "Rise in Level.",
                  style: AppTextStyles.bodySecondary,
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Hunter name',
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryActionButton(
                    label: 'Begin my journey',
                    onPressed: () => _completeAwakening(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}