// ============================================================
//  REDEMPTION ITEMS — Arise OS
//
//  Two tiers of items:
//    kRedemptionItems → purchased with WalletXP
//    kCrystalItems    → purchased with Mana Crystals
//
//  Items are consumed on purchase (no inventory hoarding).
//  Effect items set an activeItemEffect flag in Hive.
// ============================================================

class RedemptionItem {
  final String id;
  final String name;
  final String description;
  final String realLifeEffect;
  final int costXP;        // 0 if crystal item
  final int costCrystals;  // 0 if XP item
  final String rankRequired; // minimum rank to purchase
  final String iconCode;     // material icon codepoint as hex string
  final String? effectId;    // if set, activates this item effect flag

  const RedemptionItem({
    required this.id,
    required this.name,
    required this.description,
    required this.realLifeEffect,
    this.costXP = 0,
    this.costCrystals = 0,
    required this.rankRequired,
    required this.iconCode,
    this.effectId,
  });
}

// ── WalletXP Shop Items ──────────────────────────────────────────
const List<RedemptionItem> kRedemptionItems = [
  RedemptionItem(
    id: 'focus_tea',
    name: 'CLARITY DRAUGHT',
    description: 'A cognitive enhancer for the next deep work session.',
    realLifeEffect: '+20% Perception bonus on next Deep Work session.',
    costXP: 300,
    rankRequired: 'D',
    iconCode: 'e1b1', // local_cafe
    effectId: 'clarity_draught',
  ),
  RedemptionItem(
    id: 'strength_wrap',
    name: 'IRON BINDING',
    description: 'Heavy wristbands. Suffering builds power.',
    realLifeEffect: '×1.5 STR XP bonus for today\'s physical session.',
    costXP: 400,
    rankRequired: 'D',
    iconCode: 'e8d0', // fitness_center
    effectId: 'iron_binding',
  ),
  RedemptionItem(
    id: 'nap_voucher',
    name: 'NAP PROTOCOL',
    description: 'System-authorized rest. Guilt-free.',
    realLifeEffect: 'Guilt-free 30-min nap. +10 HP on use.',
    costXP: 500,
    rankRequired: 'D',
    iconCode: 'e176', // hotel
    effectId: 'nap_protocol',
  ),
  RedemptionItem(
    id: 'social_escape',
    name: 'TACTICAL RETREAT',
    description: 'One social obligation waived. No guilt logged.',
    realLifeEffect: 'Skip one social event without sin penalty.',
    costXP: 600,
    rankRequired: 'D',
    iconCode: 'e5c8', // exit_to_app
    effectId: 'tactical_retreat',
  ),
  RedemptionItem(
    id: 'cheat_meal_pass',
    name: 'NUTRIENT OVERRIDE',
    description: 'System clearance for one dietary deviation.',
    realLifeEffect: 'Next food/meal sin confession costs 0 XP.',
    costXP: 800,
    rankRequired: 'C',
    iconCode: 'e56c', // restaurant
    effectId: 'nutrient_override',
  ),
  RedemptionItem(
    id: 'gaming_permit',
    name: 'COMBAT SIMULATION',
    description: 'Authorized combat training. Duration: 1 hour.',
    realLifeEffect: '1 hour unrestricted gaming — no sin logged.',
    costXP: 1000,
    rankRequired: 'C',
    iconCode: 'e338', // sports_esports
    effectId: 'combat_simulation',
  ),
];

// ── Mana Crystal Shop Items ──────────────────────────────────────
const List<RedemptionItem> kCrystalItems = [
  RedemptionItem(
    id: 'crystal_surge',
    name: 'CRYSTAL SURGE',
    description: 'Compress mana energy into raw XP acceleration.',
    realLifeEffect: '×2 XP on your next directive session.',
    costCrystals: 3,
    rankRequired: 'D',
    iconCode: 'e19c', // bolt
    effectId: 'crystal_surge',
  ),
  RedemptionItem(
    id: 'rune_stone',
    name: 'RUNE STONE',
    description: 'Ancient knowledge encoded in crystal form.',
    realLifeEffect: '+1 free stat point awarded immediately.',
    costCrystals: 5,
    rankRequired: 'D',
    iconCode: 'e86f', // menu_book
    effectId: null, // direct effect, no flag needed
  ),
  RedemptionItem(
    id: 'restoration_potion',
    name: 'RESTORATION POTION',
    description: 'Full recovery from the System\'s debt chains.',
    realLifeEffect: 'Reset Wallet XP debt to 0 (from negative).',
    costCrystals: 10,
    rankRequired: 'C',
    iconCode: 'e798', // healing
    effectId: null, // direct effect
  ),
];

// ── Rank order for comparisons (lower index = higher rank) ────────
const List<String> kRankOrder = ['GOD', 'S', 'A', 'B', 'C', 'D', 'E'];

/// Returns true if [playerRank] meets or exceeds [requiredRank].
bool meetsRankRequirement(String playerRank, String requiredRank) {
  final playerIdx = kRankOrder.indexOf(playerRank);
  final reqIdx = kRankOrder.indexOf(requiredRank);
  if (playerIdx == -1 || reqIdx == -1) return false;
  return playerIdx <= reqIdx; // lower index = higher rank
}
