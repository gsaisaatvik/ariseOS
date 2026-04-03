// ============================================================
//  SKILL DEFINITIONS — ARISE OS V1 Skill Matrix
//
//  Skills = system capabilities that unlock as the player levels up.
//  They are modifiers, not collectibles.
//
//  Same-family rule:
//    Skills sharing the same `family` string do NOT stack.
//    Only the one with the highest xpModifier or penaltyModifier applies.
//    lower-tier skills in the same family are automatically superseded.
//
//  XP formula:
//    Final XP = Base XP × (1 + sum of best-per-family modifiers)
//    Modifiers are ADDITIVE, never multiplicative.
// ============================================================

enum SkillCategory { control, recovery, performance, identity }

class SkillDefinition {
  final String id;
  final String name;
  final SkillCategory category;

  /// Family key. Skills in the same family do NOT stack.
  /// Only the highest modifier in the family is applied.
  /// Null means skill is independent (always included if unlocked).
  final String? family;

  final int unlockLevel;
  final String description;

  /// Additive XP modifier fraction. 0.10 = +10% XP.
  final double xpModifier;

  /// Optional: only apply xpModifier if session exceeds this many minutes.
  final int? conditionMinutes;

  /// Optional: multiplies penalty amount (e.g. 0.5 = 50% less loss).
  /// NEGATIVE means penalty reduction. POSITIVE > 1.0 means amplification.
  final double? penaltyModifier;

  const SkillDefinition({
    required this.id,
    required this.name,
    required this.category,
    this.family,
    required this.unlockLevel,
    required this.description,
    this.xpModifier = 0.0,
    this.conditionMinutes,
    this.penaltyModifier,
  });
}

// ============================================================
//  V1 SKILL ROSTER
// ============================================================
const List<SkillDefinition> kSkillRoster = [
  // ── TIER 1 ─────────────────────────────────────────────────

  SkillDefinition(
    id: 'second_chance',
    name: 'SECOND CHANCE',
    category: SkillCategory.recovery,
    family: 'miss_reduction',
    unlockLevel: 5,
    description: 'First daily miss penalty reduced by 50%.',
    penaltyModifier: 0.50,
  ),

  SkillDefinition(
    id: 'flow_state_i',
    name: 'FLOW STATE I',
    category: SkillCategory.performance,
    family: 'flow',
    unlockLevel: 10,
    description: '+10% XP for study sessions exceeding 30 minutes.',
    xpModifier: 0.10,
    conditionMinutes: 30,
  ),

  SkillDefinition(
    id: 'focused_strike',
    name: 'FOCUSED STRIKE',
    category: SkillCategory.control,
    family: 'base_xp',
    unlockLevel: 15,
    description: '+5% XP on all study sessions, no conditions.',
    xpModifier: 0.05,
  ),

  // ── TIER 2 ─────────────────────────────────────────────────

  SkillDefinition(
    id: 'recovery_mode',
    name: 'RECOVERY MODE',
    category: SkillCategory.recovery,
    family: 'miss_reduction',
    unlockLevel: 20,
    description: 'All XP penalties reduced by 25%. Supersedes Second Chance.',
    penaltyModifier: 0.75,
  ),

  SkillDefinition(
    id: 'xp_amplifier',
    name: 'XP AMPLIFIER',
    category: SkillCategory.performance,
    family: 'base_xp',
    unlockLevel: 25,
    description: '+20% XP on all sessions. Supersedes Focused Strike.',
    xpModifier: 0.20,
  ),

  SkillDefinition(
    id: 'flow_state_ii',
    name: 'FLOW STATE II',
    category: SkillCategory.performance,
    family: 'flow',
    unlockLevel: 30,
    description: '+15% XP for sessions exceeding 45 minutes. Supersedes Flow State I.',
    xpModifier: 0.15,
    conditionMinutes: 45,
  ),

  // ── TIER 3 ─────────────────────────────────────────────────

  SkillDefinition(
    id: 'iron_discipline',
    name: 'IRON DISCIPLINE',
    category: SkillCategory.control,
    family: 'penalty_cap',
    unlockLevel: 40,
    description: 'XP penalty per event capped at 70% of current wallet balance.',
    penaltyModifier: 0.70,
  ),

  // ── TIER 4 — ENDGAME ───────────────────────────────────────

  SkillDefinition(
    id: 'monarch_protocol',
    name: 'MONARCH PROTOCOL',
    category: SkillCategory.identity,
    family: 'flow',
    unlockLevel: 50,
    description: '+30% XP for sessions exceeding 60 minutes. Supersedes Flow State II.',
    xpModifier: 0.30,
    conditionMinutes: 60,
  ),

  SkillDefinition(
    id: 'no_excuse_protocol',
    name: 'NO EXCUSE PROTOCOL',
    category: SkillCategory.identity,
    family: 'penalty_cap',
    unlockLevel: 50,
    description: 'All XP penalties amplified ×1.5. Replaces Iron Discipline. For those who demand consequence.',
    penaltyModifier: 1.50,
  ),
];

