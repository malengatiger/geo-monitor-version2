// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_position.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProjectPositionAdapter extends TypeAdapter<ProjectPosition> {
  @override
  final int typeId = 6;

  @override
  ProjectPosition read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectPosition(
      projectName: fields[0] as String?,
      caption: fields[2] as String?,
      projectPositionId: fields[4] as String?,
      created: fields[3] as String?,
      position: fields[6] as Position?,
      placemark: fields[7] as PlaceMark?,
      nearestCities: (fields[8] as List?)?.cast<City>(),
      organizationId: fields[5] as String?,
      projectId: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectPosition obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.projectName)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.caption)
      ..writeByte(3)
      ..write(obj.created)
      ..writeByte(4)
      ..write(obj.projectPositionId)
      ..writeByte(5)
      ..write(obj.organizationId)
      ..writeByte(6)
      ..write(obj.position)
      ..writeByte(7)
      ..write(obj.placemark)
      ..writeByte(8)
      ..write(obj.nearestCities);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectPositionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
