import 'dart:async';

import '../api/data_api.dart';
import '../data/data_bag.dart';
import '../data/questionnaire.dart';
import '../data/video.dart';
import '../functions.dart';
import '../hive_util.dart';
import '../data/community.dart';
import '../data/field_monitor_schedule.dart';
import '../data/photo.dart';
import '../data/project.dart';
import '../data/project_position.dart';
import '../data/user.dart';

final UserBloc userBloc = UserBloc();

class UserBloc {
  UserBloc() {
    pp('UserBloc constructed');
  }

  User? _user;

  User get user => _user!;
  final StreamController<List<Community>> _reportController =
      StreamController.broadcast();
  final StreamController<List<User>> _userController =
      StreamController.broadcast();
  final StreamController<List<Community>> _communityController =
      StreamController.broadcast();
  final StreamController<List<Questionnaire>> _questController =
      StreamController.broadcast();
  final StreamController<List<Project>> _projController =
      StreamController.broadcast();
  final StreamController<List<Photo>> _photoController =
      StreamController.broadcast();
  final StreamController<List<Video>> _videoController =
      StreamController.broadcast();
  
  final StreamController<List<ProjectPosition>> _projPositionsController =
      StreamController.broadcast();
  final StreamController<List<FieldMonitorSchedule>>
      _fieldMonitorScheduleController = StreamController.broadcast();
  

  
  Stream get reportStream => _reportController.stream;

  Stream get settlementStream => _communityController.stream;

  Stream get questionnaireStream => _questController.stream;
  
  Stream get fieldMonitorScheduleStream =>
      _fieldMonitorScheduleController.stream;

  Stream<List<Photo>> get photoStream => _photoController.stream;

  Stream<List<Video>> get videoStream => _videoController.stream;


  

  static const mm = '💜💜💜 UserBloc 💜: ';
  
  Future<List<Photo>> getPhotos(
      {required String userId, required bool forceRefresh}) async {
    // var android = UniversalPlatform.isAndroid;
      var photos = await hiveUtil.getUserPhotos(userId);
    

    if (photos.isEmpty || forceRefresh) {
      photos = await DataAPI.getUserProjectPhotos(userId);
    }
    _photoController.sink.add(photos);
    pp('$mm getUserProjectPhotos found: 💜 ${photos.length} photos ');
    return photos;
  }

  Future<List<Video>> getVideos(
      {required String userId, required bool forceRefresh}) async {
    // var android = UniversalPlatform.isAndroid;
      var videos = await hiveUtil.getUserVideos(userId);

    if (videos.isEmpty || forceRefresh) {
      videos = await DataAPI.getUserProjectVideos(userId);
    }
    _videoController.sink.add(videos);
    pp('$mm getUserProjectVideos found: 💜 ${videos.length} videos ');
    return videos;
  }
  Future<List<FieldMonitorSchedule>> getFieldMonitorSchedules(
      {required String userId, required bool forceRefresh}) async {
    // var android = UniversalPlatform.isAndroid;
    var schedules = await hiveUtil.getProjectMonitorSchedules(userId);

    if (schedules.isEmpty || forceRefresh) {
      schedules = await DataAPI.getUserFieldMonitorSchedules(userId);
    }
    _fieldMonitorScheduleController.sink.add(schedules);
    pp('$mm getFieldMonitorSchedules found: 💜 ${schedules.length} schedules ');
    return schedules;
  }

  Future refreshUserData(
      {required String userId,
      required bool forceRefresh}) async {
    pp('$mm refreshUserData ... forceRefresh: $forceRefresh');
    try {
      //todo - for monitor, only their projects must show
      var bag = await hiveUtil.getLatestDataBag();
      if (forceRefresh || bag == null) {
        bag = await DataAPI.getUserData(userId);
      }
      _processBag(bag);
      return bag;
    } catch (e) {
      pp('We seem fucked! $e');
      rethrow;
    }
  }

  void _processBag(DataBag bag) {
    pp('$mm _processBag: send data to streams ...');
    if (bag.photos != null) {
        _photoController.sink.add(bag.photos!);

    }
    if (bag.videos != null) {
        _videoController.sink.add(bag.videos!);

    }
    if (bag.fieldMonitorSchedules != null) {
        _fieldMonitorScheduleController.sink.add(bag.fieldMonitorSchedules!);

    }
    if (bag.users != null) {
        _userController.sink.add(bag.users!);

    }
    if (bag.projects != null) {
        _projController.sink.add(bag.projects!);

    }
    if (bag.projectPositions != null) {
        _projPositionsController.sink.add(bag.projectPositions!);

    }
  }

  close() {
    _communityController.close();
    _questController.close();
    _projController.close();
    _userController.close();
    
    _reportController.close();
    _projPositionsController.close();

    _videoController.close();
    _photoController.close();
    _fieldMonitorScheduleController.close();
   
  }
}
