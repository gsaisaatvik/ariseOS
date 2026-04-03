// ============================================================
//  RANK-UP EVENT — Arise OS
//
//  Fired when the player's computed rank changes to a new tier.
//  Queued separately from LevelUpEvents.
//  Consumed by the Dashboard overlay listener.
// ============================================================

class RankUpEvent {
  final String fromRank;
  final String toRank;
  final String newJobLabel;
  final String systemVoiceLine;

  const RankUpEvent({
    required this.fromRank,
    required this.toRank,
    required this.newJobLabel,
    required this.systemVoiceLine,
  });

  static String voiceLineFor(String toRank) {
    switch (toRank) {
      case 'D':
        return 'The System acknowledges your first step. The hunt begins.';
      case 'C':
        return 'Awakening confirmed. You are no longer merely registered.';
      case 'B':
        return 'Shadow Vanguard. The system has elevated your authority.';
      case 'A':
        return 'Sovereign Blade. Only one rank remains between you and absolue dominion.';
      case 'S':
        return 'Dark Monarch. The System bows to none but you. ARISE.';
      case 'GOD':
        return 'Beyond rank. Beyond limitation. You have transcended the system itself.';
      default:
        return 'Rank status updated.';
    }
  }
}
