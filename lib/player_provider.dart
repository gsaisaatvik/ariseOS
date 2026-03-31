import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'services/hive_service.dart';

// ============================================================
//  RANK CONSTANTS — V2.1 Three-Pillar Exponential Gate System
// ============================================================
class RankSystem {
  // { minLifetimeXP, minLevel, minStreakDays }
  static const Map<String, List<int>> gates = {
    'GOD': [1000000, 200, 730],
    'S':   [500000,  120, 420],
    'A':   [200000,   80, 300],
    'B':   [100000,   50, 200],
    'C':   [48000,    25, 120],
    'D':   [12000,    10,  50],
    'E':   [0,         0,   0],
  };

  static String calcRank(int totalXP, int level, int streakDays) {
    for (final entry in ['GOD','S','A','B','C','D']) {
      final gate = gates[entry]!;
      if (totalXP >= gate[0] && level >= gate[1] && streakDays >= gate[2]) {
        return entry;
      }
    }
    return 'E';
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
      case 'GOD': return 'GOD';
      default: return rank;
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
  int _penaltyDebt = 0;
  int _level = 0;
  int _totalXP = 0;   // Lifetime XP — never decremented by penalties
  int _walletXP = 0;  // Spendable XP — can go negative (debt)
  String _awakeningDate = '';

  // =========================
  // V2.1 STREAK & DAILY TRACKING
  // =========================
  int _streakDays = 0;               // Consecutive days with quest cleared
  int _consecutiveMisses = 0;        // Days without any quest cleared
  bool _dailyQuestCleared = false;   // Was today's quest cleared?
  bool _isPenaltyMode = false;
  int _dailyXPEarned = 0;            // XP earned today (for daily cap)
  String _dailyXPDate = '';          // UTC date string for daily cap reset
  int _studySessionsToday = 0;       // Number of study sessions completed today
  final List<String> _systemLogs = [];

  // =========================
  // STATS (PHASE 4)
  // =========================
  int _strength = 0;
  int _focus = 0;
  int _discipline = 0;
  int _intelligence = 0;
  int _availablePoints = 0;

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
    'HP': 100, 'STR': 10, 'AGI': 10, 'VIT': 10, 'INT': 10, 'PER': 10,
  };

  final Map<String, int> _questProgress = {
    'Push-ups': 0, 'Sit-ups': 0, 'Squats': 0, 'Running': 0,
  };

  // =========================
  // INITIAL LOAD
  // =========================

  void _initialize() {
    final settings = HiveService.settings;

    final rawXP = settings.get('lifetimeXP', defaultValue: 0);
    if (rawXP is int) {
      _totalXP = rawXP;
    } else if (rawXP is double) {
      _totalXP = rawXP.toInt();
    }

    _level = _calculateLevel(_totalXP);
    _walletXP = settings.get('walletXP', defaultValue: 0);

    _strength = settings.get('strength', defaultValue: 0);
    _focus = settings.get('focus', defaultValue: 0);
    _discipline = settings.get('discipline', defaultValue: 0);
    _intelligence = settings.get('intelligence', defaultValue: 0);
    _availablePoints = settings.get('availablePoints', defaultValue: 0);

    _flowUnlocked = settings.get('flowUnlocked', defaultValue: false);
    _enduranceUnlocked = settings.get('enduranceUnlocked', defaultValue: false);
    _insightUnlocked = settings.get('insightUnlocked', defaultValue: false);
    _ironUnlocked = settings.get('ironUnlocked', defaultValue: false);

    _flowUsedToday = settings.get('flowUsedToday', defaultValue: false);
    _enduranceUsedToday = settings.get('enduranceUsedToday', defaultValue: false);
    _insightUsedToday = settings.get('insightUsedToday', defaultValue: false);
    _ironUsedThisWeek = settings.get('ironUsedThisWeek', defaultValue: false);

    _flowActive = settings.get('flowActive', defaultValue: false);
    _enduranceActive = settings.get('enduranceActive', defaultValue: false);
    _insightActive = settings.get('insightActive', defaultValue: false);
    _ironActive = settings.get('ironActive', defaultValue: false);

    _hasNotifiedFlow = settings.get('hasNotifiedFlow', defaultValue: false);
    _hasNotifiedEndurance = settings.get('hasNotifiedEndurance', defaultValue: false);
    _hasNotifiedInsight = settings.get('hasNotifiedInsight', defaultValue: false);
    _hasNotifiedIron = settings.get('hasNotifiedIron', defaultValue: false);

    _name = settings.get('playerName', defaultValue: 'Player');
    _awakeningDate = settings.get('awakeningDate', defaultValue: '');

    // V2.1 streak & daily fields
    _streakDays = settings.get('streakDays', defaultValue: 0);
    _consecutiveMisses = settings.get('consecutiveMisses', defaultValue: 0);
    _dailyQuestCleared = settings.get('dailyQuestCleared', defaultValue: false);
    _isPenaltyMode = settings.get('isPenaltyMode', defaultValue: false);
    _dailyXPEarned = settings.get('dailyXPEarned', defaultValue: 0);
    _dailyXPDate = settings.get('dailyXPDate', defaultValue: '');
    _studySessionsToday = settings.get('studySessionsToday', defaultValue: 0);

    _checkResets();
    notifyListeners();
  }