// ============================================================
//  SKILL ENGINE — XP + PENALTY MODIFIER COMPUTATION
// ============================================================
class SkillEngine {
  SkillEngine._();

  /// Returns all skills unlocked for the given level.
  static List<SkillDefinition> activeSkills(int level) {
    return kSkillRoster.where((s) => level >= s.unlockLevel).toList();
  }

  /// Applies the best-per-family XP modifier to rawXp.
  ///
  /// [minutes] — session duration; used to check conditionMinutes.
  /// Returns final adjusted XP.
  static int applyXpModifiers({
    required int rawXp,
    required int minutes,
    required int level,
  }) {
    final unlocked = activeSkills(level);
    final Map<String, SkillDefinition> bestByFamily = {};
    final List<double> modifiers = [];

    for (final skill in unlocked) {
      if (skill.xpModifier == 0.0) continue; // penalty-only skill, skip
      if (skill.conditionMinutes != null && minutes < skill.conditionMinutes!) continue;

      if (skill.family == null) {
        modifiers.add(skill.xpModifier);
      } else {
        final existing = bestByFamily[skill.family];
        if (existing == null || skill.xpModifier > existing.xpModifier) {
          bestByFamily[skill.family!] = skill;
        }
      }
    }
    modifiers.addAll(bestByFamily.values.map((s) => s.xpModifier));

    final totalModifier = modifiers.fold(0.0, (a, b) => a + b);
    if (totalModifier == 0.0) return rawXp;
    return (rawXp * (1.0 + totalModifier)).round();
  }

  /// Returns the penalty multiplier from the best-per-family penalty skill.
  ///
  /// < 1.0 = penalty reduction  |  > 1.0 = penalty amplification
  /// Returns 1.0 if no penalty skill is active.
  static double penaltyMultiplier(int level) {
    final unlocked = activeSkills(level);
    final Map<String, SkillDefinition> bestByFamily = {};
    final List<double> multipliers = [];

    for (final skill in unlocked) {
      if (skill.penaltyModifier == null) continue;

      if (skill.family == null) {
        multipliers.add(skill.penaltyModifier!);
      } else {
        final existing = bestByFamily[skill.family];
        // "Best" for penalty = highest numeric value wins
        // (1.50 amplifier wins over 0.50 reducer within same family)
        if (existing == null ||
            skill.penaltyModifier! > existing.penaltyModifier!) {
          bestByFamily[skill.family!] = skill;
        }
      }
    }
    multipliers.addAll(bestByFamily.values.map((s) => s.penaltyModifier!));

    if (multipliers.isEmpty) return 1.0;
    return multipliers.fold(1.0, (a, b) => a * b);
  }

  /// Display utility: returns the name/label for a SkillCategory.
  static String categoryLabel(SkillCategory cat) {
    switch (cat) {
      case SkillCategory.control:
        return 'CONTROL';
      case SkillCategory.recovery:
        return 'RECOVERY';
      case SkillCategory.performance:
        return 'PERFORMANCE';
      case SkillCategory.identity:
        return 'IDENTITY';
    }
  }
}
