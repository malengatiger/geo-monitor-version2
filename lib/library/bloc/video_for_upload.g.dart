// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_for_upload.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VideoForUploadAdapter extends TypeAdapter<VideoForUpload> {
  @override
  final int typeId = 34;

  @override
  VideoForUpload read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VideoForUpload(
      filePath: fields[0] as String?,
      videoId: fields[7] as String?,
      thumbnailPath: fields[1] as String?,
      projectPositionId: fields[3] as String?,
      projectPolygonId: fields[4] as String?,
      project: fields[2] as Project?,
      position: fields[5] as Position?,
      durationInSeconds: fields[8] as int?,
      height: fields[9] as double?,
      width: fields[10] as double?,
      date: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, VideoForUpload obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.filePath)
      ..writeByte(1)
      ..write(obj.thumbnailPath)
      ..writeByte(2)
      ..write(obj.project)
      ..writeByte(3)
      ..write(obj.projectPositionId)
      ..writeByte(4)
      ..write(obj.projectPolygonId)
      ..writeByte(5)
      ..write(obj.position)
      ..writeByte(6)
      ..write(obj.date)
      ..writeByte(7)
      ..write(obj.videoId)
      ..writeByte(8)
      ..write(obj.durationInSeconds)
      ..writeByte(9)
      ..write(obj.height)
      ..writeByte(10)
      ..write(obj.width);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoForUploadAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
