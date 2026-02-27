import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

class SystemOverlay {
  static void show(BuildContext context, {required String title, required String message}) {
    OverlayState? overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _SystemOverlayWidget(
        title: title,
        message: message,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlayState.insert(overlayEntry);
  }
}

class _SystemOverlayWidget extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback onDismiss;

  const _SystemOverlayWidget({
    required this.title,
    required this.message,
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
      if (await Vibration.hasVibrator() ?? false) {
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
                        color: Colors.black.withOpacity(0.9),
                        // Sharp borders
                        border: Border.all(
                          color: const Color(0xFF00FFFF).withOpacity(0.7),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00FFFF).withOpacity(0.3 * _glowAnimation.value),
                            blurRadius: 15 * _glowAnimation.value,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "SYSTEM MESSAGE",
                                style: TextStyle(
                                  color: const Color(0xFF00FFFF).withOpacity(0.6),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 3,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              Icon(
                                Icons.info_outline,
                                color: const Color(0xFF00FFFF).withOpacity(0.6),
                                size: 12,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Divider line
                          Container(
                            height: 1,
                            width: double.infinity,
                            color: const Color(0xFF00FFFF).withOpacity(0.4),
                          ),
                          const SizedBox(height: 16),
                          // Main Title
                          Text(
                            widget.title.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF00FFFF),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Subtitle / Message
                          Text(
                            widget.message,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                              fontFamily: 'monospace',
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
