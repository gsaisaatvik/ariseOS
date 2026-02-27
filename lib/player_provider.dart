import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'services/hive_service.dart';

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
  int _totalXP = 0;

  // =========================
  // NEW STATS (PHASE 4)
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

  // =========================
  // STATS (OLD - kept for compatibility if needed)
  // =========================
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

    final rawXP = settings.get('lifetimeXP', defaultValue: 0);
    if (rawXP is int) {
      _totalXP = rawXP;
    } else if (rawXP is double) {
      _totalXP = rawXP.toInt();
    }

    _level = _calculateLevel(_totalXP);

    // Initialize Phase 4 stats
    _strength = settings.get('strength', defaultValue: 0);
    _focus = settings.get('focus', defaultValue: 0);
    _discipline = settings.get('discipline', defaultValue: 0);
    _intelligence = settings.get('intelligence', defaultValue: 0);
    _availablePoints = settings.get('availablePoints', defaultValue: 0);

    // Initialize Phase 6 abilities
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

    _checkResets();

    notifyListeners(); // ensure UI sync on startup
  }

  void _checkResets() {
    final settings = HiveService.settings;
    final now = DateTime.now().toUtc();
    final lastResetStr = settings.get('lastDailyReset', defaultValue: '');

    final todayStr = "${now.year}-${now.month}-${now.day}";
    
    // Daily Reset - Only if moving forward to a new day
    bool isNewDay = false;
    if (lastResetStr != '') {
      final lastDate = DateTime.parse(lastResetStr);
      if (now.isAfter(DateTime(lastDate.year, lastDate.month, lastDate.day, 23, 59, 59))) {
        isNewDay = true;
      }
    } else {
      isNewDay = true; // First run
    }

    if (isNewDay) {
      _flowUsedToday = false;
      _enduranceUsedToday = false;
      _insightUsedToday = false;
      settings.put('flowUsedToday', false);
      settings.put('enduranceUsedToday', false);
      settings.put('insightUsedToday', false);
      settings.put('lastDailyReset', todayStr);
    }

    // Weekly Reset (Monday start)
    int currentWeek = _getWeekOfYear(now);
    int lastWeek = settings.get('lastWeeklyResetWeek', defaultValue: -1);
    
    // Only reset if it's a NEW week (moving forward)
    if (currentWeek > lastWeek || (now.year > settings.get('lastWeeklyResetYear', defaultValue: now.year))) {
      _ironUsedThisWeek = false;
      settings.put('ironUsedThisWeek', false);
      settings.put('lastWeeklyResetWeek', currentWeek);
      settings.put('lastWeeklyResetYear', now.year);
    }
  }

  int _getWeekOfYear(DateTime date) {
    // Basic week of year calculation
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
  int get penaltyDebt => _penaltyDebt;
  int get level => _level;
  int get totalXP => _totalXP;

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

  String get rank {
    if (_totalXP >= 5000) return 'S';
    if (_totalXP >= 2500) return 'A';
    if (_totalXP >= 1000) return 'B';
    if (_totalXP >= 400) return 'C';
    if (_totalXP >= 100) return 'D';
    return 'E';
  }

  // =========================
  // 🔥 ONLY WAY TO ADD XP
  // =========================

  void addXP(int xp) {
    if (xp <= 0) return;

    final settings = HiveService.settings;
    int oldLevel = _level;

    _totalXP += xp;

    // persist XP
    settings.put('lifetimeXP', _totalXP);

    // recompute level
    _level = _calculateLevel(_totalXP);

    // Check for level up points
    if (_level > oldLevel) {
      int pointsEarned = _level - oldLevel;
      _availablePoints += pointsEarned;
      settings.put('availablePoints', _availablePoints);
    }

    notifyListeners();
  }

  // =========================
  // STAT INCREASE METHODS
  // =========================

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

  // =========================
  // ABILITY ACTIVATION
  // =========================

  void activateFlow() {
    if (_flowUnlocked && !_flowUsedToday) {
      _flowActive = true;
      _flowUsedToday = true;
      final settings = HiveService.settings;
      settings.put('flowActive', true);
      settings.put('flowUsedToday', true);
      notifyListeners();
    }
  }

  void activateEndurance() {
    if (_enduranceUnlocked && !_enduranceUsedToday) {
      _enduranceActive = true;
      _enduranceUsedToday = true;
      final settings = HiveService.settings;
      settings.put('enduranceActive', true);
      settings.put('enduranceUsedToday', true);
      notifyListeners();
    }
  }

  void activateInsight() {
    if (_insightUnlocked && !_insightUsedToday) {
      _insightActive = true;
      _insightUsedToday = true;
      final settings = HiveService.settings;
      settings.put('insightActive', true);
      settings.put('insightUsedToday', true);
      notifyListeners();
    }
  }

  void activateIron() {
    if (_ironUnlocked && !_ironUsedThisWeek) {
      _ironActive = true;
      _ironUsedThisWeek = true;
      final settings = HiveService.settings;
      settings.put('ironActive', true);
      settings.put('ironUsedThisWeek', true);
      notifyListeners();
    }
  }

  // =========================
  // ABILITY CONSUMPTION (INTERNAL/UI USE)
  // =========================

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
  // =========================
  // OPTIONAL FORCE SYNC
  // =========================
  // ... (rest of the file kept or removed if not needed)

  // =========================
  // OPTIONAL FORCE SYNC
  // =========================

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

  // =========================
  // PLAYER SETTINGS
  // =========================

  void setPlayer(String name) {
    _name = name;
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

  // =========================
  // STATS
  // =========================

  void updateStat(String key, int delta) {
    if (!_stats.containsKey(key)) return;

    _stats[key] =
        (_stats[key]! + delta).clamp(0, 999);

    notifyListeners();
  }

  // =========================
  // QUESTS
  // =========================

  void updateQuest(String quest, int delta) {
    if (!_questProgress.containsKey(quest)) return;

    _questProgress[quest] =
        (_questProgress[quest]! + delta).clamp(0, 100);

    notifyListeners();
  }
}