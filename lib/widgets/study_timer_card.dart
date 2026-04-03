import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../player_provider.dart';
import '../services/hive_service.dart';
import '../ui/widgets/system_notification_card.dart';
import 'system_overlay.dart';

/// 90-minute focus timer.
///
/// **Study mode** (default): awards [PlayerProvider.addStudyXP] on completion.
/// **Directive mode** ([onDirectiveComplete] set): awards nothing here — caller
/// must grant XP and mark the quest complete only in the callback (full 90:00).
class StudyTimerCard extends StatefulWidget {
  const StudyTimerCard({
    super.key,
    this.storageKeyPrefix = 'study',
    this.onDirectiveComplete,
    this.onDirectiveAborted,
    this.compact = false,
    this.autoStartDirective = false,
    /// Session target length. Default 90 min (Quests study timer).
    this.durationSeconds = 5400,
  });

  /// Isolates Hive keys so Quests-tab study timer does not clash with directive sessions.
  final String storageKeyPrefix;

  /// Total session length in seconds (directive: per [DirectiveConfig]).
  final int durationSeconds;

  /// When non-null, timer runs in **directive** mode: XP is applied only here
  /// after a **full** 90:00 session. Early stop resets with no reward.
  final Future<void> Function(int minutes)? onDirectiveComplete;

  /// Directive STOP / short cancel — [elapsedSeconds] at exit; parent applies penalty if ≥ 60s.
  final void Function(int elapsedSeconds)? onDirectiveAborted;

  /// Inline directive card: smaller layout, no outer frame (parent card provides chrome).
  final bool compact;

  /// Start countdown immediately when mounted (directive inline only).
  final bool autoStartDirective;

  @override
  State<StudyTimerCard> createState() => _StudyTimerCardState();
}

