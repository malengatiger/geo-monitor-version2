
import 'dart:async';

import 'package:universal_platform/universal_platform.dart';

import '../api/data_api.dart';
import '../data/community.dart';
import '../data/country.dart';
import '../data/data_bag.dart';
import '../data/field_monitor_schedule.dart';
import '../data/monitor_report.dart';
import '../data/organization.dart';
import '../data/photo.dart';
import '../data/project.dart';
import '../data/project_position.dart';
import '../data/questionnaire.dart';
import '../data/user.dart';
import '../data/video.dart';
import '../emojis.dart';
import '../functions.dart';
import '../hive_util.dart';

final OrganizationBloc organizationBloc = OrganizationBloc();
class OrganizationBloc {

  OrganizationBloc(){
    pp('$mm OrganizationBloc constructed');
  }
  final  mm = '${Emoji.blueDot}${Emoji.blueDot}${Emoji.blueDot} '
      'OrganizationBloc: ';
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

  final StreamController<List<Photo>> _projectPhotoController =
  StreamController.broadcast();
  final StreamController<List<Video>> _projectVideoController =
  StreamController.broadcast();

  final StreamController<List<ProjectPosition>> _projPositionsController =
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

  Stream<List<Questionnaire>> get questionnaireStream => _questController.stream;

  Stream<List<Project>> get projectStream => _projController.stream;

  Stream<List<ProjectPosition>> get projectPositionsStream => _projPositionsController.stream;

  Stream get countryStream => _countryController.stream;

  Stream<List<User>> get usersStream => _userController.stream;

  Stream get activeQuestionnaireStream => _activeQuestionnaireController.stream;

  Stream<List<FieldMonitorSchedule>> get fieldMonitorScheduleStream =>
      _fieldMonitorScheduleController.stream;

  Stream<List<Photo>> get photoStream => _photoController.stream;

  Stream<List<Video>> get videoStream => _videoController.stream;
  //
  Future<DataBag> getOrganizationData(
      {required String organizationId, required bool forceRefresh}) async {
    pp('$mm refreshing organization data ... photos, videos and schedules'
        ' ...forceRefresh: $forceRefresh');

    DataBag bag = await hiveUtil.getOrganizationData(organizationId: organizationId);

    if (forceRefresh) {
      pp('$mm get data from server; forceRefresh: $forceRefresh');
      bag = await DataAPI.getOrganizationData(organizationId);
    } else {
      if (bag.isEmpty()) {
        pp('$mm bag is empty. No organization data anywhere yet? ... '
            'will force refresh, forceRefresh: $forceRefresh');
        bag = await DataAPI.getOrganizationData(organizationId);
      }
    }

    _putContentsOfBagIntoStreams(bag);
    return bag;
  }

