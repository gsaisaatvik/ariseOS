import 'package:hive/hive.dart';

part 'dungeon_template.g.dart';

@HiveType(typeId: 3)
class DungeonTemplate extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String category;

  DungeonTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
  });
}