class _StudyTimerCardState extends State<StudyTimerCard> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isActive = false;

  int? _sessionTotalSeconds;

  // Freeze the active session duration. This prevents daily adaptive duration
  // changes from altering an already-running directive/session.
  int get _totalSeconds => _sessionTotalSeconds ?? widget.durationSeconds;

  String get _kStart => '${widget.storageKeyPrefix}TimerStartISO';
  String get _kElapsed => '${widget.storageKeyPrefix}TimerElapsedSecs';
  String get _kActive => '${widget.storageKeyPrefix}TimerActive';
  String get _kTotal => '${widget.storageKeyPrefix}TimerTotalSecs';

  bool get _directiveMode => widget.onDirectiveComplete != null;

  @override
  void initState() {
    super.initState();
    _loadState();
    if (widget.autoStartDirective && widget.onDirectiveComplete != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!_isActive && _elapsedSeconds == 0) {
          _toggleTimer();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadState() {
    final settings = HiveService.settings;
    _isActive = settings.get(_kActive, defaultValue: false);
    _elapsedSeconds = settings.get(_kElapsed, defaultValue: 0);

    _sessionTotalSeconds =
        settings.get(_kTotal, defaultValue: widget.durationSeconds) as int;

    if (_isActive) {
      final startIso = settings.get(_kStart, defaultValue: '');
      if (startIso.isNotEmpty) {
        final startTime = DateTime.tryParse(startIso);
        if (startTime != null) {
          final now = DateTime.now().toUtc();
          final diff = now.difference(startTime).inSeconds;
          _elapsedSeconds += diff;
          settings.put(_kStart, now.toIso8601String());
          settings.put(_kElapsed, _elapsedSeconds);
          _startInternalTimer(now);
        } else {
          _isActive = false;
        }
      } else {
        _isActive = false;
      }
    }

    if (_elapsedSeconds >= _totalSeconds) {
      _autoComplete();
    }
  }

  void _startInternalTimer(DateTime startTime) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final now = DateTime.now().toUtc();
      final diff = now.difference(startTime).inSeconds;

      setState(() {
        final totalElapsed = _elapsedSeconds + diff;
        if (totalElapsed >= _totalSeconds) {
          timer.cancel();
          _autoComplete();
        }
      });
    });
  }

  int get _currentElapsed {
    if (!_isActive) return _elapsedSeconds;
    final startIso = HiveService.settings.get(_kStart, defaultValue: '');
    if (startIso.isEmpty) return _elapsedSeconds;
    final startTime = DateTime.tryParse(startIso);
    if (startTime == null) return _elapsedSeconds;
    return _elapsedSeconds + DateTime.now().toUtc().difference(startTime).inSeconds;
  }

  void _toggleTimer() {
    final settings = HiveService.settings;
    setState(() {
      if (_isActive) {
        _isActive = false;
        _timer?.cancel();
        _elapsedSeconds = _currentElapsed;
        settings.put(_kActive, false);
        settings.put(_kElapsed, _elapsedSeconds);
        settings.put(_kStart, '');
      } else {
        _isActive = true;
        _sessionTotalSeconds = widget.durationSeconds;
        settings.put(_kTotal, _sessionTotalSeconds);
        final now = DateTime.now().toUtc();
        settings.put(_kActive, true);
        settings.put(_kStart, now.toIso8601String());

        // Focus Boost is a "next directive session" modifier.
        // Consume it at the moment the timer starts to ensure the session
        // duration matches the boosted value.
        if (_directiveMode) {
          final player = Provider.of<PlayerProvider>(context, listen: false);
          player.consumeFocusBoostNextIfActive();
        }

        _startInternalTimer(now);
      }
    });
  }

  void _finishEarly() {
    final elapsedTotal = _currentElapsed;
    if (elapsedTotal < 60) {
      _resetTimerData();
      setState(() {
        _elapsedSeconds = 0;
        _isActive = false;
      });
      if (_directiveMode) {
        widget.onDirectiveAborted?.call(elapsedTotal);
      }
      return;
    }

    if (_directiveMode) {
      // Directive: no partial credit — abort only.
      _timer?.cancel();
      _resetTimerData();
      setState(() {
        _isActive = false;
        _elapsedSeconds = 0;
      });
      widget.onDirectiveAborted?.call(elapsedTotal);
      if (mounted) {
        SystemOverlay.show(
          context,
          title: 'DIRECTIVE TERMINATED',
          message:
              'Directive aborted. Progress lost.\nWallet penalty may apply.',
          type: SystemNotificationType.danger,
        );
      }
      return;
    }

    _processCompletion(elapsedTotal ~/ 60);
  }

  void _autoComplete() {
    _processCompletion(_totalSeconds ~/ 60);
  }

  Future<void> _processCompletion(int minutes) async {
    _timer?.cancel();
    _resetTimerData();

    setState(() {
      _isActive = false;
      _elapsedSeconds = 0;
    });

    if (_directiveMode) {
      await widget.onDirectiveComplete!(minutes);
      return;
    }

    final player = Provider.of<PlayerProvider>(context, listen: false);
    player.addStudyXP(minutes);
  }

  void _resetTimerData() {
    final settings = HiveService.settings;
    settings.put(_kActive, false);
    settings.put(_kStart, '');
    settings.put(_kElapsed, 0);
    _sessionTotalSeconds = null;
    settings.delete(_kTotal);
  }

  String _formatDisplay(int seconds) {
    int rem = _totalSeconds - seconds;
    if (rem < 0) rem = 0;
    final m = (rem ~/ 60).toString().padLeft(2, '0');
    final s = (rem % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final sessionsCount = player.studySessionsToday;

    String effText = "EFFICIENCY: 100% [+10XP/MIN]";
    if (sessionsCount == 1) {
      effText = "EFFICIENCY: 50% [+5XP/MIN]";
    } else if (sessionsCount >= 2) {
      effText = "EFFICIENCY: 25% [+2.5XP/MIN]";
    }

    if (_directiveMode) {
      final m = _totalSeconds ~/ 60;
      effText =
          'DIRECTIVE: complete full session ($m min) to earn +10 XP';
    }

    int currentSecs = _currentElapsed;
    if (currentSecs > _totalSeconds) currentSecs = _totalSeconds;

    if (widget.compact) {
      return _buildCompact(context, effText, currentSecs);
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        border: Border.all(
          color: Colors.blueAccent.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withValues(alpha: 0.4),
            blurRadius: 15,
          )
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _directiveMode ? "DIRECTIVE TIMER" : "FOCUS TRAINING",
                style: TextStyle(
                  color: Colors.blueAccent.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              const Icon(Icons.psychology, color: Colors.blueAccent, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _directiveMode ? "SESSION LOCK" : "COGNITIVE ASCENSION",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            effText,
            style: const TextStyle(
              color: Colors.amberAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              _formatDisplay(currentSecs),
              style: const TextStyle(
                color: Colors.blueAccent,
                fontSize: 48,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: currentSecs / _totalSeconds,
            backgroundColor: Colors.white10,
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Transform(
                  transform: Matrix4.skewX(-0.15),
                  child: ElevatedButton(
                    onPressed: _toggleTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                      side: const BorderSide(color: Colors.blueAccent, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: Transform(
                      transform: Matrix4.skewX(0.15),
                      child: Text(
                        _isActive ? "PAUSE" : (currentSecs > 0 ? "RESUME" : "START SESSION"),
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (currentSecs > 60) ...[
                const SizedBox(width: 12),
                Transform(
                  transform: Matrix4.skewX(-0.15),
                  child: ElevatedButton(
                    onPressed: _finishEarly,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                      side: const BorderSide(color: Colors.redAccent, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1)),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      elevation: 0,
                    ),
                    child: Transform(
                      transform: Matrix4.skewX(0.15),
                      child: Icon(
                        _directiveMode ? Icons.close : Icons.stop,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompact(
    BuildContext context,
    String effText,
    int currentSecs,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            effText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.cyanAccent.withValues(alpha: 0.75),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDisplay(currentSecs),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF00E5FF),
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: currentSecs / _totalSeconds,
              minHeight: 3,
              backgroundColor: Colors.white10,
              color: const Color(0xFF00E5FF),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _toggleTimer,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00E5FF),
                    side: const BorderSide(color: Color(0xFF00E5FF)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    _isActive ? 'PAUSE' : (currentSecs > 0 ? 'RESUME' : 'START'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              if (currentSecs > 60) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _finishEarly,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Text(
                    _directiveMode ? 'STOP' : 'END',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