  // =========================
  // DAILY / WEEKLY RESETS
  // =========================

  void _checkResets() {
    final settings = HiveService.settings;
    final now = DateTime.now().toUtc();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
    final lastResetStr = settings.get('lastDailyReset', defaultValue: '');

    bool isNewDay = false;

    if (lastResetStr != '') {
      try {
        final lastDate = DateTime.parse(lastResetStr);
        if (now.year > lastDate.year ||
            (now.year == lastDate.year && now.month > lastDate.month) ||
            (now.year == lastDate.year && now.month == lastDate.month && now.day > lastDate.day)) {
          isNewDay = true;
        }
      } catch (_) {
        isNewDay = true;
      }
    } else {
      isNewDay = true;
    }

    if (isNewDay) {
      // -- Streak / Miss evaluation --
      if (_dailyQuestCleared) {
        _streakDays++;
        _consecutiveMisses = 0;
        log('SYSTEM: STREAK EXTENDED. DAY $_streakDays.');
      } else if (lastResetStr != '') {
        // Quest was NOT cleared yesterday
        int previousStreak = _streakDays;
        _consecutiveMisses++;
        _streakDays = 0;
        log('SYSTEM: STREAK BROKEN. MISS #$_consecutiveMisses.');

        // 3-day Nuclear Reset
        if (_consecutiveMisses >= 3) {
          _triggerNuclearReset();
        } else if (_consecutiveMisses == 2) {
          _applyWalletPenalty(3000, 'CONSECUTIVE MISS PENALTY (DAY 2)');
        } else {
          // 1st Miss
          int penalty = 1200;
          String reason = 'MISSED DAILY QUEST PENALTY';

          // Grace Period: 1st miss of the month AND 10+ streak before miss
          int lastMissMonth = settings.get('lastMissMonth', defaultValue: -1);
          if (lastMissMonth != now.month) {
            settings.put('lastMissMonth', now.month);
            if (previousStreak >= 10) {
              penalty = 600;
              reason = 'GRACE PERIOD WARNING (STREAK 10+)';
            }
          }

          _applyWalletPenalty(penalty, reason);
        }
      }

      // -- Debt Interest (1% daily) --
      if (_walletXP < 0) {
        int tax = (_walletXP.abs() * 0.01).ceil();
        _walletXP -= tax;
        settings.put('walletXP', _walletXP);
        log('DEBT INTEREST: -$tax XP. BALANCE: $_walletXP.');
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
      settings.put('consecutiveMisses', _consecutiveMisses);
      settings.put('flowUsedToday', false);
      settings.put('enduranceUsedToday', false);
      settings.put('insightUsedToday', false);
      settings.put('lastDailyReset', now.toIso8601String());
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
    if (currentWeek > lastWeek || (now.year > settings.get('lastWeeklyResetYear', defaultValue: now.year))) {
      _ironUsedThisWeek = false;
      settings.put('ironUsedThisWeek', false);
      settings.put('lastWeeklyResetWeek', currentWeek);
      settings.put('lastWeeklyResetYear', now.year);
    }
  }

  int _getWeekOfYear(DateTime date) {
    final dayOfYear = int.parse(math.max(1, date.difference(DateTime(date.year, 1, 1)).inDays).toString());
    return (dayOfYear / 7).ceil();
  }

  int _calculateLevel(int xp) {
    return math.sqrt(xp.toDouble()).floor();
  }

  // =========================
  // GETTERS
  // =========================

  String get name => _name;
  String get awakeningDate => _awakeningDate;
  int get penaltyDebt => _penaltyDebt;
  int get level => _level;
  int get totalXP => _totalXP;
  int get walletXP => _walletXP;
  int get streakDays => _streakDays;
  int get consecutiveMisses => _consecutiveMisses;
  int get studySessionsToday => _studySessionsToday;
  bool get dailyQuestCleared => _dailyQuestCleared;
  bool get isPenaltyMode => _isPenaltyMode;
  bool get isRestricted => _walletXP < 0;
  List<String> get systemLogs => List.unmodifiable(_systemLogs);

  int get strength => _strength;
  int get focus => _focus;
  int get discipline => _discipline;
  int get intelligence => _intelligence;
  int get availablePoints => _availablePoints;

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

  Map<String, int> get stats => Map.unmodifiable(_stats);
  Map<String, int> get questProgress => Map.unmodifiable(_questProgress);

  // ============================================================
  // V2.1 RANK — Three-Pillar Exponential Gate
  // ============================================================

  String get rank => RankSystem.calcRank(_totalXP, _level, _streakDays);

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
  void addStudyXP(int minutes) {
    if (minutes <= 0) return;

    int earnedXP = 0;
    if (_studySessionsToday == 0) {
      earnedXP = minutes * 10;
    } else if (_studySessionsToday == 1) {
      earnedXP = minutes * 5;
    } else {
      earnedXP = (minutes * 2.5).ceil();
    }

    _studySessionsToday++;
    HiveService.settings.put('studySessionsToday', _studySessionsToday);

    log('SYSTEM: STUDY SESSION COMPLETED. +$earnedXP XP.');
    _applyDailyCapAndAddXP(earnedXP);
  }

  /// V2.1 Timed XP with multipliers + daily cap + diminishing returns
  void addTimedXP(int baseXP, int minutes) {
    if (baseXP <= 0) return;

    double multiplier = 1.0;
    if (minutes >= 120) {
      multiplier = 2.5;
    } else if (minutes >= 60) {
      multiplier = 1.5;
    }

    int earnedXP = (baseXP * multiplier).ceil();
    log('SYSTEM: MULTIPLIER ${multiplier}x → +$earnedXP XP (SESSION: $minutes MIN).');
    _applyDailyCapAndAddXP(earnedXP);
  }

  void _applyDailyCapAndAddXP(int earnedXP) {
    // Apply daily cap with diminishing returns
    final settings = HiveService.settings;
    final now = DateTime.now().toUtc();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
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
        penalty = 400;
        label = 'MINOR SIN (SNACK/VIDEO)';
        break;
      case 'major':
        penalty = 1200;
        label = 'MAJOR SIN (MEAL/GAMING)';
        break;
      case 'great':
      default:
        penalty = 2500;
        label = 'GREAT SIN (FAST FOOD/CHEAT DAY)';
        break;
    }
    _walletXP -= penalty;
    HiveService.settings.put('walletXP', _walletXP);
    log('SYSTEM: $label. -$penalty XP. WALLET: $_walletXP.');
    notifyListeners();
  }

  void logCustomSin(int penalty, String label) {
    _walletXP -= penalty;
    HiveService.settings.put('walletXP', _walletXP);
    log('SYSTEM: $label. -$penalty XP. WALLET: $_walletXP.');
    notifyListeners();
  }

  void setDailyQuestCleared() {
    _dailyQuestCleared = true;
    HiveService.settings.put('dailyQuestCleared', true);
    log('SYSTEM: DAILY QUEST MARKED CLEARED.');
    notifyListeners();
  }

  void _internalAddXP(int xp) {
    final settings = HiveService.settings;
    int oldLevel = _level;

    // Lifetime XP: only growth (rewards/sins don't touch this)
    if (xp > 0) {
      _totalXP += xp;
    }

    // Wallet XP: full economy (both gains & losses)
    _walletXP += xp;

    // Lifetime XP floor = 0
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
    }

    notifyListeners();
  }

