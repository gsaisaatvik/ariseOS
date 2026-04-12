// ============================================================
//  DAILY QUEST — auto-generated from HunterProfile
//  4 per day, non-editable, non-deletable.
// ============================================================

class DailyQuest {
  final String id;           // stable key e.g. 'pushups'
  final String title;        // 'Push-ups'
  final String statAffected; // 'STR' | 'AGI' | 'INT' | 'VIT'
  final int target;          // reps / km / min
  final String unit;         // 'reps' | 'km' | 'min'
  int progress;
  bool completed;
  bool failed;               // set at midnight if incomplete
  final int xpReward;
  final int xpPenalty;

  DailyQuest({
    required this.id,
    required this.title,
    required this.statAffected,
    required this.target,
    required this.unit,
    this.progress = 0,
    this.completed = false,
    this.failed = false,
    required this.xpReward,
    required this.xpPenalty,
  });

  double get progressFraction =>
      target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'statAffected': statAffected,
        'target': target,
        'unit': unit,
        'progress': progress,
        'completed': completed,
        'failed': failed,
        'xpReward': xpReward,
        'xpPenalty': xpPenalty,
      };

  factory DailyQuest.fromMap(Map<dynamic, dynamic> m) => DailyQuest(
        id: m['id'] as String,
        title: m['title'] as String,
        statAffected: m['statAffected'] as String? ?? 'STR',
        target: (m['target'] as num).toInt(),
        unit: m['unit'] as String? ?? 'reps',
        progress: (m['progress'] as num?)?.toInt() ?? 0,
        completed: m['completed'] as bool? ?? false,
        failed: m['failed'] as bool? ?? false,
        xpReward: (m['xpReward'] as num?)?.toInt() ?? 50,
        xpPenalty: (m['xpPenalty'] as num?)?.toInt() ?? 100,
      );
}
