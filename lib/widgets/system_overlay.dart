import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

import '../ui/theme/app_colors.dart';
import '../ui/theme/app_text_styles.dart';
import '../ui/widgets/widgets.dart';

class SystemOverlay {
  static void show(BuildContext context, {required String title, required String message, String? playerName}) {
    OverlayState? overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _SystemOverlayWidget(
        title: title,
        message: message,
        playerName: playerName,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlayState.insert(overlayEntry);
  }
}

class _SystemOverlayWidget extends StatefulWidget {
  final String title;
  final String message;
  final String? playerName;
  final VoidCallback onDismiss;

  const _SystemOverlayWidget({
    required this.title,
    required this.message,
    this.playerName,
    required this.onDismiss,
  });

  @override
  State<_SystemOverlayWidget> createState() => _SystemOverlayWidgetState();
}

class _SystemOverlayWidgetState extends State<_SystemOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();
// ... (keep audio/dismiss logic as is)
    _playAppearEffects();

    // Auto dismiss after 2 seconds (plus animation time)
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) {
        _playDismissEffects();
        _controller.reverse().then((value) {
          widget.onDismiss();
        });
      }
    });
  }

  Future<void> _playAppearEffects() async {
    try {
      await _audioPlayer.play(AssetSource('audio/system_on.mp3'));
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        Vibration.vibrate(duration: 40);
      }
    } catch (e) {
      debugPrint("Effect Error (Appear): $e");
    }
  }

  Future<void> _playDismissEffects() async {
    try {
      await _audioPlayer.play(AssetSource('audio/system_off.mp3'));
    } catch (e) {
      debugPrint("Effect Error (Dismiss): $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Background Blur
          FadeTransition(
            opacity: _fadeAnimation,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: Colors.black.withOpacity(0.8),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          // Content
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.surfaceElevated.withOpacity(0.96),
                            AppColors.surface.withOpacity(0.94),
                          ],
                        ),
                        border: Border.all(
                          color: AppColors.primaryBlue.withOpacity(0.65),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue
                                .withOpacity(0.22 * _glowAnimation.value),
                            blurRadius: 15 * _glowAnimation.value,
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: AppColors.primaryViolet
                                .withOpacity(0.10 * _glowAnimation.value),
                            blurRadius: 26 * _glowAnimation.value,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SystemHeaderBar(
                            label: "NOTIFICATION",
                            icon: Icons.error_outline,
                          ),
                          const SizedBox(height: 8),
                          // Divider line
                          Container(
                            height: 1,
                            width: double.infinity,
                            color: AppColors.borderSoft,
                          ),
                          const SizedBox(height: 12),
                          if (widget.playerName != null) ...[
                            Text(
                              "Subject: ${widget.playerName!.toUpperCase()}",
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          // Main Title
                          Text(
                            widget.title.toUpperCase(),
                            style: AppTextStyles.headerMedium.copyWith(
                              color: AppColors.primaryBlue,
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Subtitle / Message
                          Text(
                            widget.message,
                            style: TextStyle(
                              color: AppColors.textPrimary.withOpacity(0.92),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
