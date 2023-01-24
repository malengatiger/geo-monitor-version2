import 'dart:async';

import 'package:geolocator/geolocator.dart' as loc;

import '../api/data_api.dart';
import '../api/sharedprefs.dart';
import '../data/audio.dart';
import '../data/community.dart';
import '../data/country.dart';
import '../data/data_bag.dart';
import '../data/field_monitor_schedule.dart';
import '../data/monitor_report.dart';
import '../data/photo.dart';
import '../data/project.dart';
import '../data/project_polygon.dart';
import '../data/project_position.dart';
import '../data/questionnaire.dart';
import '../data/user.dart';
import '../data/video.dart';
import '../emojis.dart';
import '../functions.dart';
import '../hive_util.dart';
import '../location/loc_bloc.dart';

final ProjectBloc projectBloc = ProjectBloc();

class ProjectBloc {
  ProjectBloc() {
    pp('$mm ProjectBloc constructed');
  }
  final mm = '${Emoji.appleRed}${Emoji.appleRed}${Emoji.appleRed} '
      'ProjectBloc';
  final StreamController<List<MonitorReport>> _reportController =
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
  final StreamController<List<Audio>> _audioController =
  StreamController.broadcast();

  final StreamController<List<Photo>> _projectPhotoController =
      StreamController.broadcast();
  final StreamController<List<Video>> _projectVideoController =
      StreamController.broadcast();

  final StreamController<List<ProjectPosition>> _projPositionsController =
      StreamController.broadcast();
  final StreamController<List<ProjectPolygon>> _polygonController =
      StreamController.broadcast();
  final StreamController<List<ProjectPosition>> _projectPositionsController =
      StreamController.broadcast();
  final StreamController<List<FieldMonitorSchedule>>
      _fieldMonitorScheduleController = StreamController.broadcast();
  final StreamController<List<Country>> _countryController =
      StreamController.broadcast();

  final StreamController<Questionnaire> _activeQuestionnaireController =
      StreamController.broadcast();
  final StreamController<User> _activeUserController =
      StreamController.broadcast();

  Stream<List<MonitorReport>> get reportStream => _reportController.stream;

  Stream<List<Community>> get communityStream => _communityController.stream;

  Stream<List<Questionnaire>> get questionnaireStream =>
      _questController.stream;

  Stream<List<Project>> get projectStream => _projController.stream;

  Stream<List<ProjectPosition>> get projectPositionsStream =>
      _projPositionsController.stream;

  Stream<List<ProjectPolygon>> get projectPolygonsStream =>
      _polygonController.stream;

  Stream get countryStream => _countryController.stream;

  Stream<List<User>> get usersStream => _userController.stream;

  Stream get activeQuestionnaireStream => _activeQuestionnaireController.stream;

  Stream<List<FieldMonitorSchedule>> get fieldMonitorScheduleStream =>
      _fieldMonitorScheduleController.stream;

  Stream<List<Photo>> get photoStream => _photoController.stream;

  Stream<List<Video>> get videoStream => _videoController.stream;
  Stream<List<Audio>> get audioStream => _audioController.stream;

  //
  Future<List<ProjectPosition>> getProjectPositions(
      {required String projectId, required bool forceRefresh}) async {
    var projectPositions = await hiveUtil.getProjectPositions(projectId);
    pp('$mm getProjectPositions found ${projectPositions.length} positions in local cache ');

    if (projectPositions.isEmpty || forceRefresh) {
      projectPositions = await DataAPI.findProjectPositionsById(projectId);
      pp('$mm getProjectPositions found ${projectPositions.length} positions from remote database ');
      await hiveUtil.addProjectPositions(positions: projectPositions);
    }
    _projPositionsController.sink.add(projectPositions);
    pp('$mm getProjectPositions found: 💜 ${projectPositions.length} projectPositions from local or remote db ');
    return projectPositions;
  }

  Future<List<ProjectPolygon>> getProjectPolygons(
      {required String projectId, required bool forceRefresh}) async {
    var projectPolygons = await hiveUtil.getProjectPolygons(projectId: projectId);
    pp('$mm getProjectPolygons found ${projectPolygons.length} positions in local cache ');

    if (projectPolygons.isEmpty || forceRefresh) {
      projectPolygons = await DataAPI.findProjectPolygonsById(projectId);
      pp('$mm getProjectPolygons found ${projectPolygons.length} positions from remote database ');
      await hiveUtil.addProjectPolygons(polygons: projectPolygons);
    }
    _polygonController.sink.add(projectPolygons);
    pp('$mm getProjectPolygons found: 💜 ${projectPolygons.length} projectPolygons from local or remote db ');
    return projectPolygons;
  }

  Future<List<Photo>> getPhotos(
      {required String projectId, required bool forceRefresh}) async {

    List<Photo> photos = await hiveUtil.getProjectPhotos(projectId);
    if (photos.isEmpty || forceRefresh) {
      photos = await DataAPI.findPhotosByProject(projectId);
      await hiveUtil.addPhotos(photos: photos);
    }
    _projectPhotoController.sink.add(photos);
    pp('$mm getPhotos found: 💜 ${photos.length} photos ');

    return photos;
  }

