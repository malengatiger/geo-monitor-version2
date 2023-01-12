// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VideoAdapter extends TypeAdapter<Video> {
  @override
  final int typeId = 10;

  @override
  Video read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Video(
      url: fields[0] as String?,
      caption: fields[1] as String?,
      projectPositionId: fields[5] as String?,
      created: fields[2] as String?,
      userId: fields[6] as String?,
      userName: fields[7] as String?,
      projectPosition: fields[9] as Position?,
      distanceFromProjectPosition: fields[10] as double?,
      projectId: fields[11] as String?,
      thumbnailUrl: fields[3] as String?,
      videoId: fields[4] as String?,
      organizationId: fields[8] as String?,
      projectName: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Video obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.caption)
      ..writeByte(2)
      ..write(obj.created)
      ..writeByte(3)
      ..write(obj.thumbnailUrl)
      ..writeByte(4)
      ..write(obj.videoId)
      ..writeByte(5)
      ..write(obj.projectPositionId)
      ..writeByte(6)
      ..write(obj.userId)
      ..writeByte(7)
      ..write(obj.userName)
      ..writeByte(8)
      ..write(obj.organizationId)
      ..writeByte(9)
      ..write(obj.projectPosition)
      ..writeByte(10)
      ..write(obj.distanceFromProjectPosition)
      ..writeByte(11)
      ..write(obj.projectId)
      ..writeByte(12)
      ..write(obj.projectName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
