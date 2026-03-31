import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'engine/dynamic_engine.dart';
import 'services/hive_service.dart';
import 'widgets/system_overlay.dart';
import 'widgets/xp_floating_text.dart';
import 'ui/widgets/widgets.dart';
import 'ui/theme/app_text_styles.dart';
import 'player_provider.dart';
import 'models/dungeon_template.dart';

class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {
  late DynamicEngine engine;
  bool _initialized = false;
  bool _isProcessing = false;

  DateTime? _dungeonStartTime;
  Timer? _countdownTimer;
  int _elapsedSeconds = 0;
  static const int _dungeonDurationSeconds = 14400; // 4 hours

  @override
  void initState() {
    super.initState();
    engine = DynamicEngine();
    _initDungeon();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initDungeon() async {
    await engine.assignTodayDungeon();

    if (mounted) {
      final savedStart = HiveService.settings.get('dungeonStartTime', defaultValue: '');
      if (savedStart != '' && engine.status == 'pending') {
        final startTime = DateTime.tryParse(savedStart);
        if (startTime != null) {
          _startTimer(startTime);
        }
      }

      setState(() {
        _initialized = true;
      });
    }
  }

  void _startTimer(DateTime startTime) {
    _dungeonStartTime = startTime;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final elapsed = DateTime.now().toUtc().difference(_dungeonStartTime!).inSeconds;
      setState(() => _elapsedSeconds = elapsed);
      if (elapsed >= _dungeonDurationSeconds) {
        timer.cancel();
        if (engine.status == 'pending') {
          final player = Provider.of<PlayerProvider>(context, listen: false);
          _autoComplete(context, player);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final dungeon = engine.todayDungeon;
    final player = Provider.of<PlayerProvider>(context);
    final penalty =
        HiveService.settings.get('penaltyActive', defaultValue: false);

    return dungeon == null
        ? _buildEmptyState()
        : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                HolographicPanel(
                  header: const SystemHeaderBar(label: 'FOCUS SESSION'),
                  child: const StudyTimerCard(),
                ),
                HolographicPanel(
                  header: const SystemHeaderBar(label: 'QUEST INFO'),
                  emphasize: true,
                  child:
                      _buildDungeonCard(context, dungeon, player, penalty),
                ),
              ],
            ),
          );
  }

  Widget _buildDungeonCard(BuildContext context, DungeonTemplate dungeon,
      PlayerProvider player, bool penalty) {
    final status = engine.status;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dungeon.category.toUpperCase(),
                style: TextStyle(
                  color: _getStatusColor(status).withOpacity(0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              if (status == 'pending')
                const Icon(Icons.security, color: Colors.cyanAccent, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            dungeon.name.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            dungeon.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          if (penalty)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    "SYSTEM PENALTY ACTIVE: XP LOCKED",
                    style: TextStyle(
                      color: Colors.redAccent.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          _buildActionButton(context, status, player, penalty),
        ],
    );
  }

  Widget _buildActionButton(BuildContext context, String status,
      PlayerProvider player, bool penalty) {
    if (status == 'completed') {
      return _lockedState("DUNGEON CLEARED", Colors.greenAccent);
    } else if (status == 'failed') {
      return _lockedState("MISSION FAILED", Colors.redAccent);
    }

    if (_dungeonStartTime != null) {
      return Column(
        children: [
          LinearProgressIndicator(
            value: (_elapsedSeconds / _dungeonDurationSeconds).clamp(0.0, 1.0),
            backgroundColor: Colors.white10,
            color: const Color(0xFF00E5FF),
          ),
          const SizedBox(height: 16),
          Text(
            _formatCountdown(_dungeonDurationSeconds - _elapsedSeconds),
            style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 36, fontWeight: FontWeight.w900),
          ),
          const Text("REMAINING", style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 3)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: PrimaryActionButton(
              label: 'Mark complete',
              onPressed: (_isProcessing || penalty)
                  ? null
                  : () => _handleMarkComplete(context, player),
            ),
          )
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: PrimaryActionButton(
        label: 'Enter dungeon',
        onPressed: (penalty || _isProcessing)
            ? null
            : () {
                final now = DateTime.now().toUtc();
                HiveService.settings
                    .put('dungeonStartTime', now.toIso8601String());
                _startTimer(now);
              },
      ),
    );
  }

  Widget _lockedState(String label, Color color) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        color: color.withOpacity(0.05),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'completed') return Colors.greenAccent;
    if (status == 'failed') return Colors.redAccent;
    return Colors.cyanAccent;
  }