  Future<List<FieldMonitorSchedule>> getProjectFieldMonitorSchedules(
      {required String projectId, required bool forceRefresh}) async {
    var schedules = await hiveUtil.getProjectMonitorSchedules(projectId);

    if (schedules.isEmpty || forceRefresh) {
      schedules = await DataAPI.getProjectFieldMonitorSchedules(projectId);
      await hiveUtil.addFieldMonitorSchedules(schedules: schedules);
    }

    _fieldMonitorScheduleController.sink.add(schedules);
    pp('🔵 🔵 🔵  MonitorBloc: getProjectFieldMonitorSchedules found: 💜 ${schedules.length} schedules ');

    return schedules;
  }

  Future<List<FieldMonitorSchedule>> getMonitorFieldMonitorSchedules(
      {required String userId, required bool forceRefresh}) async {
    var schedules = await hiveUtil.getFieldMonitorSchedules(userId);

    if (schedules.isEmpty || forceRefresh) {
      schedules = await DataAPI.getMonitorFieldMonitorSchedules(userId);
      await hiveUtil.addFieldMonitorSchedules(schedules: schedules);
    }
    schedules.sort((a, b) => b.date!.compareTo(a.date!));
    _fieldMonitorScheduleController.sink.add(schedules);
    pp('🔵 🔵 🔵  MonitorBloc: getMonitorFieldMonitorSchedules found: 💜 ${schedules.length} schedules ');

    return schedules;
  }

  Future<List<Video>> getProjectVideos(
      {required String projectId, required bool forceRefresh}) async {
    List<Video> videos = await hiveUtil.getProjectVideos(projectId);
    // var android = UniversalPlatform.isAndroid;
    // if (android) {
    //   //videos = await hiveUtil.getProjectVideos(projectId);
    // }
    if (videos.isEmpty || forceRefresh) {
      videos = await DataAPI.findVideosById(projectId);
    }
    _projectVideoController.sink.add(videos);
    pp('$mm getProjectVideos found: 💜 ${videos.length} videos ');

    return videos;
  }

  Future<DataBag> refreshProjectData(
      {required String projectId, required bool forceRefresh}) async {
    pp('$mm refreshing project data ... photos, videos and schedules '
        '... forceRefresh: $forceRefresh');
    var bag = await _loadBag(projectId);

    if (forceRefresh) {
      bag = await DataAPI.getProjectData(projectId);
    }
    _putBagContentsToStreams(bag);
    return bag;
  }

  Future<DataBag> _loadBag(String projectId) async {
    var positions = await hiveUtil.getProjectPositions(projectId);
    var polygons = await hiveUtil.getProjectPolygons(projectId: projectId);
    var photos = await hiveUtil.getProjectPhotos(projectId);
    var videos = await hiveUtil.getProjectVideos(projectId);
    var audios = await hiveUtil.getProjectAudios(projectId);
    var schedules = await hiveUtil.getProjectMonitorSchedules(projectId);

    var bag = DataBag(
        photos: photos,
        videos: videos,
        fieldMonitorSchedules: schedules,
        projectPositions: positions,
        projects: [],
        audios: audios,
        date: DateTime.now().toUtc().toIso8601String(),
        users: [],
        projectPolygons: polygons);
    pp('$mm project data bag loaded: ... photos: ${photos.length}, videos: ${videos.length} and audios: ${audios.length} ...');
    return bag;
  }

  void _putBagContentsToStreams(DataBag bag) {
    pp('$mm _processBag: send data to project streams ...');
    if (bag.photos != null) {
      if (bag.photos!.isNotEmpty) {
        bag.photos?.sort((a, b) => b.created!.compareTo(a.created!));
        _photoController.sink.add(bag.photos!);
      }
    }
    if (bag.videos != null) {
      if (bag.videos!.isNotEmpty) {
        bag.videos?.sort((a, b) => b.created!.compareTo(a.created!));
        _videoController.sink.add(bag.videos!);
      }
    }
    if (bag.audios != null) {
      if (bag.audios!.isNotEmpty) {
        bag.audios?.sort((a, b) => b.created!.compareTo(a.created!));
        _audioController.sink.add(bag.audios!);
      }
    }

    if (bag.projectPositions != null) {
      if (bag.projectPositions!.isNotEmpty) {
        _projectPositionsController.sink.add(bag.projectPositions!);
      }
    }
  }

  Future<List<Project>> getProjectsWithinRadius(
      {double radiusInKM = 100.5, bool checkUserOrg = true}) async {
    loc.Position pos;
    var user = await Prefs.getUser();

    try {
      pos = await locationBloc.getLocation();
      pp('$mm current location: 💜 latitude: ${pos.latitude} longitude: ${pos.longitude}');
    } catch (e) {
      pp('MonitorBloc: Location is fucked!');
      rethrow;
    }
    var projects = await DataAPI.findProjectsByLocation(
        latitude: pos.latitude,
        longitude: pos.longitude,
        radiusInKM: radiusInKM);

    List<Project> userProjects = [];

    pp('$mm Projects within radius of  🍏 $radiusInKM  🍏 kilometres; '
        'found: 💜 ${projects.length} projects');
    for (var project in projects) {
      pp('$mm 😡 ALL PROJECT found in radius: ${project.name} 🍏 ${project.organizationName}  🍏 ${project.organizationId}');
      if (project.organizationId == user!.organizationId) {
        userProjects.add(project);
      }
    }



    pp('$mm User Org Projects within radius of $radiusInKM kilometres; '
        'found: 💜 ${userProjects.length} projects in organization, filtered out non-org projects found in radius');

    if (checkUserOrg) {
      return userProjects;
    } else {
      return projects;
    }
  }
}
