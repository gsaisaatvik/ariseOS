/// Player Agency — System Abilities (Phase 3)
///
/// Abilities unlock at fixed levels and modify real gameplay systems.
enum SystemAbilityId {
  focusBoost,
  intelBurst,
  disciplineShield,
  overrideNextDirective,
}

enum SystemAbilityEffectType {
  focusBoost,
  intelBurst,
  disciplineShield,
  overrideNextDirective,
}

class SystemAbilityDefinition {
  const SystemAbilityDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.unlockLevel,
    required this.effectType,
  });

  final SystemAbilityId id;
  final String name;
  final String description;
  final int unlockLevel;
  final SystemAbilityEffectType effectType;
}

const Map<SystemAbilityId, SystemAbilityDefinition> systemAbilities = {
  SystemAbilityId.focusBoost: SystemAbilityDefinition(
    id: SystemAbilityId.focusBoost,
    name: 'FOCUS BOOST',
    description: 'Reduce your next directive session time by 20%.',
    unlockLevel: 3,
    effectType: SystemAbilityEffectType.focusBoost,
  ),
  SystemAbilityId.intelBurst: SystemAbilityDefinition(
    id: SystemAbilityId.intelBurst,
    name: 'INTEL BURST',
    description: 'Double XP for your next directive completion.',
    unlockLevel: 5,
    effectType: SystemAbilityEffectType.intelBurst,
  ),
  SystemAbilityId.disciplineShield: SystemAbilityDefinition(
    id: SystemAbilityId.disciplineShield,
    name: 'DISCIPLINE SHIELD',
    description: 'Ignore the next penalty (abort/sin/wallet penalty).',
    unlockLevel: 8,
    effectType: SystemAbilityEffectType.disciplineShield,
  ),
  SystemAbilityId.overrideNextDirective: SystemAbilityDefinition(
    id: SystemAbilityId.overrideNextDirective,
    name: 'OVERRIDE',
    description: 'Unlock a new directive even while another is in progress.',
    unlockLevel: 10,
    effectType: SystemAbilityEffectType.overrideNextDirective,
  ),
};