  void _applyWalletPenalty(int amount, String reason) {
    _walletXP -= amount;
    HiveService.settings.put('walletXP', _walletXP);
    log('SYSTEM: $reason. -$amount XP. WALLET: $_walletXP.');
  }

  // ============================================================
  // NUCLEAR RESET (3 consecutive missed days)
  // ============================================================

  void _triggerNuclearReset() {
    log('SYSTEM: PURGE_PROTOCOL_INITIATED. 3 DAYS WITHOUT DIRECTIVE.');
    final settings = HiveService.settings;

    // Hard penalty to wallet
    _walletXP = -5000;
    settings.put('walletXP', _walletXP);

    // Wipe level & stats
    _level = 1;
    _totalXP = 0;
    _strength = 0;
    _focus = 0;
    _discipline = 0;
    _intelligence = 0;
    _availablePoints = 0;

    // Revoke abilities
    _flowUnlocked = false;
    _enduranceUnlocked = false;
    _insightUnlocked = false;
    _ironUnlocked = false;

    // Reset streak
    _streakDays = 0;
    _consecutiveMisses = 0;

    settings.put('lifetimeXP', 0);
    settings.put('strength', 0);
    settings.put('focus', 0);
    settings.put('discipline', 0);
    settings.put('intelligence', 0);
    settings.put('availablePoints', 0);
    settings.put('flowUnlocked', false);
    settings.put('enduranceUnlocked', false);
    settings.put('insightUnlocked', false);
    settings.put('ironUnlocked', false);
    settings.put('streakDays', 0);
    settings.put('consecutiveMisses', 0);

    log('SYSTEM: PURGE COMPLETE. RANK RESET TO E. WALLET: $_walletXP.');
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
      settings.put('availablePoints', _availablePoints);
      if (!_enduranceUnlocked && _strength >= 10) {
        _enduranceUnlocked = true;
        settings.put('enduranceUnlocked', true);
      }
      notifyListeners();
    }
  }

  void increaseFocus() {
    if (_availablePoints > 0) {
      _focus++;
      _availablePoints--;
      final settings = HiveService.settings;
      settings.put('focus', _focus);
      settings.put('availablePoints', _availablePoints);
      if (!_flowUnlocked && _focus >= 10) {
        _flowUnlocked = true;
        settings.put('flowUnlocked', true);
      }
      notifyListeners();
    }
  }

  void increaseDiscipline() {
    if (_availablePoints > 0) {
      _discipline++;
      _availablePoints--;
      final settings = HiveService.settings;
      settings.put('discipline', _discipline);
      settings.put('availablePoints', _availablePoints);
      if (!_ironUnlocked && _discipline >= 10) {
        _ironUnlocked = true;
        settings.put('ironUnlocked', true);
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
      if (!_insightUnlocked && _intelligence >= 10) {
        _insightUnlocked = true;
        settings.put('insightUnlocked', true);
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

  void spendXP(int amount) {
    // Wallet Abyss — can go negative
    _walletXP -= amount;
    HiveService.settings.put('walletXP', _walletXP);
    log('SYSTEM: REWARD EXCHANGED. -$amount XP. WALLET: $_walletXP.');
    notifyListeners();
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

  void increasePenalty() {
    _penaltyDebt++;
    notifyListeners();
  }

  void decreasePenalty({int amount = 1}) {
    _penaltyDebt = (_penaltyDebt - amount).clamp(0, 999);
    notifyListeners();
  }

  void updateStat(String key, int delta) {
    if (!_stats.containsKey(key)) return;
    _stats[key] = (_stats[key]! + delta).clamp(0, 999);
    notifyListeners();
  }

  void updateQuest(String quest, int delta) {
    if (!_questProgress.containsKey(quest)) return;
    _questProgress[quest] = (_questProgress[quest]! + delta).clamp(0, 100);
    notifyListeners();
  }
}