import 'package:hive/hive.dart';

part 'subject.g.dart';

@HiveType(typeId: 0)
class Subject extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double baseDifficulty;

  @HiveField(3)
  final double scalingFactor;

  Subject({
    required this.id,
    required this.name,
    required this.baseDifficulty,
    required this.scalingFactor,
  });
}