// ============================================================
//  HUNTER PROFILE — onboarding fitness data
//  Collected once during awakening; drives daily quest generation.
// ============================================================

class HunterProfile {
  final int age;
  final String gender;          // 'male' | 'female' | 'other'
  final String bodyType;        // 'ectomorph' | 'mesomorph' | 'endomorph'
  final String fitnessGoal;     // 'strength' | 'endurance' | 'balance' | 'weight_loss'
  final String experienceLevel; // 'beginner' | 'intermediate' | 'advanced'
  final List<int> trainingDays; // weekday indices Mon=1…Sun=7, min 3 max 7

  const HunterProfile({
    required this.age,
    required this.gender,
    required this.bodyType,
    required this.fitnessGoal,
    required this.experienceLevel,
    required this.trainingDays,
  });

  bool get isTrainingDay =>
      trainingDays.contains(DateTime.now().weekday);

  Map<String, dynamic> toMap() => {
        'age': age,
        'gender': gender,
        'bodyType': bodyType,
        'fitnessGoal': fitnessGoal,
        'experienceLevel': experienceLevel,
        'trainingDays': trainingDays,
      };

  factory HunterProfile.fromMap(Map<dynamic, dynamic> m) => HunterProfile(
        age: (m['age'] as num?)?.toInt() ?? 18,
        gender: m['gender'] as String? ?? 'other',
        bodyType: m['bodyType'] as String? ?? 'mesomorph',
        fitnessGoal: m['fitnessGoal'] as String? ?? 'balance',
        experienceLevel: m['experienceLevel'] as String? ?? 'beginner',
        trainingDays: List<int>.from(
            (m['trainingDays'] as List?)?.map((e) => (e as num).toInt()) ??
                [1, 3, 5]),
      );
}
