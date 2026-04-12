// ============================================================
//  CHRONICLE ENTRY — one log entry in the Shadow Chronicle
// ============================================================

class ChronicleEntry {
  final DateTime timestamp;
  final String type;
  final String title;
  final String detail;
  final int? xpDelta; // positive=gain, negative=loss, null=neutral

  const ChronicleEntry({
    required this.timestamp,
    required this.type,
    required this.title,
    required this.detail,
    this.xpDelta,
  });

  Map<String, dynamic> toMap() => {
        'timestamp': timestamp.toIso8601String(),
        'type': type,
        'title': title,
        'detail': detail,
        'xpDelta': xpDelta,
      };

  factory ChronicleEntry.fromMap(Map<dynamic, dynamic> m) => ChronicleEntry(
        timestamp: DateTime.tryParse(m['timestamp'] as String? ?? '') ??
            DateTime.now(),
        type: m['type'] as String? ?? ChronicleType.xpGain,
        title: m['title'] as String? ?? '',
        detail: m['detail'] as String? ?? '',
        xpDelta: (m['xpDelta'] as num?)?.toInt(),
      );

  String get timeLabel {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final min = timestamp.minute.toString().padLeft(2, '0');
    return '$h:$min';
  }
}

// Type constants
class ChronicleType {
  static const questComplete   = 'quest_complete';
  static const questFail       = 'quest_fail';
  static const customQuestLock = 'custom_quest_lock';
  static const levelUp         = 'level_up';
  static const xpGain          = 'xp_gain';
  static const xpLoss          = 'xp_loss';
  static const penaltyTrigger  = 'penalty_trigger';
  static const penaltyRecovery = 'penalty_recovery';
  static const rewardRedeemed  = 'reward_redeemed';
  static const premiumUpgrade  = 'premium_upgrade';
}
