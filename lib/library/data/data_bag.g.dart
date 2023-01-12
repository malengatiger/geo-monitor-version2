// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_bag.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DataBagAdapter extends TypeAdapter<DataBag> {
  @override
  final int typeId = 18;

  @override
  DataBag read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DataBag(
      photos: (fields[0] as List?)?.cast<Photo>(),
      videos: (fields[1] as List?)?.cast<Video>(),
      fieldMonitorSchedules: (fields[2] as List?)?.cast<FieldMonitorSchedule>(),
      projectPositions: (fields[3] as List?)?.cast<ProjectPosition>(),
      projects: (fields[4] as List?)?.cast<Project>(),
      date: fields[5] as String?,
      users: (fields[6] as List?)?.cast<User>(),
    );
  }

  @override
  void write(BinaryWriter writer, DataBag obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.photos)
      ..writeByte(1)
      ..write(obj.videos)
      ..writeByte(2)
      ..write(obj.fieldMonitorSchedules)
      ..writeByte(3)
      ..write(obj.projectPositions)
      ..writeByte(4)
      ..write(obj.projects)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.users);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataBagAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