  String _formatCountdown(int seconds) {
    if (seconds <= 0) return '00:00:00';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  Future<void> _handleMarkComplete(BuildContext context, PlayerProvider player) async {
    final elapsedMinutes = DateTime.now().toUtc().difference(_dungeonStartTime!).inMinutes;
    await _executeCompletion(context, player, elapsedMinutes);
  }

  Future<void> _autoComplete(BuildContext context, PlayerProvider player) async {
    await _executeCompletion(context, player, 240); // 4 full hours
  }

  Future<void> _executeCompletion(BuildContext context, PlayerProvider player, int minutes) async {
    setState(() => _isProcessing = true);
    _countdownTimer?.cancel();
    try {
      await engine.completeDungeon(context);

      int totalBaseXP = 240;

      if (player.insightActive) {
        player.consumeInsight();
        SystemOverlay.show(
          context,
          title: "ABILITY TRIGGERED",
          message: "Tactical Insight Applied",
        );
      }

      player.addXP(totalBaseXP);
      player.setDailyQuestCleared();
      HiveService.settings.put('dungeonStartTime', '');

      SystemOverlay.show(
        context,
        title: "DUNGEON CLEAR",
        message: minutes >= 240 
            ? "DUNGEON AUTO-CLEARED\n+$totalBaseXP XP" 
            : "Success\n+$totalBaseXP XP",
        playerName: player.name,
      );
      XPFloatingText.show(context, amount: totalBaseXP);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _dungeonStartTime = null;
        });
      }
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        "NO ACTIVE GATE DETECTED",
        style: TextStyle(
          color: Colors.white24,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class StudyTimerCard extends StatefulWidget {
  const StudyTimerCard({super.key});

  @override
  State<StudyTimerCard> createState() => _StudyTimerCardState();
}

class _StudyTimerCardState extends State<StudyTimerCard> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isActive = false;
  static const int _totalSeconds = 5400; // 90 minutes
  
  // Hive keys
  static const String _timerStartKey = 'studyTimerStartISO';
  static const String _timerElapsedKey = 'studyTimerElapsedSecs';
  static const String _timerActiveKey = 'studyTimerActive';

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadState() {
    final settings = HiveService.settings;
    _isActive = settings.get(_timerActiveKey, defaultValue: false);
    _elapsedSeconds = settings.get(_timerElapsedKey, defaultValue: 0);
    
    if (_isActive) {
      final startIso = settings.get(_timerStartKey, defaultValue: '');
      if (startIso.isNotEmpty) {
        final startTime = DateTime.tryParse(startIso);
        if (startTime != null) {
          final now = DateTime.now().toUtc();
          final diff = now.difference(startTime).inSeconds;
          _elapsedSeconds += diff;
          // Update the start time to now so we can continue tracking easily
          settings.put(_timerStartKey, now.toIso8601String());
          settings.put(_timerElapsedKey, _elapsedSeconds);
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
    final startIso = HiveService.settings.get(_timerStartKey, defaultValue: '');
    if (startIso.isEmpty) return _elapsedSeconds;
    final startTime = DateTime.tryParse(startIso);
    if (startTime == null) return _elapsedSeconds;
    return _elapsedSeconds + DateTime.now().toUtc().difference(startTime).inSeconds;
  }

  void _toggleTimer() {
    final settings = HiveService.settings;
    setState(() {
      if (_isActive) {
        // Pause
        _isActive = false;
        _timer?.cancel();
        _elapsedSeconds = _currentElapsed;
        settings.put(_timerActiveKey, false);
        settings.put(_timerElapsedKey, _elapsedSeconds);
        settings.put(_timerStartKey, '');
      } else {
        // Start/Resume
        _isActive = true;
        final now = DateTime.now().toUtc();
        settings.put(_timerActiveKey, true);
        settings.put(_timerStartKey, now.toIso8601String());
        _startInternalTimer(now);
      }
    });
  }

  void _finishEarly() {
    final elapsedTotal = _currentElapsed;
    if (elapsedTotal < 60) {
      // Less than 1 minute, don't count it
       _resetTimerData();
       setState(() {
         _elapsedSeconds = 0;
         _isActive = false;
       });
       return;
    }
    
    _processCompletion(elapsedTotal ~/ 60);
  }

  void _autoComplete() {
    _processCompletion(_totalSeconds ~/ 60);
  }

  void _processCompletion(int minutes) {
    _timer?.cancel();
    _resetTimerData();

    setState(() {
      _isActive = false;
      _elapsedSeconds = 0;
    });

    final player = Provider.of<PlayerProvider>(context, listen: false);
    player.addStudyXP(minutes);

    SystemOverlay.show(
      context,
      title: "SESSION COMPLETE",
      message: "Study Duration: $minutes MIN\nFocus Session Logged.",
      playerName: player.name,
    );
  }
  
  void _resetTimerData() {
    final settings = HiveService.settings;
    settings.put(_timerActiveKey, false);
    settings.put(_timerStartKey, '');
    settings.put(_timerElapsedKey, 0);
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
    if (sessionsCount == 1) effText = "EFFICIENCY: 50% [+5XP/MIN]";
    else if (sessionsCount >= 2) effText = "EFFICIENCY: 25% [+2.5XP/MIN]";

    int currentSecs = _currentElapsed;
    if (currentSecs > _totalSeconds) currentSecs = _totalSeconds;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border.all(
          color: Colors.blueAccent.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.4),
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
                "FOCUS TRAINING",
                style: TextStyle(
                  color: Colors.blueAccent.withOpacity(0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              const Icon(Icons.psychology, color: Colors.blueAccent, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "COGNITIVE ASCENSION",
            style: TextStyle(
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
                      backgroundColor: Colors.blueAccent.withOpacity(0.1),
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
                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                      side: const BorderSide(color: Colors.redAccent, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1)),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      elevation: 0,
                    ),
                    child: Transform(
                      transform: Matrix4.skewX(0.15),
                      child: const Icon(Icons.stop, color: Colors.redAccent, size: 20),
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