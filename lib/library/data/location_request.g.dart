// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_request.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocationRequestAdapter extends TypeAdapter<LocationRequest> {
  @override
  final int typeId = 23;

  @override
  LocationRequest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocationRequest(
      organizationId: fields[0] as String?,
      administratorId: fields[1] as String?,
      created: fields[2] as String?,
      response: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LocationRequest obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.organizationId)
      ..writeByte(1)
      ..write(obj.administratorId)
      ..writeByte(2)
      ..write(obj.created)
      ..writeByte(3)
      ..write(obj.response);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationRequestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
