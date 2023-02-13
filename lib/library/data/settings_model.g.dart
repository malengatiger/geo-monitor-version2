// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsModelAdapter extends TypeAdapter<SettingsModel> {
  @override
  final int typeId = 30;

  @override
  SettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsModel(
      distanceFromProject: fields[0] as int?,
      photoSize: fields[1] as int?,
      maxVideoLengthInMinutes: fields[2] as int?,
      maxAudioLengthInMinutes: fields[3] as int?,
      themeIndex: fields[4] as int?,
      settingsId: fields[5] as String?,
      created: fields[6] as String?,
      organizationId: fields[7] as String?,
      projectId: fields[8] as String?,
      activityStreamHours: fields[9] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.distanceFromProject)
      ..writeByte(1)
      ..write(obj.photoSize)
      ..writeByte(2)
      ..write(obj.maxVideoLengthInMinutes)
      ..writeByte(3)
      ..write(obj.maxAudioLengthInMinutes)
      ..writeByte(4)
      ..write(obj.themeIndex)
      ..writeByte(5)
      ..write(obj.settingsId)
      ..writeByte(6)
      ..write(obj.created)
      ..writeByte(7)
      ..write(obj.organizationId)
      ..writeByte(8)
      ..write(obj.projectId)
      ..writeByte(9)
      ..write(obj.activityStreamHours);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
