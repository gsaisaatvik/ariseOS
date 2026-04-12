// ============================================================
//  PREMIUM SERVICE — THE SEAM
//  Phase 1–9: Simulates premium upgrade (flag flip only).
//  Phase 10: Replace initiatePurchase() body with Razorpay call.
//  Everything else in the codebase stays untouched forever.
// ============================================================

import 'package:flutter/material.dart';
import '../player_provider.dart';
import '../models/chronicle_entry.dart';
import '../models/premium_tier.dart';

class PremiumService {
  /// Initiates a premium upgrade.
  ///
  /// SIMULATION MODE (Phase 1–9):
  ///   Instantly upgrades the user without payment.
  ///   Returns true on success.
  ///
  /// PRODUCTION MODE (Phase 10):
  ///   Replace body with RazorpayService.startPayment(...)
  static Future<bool> initiatePurchase({
    required BuildContext context,
    required PlayerProvider player,
  }) async {
    // ── SIMULATION ─────────────────────────────────────────
    // In Phase 10, delete everything below this comment
    // and replace with: return await RazorpayService.startPayment(...)
    player.setPremiumTier(PremiumTier.premium);
    player.addChronicleEntry(ChronicleEntry(
      timestamp: DateTime.now(),
      type: ChronicleType.premiumUpgrade,
      title: 'PREMIUM UNLOCKED',
      detail: 'Full custom quest access now active.',
      xpDelta: null,
    ));
    return true;
    // ── END SIMULATION ─────────────────────────────────────
  }

  /// DEV ONLY — toggle between free and premium for testing.
  /// Remove this method (or gate behind a kDebugMode flag) before release.
  static void devToggle(PlayerProvider player) {
    if (player.tier == PremiumTier.free) {
      player.setPremiumTier(PremiumTier.premium);
    } else {
      player.setPremiumTier(PremiumTier.free);
    }
  }
}