  void _putContentsOfBagIntoStreams(DataBag bag) {
    pp('$mm _putContentsOfBagIntoStreams: ... send data to streams ...');
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

  Future<List<User>> getUsers(
      {required String organizationId, required bool forceRefresh}) async {
    pp('$mm getOrganizationUsers ... forceRefresh: $forceRefresh');
    var users = await hiveUtil.getUsers(organizationId: organizationId);

    if (users.isEmpty || forceRefresh) {
      users = await DataAPI.findUsersByOrganization(organizationId);
      pp('$mm getOrganizationUsers ... _users: ${users.length} ... will add to cache');
    }
    pp('$mm getOrganizationUsers found: 💜 ${users.length} users. adding to stream ... ');
    _userController.sink.add(users);

    for (var element in users) {
      pp('$mm 😲 😡 USER:  🍏 ${element.name} 🍏 ${element.organizationName}');
    }

    return users;
  }

  Future<List<ProjectPosition>> getProjectPositions(
      {required String organizationId, required bool forceRefresh}) async {
    var projectPositions = await hiveUtil.getOrganizationProjectPositions(
        organizationId: organizationId);
    pp('$mm getOrganizationProjectPositions found ${projectPositions.length} positions in local cache ');

    if (projectPositions.isEmpty || forceRefresh) {
      projectPositions =
      await DataAPI.getOrganizationProjectPositions(organizationId);
      pp('$mm getOrganizationProjectPositions found ${projectPositions.length} positions from remote database ');
      await hiveUtil.addProjectPositions(positions: projectPositions);
    }
    _projPositionsController.sink.add(projectPositions);
    pp('$mm getOrganizationProjectPositions found: 💜 ${projectPositions.length} projectPositions from local or remote db ');
    return projectPositions;
  }

  Future<List<FieldMonitorSchedule>> getFieldMonitorSchedules(
      {required String organizationId, required bool forceRefresh}) async {
    var schedules = await hiveUtil.getOrganizationMonitorSchedules(organizationId);

    if (schedules.isEmpty || forceRefresh) {
      schedules = await DataAPI.getOrgFieldMonitorSchedules(organizationId);
      await hiveUtil.addFieldMonitorSchedules(schedules: schedules);
    }

    _fieldMonitorScheduleController.sink.add(schedules);
    pp('$mm getOrgFieldMonitorSchedules found: 🔵 ${schedules.length} schedules ');

    return schedules;
  }

  Future<List<Photo>> getPhotos(
      {required String organizationId, required bool forceRefresh}) async {
    var photos = <Photo>[];
    try {
        photos = await hiveUtil.getOrganizationPhotos(organizationId);
      if (photos.isEmpty || forceRefresh) {
        photos = await DataAPI.getOrganizationPhotos(organizationId);
        await hiveUtil.addPhotos(photos: photos);
      }
      _photoController.sink.add(photos);
      pp('$mm getPhotos found: 💜 ${photos.length} photos 💜 ');
    } catch (e) {
      pp('😈😈😈😈😈 MonitorBloc: getOrganizationPhotos FAILED: 😈😈😈😈😈 $e');
      rethrow;
    }

    return photos;
  }

  Future<List<Video>> getVideos(
      {required String organizationId, required bool forceRefresh}) async {
    var videos = <Video>[];
    try {
      var android = UniversalPlatform.isAndroid;
      if (android) {
        //_videos = await hiveUtil.getVideos();
      } else {
        videos.clear();
      }
      if (videos.isEmpty || forceRefresh) {
        videos = await DataAPI.getOrganizationVideos(organizationId);
        if (android) await hiveUtil.addVideos(videos: videos);
      }
      _videoController.sink.add(videos);
      pp('$mm getVideos found: 💜 ${videos.length} videos ');
    } catch (e) {
      pp('😈😈😈😈😈 MonitorBloc: getOrganizationVideos FAILED');
      rethrow;
    }

    return videos;
  }

  Future<List<Project>> getProjects(
      {required String organizationId, required bool forceRefresh}) async {
    var projects = await hiveUtil.getProjects(organizationId);

    try {
      if (projects.isEmpty || forceRefresh) {
        projects = await DataAPI.findProjectsByOrganization(organizationId);
      }
      _projController.sink.add(projects);
      pp('💜💜💜💜 MonitorBloc: OrganizationProjects found: 💜 ${projects.length} projects ; organizationId: $organizationId💜');
      for (var project in projects) {
        pp('💜💜 Org PROJECT: ${project.name} 🍏 ${project.organizationName}  🍏 ${project.organizationId}');
      }
    } catch (e) {
      pp('$mm $e');
      rethrow;
    }

    return projects;
  }

  Future<Organization?> getOrganizationById(
      {required String organizationId}) async {

    var org = await hiveUtil.getOrganizationById(organizationId: organizationId);

    try {
      org ??= await DataAPI.findOrganizationById(organizationId);

      pp('$mm OrganizationBloc: Organization found: 💜 ${org!.toJson()} ');

    } catch (e) {
      pp('$mm $e');
      rethrow;
    }

    return org;
  }

}