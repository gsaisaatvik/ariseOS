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
  // STATS
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

    notifyListeners(); // ensure UI sync on startup
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

  Map<String, int> get stats => Map.unmodifiable(_stats);
  Map<String, int> get questProgress =>
      Map.unmodifiable(_questProgress);

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

    _totalXP += xp;

    // persist XP
    settings.put('lifetimeXP', _totalXP);

    // recompute level
    _level = _calculateLevel(_totalXP);

    notifyListeners();
  }

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