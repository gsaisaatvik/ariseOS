import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'models/core_quest.dart';
import 'services/hive_service.dart';
import 'engine/core_engine.dart';
import 'engine/dynamic_engine.dart';
import 'player_provider.dart';
import 'widgets/system_overlay.dart';
import 'widgets/xp_floating_text.dart';
import 'ui/widgets/widgets.dart';
import 'ui/theme/app_text_styles.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int? _lastLevel;
  String? _lastRank;
  bool? _lastPenalty;
  bool _isProcessing = false;

  Timer? _midnightTimer;
  Duration _timeLeft = Duration.zero;
  DateTime _nextMidnight = DateTime.now();

  @override
  void initState() {
    super.initState();
    final coreBox = HiveService.coreQuests;
    final settings = HiveService.settings;
    final engine = CoreEngine(coreBox, settings);
    engine.checkAndEvaluateNewDay();

    final dynamicEngine = DynamicEngine();
    dynamicEngine.assignTodayDungeon();

    _nextMidnight = _getNextMidnight();
    _startMidnightTimer();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(_pulseController);
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  DateTime _getNextMidnight() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  void _startMidnightTimer() {
    _midnightTimer?.cancel();
    _updateTimeLeft();
    _midnightTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      final now = DateTime.now();
      if (now.isAfter(_nextMidnight)) {
        _nextMidnight = _getNextMidnight();
      }
      
      _updateTimeLeft();
    });
  }

  void _updateTimeLeft() {
    setState(() {
      _timeLeft = _nextMidnight.difference(DateTime.now());
      if (_timeLeft.isNegative) {
        _timeLeft = Duration.zero;
      }
    });
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = (d.inMinutes % 60);
    final s = (d.inSeconds % 60);
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _checkTriggers(
      BuildContext context, int level, String rank, bool penalty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final player = Provider.of<PlayerProvider>(context, listen: false);
      
      if (_lastLevel != null && level > _lastLevel!) {
        SystemOverlay.show(
          context,
          title: "SYSTEM EVOLUTION",
          message: "Level Up\nLevel $level",
          playerName: player.name,
        );
      }
      if (_lastRank != null && rank != _lastRank) {
        SystemOverlay.show(
          context,
          title: "RANK ADVANCEMENT",
          message: "New Rank Obtained\n$rank Rank",
          playerName: player.name,
        );
      }
      if (_lastPenalty != null && penalty && !_lastPenalty!) {
        if (player.ironActive) {
          final settings = HiveService.settings;
          final coreBox = HiveService.coreQuests;
          final engine = CoreEngine(coreBox, settings);
          engine.clearPenalty();
          player.consumeIron(); 
          
          SystemOverlay.show(
            context,
            title: "IRON RESOLVE",
            message: "Penalty Blocked\nAbility Expended",
            playerName: player.name,
          );
        } else {
          SystemOverlay.show(
            context,
            title: "SYSTEM PENALTY",
            message: "Penalty Activated\nTraining Failure",
            playerName: player.name,
          );
        }
      }

      _checkNewUnlocks(context, player);

      _lastLevel = level;
      _lastRank = rank;
      _lastPenalty = penalty;
    });
  }

  void _checkNewUnlocks(BuildContext context, PlayerProvider player) {
    if (player.flowUnlocked && !player.hasNotifiedFlow) {
      _showUnlock(context, "FLOW STATE", player);
      player.setNotified("FLOW STATE");
    }
    if (player.enduranceUnlocked && !player.hasNotifiedEndurance) {
      _showUnlock(context, "ENDURANCE BURST", player);
      player.setNotified("ENDURANCE BURST");
    }
    if (player.insightUnlocked && !player.hasNotifiedInsight) {
      _showUnlock(context, "TACTICAL INSIGHT", player);
      player.setNotified("TACTICAL INSIGHT");
    }
    if (player.ironUnlocked && !player.hasNotifiedIron) {
      _showUnlock(context, "IRON RESOLVE", player);
      player.setNotified("IRON RESOLVE");
    }
  }

  void _showUnlock(BuildContext context, String name, PlayerProvider player) {
    SystemOverlay.show(
      context,
      title: "NEW ABILITY UNLOCKED",
      message: name,
      playerName: player.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final coreBox = HiveService.coreQuests;
    final settings = HiveService.settings;

    return ValueListenableBuilder(
      valueListenable: coreBox.listenable(),
      builder: (context, Box<CoreQuest> box, _) {
        final engine = CoreEngine(box, settings);
        final player = Provider.of<PlayerProvider>(context);

        // Update Triggers
        _checkTriggers(
            context, player.level, player.rank, engine.penaltyActive);

        bool allCleared = box.values.isNotEmpty && box.values.every((q) => q.completed);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              HolographicPanel(
                header: const SystemHeaderBar(label: 'QUEST INFO'),
                emphasize: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(player, engine.streak),
                    const SizedBox(height: 16),
                    Text(
                      'Primary directives must be cleared before midnight.',
                      style: AppTextStyles.bodySecondary,
                    ),
                    const SizedBox(height: 16),
                    _buildCountdownTracker(allCleared),
                  ],
                ),
              ),
              HolographicPanel(
                header: const SystemHeaderBar(label: 'PRIMARY DIRECTIVES'),
                child: Column(
                  children: [
                    ...box.values.map(
                      (quest) =>
                          _buildQuestCard(quest, player, engine, context),
                    ),
                  ],
                ),
              ),
              HolographicPanel(
                header: const SystemHeaderBar(label: 'SYSTEM STATUS'),
                child:
                    _buildFooter(player, engine.penaltyActive, engine.streak),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCountdownTracker(bool allCleared) {
    if (allCleared) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.cyanAccent.withOpacity(0.1),
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
        ),
        child: Column(
          children: const [
            Text(
              "[DIRECTIVES CLEARED]",
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "AWAITING NEXT CYCLE",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      );
    } else {
      double progress = _timeLeft.inSeconds / 86400.0;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.05),
          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.timer, color: Colors.redAccent, size: 16),
                const SizedBox(width: 8),
                const Text(
                  "TIME REMAINING:",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      _formatDuration(_timeLeft),
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation(Colors.redAccent),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "[FAILURE RESULTS IN PENALTY]",
              style: TextStyle(
                color: Colors.redAccent.withOpacity(0.7),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildHeader(PlayerProvider player, int streak) {
    // Calculate Day Count
    if (player.awakeningDate.isNotEmpty) {
      try {
        DateTime.parse(player.awakeningDate);
      } catch (_) {}
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "HUNTER PROFILE",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      "DAILY DIRECTIVE",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _buildRankBadge(player.rank),
          ],
        ),
        const SizedBox(height: 16),
        _buildWeeklyStreakRow(player.streakDays),
        const SizedBox(height: 12),
        if (player.isRestricted)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '[STATUS: DEBT ACTIVE — WALLET ${player.walletXP} XP]',
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        const SizedBox(height: 16),
        Container(
          height: 1,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.cyanAccent.withOpacity(0.5),
                Colors.cyanAccent.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankBadge(String rank) {
    Color rankColor;
    switch (rank) {
      case 'S': rankColor = Colors.purpleAccent; break;
      case 'A': rankColor = Colors.redAccent; break;
      case 'B': rankColor = Colors.orangeAccent; break;
      case 'C': rankColor = Colors.greenAccent; break;
      case 'D': rankColor = Colors.cyanAccent; break;
      default: rankColor = Colors.grey;
    }

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: rankColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: rankColor.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          rank,
          style: TextStyle(
            color: rankColor,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildQuestCard(CoreQuest quest, PlayerProvider player,
      CoreEngine engine, BuildContext context) {
    final bool isCompleted = quest.completed;
    
    // Potential XP (Base + Current Bonuses)
    int baseXP = 10;
    int displayXP = baseXP;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isCompleted 
              ? Colors.white10 
              : Colors.cyanAccent.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: isCompleted ? [] : [
          BoxShadow(
            color: const Color(0xFF00E5FF).withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    quest.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCompleted ? Colors.white24 : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    "+$displayXP XP",
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCompleted ? Colors.white10 : Colors.amberAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCompleted ? "STATE: CLEARED" : "STATE: PENDING",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isCompleted ? Colors.greenAccent : Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (!isCompleted)
                  Flexible(
                    child: Transform(
                      transform: Matrix4.skewX(-0.15),
                      child: SizedBox(
                        height: 28,
                        child: ElevatedButton(
                          onPressed: _isProcessing
                              ? null
                              : () => _handleComplete(quest, player, engine, context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent.withOpacity(0.1),
                            side: const BorderSide(color: Colors.cyanAccent, width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(1),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: Transform(
                            transform: Matrix4.skewX(0.15),
                            child: const Text(
                              "EXECUTE",
                              style: TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.check_circle_outline, color: Colors.white10, size: 20),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleComplete(CoreQuest quest, PlayerProvider player,
      CoreEngine engine, BuildContext context) async {
    setState(() => _isProcessing = true);
    try {
      await engine.completeQuest(quest);

      int baseXP = 10;
      int abilityBonus = 0;
      bool consumed = false;

      if (quest.id == 'deep_work' && player.flowActive) {
        abilityBonus += baseXP;
        player.consumeFlow();
        consumed = true;
      }

      if (quest.id == 'strength' && player.enduranceActive) {
        abilityBonus += 5;
        player.consumeEndurance();
        consumed = true;
      }

      if (consumed) {
        SystemOverlay.show(
          context,
          title: "ABILITY TRIGGERED",
          message: "Special Bonus Applied",
          playerName: player.name,
        );
      }

      int totalBaseXP = baseXP + abilityBonus;

      // V2.1: default to <60 min since core quests typically short — caller can't log time
      // Using addTimedXP with 30 min (1.0x) so daily cap logic still applies
      player.addTimedXP(totalBaseXP, 30);
      player.setDailyQuestCleared();

      XPFloatingText.show(context, amount: totalBaseXP);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Widget _buildFooter(PlayerProvider player, bool penaltyActive, int streak) {
    String activeAbility = "NONE";
    if (player.flowActive) activeAbility = "FLOW STATE";
    else if (player.enduranceActive) activeAbility = "ENDURANCE BURST";
    else if (player.insightActive) activeAbility = "TACTICAL INSIGHT";
    else if (player.ironActive) activeAbility = "IRON RESOLVE";

    bool showStats = activeAbility != "NONE" || player.availablePoints > 0;

    return Container(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Column(
        children: [
          Container(
            height: 1,
            width: double.infinity,
            color: Colors.white.withOpacity(0.05),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _footerItem('WALLET', '${player.walletXP} XP',
                    player.isRestricted ? Colors.redAccent : Colors.amberAccent),
              ),
              Expanded(
                child: _footerItem('MISSES',
                    '${player.consecutiveMisses}/3',
                    player.consecutiveMisses > 0 ? Colors.redAccent : Colors.white24),
              ),
              Expanded(
                child: _footerItem('RANK STATUS',
                    penaltyActive ? 'PENALTY' : (player.isRestricted ? 'DEBT' : 'NORMAL'),
                    penaltyActive || player.isRestricted ? Colors.redAccent : Colors.cyanAccent),
              ),
            ],
          ),
          if (showStats) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _footerItem('ABILITY STATE', activeAbility,
                      activeAbility == 'NONE' ? Colors.white38 : Colors.purpleAccent),
                ),
                Expanded(
                  child: _footerItem('ATTR POINTS', '${player.availablePoints}', Colors.amberAccent),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _footerItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.2),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyStreakRow(int streakDays) {
    final now = DateTime.now();
    final todayWeekday = now.weekday; // 1 = Mon, 7 = Sun
    final days = ["M", "T", "W", "T", "F", "S", "S"];

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final dayIndex = index + 1;
          Color color;
          double opacity = 1.0;
          bool isToday = dayIndex == todayWeekday;
          
          // Mocking previous days based on total streak
          // If streakDays >= (today's distance from target day), mark green
          if (dayIndex < todayWeekday) {
             bool cleared = streakDays >= (todayWeekday - dayIndex);
             color = cleared ? Colors.greenAccent : Colors.redAccent;
          } else if (isToday) {
             color = Colors.cyanAccent;
          } else {
             color = Colors.white10;
             opacity = 0.3;
          }

          return Padding(
            padding: EdgeInsets.only(right: index == 6 ? 0 : 8),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isToday ? color.withOpacity(0.1 * _pulseAnimation.value) : color.withOpacity(0.1),
                        border: Border.all(
                          color: isToday ? color.withOpacity(_pulseAnimation.value) : color.withOpacity(opacity),
                          width: isToday ? 2 : 1,
                        ),
                        boxShadow: isToday ? [
                          BoxShadow(
                            color: color.withOpacity(0.3 * _pulseAnimation.value),
                            blurRadius: 8,
                          )
                        ] : [],
                      ),
                      child: Center(
                        child: Text(
                          days[index],
                          style: TextStyle(
                            color: color.withOpacity(isToday ? 1.0 : (dayIndex < todayWeekday ? 0.8 : 0.3)),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

