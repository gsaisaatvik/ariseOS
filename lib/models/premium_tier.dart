// ============================================================
//  PREMIUM TIER — defines tiers and feature limits
//  Seam designed for Razorpay plug-in later (Phase 10)
// ============================================================

enum PremiumTier { free, premium, superPremium }

class TierLimits {
  static int customQuestLimit(PremiumTier t) => switch (t) {
        PremiumTier.free         => 0,
        PremiumTier.premium      => 2,
        PremiumTier.superPremium => 3,
      };

  static bool canCreateCustomQuests(PremiumTier t) =>
      customQuestLimit(t) > 0;

  static bool canModifyOneSystemQuest(PremiumTier t) =>
      t == PremiumTier.superPremium;

  static String tierLabel(PremiumTier t) => switch (t) {
        PremiumTier.free         => 'FREE',
        PremiumTier.premium      => 'PREMIUM',
        PremiumTier.superPremium => 'SUPER PREMIUM',
      };
}
