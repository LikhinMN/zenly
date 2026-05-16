// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transcript_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TranscriptModelAdapter extends TypeAdapter<TranscriptModel> {
  @override
  final int typeId = 0;

  @override
  TranscriptModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TranscriptModel(
      id: fields[0] as String,
      text: fields[1] as String,
      createdAt: fields[2] as DateTime,
      durationSeconds: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, TranscriptModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.durationSeconds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranscriptModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
