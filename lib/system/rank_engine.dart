import 'dart:math' as math;

/// Rank is separate from Level.
///
/// Rank is computed from a weighted hybrid of:
/// - lifetime XP (progress)
/// - streak days (consistency)
/// - reliability (completion rate / failure rate)
///
/// This is config-driven (thresholds/weights) so it can be extended later.
class RankEngine {
  RankEngine._();

  static const List<String> ordered = ['S', 'A', 'B', 'C', 'D', 'E'];

  static String computeRank({
    required int lifetimeXp,
    required int streakDays,
    required int totalCompletions,
    required int totalFailures,
  }) {
    final xpScore = _lifetimeXpScore(lifetimeXp);
    final consistencyScore = _consistencyScore(streakDays);
    final reliabilityScore = _reliabilityScore(totalCompletions, totalFailures);

    final score =
        xpScore * _RankConfig.weights.lifetimeXp +
        consistencyScore * _RankConfig.weights.consistency +
        reliabilityScore * _RankConfig.weights.reliability;

    for (final t in _RankConfig.thresholds) {
      if (score >= t.minScore) return t.rank;
    }
    return 'E';
  }

  static String titleFor({
    required String rank,
    required int streakDays,
    required double reliability,
  }) {
    // Titles are intentionally simple and extensible.
    if (rank == 'S') return 'SYSTEM EXEMPLAR';
    if (rank == 'A') return 'ELITE HUNTER';
    if (rank == 'B') return 'VETERAN';
    if (rank == 'C') return 'OPERATOR';
    if (rank == 'D') return 'INITIATE';

    // Rank E: reflect reliability/consistency.
    if (streakDays >= 3) return 'REBUILDING';
    if (reliability >= 0.65) return 'UNSTABLE POTENTIAL';
    return 'UNREGISTERED';
  }

  static double reliability({
    required int totalCompletions,
    required int totalFailures,
  }) {
    return _reliabilityScore(totalCompletions, totalFailures);
  }

  static double _lifetimeXpScore(int xp) {
    // log10 curve: fast early progress, slow later.
    // 1,000,000 lifetimeXP => ~1.0
    final clamped = math.max(0, xp);
    final v = math.log(clamped + 1) / math.ln10;
    return (v / 6.0).clamp(0.0, 1.0);
  }

  static double _consistencyScore(int streakDays) {
    // 30 day streak => 1.0
    return (streakDays / 30.0).clamp(0.0, 1.0);
  }

  static double _reliabilityScore(int completions, int failures) {
    final total = completions + failures;
    if (total <= 0) return 0.50; // neutral prior
    return (completions / total).clamp(0.0, 1.0);
  }
}

/// Tunable rank configuration (no gameplay logic here).
class _RankConfig {
  _RankConfig._();

  static const _RankWeights weights = _RankWeights(
    lifetimeXp: 0.55,
    consistency: 0.25,
    reliability: 0.20,
  );

  static const List<_RankThreshold> thresholds = [
    _RankThreshold(rank: 'S', minScore: 0.92),
    _RankThreshold(rank: 'A', minScore: 0.80),
    _RankThreshold(rank: 'B', minScore: 0.65),
    _RankThreshold(rank: 'C', minScore: 0.50),
    _RankThreshold(rank: 'D', minScore: 0.35),
    _RankThreshold(rank: 'E', minScore: 0.00),
  ];
}

class _RankThreshold {
  const _RankThreshold({
    required this.rank,
    required this.minScore,
  });
  final String rank;
  final double minScore;
}

class _RankWeights {
  const _RankWeights({
    required this.lifetimeXp,
    required this.consistency,
    required this.reliability,
  });
  final double lifetimeXp;
  final double consistency;
  final double reliability;
}

