// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dungeon_template.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DungeonTemplateAdapter extends TypeAdapter<DungeonTemplate> {
  @override
  final int typeId = 3;

  @override
  DungeonTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DungeonTemplate(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      category: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DungeonTemplate obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.category);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DungeonTemplateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
