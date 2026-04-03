import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math' as math;
import 'services/hive_service.dart';
import 'system/directive_config.dart';
import 'system/attribute_effects.dart';
import 'system/level_up_event.dart';
import 'system/system_abilities.dart';
import 'system/adaptive_directive_engine.dart';
import 'system/rank_engine.dart';
import 'system/health_system.dart';
import 'system/xp_economy_engine.dart';
import 'system/skill_definitions.dart';
import 'models/physical_foundation.dart';
import 'models/monarch_rewards.dart';


// ============================================================
//  RANK CONSTANTS — V2.1 Three-Pillar Exponential Gate System
// ============================================================
class RankSystem {
  /// Rank is now separate from Level and uses a weighted hybrid engine.
  static String calcRank({
    required int lifetimeXP,
    required int streakDays,
    required int totalCompletions,
    required int totalFailures,
  }) {
    return RankEngine.computeRank(
      lifetimeXp: lifetimeXP,
      streakDays: streakDays,
      totalCompletions: totalCompletions,
      totalFailures: totalFailures,
    );
  }

  // What rank can access the Redemption Terminal?
  static bool canRedeem(String rank) => rank != 'E';

  // Which reward tier is unlocked?
  // 0 = nothing, 1 = minor only, 2 = full
  static int rewardTier(String rank) {
    if (rank == 'E') return 0;
    if (rank == 'D') return 1;
    return 2; // C, B, A, S, GOD
  }

  // Color hint per rank
  static String rankLabel(String rank) {
    switch (rank) {
      case 'GOD':
        return 'GOD';
      default:
        return rank;
    }
  }
}

class PlayerProvider extends ChangeNotifier {
  PlayerProvider() {
    _initialize();
  }

  // =========================
  // PLAYER CORE DATA
  // =========================

  String _name = '';
  int _level = 0;

  // ⚠️ DO NOT mutate directly. Use _internalAddXP() only.
  int _totalXP = 0; // Lifetime XP — never decremented by penalties

  // ⚠️ DO NOT mutate directly outside _internalAddXP / _applyWalletPenalty / _applyMaximumPenalty / spendXP / logSin.
  int _walletXP = 0; // Spendable XP — can go negative (debt)

  String _awakeningDate = '';

  // =========================
  // V2.1 STREAK & DAILY TRACKING
  // =========================
  int _streakDays = 0; // Consecutive days with quest cleared
  int _bestStreak = 0; // All-time best streak (never reset)
  int _consecutiveMisses = 0; // Days without any quest cleared
  bool _dailyQuestCleared = false; // Was today's quest cleared?
  int _dailyXPEarned = 0; // XP earned today (for daily cap)
  String _dailyXPDate = ''; // UTC date string for daily cap reset
  int _studySessionsToday = 0; // Number of study sessions completed today
  final List<String> _systemLogs = [];

  // Penalty log for UI
  final List<String> _penaltyLog = [];

  // ============================================================
  // Level-up moment system (full-screen dopamine anchor)
  // ============================================================
  final List<LevelUpEvent> _levelUpQueue = [];
  int _lastEnqueuedLevelTo = -1;

  // ============================================================
  // Midnight Timer for Monarch Integration
  // ============================================================
  Timer? _midnightTimer;

  // ============================================================
  // System Ability State (Phase 3)
  // ============================================================
  bool _focusBoostNext = false;
  bool _intelBurstNext = false;
  bool _disciplineShieldNext = false;
  bool _overrideNextStart = false;

  // Ability charges (V1 contract)
  int _focusBoostCharges = 0;
  int _intelBurstCharges = 0;
  int _disciplineShieldCharges = 0;
  int _overrideCharges = 0;
  String _abilitiesLastRefreshLocalDate = '';
  DateTime? _overrideLastUsedAtUtc;

  // Competitive directives (future-ready scaffold)
  bool _competitiveDirectivesEnabled = false;

  /// Single source for directive system lock (mirrors Hive `systemActiveDirectiveId`).
  String? _activeDirectiveId;

  // =========================
  // PENALTY CONSTANTS (Phase 1.5)
  // =========================
  static const int _maxSinglePenalty = 1500;
  static const int _walletFloor = -500; // V1 contract: floor at -500

  // =========================
  // STATS (PHASE 4 / MONARCH REBOOT)
  // =========================
  int _strength = 10;
  int _vitality = 10;
  int _agility = 10;
  int _intelligence = 10;
  int _perception = 10;
  int _availablePoints = 0;

  // Legacy field aliases for internal logic
  int get _discipline => _vitality;
  int get _focus => _agility;

  // Monarch stats (Internal state aliases) - Syncing with new stats
  int get _str => _strength;
  set _str(int v) => _strength = v;
  int get _int => _intelligence;
  set _int(int v) => _intelligence = v;
  int get _per => _perception;
  set _per(int v) => _perception = v;

  // =========================
  // MONARCH STATE FIELDS (ARISE OS Monarch Integration)
  // =========================
  // Monarch stats (Unified)
  // We use the fields above as source of truth.

  // Penalty Zone state
  bool _inPenaltyZone = false;
  DateTime? _penaltyActivatedAt;

  // Limiter Removal state
  bool _limiterRemovedToday = false;
  bool _overloadTitleAwarded = false;

  // Locked Mandatory Quests state
  int? _lockedCognitiveDurationMinutes;
  String? _lockedTechnicalTask;
  bool _cognitiveLocked = false;
  bool _technicalLocked = false;
  bool _cognitiveCompleted = false;
  bool _technicalCompleted = false;

  // Pending (tomorrow's) quest configuration
  int? _pendingCognitiveDurationMinutes;
  String? _pendingTechnicalTask;

  // =========================
  // HEALTH (PHASE 6)
  // =========================
  int _hp = HealthSystem.defaultMaxHp;
  int _maxHp = HealthSystem.defaultMaxHp;
  HealthZone _healthZone = HealthZone.stable;
  HealthZone? _lastHealthZoneNotified;
  String _lastHealthZoneNotifiedDate = '';
  bool _pendingAllocationReminder = false;

  // =========================
  // ACTIVE ABILITIES (PHASE 6)
  // =========================
  bool _flowUnlocked = false;
  bool _enduranceUnlocked = false;
  bool _insightUnlocked = false;
  bool _ironUnlocked = false;

  bool _flowUsedToday = false;
  bool _enduranceUsedToday = false;
  bool _insightUsedToday = false;
  bool _ironUsedThisWeek = false;

  bool _flowActive = false;
  bool _enduranceActive = false;
  bool _insightActive = false;
  bool _ironActive = false;

  // Notification Flags (Phase 8 Stability)
  bool _hasNotifiedFlow = false;
  bool _hasNotifiedEndurance = false;
  bool _hasNotifiedInsight = false;
  bool _hasNotifiedIron = false;

  // Legacy stats (kept for compatibility)
  final Map<String, int> _stats = {
    'HP': 100,
    'STR': 10,
    'AGI': 10,
    'VIT': 10,
    'INT': 10,
    'PER': 10,
  };

  final Map<String, int> _questProgress = {
    'Push-ups': 0,
    'Sit-ups': 0,
    'Squats': 0,
    'Running': 0,
  };

  // =========================
  // INITIAL LOAD
  // =========================

