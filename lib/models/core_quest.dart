import 'package:hive/hive.dart';

part 'core_quest.g.dart';

@HiveType(typeId: 2)
class CoreQuest extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  bool completed;

  @HiveField(3)
  final DateTime date;

  CoreQuest({
    required this.id,
    required this.name,
    required this.date,
    this.completed = false,
  });
}