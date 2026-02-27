// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dungeon.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DungeonAdapter extends TypeAdapter<Dungeon> {
  @override
  final int typeId = 1;

  @override
  Dungeon read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Dungeon(
      id: fields[0] as String,
      date: fields[1] as String,
      subjectId: fields[2] as String,
      difficulty: fields[3] as double,
      completed: fields[4] as bool,
      xpReward: fields[5] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Dungeon obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.subjectId)
      ..writeByte(3)
      ..write(obj.difficulty)
      ..writeByte(4)
      ..write(obj.completed)
      ..writeByte(5)
      ..write(obj.xpReward);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DungeonAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
