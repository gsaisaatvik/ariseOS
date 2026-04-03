import 'package:audioplayers/audioplayers.dart';

/// Subtle audio feedback for XP events (Phase 1 — no overlay spam).
class XpFeedback {
  XpFeedback._();

  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playChime() async {
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setVolume(0.28);
    await _player.play(AssetSource('audio/system_on.mp3'));
  }

  /// Stronger chime for the full-screen level up moment.
  static Future<void> playLevelUpChime() async {
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setVolume(0.42);
    await _player.play(AssetSource('audio/system_on.mp3'));
    // Slight delay echo for the "dopamine spike" feel.
    await Future.delayed(const Duration(milliseconds: 220));
    await _player.play(AssetSource('audio/system_on.mp3'));
  }

  /// Short activation ping when a directive session starts (inline card).
  static Future<void> playExecutePing() async {
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setVolume(0.18);
    await _player.play(AssetSource('audio/system_off.mp3'));
  }
}
