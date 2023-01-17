// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization_registration_bag.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrganizationRegistrationBagAdapter
    extends TypeAdapter<OrganizationRegistrationBag> {
  @override
  final int typeId = 21;

  @override
  OrganizationRegistrationBag read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrganizationRegistrationBag(
      organization: fields[0] as Organization?,
      sampleProjectPosition: fields[1] as ProjectPosition?,
      sampleUsers: (fields[2] as List?)?.cast<User>(),
      sampleProject: fields[4] as Project?,
      date: fields[3] as String?,
      latitude: fields[5] as double?,
      longitude: fields[6] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, OrganizationRegistrationBag obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.organization)
      ..writeByte(1)
      ..write(obj.sampleProjectPosition)
      ..writeByte(2)
      ..write(obj.sampleUsers)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.sampleProject)
      ..writeByte(5)
      ..write(obj.latitude)
      ..writeByte(6)
      ..write(obj.longitude);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizationRegistrationBagAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