  void _initialize() {
    final settings = HiveService.settings;
    final monarchState = HiveService.monarchState;

    final rawXP = settings.get('lifetimeXP', defaultValue: 0);
    if (rawXP is int) {
      _totalXP = rawXP;
    } else if (rawXP is double) {
      _totalXP = rawXP.toInt();
    }

    _level = _calculateLevel(_totalXP);
    _walletXP = settings.get('walletXP', defaultValue: 0);
    if (_walletXP < _walletFloor) _walletXP = _walletFloor;

    _strength = settings.get('strength', defaultValue: 10);
    _vitality = settings.get('vitality', defaultValue: 10);
    _agility = settings.get('agility', defaultValue: 10);
    _intelligence = settings.get('intelligence', defaultValue: 10);
    _perception = settings.get('perception', defaultValue: 10);
    _availablePoints = settings.get('availablePoints', defaultValue: 0);

    // Synchronizing Monarch state fields
    _strength = _strength;
    _intelligence = _intelligence;
    _perception = _perception;
    _vitality = _vitality;
    _agility = _agility;

    _inPenaltyZone = monarchState.get('inPenaltyZone', defaultValue: false);
    final penaltyTimestampStr = monarchState.get('penaltyActivatedAt', defaultValue: '');
    if (penaltyTimestampStr is String && penaltyTimestampStr.isNotEmpty) {
      _penaltyActivatedAt = DateTime.tryParse(penaltyTimestampStr);
    }

    // Handle penalty zone state recovery and corrupted state
    if (_inPenaltyZone) {
      if (_penaltyActivatedAt == null) {
        // Corrupted state: inPenaltyZone=true but no timestamp
        _inPenaltyZone = false;
        monarchState.put('inPenaltyZone', false);
        monarchState.delete('penaltyActivatedAt');
        log('SYSTEM: WARNING - Corrupted penalty state detected. Penalty zone deactivated.');
      } else {
        // Check if 4 hours have elapsed
        final elapsed = DateTime.now().difference(_penaltyActivatedAt!);
        if (elapsed >= const Duration(hours: 4)) {
          // Auto-deactivate expired penalty zone
          _inPenaltyZone = false;
          monarchState.put('inPenaltyZone', false);
          monarchState.delete('penaltyActivatedAt');
          _penaltyActivatedAt = null;
          log('SYSTEM: Penalty zone expired. Full access restored.');
        }
      }
    }

    _limiterRemovedToday = monarchState.get('limiterRemovedToday', defaultValue: false);
    _overloadTitleAwarded = monarchState.get('overloadTitleAwarded', defaultValue: false);

    _lockedCognitiveDurationMinutes = monarchState.get('lockedCognitiveMins', defaultValue: null);
    _lockedTechnicalTask = monarchState.get('lockedTechnicalTask', defaultValue: null);
    _cognitiveLocked = monarchState.get('cognitiveLocked', defaultValue: false);
    _technicalLocked = monarchState.get('technicalLocked', defaultValue: false);
    _cognitiveCompleted = monarchState.get('cognitiveCompleted', defaultValue: false);
    _technicalCompleted = monarchState.get('technicalCompleted', defaultValue: false);

    _pendingCognitiveDurationMinutes = monarchState.get('pendingCognitiveMins', defaultValue: null);
    _pendingTechnicalTask = monarchState.get('pendingTechnicalTask', defaultValue: null);

    // Load physical progress from monarch_state
    _questProgress['Push-ups'] = monarchState.get('physProgress_pushups', defaultValue: 0);
    _questProgress['Sit-ups'] = monarchState.get('physProgress_situps', defaultValue: 0);
    _questProgress['Squats'] = monarchState.get('physProgress_squats', defaultValue: 0);
    _questProgress['Running'] = monarchState.get('physProgress_running', defaultValue: 0);

    _maxHp = settings.get('maxHp', defaultValue: HealthSystem.defaultMaxHp);
    _hp = settings.get('hp', defaultValue: _maxHp);
    _hp = _hp.clamp(0, _maxHp);
    _healthZone = HealthSystem.zoneFor(_hp, _maxHp);
    final rawZone =
        settings.get('lastHealthZoneNotified', defaultValue: '') as String;
    _lastHealthZoneNotified = _parseHealthZone(rawZone);
    _lastHealthZoneNotifiedDate = settings.get(
      'lastHealthZoneNotifiedDate',
      defaultValue: '',
    );
    _pendingAllocationReminder = settings.get(
      'pendingAllocationReminder',
      defaultValue: false,
    );

    _competitiveDirectivesEnabled = settings.get(
      'competitiveDirectivesEnabled',
      defaultValue: false,
    );

    _focusBoostCharges = settings.get(
      'ability_focusBoostCharges',
      defaultValue: 0,
    );
    _intelBurstCharges = settings.get(
      'ability_intelBurstCharges',
      defaultValue: 0,
    );
    _disciplineShieldCharges = settings.get(
      'ability_disciplineShieldCharges',
      defaultValue: 0,
    );
    _overrideCharges = settings.get('ability_overrideCharges', defaultValue: 0);
    _abilitiesLastRefreshLocalDate = settings.get(
      'ability_lastRefreshLocalDate',
      defaultValue: '',
    );
    final rawOverrideTs = settings.get(
      'ability_overrideLastUsedAtUtc',
      defaultValue: '',
    );
    if (rawOverrideTs is String && rawOverrideTs.isNotEmpty) {
      _overrideLastUsedAtUtc = DateTime.tryParse(rawOverrideTs);
    }

    _flowUnlocked = settings.get('flowUnlocked', defaultValue: false);
    _enduranceUnlocked = settings.get('enduranceUnlocked', defaultValue: false);
    _insightUnlocked = settings.get('insightUnlocked', defaultValue: false);
    _ironUnlocked = settings.get('ironUnlocked', defaultValue: false);

    _flowUsedToday = settings.get('flowUsedToday', defaultValue: false);
    _enduranceUsedToday = settings.get(
      'enduranceUsedToday',
      defaultValue: false,
    );
    _insightUsedToday = settings.get('insightUsedToday', defaultValue: false);
    _ironUsedThisWeek = settings.get('ironUsedThisWeek', defaultValue: false);

    _flowActive = settings.get('flowActive', defaultValue: false);
    _enduranceActive = settings.get('enduranceActive', defaultValue: false);
    _insightActive = settings.get('insightActive', defaultValue: false);
    _ironActive = settings.get('ironActive', defaultValue: false);

    _hasNotifiedFlow = settings.get('hasNotifiedFlow', defaultValue: false);
    _hasNotifiedEndurance = settings.get(
      'hasNotifiedEndurance',
      defaultValue: false,
    );
    _hasNotifiedInsight = settings.get(
      'hasNotifiedInsight',
      defaultValue: false,
    );
    _hasNotifiedIron = settings.get('hasNotifiedIron', defaultValue: false);

    _name = settings.get('playerName', defaultValue: 'Player');
    _awakeningDate = settings.get('awakeningDate', defaultValue: '');

    // V2.1 streak & daily fields
    _streakDays = settings.get('streakDays', defaultValue: 0);
    _bestStreak = settings.get('bestStreak', defaultValue: 0);
    _consecutiveMisses = settings.get('consecutiveMisses', defaultValue: 0);
    _dailyQuestCleared = settings.get('dailyQuestCleared', defaultValue: false);
    _dailyXPEarned = settings.get('dailyXPEarned', defaultValue: 0);
    _dailyXPDate = settings.get('dailyXPDate', defaultValue: '');
    _studySessionsToday = settings.get('studySessionsToday', defaultValue: 0);

    _syncActiveDirectiveOnInit();

    _checkResets();
    
    // Schedule midnight timer for Monarch Integration
    _scheduleMidnightTimer();
    
    notifyListeners();
  }

  String? get activeDirectiveId => _activeDirectiveId;

  void _syncActiveDirectiveOnInit() {
    final box = HiveService.settings;
    final stored = box.get(DirectiveConfig.hiveLockKey, defaultValue: '');
    if (stored is String && stored.isNotEmpty) {
      _activeDirectiveId = stored;
      return;
    }
    for (final id in const ['strength', 'deep_work', 'skill']) {
      final prefix = 'directive_$id';
      final active = box.get('${prefix}TimerActive', defaultValue: false);
      final raw = box.get('${prefix}TimerElapsedSecs', defaultValue: 0);
      final elapsed = raw is int ? raw : (raw as num).toInt();
      if (active == true || elapsed > 0) {
        _activeDirectiveId = id;
        box.put(DirectiveConfig.hiveLockKey, id);
        return;
      }
    }
    _activeDirectiveId = null;
  }

  void setActiveDirective(String? id) {
    final normalized = (id == null || id.isEmpty) ? null : id;
    _activeDirectiveId = normalized;
    HiveService.settings.put(DirectiveConfig.hiveLockKey, normalized ?? '');
    notifyListeners();
  }

  Future<void> forceClearActiveDirectiveLock() async {
    _activeDirectiveId = null;
    await HiveService.clearActiveDirective();
    notifyListeners();
  }

  // =========================
  // MIDNIGHT TIMER SCHEDULING (Monarch Integration)
  // =========================

  void _scheduleMidnightTimer() {
    // Cancel any existing timer
    _midnightTimer?.cancel();

    // Calculate time until next midnight (local time)
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = tomorrow.difference(now);

    // Schedule timer to fire at midnight
    _midnightTimer = Timer(durationUntilMidnight, () {
      _onMidnightReached();
      // Reschedule for next midnight
      _scheduleMidnightTimer();
    });
  }

  void _onMidnightReached() {
    // This will be called by the midnight timer
    // CoreEngine.runMidnightJudgement will be implemented in task 4.1
    // For now, just log that midnight was reached
    log('SYSTEM: Midnight reached. Midnight Judgement scheduled.');
  }

  // =========================
  // DAILY / WEEKLY RESETS (Phase 1.5 — Multi-day aware)
  // =========================

