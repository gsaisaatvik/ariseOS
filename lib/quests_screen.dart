import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'player_provider.dart';
import 'ui/theme/app_text_styles.dart';
import 'ui/theme/app_colors.dart';
import 'ui/widgets/widgets.dart';

class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {
  int remainingSeconds = 90 * 60; // 90 min
  Timer? timer;
  bool isRunning = false;

  void startTimer() {
    timer?.cancel();
    setState(() => isRunning = true);

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingSeconds > 0) {
        setState(() => remainingSeconds--);
      } else {
        t.cancel();
        setState(() => isRunning = false);
      }
    });
  }

  void pauseTimer() {
    timer?.cancel();
    setState(() => isRunning = false);
  }

  String formatTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  void stopTimer() {
    timer?.cancel();
    setState(() {
      isRunning = false;
      remainingSeconds = 90 * 60;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [

            /// 🔥 DAILY DUNGEON PANEL
            HolographicPanel(
              header: const SystemHeaderBar(label: 'DAILY DUNGEON'),
              emphasize: true,
              padding: const EdgeInsets.all(12),
              child: _buildCognitiveAscension(),
            ),

            /// SIDE QUESTS (UNCHANGED)
            HolographicPanel(
              header: const SystemHeaderBar(label: 'SIDE QUESTS'),
              padding: const EdgeInsets.all(12),
              child: _buildSideQuests(),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCognitiveAscension() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const SizedBox(height: 10),

        /// TOP LABEL
        Text(
          "FOCUS TRAINING",
          style: AppTextStyles.systemLabel.copyWith(
            color: AppColors.primaryBlue,
            letterSpacing: 2,
          ),
        ),

        const SizedBox(height: 8),

        /// TITLE
        Text(
          "COGNITIVE\nASCENSION",
          style: AppTextStyles.headerLarge.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),

        const SizedBox(height: 12),

        /// EFFICIENCY
        Text(
          "EFFICIENCY: 100% [+10XP/MIN]",
          style: AppTextStyles.bodyPrimary.copyWith(
            color: Colors.amberAccent,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),

        const SizedBox(height: 20),

        /// 🔥 TIMER (CENTERPIECE)
        Center(
          child: Text(
            formatTime(remainingSeconds),
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
              letterSpacing: 2,
            ),
          ),
        ),

        const SizedBox(height: 12),

        /// PROGRESS LINE
        Container(
          height: 2,
          color: Colors.white12,
        ),

        const SizedBox(height: 16),

        /// 🔥 START / PAUSE / END BUTTONS
        Center(
          child: isRunning
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    /// PAUSE
                    GestureDetector(
                      onTap: pauseTimer,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.redAccent),
                        ),
                        child: const Text(
                          "PAUSE",
                          style: TextStyle(
                            color: Colors.redAccent,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    /// END
                    GestureDetector(
                      onTap: stopTimer,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white54),
                        ),
                        child: const Text(
                          "END",
                          style: TextStyle(
                            color: Colors.white70,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : (remainingSeconds < (90 * 60)
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        /// RESUME
                        GestureDetector(
                          onTap: startTimer,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.primaryBlue),
                            ),
                            child: const Text(
                              "RESUME",
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                letterSpacing: 2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        /// END
                        GestureDetector(
                          onTap: stopTimer,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white54),
                            ),
                            child: const Text(
                              "END",
                              style: TextStyle(
                                color: Colors.white70,
                                letterSpacing: 2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : GestureDetector(
                      onTap: startTimer,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primaryBlue),
                        ),
                        child: const Text(
                          "START SESSION",
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )),
        ),
      ],
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: AppTextStyles.systemLabel.copyWith(color: Colors.white38),
          ),
          Text(
            value,
            style: AppTextStyles.systemLabel.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// SIDE QUESTS (same minimal style)
  Widget _buildSideQuests() {
    return Column(
      children: [
        _sideQuestItem("Drink 3L water", 10),
        _sideQuestItem("Read 10 pages", 15),
        _sideQuestItem("Walk 5000 steps", 20),
      ],
    );
  }

  Widget _sideQuestItem(String label, int xp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Text("[ ] ", style: TextStyle(color: Colors.white38)),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyPrimary,
            ),
          ),
          Text(
            "+$xp XP",
            style: AppTextStyles.systemLabel.copyWith(
              color: Colors.amberAccent,
            ),
          ),
        ],
      ),
    );
  }
}