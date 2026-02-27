import 'package:hive/hive.dart';

part 'dungeon.g.dart';

@HiveType(typeId: 1)
class Dungeon extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String date;

  @HiveField(2)
  final String subjectId;

  @HiveField(3)
  final double difficulty;

  @HiveField(4)
  bool completed;

  @HiveField(5)
  final double xpReward;

  Dungeon({
    required this.id,
    required this.date,
    required this.subjectId,
    required this.difficulty,
    this.completed = false,
    required this.xpReward,
  });
}