  void _checkResets() {
    final settings = HiveService.settings;
    final now = DateTime.now().toUtc();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final lastResetStr = settings.get('lastDailyReset', defaultValue: '');

    int daysMissed = 0;

    if (lastResetStr != '') {
      try {
        final lastDate = DateTime.parse(lastResetStr);
        daysMissed = DateTime(now.year, now.month, now.day)
            .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
            .inDays;
      } catch (_) {
        daysMissed = 1; // Fallback: treat as 1 new day
      }
    } else {
      // First launch — initialize system baseline
      daysMissed = 0;

      // 🔥 FIX 1: CRITICAL FIX — write lastDailyReset so day 2 can be detected
      settings.put('lastDailyReset', now.toIso8601String());

      // Also initialize daily flags safely
      settings.put('dailyQuestCleared', false);
    }

    if (daysMissed > 0) {
      int totalMissesToApply = 0;
      bool walletChanged = false;

      // 1. Evaluate the Origin Day
      if (_dailyQuestCleared) {
        _streakDays++;
        if (_streakDays > _bestStreak) {
          _bestStreak = _streakDays;
          settings.put('bestStreak', _bestStreak);
        }
        _consecutiveMisses = 0;
        log('SYSTEM: STREAK EXTENDED. DAY $_streakDays.');

        // Origin day was success — we only owe misses for the gap
        totalMissesToApply = math.max(0, daysMissed - 1);
      } else {
        // Origin day was failure — gap days + origin day are misses
        totalMissesToApply = daysMissed;
      }

      // 2. Enforce the Max 3 Penalty Rule
      int cappedMisses = math.min(totalMissesToApply, 3);

      // 3. Unified Penalty Loop
      for (int i = 0; i < cappedMisses; i++) {
        int previousStreak = _streakDays;
        _consecutiveMisses++;
        _streakDays = 0;

        _penaltyLog.add('MISS #$_consecutiveMisses');

        if (_consecutiveMisses == 1) {
          log('SYSTEM: STREAK BROKEN. MISS #$_consecutiveMisses.');
        }

        if (_consecutiveMisses >= 3) {
          _applyMaximumPenalty();
          _applyHpLoss(HealthSystem.lossOnMiss, 'MAX MISS');
          walletChanged = true;
          log(
            'SYSTEM: PURGE_PROTOCOL_INITIATED. $_consecutiveMisses CONSECUTIVE MISSES.',
          );
          break; // Stop processing further misses
        } else if (_consecutiveMisses == 2) {
          _applyWalletPenalty(3000, 'CONSECUTIVE MISS PENALTY (DAY 2)');
          _applyHpLoss(HealthSystem.lossOnMiss, 'MISS');
          walletChanged = true;
        } else {
          // First Miss (with Grace Period logic)
          int penalty = 1200;
          String reason = 'MISSED DAILY QUEST PENALTY';

          int lastMissMonth = settings.get('lastMissMonth', defaultValue: -1);
          if (lastMissMonth != now.month) {
            settings.put('lastMissMonth', now.month);
            if (previousStreak >= 10) {
              penalty = 600;
              reason = 'GRACE PERIOD WARNING (STREAK 10+)';
            }
          }

          _applyWalletPenalty(penalty, reason);
          _applyHpLoss(HealthSystem.lossOnMiss, 'MISS');
          walletChanged = true;
        }

        // V1 contract: wallet floor is fixed; no compounding debt interest.
      }

      // -- Reset daily flags --
      _dailyQuestCleared = false;
      _dailyXPEarned = 0;
      _dailyXPDate = todayStr;
      _studySessionsToday = 0;
      _flowUsedToday = false;
      _enduranceUsedToday = false;
      _insightUsedToday = false;

      // -- Ability lockout if restricted --
      if (_walletXP < 0) {
        _flowActive = false;
        _enduranceActive = false;
        _insightActive = false;
        _ironActive = false;
        settings.put('flowActive', false);
        settings.put('enduranceActive', false);
        settings.put('insightActive', false);
        settings.put('ironActive', false);
      }

      settings.put('dailyQuestCleared', false);
      settings.put('dailyXPEarned', 0);
      settings.put('dailyXPDate', todayStr);
      settings.put('studySessionsToday', 0);
      settings.put('streakDays', _streakDays);
      settings.put('bestStreak', _bestStreak);
      settings.put('consecutiveMisses', _consecutiveMisses);
      settings.put('flowUsedToday', false);
      settings.put('enduranceUsedToday', false);
      settings.put('insightUsedToday', false);
      settings.put('lastDailyReset', now.toIso8601String());

      // Ensure UI reflects penalties applied during reset processing.
      if (walletChanged) notifyListeners();
    } else {
      // Same day — sync daily XP cap date
      if (_dailyXPDate != todayStr) {
        _dailyXPEarned = 0;
        _dailyXPDate = todayStr;
        _studySessionsToday = 0;
        settings.put('dailyXPEarned', 0);
        settings.put('dailyXPDate', todayStr);
        settings.put('studySessionsToday', 0);
      }
    }

    // Weekly Reset (Monday start)
    int currentWeek = _getWeekOfYear(now);
    int lastWeek = settings.get('lastWeeklyResetWeek', defaultValue: -1);
    if (currentWeek > lastWeek ||
        (now.year >
            settings.get('lastWeeklyResetYear', defaultValue: now.year))) {
      _ironUsedThisWeek = false;
      settings.put('ironUsedThisWeek', false);
      settings.put('lastWeeklyResetWeek', currentWeek);
      settings.put('lastWeeklyResetYear', now.year);
    }
  }

  int _getWeekOfYear(DateTime date) {
    final dayOfYear = int.parse(
      math.max(1, date.difference(DateTime(date.year, 1, 1)).inDays).toString(),
    );
    return (dayOfYear / 7).ceil();
  }

  int _calculateLevel(int xp) {
    return (math.sqrt(xp.toDouble()) / 10).floor() + 1;
  }

  /// Public static method for testability.
  /// Calculates level using the formula: Level = floor(sqrt(LifetimeXP) / 10) + 1
  static int calculateLevel(int lifetimeXP) {
    return (math.sqrt(lifetimeXP.toDouble()) / 10).floor() + 1;
  }

  // =========================
  // GETTERS
  // =========================

  String get name => _name;
  String get awakeningDate => _awakeningDate;
  int get level => _level;
  int get totalXP => _totalXP;
  int get lifetimeXP => _totalXP; // Unified getter
  int get walletXP => _walletXP;
  static int get walletFloor => _walletFloor;
  int get streakDays => _streakDays;
  int get bestStreak => _bestStreak;
  int get consecutiveMisses => _consecutiveMisses;
  int get studySessionsToday => _studySessionsToday;
  bool get dailyQuestCleared => _dailyQuestCleared;
  bool get isRestricted => _walletXP < 0;
  List<String> get systemLogs => List.unmodifiable(_systemLogs);
  List<String> get penaltyLog => List.unmodifiable(_penaltyLog);

  int get Strength => _strength;
  int get strength => _strength; // Lowercase alias
  int get Vitality => _vitality;
  int get vitality => _vitality;
  int get Agility => _agility;
  int get agility => _agility;
  int get Intelligence => _intelligence;
  int get intelligence => _intelligence; // Lowercase alias
  int get Perception => _perception;
  int get perception => _perception;
  int get availablePoints => _availablePoints;
  // Focus and Discipline mapped for compatibility
  int get focus => _agility;
  int get discipline => _vitality;

  // Method Aliases for backward compatibility
  void increaseFocus() => increaseAgility();
  void increaseDiscipline() => increaseVitality();
  // increaseIntelligence is already defined
  bool get pendingAllocationReminder => _pendingAllocationReminder;
  int get hp => _hp;
  int get maxHp => _maxHp;
  HealthZone get healthZone => _healthZone;

  // Monarch stats (Unified)
  int get str => _strength;
  int get intStat => _intelligence;
  int get per => _perception;
  int get vit => _vitality;
  int get agi => _agility;

