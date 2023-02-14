// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_for_upload.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AudioForUploadAdapter extends TypeAdapter<AudioForUpload> {
  @override
  final int typeId = 35;

  @override
  AudioForUpload read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AudioForUpload(
      filePath: fields[0] as String?,
      project: fields[2] as Project?,
      position: fields[5] as Position?,
      audioId: fields[7] as String?,
      date: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AudioForUpload obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.filePath)
      ..writeByte(2)
      ..write(obj.project)
      ..writeByte(5)
      ..write(obj.position)
      ..writeByte(6)
      ..write(obj.date)
      ..writeByte(7)
      ..write(obj.audioId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioForUploadAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
