import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'player_provider.dart';
import 'system/skill_definitions.dart';
import 'ui/theme/app_colors.dart';
import 'ui/theme/app_text_styles.dart';
import 'ui/widgets/widgets.dart';

// ============================================================
//  SKILL MATRIX — Compact System Interface
//  Rules:
//  · Cards ~90px — scan-friendly
//  · No category labels inside cards
//  · No verbose descriptions
//  · Locked = dimmed (opacity 0.35)
//  · Only unlocked + not-superseded = glow
//  · Filter tabs = horizontally scrollable
// ============================================================

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});
  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  SkillCategory? _filter;

  static const _tabs = <SkillCategory?>[
    null,
    SkillCategory.performance,
    SkillCategory.control,
    SkillCategory.recovery,
    SkillCategory.identity,
  ];

  static const _tabLabels = ['ALL', 'PERFORMANCE', 'CONTROL', 'RECOVERY', 'IDENTITY'];

  static const _categoryColors = {
    SkillCategory.control: AppColors.primaryBlue,
    SkillCategory.recovery: AppColors.success,
    SkillCategory.performance: AppColors.primaryViolet,
    SkillCategory.identity: AppColors.warning,
  };

  // Build a short 1-line effect string from SkillDefinition
  String _effectLine(SkillDefinition s) {
    if (s.xpModifier > 0) {
      final pct = (s.xpModifier * 100).round();
      final cond = s.conditionMinutes != null
          ? ' after ${s.conditionMinutes} min'
          : ' all sessions';
      return '+$pct% XP$cond';
    }
    if (s.penaltyModifier != null) {
      final pm = s.penaltyModifier!;
      if (pm < 1.0) {
        final pct = ((1.0 - pm) * 100).round();
        return '-$pct% miss penalty';
      } else {
        final pct = ((pm - 1.0) * 100).round();
        return 'Penalties ×${pm.toStringAsFixed(1)}  (+$pct%)';
      }
    }
    return '—';
  }

  Set<String> _superseded(int level) {
    final result = <String>{};
    final Map<String, List<SkillDefinition>> byFamily = {};
    for (final s in kSkillRoster) {
      if (s.family == null) continue;
      byFamily.putIfAbsent(s.family!, () => []).add(s);
    }
    for (final family in byFamily.values) {
      final unlocked = family.where((s) => level >= s.unlockLevel).toList();
      if (unlocked.length <= 1) continue;
      unlocked.sort((a, b) {
        final aM = a.xpModifier + (a.penaltyModifier ?? 0.0);
        final bM = b.xpModifier + (b.penaltyModifier ?? 0.0);
        return bM.compareTo(aM);
      });
      for (int i = 1; i < unlocked.length; i++) {
        result.add(unlocked[i].id);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final level = player.level;

    final sorted = List<SkillDefinition>.from(kSkillRoster)
      ..sort((a, b) => a.unlockLevel.compareTo(b.unlockLevel));

    final filtered = _filter == null
        ? sorted
        : sorted.where((s) => s.category == _filter).toList();

    final unlockedCount =
        kSkillRoster.where((s) => level >= s.unlockLevel).length;
    final supersededIds = _superseded(level);

    // Compute max bonus at this level (long session)
    final bonusXp = SkillEngine.applyXpModifiers(
        rawXp: 100, minutes: 999, level: level);
    final bonusPct = bonusXp - 100;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: HolographicPanel(
              header: const SystemHeaderBar(label: 'SKILL MATRIX'),
              emphasize: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LEVEL $level OPERATIVE',
                              style: AppTextStyles.headerSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$unlockedCount / ${kSkillRoster.length} PROTOCOLS ACTIVE',
                              style: AppTextStyles.systemLabel.copyWith(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (bonusPct > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primaryViolet.withOpacity(0.12),
                            border: Border.all(
                                color: AppColors.primaryViolet
                                    .withOpacity(0.45)),
                          ),
                          child: Text(
                            'MAX +$bonusPct% XP',
                            style: AppTextStyles.systemLabel.copyWith(
                              color: AppColors.primaryViolet,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── FILTER TABS ──────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final isSelected = _filter == _tabs[i];
                final color = _tabs[i] == null
                    ? AppColors.primaryBlue
                    : _categoryColors[_tabs[i]]!;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _filter = _tabs[i]),
                      borderRadius: BorderRadius.circular(2),
                      splashColor: color.withOpacity(0.15),
                      highlightColor: color.withOpacity(0.08),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withOpacity(0.12)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? color : Colors.white12,
                            width: isSelected ? 1.2 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.20),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          _tabLabels[i],
                          style: AppTextStyles.systemLabel.copyWith(
                            color: isSelected ? color : AppColors.textDisabled,
                            fontSize: 9,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 8),

          // ── SKILL LIST ───────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'NO SKILLS IN THIS CATEGORY',
                      style: AppTextStyles.systemLabel.copyWith(
                          color: AppColors.textDisabled, fontSize: 9),
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final skill = filtered[i];
                      final isUnlocked = level >= skill.unlockLevel;
                      final isSuperseded =
                          supersededIds.contains(skill.id);
                      final accentColor =
                          _categoryColors[skill.category]!;
                      final glowing = isUnlocked && !isSuperseded;

                      // Proximity-based opacity for locked skills:
                      // closer to unlock = brighter, further = dimmer
                      double lockedOpacity = 0.30;
                      if (!isUnlocked) {
                        final away = skill.unlockLevel - level;
                        if (away <= 3) lockedOpacity = 0.65;
                        else if (away <= 8) lockedOpacity = 0.48;
                        else lockedOpacity = 0.30;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _SkillRow(
                          skill: skill,
                          isUnlocked: isUnlocked,
                          isSuperseded: isSuperseded,
                          glowing: glowing,
                          levelsAway: skill.unlockLevel - level,
                          lockedOpacity: lockedOpacity,
                          accentColor: accentColor,
                          effectLine: _effectLine(skill),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  COMPACT SKILL ROW (~90px)
// ============================================================
class _SkillRow extends StatelessWidget {
  final SkillDefinition skill;
  final bool isUnlocked;
  final bool isSuperseded;
  final bool glowing;
  final int levelsAway;
  final double lockedOpacity;
  final Color accentColor;
  final String effectLine;

  const _SkillRow({
    required this.skill,
    required this.isUnlocked,
    required this.isSuperseded,
    required this.glowing,
    required this.levelsAway,
    required this.lockedOpacity,
    required this.accentColor,
    required this.effectLine,
  });

  @override
  Widget build(BuildContext context) {
    // Proximity-aware opacity
    final double cardOpacity = !isUnlocked
        ? lockedOpacity
        : (isSuperseded ? 0.55 : 1.0);

    final borderColor = glowing
        ? accentColor.withOpacity(0.38)
        : Colors.white.withOpacity(0.06);

    final bgColor = glowing
        ? accentColor.withOpacity(0.05)
        : Colors.white.withOpacity(0.015);

    return Opacity(
      opacity: cardOpacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 1.0),
        ),
        child: Row(
          children: [
            // Left: status glyph
            _Glyph(
                isUnlocked: isUnlocked,
                isSuperseded: isSuperseded,
                color: glowing ? accentColor : AppColors.textDisabled),

            const SizedBox(width: 12),

            // Center: name + effect
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    skill.name,
                    style: AppTextStyles.headerSmall.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      // Always full white — locked cards are dimmed via Opacity wrapper
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isSuperseded
                        ? 'Superseded — $effectLine'
                        : effectLine,
                    style: AppTextStyles.bodySecondary.copyWith(
                      fontSize: 11,
                      height: 1.2,
                      // 70% opacity — effect text
                      color: Colors.white.withOpacity(0.70),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isUnlocked) ...[
                    const SizedBox(height: 3),
                    Text(
                      // "UNLOCK IN N LEVELS" format
                      levelsAway == 1
                          ? 'UNLOCK IN 1 LEVEL'
                          : 'UNLOCK IN $levelsAway LEVELS',
                      style: AppTextStyles.systemLabel.copyWith(
                        fontSize: 8.5,
                        // 50% opacity — tertiary info
                        color: Colors.white.withOpacity(0.50),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Right: level badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(glowing ? 0.10 : 0.04),
                border: Border.all(
                  color: accentColor.withOpacity(glowing ? 0.35 : 0.12),
                ),
              ),
              child: Text(
                'LV.${skill.unlockLevel}',
                style: AppTextStyles.systemLabel.copyWith(
                  color: glowing ? accentColor : AppColors.textDisabled,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Compact status glyph (left of card)
class _Glyph extends StatelessWidget {
  final bool isUnlocked;
  final bool isSuperseded;
  final Color color;
  const _Glyph(
      {required this.isUnlocked,
      required this.isSuperseded,
      required this.color});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    double size;
    double opacity;

    if (!isUnlocked) {
      icon = Icons.lock_rounded;
      size = 13;   // smaller for locked
      opacity = 0.45; // dimmer — doesn't compete with name
    } else if (isSuperseded) {
      icon = Icons.arrow_upward_rounded;
      size = 14;
      opacity = 0.70;
    } else {
      icon = Icons.bolt_rounded;
      size = 16;
      opacity = 1.0;
    }
    return Opacity(
      opacity: opacity,
      child: Icon(icon, size: size, color: color),
    );
  }
}