  // Penalty Zone state
  bool get inPenaltyZone => _inPenaltyZone;
  DateTime? get penaltyActivatedAt => _penaltyActivatedAt;
  Duration? get penaltyRemainingDuration {
    if (!_inPenaltyZone || _penaltyActivatedAt == null) return null;
    final elapsed = DateTime.now().difference(_penaltyActivatedAt!);
    final remaining = const Duration(hours: 4) - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  // Limiter Removal state
  bool get limiterRemovedToday => _limiterRemovedToday;
  bool get overloadTitleAwarded => _overloadTitleAwarded;

  // Locked Mandatory Quests state
  int? get lockedCognitiveDurationMinutes => _lockedCognitiveDurationMinutes;
  String? get lockedTechnicalTask => _lockedTechnicalTask;
  bool get cognitiveLocked => _cognitiveLocked;
  bool get technicalLocked => _technicalLocked;
  bool get cognitiveCompleted => _cognitiveCompleted;
  bool get technicalCompleted => _technicalCompleted;

  // Pending quest configuration
  int? get pendingCognitiveDurationMinutes => _pendingCognitiveDurationMinutes;
  String? get pendingTechnicalTask => _pendingTechnicalTask;

  double get healthRewardMultiplier =>
      HealthSystem.rewardMultiplier(_healthZone);
  double get healthPenaltyMultiplier =>
      HealthSystem.penaltyMultiplier(_healthZone);

  // ── SKILL SYSTEM GETTERS ──────────────────────────────────────────────────

  /// All skills currently unlocked for the player's level.
  List<SkillDefinition> get activeSkills => SkillEngine.activeSkills(_level);

  /// Applies the best-per-family XP modifier to [rawXp] for a [sessionMinutes]
  /// long session. Returns adjusted XP. Uses [SkillEngine.applyXpModifiers].
  int applySkillXpModifiers(int rawXp, int sessionMinutes) {
    return SkillEngine.applyXpModifiers(
      rawXp: rawXp,
      minutes: sessionMinutes,
      level: _level,
    );
  }

  /// Penalty multiplier from active penalty skills.
  /// < 1.0 = reduction, > 1.0 = amplification, 1.0 = no active skill.
  double get skillPenaltyMultiplier => SkillEngine.penaltyMultiplier(_level);

  // Physical stats
  /// 🔥 QUEST UI FRIENDLY GETTERS
  int get pushUps => _questProgress['Push-ups'] ?? 0;
  int get sitUps => _questProgress['Sit-ups'] ?? 0;
  int get squatsCount => _questProgress['Squats'] ?? 0;
  int get running => _questProgress['Running'] ?? 0;

  /// ✅ DAILY COMPLETION CHECK
  bool get isDailyPhysicalCompleted =>
      pushUps >= 100 &&
      sitUps >= 100 &&
      squatsCount >= 100 &&
      running >= 100;

  /// Next pending level-up moment to show (full-screen overlay).
  LevelUpEvent? get nextLevelUpEvent =>
      _levelUpQueue.isEmpty ? null : _levelUpQueue.first;

  // ----------------------------
  // Ability unlock / activation
  // ----------------------------
  bool isSystemAbilityUnlocked(SystemAbilityId id) {
    final def = systemAbilities[id]!;
    return _level >= def.unlockLevel;
  }

  int chargesFor(SystemAbilityId id) {
    return switch (id) {
      SystemAbilityId.focusBoost => _focusBoostCharges,
      SystemAbilityId.intelBurst => _intelBurstCharges,
      SystemAbilityId.disciplineShield => _disciplineShieldCharges,
      SystemAbilityId.overrideNextDirective => _overrideCharges,
    };
  }

  bool get overrideOnCooldown {
    final last = _overrideLastUsedAtUtc;
    if (last == null) return false;
    return DateTime.now().toUtc().difference(last) < const Duration(hours: 72);
  }

  bool get isFocusBoostNextActive => _focusBoostNext;
  bool get isIntelBurstNextActive => _intelBurstNext;
  bool get isDisciplineShieldNextActive => _disciplineShieldNext;
  bool get isOverrideNextStartActive => _overrideNextStart;
  bool get competitiveDirectivesEnabled => _competitiveDirectivesEnabled;

  void setCompetitiveDirectivesEnabled(bool enabled) {
    _competitiveDirectivesEnabled = enabled;
    HiveService.settings.put('competitiveDirectivesEnabled', enabled);
    notifyListeners();
  }

  void activateSystemAbility(SystemAbilityId id) {
    if (!isSystemAbilityUnlocked(id)) return;
    if (chargesFor(id) <= 0) return;
    if (id == SystemAbilityId.overrideNextDirective && overrideOnCooldown) {
      return;
    }
    switch (id) {
      case SystemAbilityId.focusBoost:
        _focusBoostNext = true;
        _focusBoostCharges--;
        HiveService.settings.put(
          'ability_focusBoostCharges',
          _focusBoostCharges,
        );
        break;
      case SystemAbilityId.intelBurst:
        _intelBurstNext = true;
        _intelBurstCharges--;
        HiveService.settings.put(
          'ability_intelBurstCharges',
          _intelBurstCharges,
        );
        break;
      case SystemAbilityId.disciplineShield:
        _disciplineShieldNext = true;
        _disciplineShieldCharges--;
        HiveService.settings.put(
          'ability_disciplineShieldCharges',
          _disciplineShieldCharges,
        );
        break;
      case SystemAbilityId.overrideNextDirective:
        _overrideNextStart = true;
        _overrideCharges--;
        _overrideLastUsedAtUtc = DateTime.now().toUtc();
        HiveService.settings.put('ability_overrideCharges', _overrideCharges);
        HiveService.settings.put(
          'ability_overrideLastUsedAtUtc',
          _overrideLastUsedAtUtc!.toIso8601String(),
        );
        break;
    }
    notifyListeners();
  }

  bool consumeFocusBoostNextIfActive() {
    if (!_focusBoostNext) return false;
    _focusBoostNext = false;
    notifyListeners();
    return true;
  }

  bool consumeIntelBurstNextIfActive() {
    if (!_intelBurstNext) return false;
    _intelBurstNext = false;
    notifyListeners();
    return true;
  }

  bool consumeDisciplineShieldNextIfActive() {
    if (!_disciplineShieldNext) return false;
    _disciplineShieldNext = false;
    notifyListeners();
    return true;
  }

  bool consumeOverrideNextStartIfActive() {
    if (!_overrideNextStart) return false;
    _overrideNextStart = false;
    notifyListeners();
    return true;
  }

  void refreshAbilityChargesIfDue() {
    // Local-midnight refresh (V1 contract).
    final nowLocal = DateTime.now();
    final dateStr =
        '${nowLocal.year}-${nowLocal.month.toString().padLeft(2, '0')}-${nowLocal.day.toString().padLeft(2, '0')}';
    if (_abilitiesLastRefreshLocalDate == dateStr) return;
    _abilitiesLastRefreshLocalDate = dateStr;
    HiveService.settings.put('ability_lastRefreshLocalDate', dateStr);

    // Basic abilities refresh daily.
    _focusBoostCharges = 1;
    _intelBurstCharges = 1;
    _disciplineShieldCharges = 1;
    HiveService.settings.put('ability_focusBoostCharges', _focusBoostCharges);
    HiveService.settings.put('ability_intelBurstCharges', _intelBurstCharges);
    HiveService.settings.put(
      'ability_disciplineShieldCharges',
      _disciplineShieldCharges,
    );

    // Override is rare: refresh only if cooldown elapsed.
    if (!overrideOnCooldown) {
      _overrideCharges = 1;
      HiveService.settings.put('ability_overrideCharges', _overrideCharges);
    }

    notifyListeners();
  }

  bool get flowUnlocked => _flowUnlocked;
  bool get enduranceUnlocked => _enduranceUnlocked;
  bool get insightUnlocked => _insightUnlocked;
  bool get ironUnlocked => _ironUnlocked;

  bool get flowUsedToday => _flowUsedToday;
  bool get enduranceUsedToday => _enduranceUsedToday;
  bool get insightUsedToday => _insightUsedToday;
  bool get ironUsedThisWeek => _ironUsedThisWeek;

  bool get flowActive => _flowActive;
  bool get enduranceActive => _enduranceActive;
  bool get insightActive => _insightActive;
  bool get ironActive => _ironActive;

  bool get hasNotifiedFlow => _hasNotifiedFlow;
  bool get hasNotifiedEndurance => _hasNotifiedEndurance;
  bool get hasNotifiedInsight => _hasNotifiedInsight;
  bool get hasNotifiedIron => _hasNotifiedIron;

  // How many reward tiers are unlocked (0=none,1=minor,2=full)
  int get rewardTier => RankSystem.rewardTier(rank);

  void setNotified(String ability) {
    final settings = HiveService.settings;
    if (ability == "FLOW STATE") {
      _hasNotifiedFlow = true;
      settings.put('hasNotifiedFlow', true);
    } else if (ability == "ENDURANCE BURST") {
      _hasNotifiedEndurance = true;
      settings.put('hasNotifiedEndurance', true);
    } else if (ability == "TACTICAL INSIGHT") {
      _hasNotifiedInsight = true;
      settings.put('hasNotifiedInsight', true);
    } else if (ability == "IRON RESOLVE") {
      _hasNotifiedIron = true;
      settings.put('hasNotifiedIron', true);
    }
    notifyListeners();
  }

  void consumeNextLevelUpEvent() {
    if (_levelUpQueue.isEmpty) return;
    _levelUpQueue.removeAt(0);
    notifyListeners();
  }

  void setPendingAllocationReminder(bool value) {
    _pendingAllocationReminder = value;
    HiveService.settings.put('pendingAllocationReminder', value);
    notifyListeners();
  }

  void clearPendingAllocationReminder() {
    if (!_pendingAllocationReminder) return;
    _pendingAllocationReminder = false;
    HiveService.settings.put('pendingAllocationReminder', false);
    notifyListeners();
  }

  bool get hasHealthZoneChangedForUi {
    return _shouldNotifyHealthZone();
  }

  HealthZone? consumeHealthZoneChangeForUi() {
    if (!_shouldNotifyHealthZone()) return null;
    _lastHealthZoneNotified = _healthZone;
    _lastHealthZoneNotifiedDate = _todayLocalString();
    HiveService.settings.put(
      'lastHealthZoneNotified',
      _healthZoneStorageLabel(_healthZone),
    );
    HiveService.settings.put(
      'lastHealthZoneNotifiedDate',
      _lastHealthZoneNotifiedDate,
    );
    return _healthZone;
  }

  bool _shouldNotifyHealthZone() {
    final today = _todayLocalString();
    final zoneChanged = _lastHealthZoneNotified != _healthZone;
    final dailyReminderDue = _lastHealthZoneNotifiedDate != today;
    return zoneChanged || dailyReminderDue;
  }

  String _todayLocalString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _healthZoneStorageLabel(HealthZone zone) {
    return switch (zone) {
      HealthZone.stable => 'stable',
      HealthZone.warning => 'warning',
      HealthZone.critical => 'critical',
      HealthZone.collapse => 'collapse',
    };
  }

  HealthZone? _parseHealthZone(String raw) {
    switch (raw) {
      case 'stable':
        return HealthZone.stable;
      case 'warning':
        return HealthZone.warning;
      case 'critical':
        return HealthZone.critical;
      case 'collapse':
        return HealthZone.collapse;
      default:
        return null;
    }
  }

  Map<String, int> get stats => Map.unmodifiable(_stats);
  Map<String, int> get questProgress => Map.unmodifiable(_questProgress);

  // ============================================================
  // V2.1 RANK — Three-Pillar Exponential Gate
  // ============================================================

  String get rank {
    final totals = AdaptiveDirectiveEngine.aggregateTotals();
    return RankSystem.calcRank(
      lifetimeXP: _totalXP,
      streakDays: _streakDays,
      totalCompletions: totals.completions,
      totalFailures: totals.failures,
    );
  }

  String get title {
    final totals = AdaptiveDirectiveEngine.aggregateTotals();
    final r = RankSystem.calcRank(
      lifetimeXP: _totalXP,
      streakDays: _streakDays,
      totalCompletions: totals.completions,
      totalFailures: totals.failures,
    );
    final reliability = RankEngine.reliability(
      totalCompletions: totals.completions,
      totalFailures: totals.failures,
    );
    return RankEngine.titleFor(
      rank: r,
      streakDays: _streakDays,
      reliability: reliability,
    );
  }

  // ============================================================
  // V2.1 XP ENGINE
  // Daily hard cap: 4,000 XP. Diminishing returns after that.
  // ============================================================

  static const int _dailyCap = 4000;

  void addXP(int xp) {
    if (xp <= 0) return;
    _internalAddXP(xp);
  }

  /// Calculates and awards study session XP, then increments the session count.
  /// Diminishing returns: 10x -> 5x -> 2.5x
  int addStudyXP(int minutes) {
    if (minutes <= 0) return 0;

    final int earnedXP = XpEconomyEngine.computeStudyXp(
      minutes: minutes,
      sessionsToday: _studySessionsToday,
      intelligenceMultiplier: AttributeEffects.intelligenceXpGainMultiplier(
        _intelligence,
      ),
      streakDays: _streakDays,
      healthZone: _healthZone,
      walletXp: _walletXP,
    );

    _studySessionsToday++;
    HiveService.settings.put('studySessionsToday', _studySessionsToday);

    log('SYSTEM: STUDY SESSION COMPLETED. +$earnedXP XP.');
    _applyDailyCapAndAddXP(earnedXP);

    _applyHpRecovery(HealthSystem.recoveryOnStudyComplete, 'STUDY COMPLETION');
    return earnedXP;
  }

  /// V2.1 Timed XP with multipliers + daily cap + diminishing returns
  int addTimedXP(int baseXP, int minutes) {
    if (baseXP <= 0) return 0;

    double multiplier = 1.0;
    if (minutes >= 120) {
      multiplier = 2.5;
    } else if (minutes >= 60) {
      multiplier = 1.5;
    }

    final usedIntelBurst = consumeIntelBurstNextIfActive();
    final earnedXP = XpEconomyEngine.computeDirectiveXp(
      baseXp: baseXP,
      minutes: minutes,
      timeMultiplier: multiplier,
      intelligenceMultiplier: AttributeEffects.intelligenceXpGainMultiplier(
        _intelligence,
      ),
      intelBurst: usedIntelBurst,
      streakDays: _streakDays,
      healthZone: _healthZone,
      walletXp: _walletXP,
    );
    log(
      'SYSTEM: MULTIPLIER ${multiplier}x → +$earnedXP XP (SESSION: $minutes MIN).',
    );
    _applyDailyCapAndAddXP(earnedXP);

    _applyHpRecovery(
      HealthSystem.recoveryOnDirectiveComplete,
      'DIRECTIVE COMPLETION',
    );
    return earnedXP;
  }

  int previewDirectiveXp({required int baseXp, required int minutes}) {
    double timeMult = 1.0;
    if (minutes >= 120) {
      timeMult = 2.5;
    } else if (minutes >= 60) {
      timeMult = 1.5;
    }
    return XpEconomyEngine.computeDirectiveXp(
      baseXp: baseXp,
      minutes: minutes,
      timeMultiplier: timeMult,
      intelligenceMultiplier: AttributeEffects.intelligenceXpGainMultiplier(
        _intelligence,
      ),
      intelBurst: _intelBurstNext,
      streakDays: _streakDays,
      healthZone: _healthZone,
      walletXp: _walletXP,
    );
  }

  void _applyDailyCapAndAddXP(int earnedXP) {
    // Apply daily cap with diminishing returns
    final settings = HiveService.settings;
    final now = DateTime.now().toUtc();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (_dailyXPDate != todayStr) {
      _dailyXPEarned = 0;
      _dailyXPDate = todayStr;
      _studySessionsToday = 0;
      settings.put('studySessionsToday', 0);
    }

    int remaining = _dailyCap - _dailyXPEarned;
    int finalXP;

    if (remaining <= 0) {
      // Hard cap hit — diminishing returns only
      // ~5 XP flat or per session, adjusting just to provide a trickle
      finalXP = 15;
      log('SYSTEM: DAILY CAP REACHED. DIMINISHING RETURNS: +$finalXP XP.');
    } else if (earnedXP <= remaining) {
      finalXP = earnedXP;
    } else {
      // Partial cap: earn up to cap, then diminishing returns on overflow
      int overflow = earnedXP - remaining;
      int dimReturns = (overflow * 0.3).ceil();
      finalXP = remaining + dimReturns;
    }

    _dailyXPEarned += finalXP;
    settings.put('dailyXPEarned', _dailyXPEarned);
    settings.put('dailyXPDate', _dailyXPDate);

    _internalAddXP(finalXP);
  }

  /// Sin confession — wallet-only penalty, no lifetime XP impact
  void logSin(String tier) {
    int penalty;
    String label;
    switch (tier) {
      case 'minor':
        penalty = 100;
        label = 'MINOR SIN (SNACK/VIDEO)';
        break;
      case 'major':
        penalty = 250;
        label = 'MAJOR SIN (MEAL/GAMING)';
        break;
      case 'great':
      default:
        penalty = 400;
        label = 'GREAT SIN (FAST FOOD/CHEAT DAY)';
        break;
    }
    final bool shield = _disciplineShieldNext;
    if (shield) _disciplineShieldNext = false;

    _applyHpLoss(HealthSystem.lossOnSin, 'SIN CONFESSION');

    final effectivePenalty = shield
        ? 0
        : AttributeEffects.applyPenaltyReduction(
            (penalty * healthPenaltyMultiplier).round(),
            _discipline,
          );
    _applyWalletDecreaseWithFloor(amount: effectivePenalty, reason: label);
    log(
      shield
          ? 'SYSTEM: $label. DISCIPLINE SHIELD NEUTRALIZED PENALTY. WALLET: $_walletXP.'
          : 'SYSTEM: $label. -$effectivePenalty XP (DISCIPLINE MODULATED). WALLET: $_walletXP.',
    );
    notifyListeners();
  }

  int logCustomSin(int penalty, String label) {
    final bool shield = _disciplineShieldNext;
    if (shield) _disciplineShieldNext = false;

    _applyHpLoss(HealthSystem.lossOnSin, label);

    final effectivePenalty = shield
        ? 0
        : AttributeEffects.applyPenaltyReduction(
            (penalty * healthPenaltyMultiplier).round(),
            _discipline,
          );
    _applyWalletDecreaseWithFloor(amount: effectivePenalty, reason: label);
    log(
      shield
          ? 'SYSTEM: $label. DISCIPLINE SHIELD NEUTRALIZED PENALTY. WALLET: $_walletXP.'
          : 'SYSTEM: $label. -$effectivePenalty XP (DISCIPLINE MODULATED). WALLET: $_walletXP.',
    );
    notifyListeners();
    return effectivePenalty;
  }

  /// Directive STOP before completion — wallet-only, reinforces system authority.
  static const int directiveAbortPenalty = 400;

  int applyDirectiveAbortPenalty() {
    _applyHpLoss(HealthSystem.lossOnAbort, 'DIRECTIVE ABORT');
    return logCustomSin(
      directiveAbortPenalty,
      'DIRECTIVE ABORT (PROGRESS LOST)',
    );
  }

  void setDailyQuestCleared() {
    _dailyQuestCleared = true;
    HiveService.settings.put('dailyQuestCleared', true);
    log('SYSTEM: DAILY QUEST MARKED CLEARED.');
    _applyHpRecovery(HealthSystem.recoveryOnStreakExtend, 'STREAK EXTENSION');
    notifyListeners();
  }

  /// Phase 1: streak flag only when **all** core directives are completed for the day.
  void refreshDailyQuestClearedFromCoreQuests() {
    final box = HiveService.coreQuests;
    if (box.isEmpty) return;
    final allDone = box.values.every((q) => q.completed);
    if (allDone) {
      setDailyQuestCleared();
    }
  }

  // ============================================================
  // XP MUTATION — SOLE ENTRY POINT (Phase 1.5 C3/C3b + Monarch Integration)
  // All earned XP MUST flow through this method.
  // Monarch Integration (Task 3.14): Dual XP award - both lifetime and wallet increase simultaneously.
  // ============================================================

  void _internalAddXP(int xp) {
    final settings = HiveService.settings;
    int oldLevel = _level;

    // Monarch Integration: Dual XP Economy (Requirements 5.3, 5.4)
    // When XP is earned, BOTH lifetime and wallet increase by the SAME amount simultaneously.
    if (xp > 0) {
      // Lifetime XP: always increases, never decremented (Requirement 5.4)
      _totalXP += xp;
      
      // Wallet XP: increases by the same amount (Requirement 5.3)
      _walletXP += xp;
    }

    // Lifetime XP floor = 0 (never negative)
    if (_totalXP < 0) _totalXP = 0;

    settings.put('lifetimeXP', _totalXP);
    settings.put('walletXP', _walletXP);

    _level = _calculateLevel(_totalXP);

    // Level-up points only if wallet not in debt
    if (_walletXP >= 0 && _level > oldLevel) {
      int pts = _level - oldLevel;
      _availablePoints += pts;
      settings.put('availablePoints', _availablePoints);
      log('SYSTEM: LEVEL UP → LVL $_level. +$pts STAT POINTS.');

      _enqueueLevelUpMoment(
        fromLevel: oldLevel,
        toLevel: _level,
        attributePoints: pts,
      );
    }

    notifyListeners();
  }

  void _applyHpLoss(int amount, String reason) {
    if (amount <= 0) return;
    _hp = (_hp - amount).clamp(0, _maxHp);
    HiveService.settings.put('hp', _hp);
    _healthZone = HealthSystem.zoneFor(_hp, _maxHp);
    log('SYSTEM: HEALTH LOSS. -$amount HP ($reason). HP: $_hp/$_maxHp.');
    notifyListeners();
  }

  void _applyWalletDecreaseWithFloor({
    required int amount,
    required String reason,
  }) {
    if (amount <= 0) return;

    final next = _walletXP - amount;
    if (next >= _walletFloor) {
      _walletXP = next;
      HiveService.settings.put('walletXP', _walletXP);
      log(
        'SYSTEM: WALLET DECREASE. -$amount XP ($reason). WALLET: $_walletXP.',
      );
      notifyListeners();
      return;
    }

    // Clamp wallet at floor; convert overflow into HP loss (not deeper debt).
    final overflow = _walletFloor - next; // positive
    _walletXP = _walletFloor;
    HiveService.settings.put('walletXP', _walletXP);

    // Conversion rate: 10 overflow XP => 1 HP damage (ceiling).
    final hpDamage = (overflow / 10).ceil();
    _applyHpLoss(hpDamage, 'WALLET FLOOR BREACH');

    log(
      'SYSTEM: WALLET FLOOR REACHED. Excess penalty converted to HP damage. WALLET: $_walletXP.',
    );
    notifyListeners();
  }

  void _applyHpRecovery(int amount, String reason) {
    if (amount <= 0) return;
    _hp = (_hp + amount).clamp(0, _maxHp);
    HiveService.settings.put('hp', _hp);
    _healthZone = HealthSystem.zoneFor(_hp, _maxHp);
    log('SYSTEM: HEALTH RECOVERY. +$amount HP ($reason). HP: $_hp/$_maxHp.');
    notifyListeners();
  }

  void _enqueueLevelUpMoment({
    required int fromLevel,
    required int toLevel,
    required int attributePoints,
  }) {
    // Dedupe: do not enqueue if we've already queued this (or a higher) level.
    if (toLevel <= _lastEnqueuedLevelTo) return;

    final voiceLines = <String>[
      'System acknowledges your growth.',
      'You are improving.',
      'Progress detected. Continue.',
      'Evolution verified. Stay consistent.',
      'The System marks your discipline.',
    ];

    final rng = math.Random();
    final voice = voiceLines[rng.nextInt(voiceLines.length)];

    _levelUpQueue.add(
      LevelUpEvent(
        fromLevel: fromLevel,
        toLevel: toLevel,
        attributePointsGained: attributePoints,
        systemVoiceLine: voice,
        newlyUnlockedAbilityName: (() {
          final newly = <String>[];
          for (final entry in systemAbilities.entries) {
            final def = entry.value;
            if (fromLevel < def.unlockLevel && toLevel >= def.unlockLevel) {
              newly.add(def.name);
            }
          }
          if (newly.isEmpty) return null;
          return newly.join(' + ');
        })(),
        nextSystemAbilityUnlockLevel: (() {
          int? next;
          for (final def in systemAbilities.values) {
            if (def.unlockLevel <= toLevel) continue;
            next = next == null
                ? def.unlockLevel
                : math.min(next, def.unlockLevel);
          }
          return next;
        })(),
      ),
    );
    _lastEnqueuedLevelTo = toLevel;
  }

  void _applyWalletPenalty(int amount, String reason) {
    final bool shield = _disciplineShieldNext;
    if (shield) _disciplineShieldNext = false;

    final effectivePenalty = shield
        ? 0
        : AttributeEffects.applyPenaltyReduction(
            (amount * healthPenaltyMultiplier).round(),
            _discipline,
          );
    _applyWalletDecreaseWithFloor(amount: effectivePenalty, reason: reason);
    log(
      shield
          ? 'SYSTEM: $reason. DISCIPLINE SHIELD NEUTRALIZED PENALTY. WALLET: $_walletXP.'
          : 'SYSTEM: $reason. -$effectivePenalty XP (DISCIPLINE MODULATED). WALLET: $_walletXP.',
    );
    notifyListeners();
  }

  // ============================================================
  // MAXIMUM PENALTY (replaces nuclear reset — Phase 1.5 C2)
  // ============================================================

  void _applyMaximumPenalty() {
    // Apply exactly 3× the max penalty — consistent with 3-miss system
    final basePenalty = 3 * _maxSinglePenalty;
    final bool shield = _disciplineShieldNext;
    if (shield) _disciplineShieldNext = false;

    final effectivePenalty = shield
        ? 0
        : AttributeEffects.applyPenaltyReduction(
            (basePenalty * healthPenaltyMultiplier).round(),
            _discipline,
          );
    _applyWalletDecreaseWithFloor(
      amount: effectivePenalty,
      reason: 'MAXIMUM PENALTY',
    );

    // lifetimeXP: untouched
    // stats: untouched
    // abilities: untouched
    // streak: already 0 by the time this fires
    _consecutiveMisses = 0;

    log(
      shield
          ? 'SYSTEM: MAXIMUM PENALTY APPLIED. DISCIPLINE SHIELD NEUTRALIZED PENALTY. WALLET: $_walletXP.'
          : 'SYSTEM: MAXIMUM PENALTY APPLIED. -$effectivePenalty XP (DISCIPLINE MODULATED). WALLET: $_walletXP.',
    );
    notifyListeners();
  }

  // ============================================================
  // STAT INCREASE
  // ============================================================

  void increaseStrength() {
    if (_availablePoints > 0) {
      _strength++;
      _availablePoints--;
      final settings = HiveService.settings;
      settings.put('strength', _strength);
      _str = _strength;
      settings.put('availablePoints', _availablePoints);
      if (_availablePoints == 0 && _pendingAllocationReminder) {
        _pendingAllocationReminder = false;
        settings.put('pendingAllocationReminder', false);
      }
      if (!_enduranceUnlocked && _strength >= 10) {
        _enduranceUnlocked = true;
        settings.put('enduranceUnlocked', true);
      }
      notifyListeners();
    }
  }

  void increaseVitality() {
    if (_availablePoints > 0) {
      _vitality++;
      _availablePoints--;
      final settings = HiveService.settings;
      settings.put('vitality', _vitality);
      settings.put('availablePoints', _availablePoints);
      if (_availablePoints == 0 && _pendingAllocationReminder) {
        _pendingAllocationReminder = false;
        settings.put('pendingAllocationReminder', false);
      }
      if (!_enduranceUnlocked && _vitality >= 10) {
        _enduranceUnlocked = true;
        settings.put('enduranceUnlocked', true);
      }
      notifyListeners();
    }
  }

  void increaseAgility() {
    if (_availablePoints > 0) {
      _agility++;
      _availablePoints--;
      final settings = HiveService.settings;
      settings.put('agility', _agility);
      settings.put('availablePoints', _availablePoints);
      if (_availablePoints == 0 && _pendingAllocationReminder) {
        _pendingAllocationReminder = false;
        settings.put('pendingAllocationReminder', false);
      }
      if (!_flowUnlocked && _agility >= 10) {
        _flowUnlocked = true;
        settings.put('flowUnlocked', true);
      }
      notifyListeners();
    }
  }

  void increaseIntelligence() {
    if (_availablePoints > 0) {
      _intelligence++;
      _availablePoints--;
      final settings = HiveService.settings;
      settings.put('intelligence', _intelligence);
      settings.put('availablePoints', _availablePoints);
      if (_availablePoints == 0 && _pendingAllocationReminder) {
        _pendingAllocationReminder = false;
        settings.put('pendingAllocationReminder', false);
      }
      if (!_insightUnlocked && _intelligence >= 10) {
        _insightUnlocked = true;
        settings.put('insightUnlocked', true);
      }
      notifyListeners();
    }
  }

  void increasePerception() {
    if (_availablePoints > 0) {
      _perception++;
      _availablePoints--;
      final settings = HiveService.settings;
      settings.put('perception', _perception);
      _per = _perception;
      settings.put('availablePoints', _availablePoints);
      if (_availablePoints == 0 && _pendingAllocationReminder) {
        _pendingAllocationReminder = false;
        settings.put('pendingAllocationReminder', false);
      }
      notifyListeners();
    }
  }

  // ============================================================
  // ABILITY ACTIVATION
  // ============================================================

  void activateFlow() {
    if (isRestricted) return;
    if (_flowUnlocked && !_flowUsedToday) {
      _flowActive = true;
      _flowUsedToday = true;
      final s = HiveService.settings;
      s.put('flowActive', true);
      s.put('flowUsedToday', true);
      notifyListeners();
    }
  }

  void activateEndurance() {
    if (isRestricted) return;
    if (_enduranceUnlocked && !_enduranceUsedToday) {
      _enduranceActive = true;
      _enduranceUsedToday = true;
      final s = HiveService.settings;
      s.put('enduranceActive', true);
      s.put('enduranceUsedToday', true);
      notifyListeners();
    }
  }

  void activateInsight() {
    if (isRestricted) return;
    if (_insightUnlocked && !_insightUsedToday) {
      _insightActive = true;
      _insightUsedToday = true;
      final s = HiveService.settings;
      s.put('insightActive', true);
      s.put('insightUsedToday', true);
      notifyListeners();
    }
  }

  void activateIron() {
    if (isRestricted) return;
    if (_ironUnlocked && !_ironUsedThisWeek) {
      _ironActive = true;
      _ironUsedThisWeek = true;
      final s = HiveService.settings;
      s.put('ironActive', true);
      s.put('ironUsedThisWeek', true);
      notifyListeners();
    }
  }

  // ============================================================
  // ABILITY CONSUMPTION
  // ============================================================

  void consumeFlow() {
    _flowActive = false;
    HiveService.settings.put('flowActive', false);
    notifyListeners();
  }

  void consumeEndurance() {
    _enduranceActive = false;
    HiveService.settings.put('enduranceActive', false);
    notifyListeners();
  }

  void consumeInsight() {
    _insightActive = false;
    HiveService.settings.put('insightActive', false);
    notifyListeners();
  }

  void consumeIron() {
    _ironActive = false;
    HiveService.settings.put('ironActive', false);
    notifyListeners();
  }

  // ============================================================
  // SPEND XP (Rewards Terminal — wallet-only)
  // ============================================================

  int spendXP(int amount) {
    // Wallet Abyss — can go negative (discipline reduces the cost).
    _applyHpLoss(HealthSystem.lossOnRedemption, 'REDEMPTION');
    final effectiveCost = AttributeEffects.applyPenaltyReduction(
      (amount * healthPenaltyMultiplier).round(),
      _discipline,
    );
    _applyWalletDecreaseWithFloor(
      amount: effectiveCost,
      reason: 'REWARD EXCHANGE',
    );
    log(
      'SYSTEM: REWARD EXCHANGED. -$effectiveCost XP (DISCIPLINE MODULATED). WALLET: $_walletXP.',
    );
    notifyListeners();
    return effectiveCost;
  }

  // ============================================================
  // SYSTEM LOG
  // ============================================================

  void log(String message) {
    final ts = DateTime.now().toIso8601String().substring(11, 19);
    _systemLogs.insert(0, '[$ts] $message');
    if (_systemLogs.length > 60) _systemLogs.removeLast();
    notifyListeners();
  }

  // ============================================================
  // MISC
  // ============================================================

  void refreshFromStorage() {
    final settings = HiveService.settings;
    final rawXP = settings.get('lifetimeXP', defaultValue: 0);
    if (rawXP is int) {
      _totalXP = rawXP;
    } else if (rawXP is double) {
      _totalXP = rawXP.toInt();
    }
    _level = _calculateLevel(_totalXP);
    notifyListeners();
  }

  void setPlayer(String name) {
    _name = name;
    HiveService.settings.put('playerName', name);
    notifyListeners();
  }

  void updateStat(String key, int delta) {
    if (!_stats.containsKey(key)) return;
    _stats[key] = (_stats[key]! + delta).clamp(0, 999);
    notifyListeners();
  }

  void updateQuest(String quest, int delta) {
    if (!_questProgress.containsKey(quest)) return;
    _questProgress[quest] = (_questProgress[quest]! + delta).clamp(
      0,
      500,
    ); // Increased cap for preparation
    notifyListeners();
  }

  void updatePhysicalProgress({
    required int pu,
    required int si,
    required int sq,
    required int rd,
  }) {
    _questProgress['Push-ups'] = pu;
    _questProgress['Sit-ups'] = si;
    _questProgress['Squats'] = sq;
    _questProgress['Running'] = rd;
    notifyListeners();
  }

  // ============================================================
  // MONARCH INTEGRATION — Physical Progress Methods (Task 3.3)
  // ============================================================

  /// 🔥 INCREMENTAL PROGRESS (USED BY UI)
  void addReps(String type, int value) {
    if (!_questProgress.containsKey(type)) return;

    final current = _questProgress[type] ?? 0;

    /// Clamp to 100 (V1 target cap)
    final updated = (current + value).clamp(0, 100);

    /// Use EXISTING SYSTEM METHOD (important)
    logPhysicalProgress(type, updated);

    /// 🔥 AUTO COMPLETE QUEST
    if (isDailyPhysicalCompleted && !_dailyQuestCleared) {
      setDailyQuestCleared();
      log('SYSTEM: DAILY PHYSICAL QUEST COMPLETED.');
    }
  }

  /// Logs progress for a specific Physical Foundation sub-task.
  ///
  /// Updates the internal progress map, persists to monarch_state box,
  /// checks for Limiter Removal condition, and notifies listeners.
  ///
  /// Parameters:
  /// - subTask: The sub-task key (e.g., 'Push-ups', 'Sit-ups', 'Squats', 'Running')
  /// - value: The new progress value (non-negative integer)
  void logPhysicalProgress(String subTask, int value) {
    // Clamp negative values to 0
    final clampedValue = value < 0 ? 0 : value;
    
    // Update internal progress map
    _questProgress[subTask] = clampedValue;
    
    // Persist to monarch_state box
    final monarchState = HiveService.monarchState;
    final key = _physicalProgressKey(subTask);
    monarchState.put(key, clampedValue);
    
    // Check for Limiter Removal condition
    checkLimiterRemoval();
    
    // Notify listeners to update UI
    notifyListeners();
  }

  /// Returns the Hive key for a Physical Foundation sub-task.
  String _physicalProgressKey(String subTask) {
    switch (subTask) {
      case 'Push-ups':
        return 'physProgress_pushups';
      case 'Sit-ups':
        return 'physProgress_situps';
      case 'Squats':
        return 'physProgress_squats';
      case 'Running':
        return 'physProgress_running';
      default:
        throw ArgumentError('Unknown sub-task: $subTask');
    }
  }

  /// Computes the aggregate Physical Foundation completion percentage.
  ///
  /// Delegates to PhysicalFoundation.completionPct to compute the mean
  /// of clamped ratios across all four sub-tasks.
  ///
  /// Returns a value in the range [0.0, 1.0] where:
  /// - 0.0 = no progress on any sub-task
  /// - 1.0 = 100% completion (all targets met)
  double get physicalCompletionPct {
    return PhysicalFoundation.completionPct(_questProgress);
  }

  /// Resets all Physical Foundation sub-task progress values to zero.
  ///
  /// This is called during Midnight Judgement to reset progress for the new day.
  /// Persists all changes to monarch_state box and notifies listeners.
  void resetPhysicalProgress() {
    final monarchState = HiveService.monarchState;
    
    // Reset all four sub-tasks to 0
    _questProgress['Push-ups'] = 0;
    _questProgress['Sit-ups'] = 0;
    _questProgress['Squats'] = 0;
    _questProgress['Running'] = 0;
    
    // Persist to monarch_state box
    monarchState.put('physProgress_pushups', 0);
    monarchState.put('physProgress_situps', 0);
    monarchState.put('physProgress_squats', 0);
    monarchState.put('physProgress_running', 0);
    
    // Notify listeners to update UI
    notifyListeners();
  }

  /// Checks if the Limiter Removal condition is met and triggers the Secret Quest Event.
  ///
  /// This method is called after each physical progress update. If all sub-tasks
  /// have reached >= 200% of their targets and the event hasn't fired today,
  /// it awards 5 stat points and sets the Overload Title flag.
  ///
  /// The event can only fire once per day (idempotence guard).
  void checkLimiterRemoval() {
    // Idempotence guard: if already triggered today, return immediately
    if (_limiterRemovedToday) return;
    
    // Check if all sub-tasks are >= 200% of target
    final isRemoved = PhysicalFoundation.isLimiterRemoved(_questProgress);
    
    if (isRemoved) {
      // Set flag to prevent duplicate triggers
      _limiterRemovedToday = true;
      
      // Award 5 stat points
      _availablePoints += 5;
      
      // Set Overload Title flag on first trigger (permanent)
      if (!_overloadTitleAwarded) {
        _overloadTitleAwarded = true;
      }
      
      // Persist to monarch_state box
      final monarchState = HiveService.monarchState;
      monarchState.put('limiterRemovedToday', true);
      monarchState.put('overloadTitleAwarded', _overloadTitleAwarded);
      
      // Persist available points to settings
      HiveService.settings.put('availablePoints', _availablePoints);
      
      // Log the event
      log('SYSTEM: LIMITER REMOVED. +5 STAT POINTS AWARDED.');
      
      // Notify listeners to update UI (will trigger overlay)
      notifyListeners();
    }
  }

  // ============================================================
  // MONARCH INTEGRATION — Stat Award Methods (Task 3.5)
  // ============================================================

  /// Awards STR (Strength) stat points.
  ///
  /// Increments the STR stat by the specified amount, persists to monarch_state,
  /// and notifies listeners to update the UI.
  ///
  /// This is called when the Hunter completes a Physical Foundation session.
  ///
  /// Parameters:
  /// - amount: The number of STR points to award (must be positive)
  void awardSTR(int amount) {
    if (amount <= 0) return;
    
    // Increment STR stat
    _str += amount;
    
    // Persist to monarch_state box
    final monarchState = HiveService.monarchState;
    monarchState.put('str', _str);
    
    // Log the award
    log('SYSTEM: +$amount STR AWARDED. TOTAL STR: $_str.');
    
    // Notify listeners to update UI
    notifyListeners();
  }

  /// Awards INT (Intelligence) stat points.
  ///
  /// Increments the INT stat by the specified amount, persists to monarch_state,
  /// and notifies listeners to update the UI.
  ///
  /// This is called when the Hunter completes a Technical Quest (Skill Calibration) session.
  ///
  /// Parameters:
  /// - amount: The number of INT points to award (must be positive)
  void awardINT(int amount) {
    if (amount <= 0) return;
    
    // Increment INT stat
    _int += amount;
    
    // Persist to monarch_state box
    final monarchState = HiveService.monarchState;
    monarchState.put('intStat', _int);
    
    // Log the award
    log('SYSTEM: +$amount INT AWARDED. TOTAL INT: $_int.');
    
    // Notify listeners to update UI
    notifyListeners();
  }

  /// Awards PER (Perception) stat points.
  ///
  /// Increments the PER stat by the specified amount, persists to monarch_state,
  /// and notifies listeners to update the UI.
  ///
  /// This is called when the Hunter completes a Cognitive Quest (Deep Work) session.
  ///
  /// Parameters:
  /// - amount: The number of PER points to award (must be positive)
  void awardPER(int amount) {
    if (amount <= 0) return;
    
    // Increment PER stat
    _per += amount;
    
    // Persist to monarch_state box
    final monarchState = HiveService.monarchState;
    monarchState.put('per', _per);
    
    // Log the award
    log('SYSTEM: +$amount PER AWARDED. TOTAL PER: $_per.');
    
    // Notify listeners to update UI
    notifyListeners();
  }

  // ============================================================
  // MONARCH INTEGRATION — Penalty Zone Methods (Task 3.7)
  // ============================================================

  /// Activates the Penalty Zone lockout.
  ///
  /// Sets the inPenaltyZone flag to true, records the activation timestamp,
  /// persists both to monarch_state box, and notifies listeners.
  ///
  /// This is called by CoreEngine.runMidnightJudgement when the Physical Foundation
  /// completion percentage is less than 100% at midnight.
  ///
  /// The Penalty Zone enforces a 4-hour full-screen lockout that blocks all app navigation.
  void activatePenaltyZone() {
    // Set penalty zone flag
    _inPenaltyZone = true;
    
    // Record activation timestamp
    _penaltyActivatedAt = DateTime.now();
    
    // Persist to monarch_state box
    final monarchState = HiveService.monarchState;
    monarchState.put('inPenaltyZone', true);
    monarchState.put('penaltyActivatedAt', _penaltyActivatedAt!.toIso8601String());
    
    // Log the activation
    log('SYSTEM: PENALTY ZONE ACTIVATED. 4-HOUR LOCKOUT INITIATED.');
    
    // Notify listeners to update UI (will show PenaltyZoneScreen)
    notifyListeners();
  }

  /// Deactivates the Penalty Zone lockout.
  ///
  /// Sets the inPenaltyZone flag to false, clears the activation timestamp,
  /// persists changes to monarch_state box, and notifies listeners.
  ///
  /// This is called automatically when the 4-hour lockout duration expires,
  /// or can be called manually to force-deactivate the penalty zone.
  void deactivatePenaltyZone() {
    // Clear penalty zone flag
    _inPenaltyZone = false;
    
    // Clear activation timestamp
    _penaltyActivatedAt = null;
    
    // Persist to monarch_state box
    final monarchState = HiveService.monarchState;
    monarchState.put('inPenaltyZone', false);
    monarchState.delete('penaltyActivatedAt');
    
    // Log the deactivation
    log('SYSTEM: PENALTY ZONE DEACTIVATED. FULL ACCESS RESTORED.');
    
    // Notify listeners to update UI (will hide PenaltyZoneScreen)
    notifyListeners();
  }

  // ============================================================
  // MONARCH INTEGRATION — Quest Management Methods (Task 3.10)
  // ============================================================

  /// Sets the pending Cognitive Quest duration for tomorrow.
  ///
  /// Validates that the duration is within the range [1, 480] minutes.
  /// If valid, persists to monarch_state box and notifies listeners.
  ///
  /// Parameters:
  /// - mins: The duration in minutes for tomorrow's Cognitive Quest (Deep Work)
  ///
  /// Throws:
  /// - ArgumentError if mins is outside the valid range [1, 480]
  void setPendingCognitiveQuest(int mins) {
    // Validate range [1, 480]
    if (mins < 1 || mins > 480) {
      throw ArgumentError(
        'Cognitive Quest duration must be between 1 and 480 minutes. Received: $mins',
      );
    }
    
    // Update pending cognitive quest duration
    _pendingCognitiveDurationMinutes = mins;
    
    // Persist to monarch_state box
    final monarchState = HiveService.monarchState;
    monarchState.put('pendingCognitiveMins', mins);
    
    // Log the configuration
    log('SYSTEM: COGNITIVE QUEST CONFIGURED. DURATION: $mins MINUTES.');
    
    // Notify listeners to update UI
    notifyListeners();
  }

  /// Sets the pending Technical Quest task for tomorrow.
  ///
  /// Persists the task description to monarch_state box and notifies listeners.
  ///
  /// Parameters:
  /// - task: The task description for tomorrow's Technical Quest (Skill Calibration)
  void setPendingTechnicalQuest(String task) {
    // Update pending technical quest task
    _pendingTechnicalTask = task;
    
    // Persist to monarch_state box
    final monarchState = HiveService.monarchState;
    monarchState.put('pendingTechnicalTask', task);
    
    // Log the configuration
    log('SYSTEM: TECHNICAL QUEST CONFIGURED. TASK: $task');
    
    // Notify listeners to update UI
    notifyListeners();
  }

  /// Locks the mandatory quests at midnight.
  ///
  /// Copies the pending quest configurations to the locked fields,
  /// sets the locked flags to true, persists all changes to monarch_state,
  /// and notifies listeners.
  ///
  /// This is called by CoreEngine.runMidnightJudgement at 00:00 local time
  /// to transition the configured quests into Locked Mandatory Quest status.
  void lockMandatoryQuests() {
    final monarchState = HiveService.monarchState;
    
    // Copy pending → locked fields
    _lockedCognitiveDurationMinutes = _pendingCognitiveDurationMinutes;
    _lockedTechnicalTask = _pendingTechnicalTask;
    
    // Set locked flags to true
    _cognitiveLocked = true;
    _technicalLocked = true;
    
    // Reset completed flags for the new day
    _cognitiveCompleted = false;
    _technicalCompleted = false;
    
    // Persist locked quest values
    if (_lockedCognitiveDurationMinutes != null) {
      monarchState.put('lockedCognitiveMins', _lockedCognitiveDurationMinutes);
    }
    if (_lockedTechnicalTask != null) {
      monarchState.put('lockedTechnicalTask', _lockedTechnicalTask);
    }
    
    // Persist locked flags
    monarchState.put('cognitiveLocked', _cognitiveLocked);
    monarchState.put('technicalLocked', _technicalLocked);
    monarchState.put('cognitiveCompleted', false);
    monarchState.put('technicalCompleted', false);
    
    // Log the lock event
    log('SYSTEM: MANDATORY QUESTS LOCKED FOR TODAY.');
    
    // Notify listeners to update UI
    notifyListeners();
  }

  /// Completes the Cognitive Quest (Deep Work).
  ///
  /// Sets the cognitive completed flag to true, awards PER stat points,
  /// persists changes to monarch_state box, and notifies listeners.
  ///
  /// This should be called when the Hunter completes their locked Cognitive Quest.
  void completeCognitiveQuest() {
    // Set completed flag
    _cognitiveCompleted = true;
    
    // Persist to monarch_state box
    final monarchState = HiveService.monarchState;
    monarchState.put('cognitiveCompleted', true);
    
    // Award PER stat points
    awardPER(MonarchRewards.perPerCognitiveCompletion);
    
    // Log the completion (awardPER already logs, so just note the quest completion)
    log('SYSTEM: COGNITIVE QUEST COMPLETED.');
    
    // Notify listeners to update UI (already called by awardPER, but ensure consistency)
    notifyListeners();
  }

  /// Completes the Technical Quest (Skill Calibration).
  ///
  /// Sets the technical completed flag to true, awards INT stat points,
  /// persists changes to monarch_state box, and notifies listeners.
  ///
  /// This should be called when the Hunter completes their locked Technical Quest.
  void completeTechnicalQuest() {
    // Set completed flag
    _technicalCompleted = true;
    
    // Persist to monarch_state box
    final monarchState = HiveService.monarchState;
    monarchState.put('technicalCompleted', true);
    
    // Award INT stat points
    awardINT(MonarchRewards.intPerTechnicalCompletion);
    
    // Log the completion (awardINT already logs, so just note the quest completion)
    log('SYSTEM: TECHNICAL QUEST COMPLETED.');
    
    // Notify listeners to update UI (already called by awardINT, but ensure consistency)
    notifyListeners();
  }

  /// Records that a day was cleared (Physical Foundation 100% complete at midnight).
  ///
  /// Increments the streak counter, updates best streak if needed,
  /// persists to settings, and notifies listeners.
  ///
  /// This is called by CoreEngine.runMidnightJudgement when physicalCompletionPct >= 1.0.
  void recordDayCleared() {
    // Increment streak
    _streakDays++;
    
    // Update best streak if needed
    if (_streakDays > _bestStreak) {
      _bestStreak = _streakDays;
    }
    
    // Reset consecutive misses
    _consecutiveMisses = 0;
    
    // Persist to settings
    final settings = HiveService.settings;
    settings.put('streakDays', _streakDays);
    settings.put('bestStreak', _bestStreak);
    settings.put('consecutiveMisses', 0);
    
    // Log the streak extension
    log('SYSTEM: DAY CLEARED. STREAK: $_streakDays DAYS.');
    
    // Notify listeners to update UI
    notifyListeners();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }
}
