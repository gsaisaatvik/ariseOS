// ============================================================
//  CUSTOM QUEST — premium user-created, permanently locked
//  Cannot be edited or deleted once confirmed.
// ============================================================

class CustomQuest {
  final String id;          // timestamp-based unique key
  final String title;       // user-defined name
  final String targetDesc;  // user-visible target string
  final int xpReward;       // flat +25 XP
  final int xpPenalty;      // flat -50 XP on failure
  bool completed;
  bool failed;
  final String createdDate; // local YYYY-MM-DD

  CustomQuest({
    required this.id,
    required this.title,
    required this.targetDesc,
    this.xpReward = 25,
    this.xpPenalty = 50,
    this.completed = false,
    this.failed = false,
    required this.createdDate,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'targetDesc': targetDesc,
        'xpReward': xpReward,
        'xpPenalty': xpPenalty,
        'completed': completed,
        'failed': failed,
        'createdDate': createdDate,
      };

  factory CustomQuest.fromMap(Map<dynamic, dynamic> m) => CustomQuest(
        id: m['id'] as String,
        title: m['title'] as String,
        targetDesc: m['targetDesc'] as String? ?? '',
        xpReward: (m['xpReward'] as num?)?.toInt() ?? 25,
        xpPenalty: (m['xpPenalty'] as num?)?.toInt() ?? 50,
        completed: m['completed'] as bool? ?? false,
        failed: m['failed'] as bool? ?? false,
        createdDate: m['createdDate'] as String? ?? '',
      );
}
