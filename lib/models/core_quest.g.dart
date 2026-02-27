// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'core_quest.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CoreQuestAdapter extends TypeAdapter<CoreQuest> {
  @override
  final int typeId = 2;

  @override
  CoreQuest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CoreQuest(
      id: fields[0] as String,
      name: fields[1] as String,
      date: fields[3] as DateTime,
      completed: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CoreQuest obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.completed)
      ..writeByte(3)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreQuestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
