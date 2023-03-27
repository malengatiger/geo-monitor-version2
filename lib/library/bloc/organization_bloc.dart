import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geo_monitor/library/bloc/data_refresher.dart';
import 'package:geo_monitor/library/bloc/theme_bloc.dart';
import 'package:geo_monitor/library/data/activity_model.dart';
import 'package:geo_monitor/library/data/project_summary.dart';
import 'package:geo_monitor/library/data/settings_model.dart';

import '../../l10n/translation_handler.dart';
import '../api/data_api.dart';
import '../cache_manager.dart';
import '../data/audio.dart';
import '../data/community.dart';
import '../data/country.dart';
import '../data/data_bag.dart';
import '../data/field_monitor_schedule.dart';
import '../data/monitor_report.dart';
import '../data/organization.dart';
import '../data/photo.dart';
import '../data/project.dart';
import '../data/project_polygon.dart';
import '../data/project_position.dart';
import '../data/questionnaire.dart';
import '../data/user.dart';
import '../data/video.dart';
import '../emojis.dart';
import '../functions.dart';
import 'zip_bloc.dart';

final OrganizationBloc organizationBloc = OrganizationBloc();

class OrganizationBloc {
  OrganizationBloc() {
    pp('$mm OrganizationBloc constructed');
  }
  final mm = '${E.blueDot}${E.blueDot}${E.blueDot} '
      'OrganizationBloc: ';
  final StreamController<DataBag> dataBagController =
      StreamController.broadcast();
  final StreamController<SettingsModel> settingsController =
  StreamController.broadcast();
  final StreamController<List<MonitorReport>> _reportController =
  StreamController.broadcast();
  final StreamController<List<User>> userController =
      StreamController.broadcast();
  final StreamController<List<Community>> communityController =
      StreamController.broadcast();
  final StreamController<List<Questionnaire>> questController =
      StreamController.broadcast();
  final StreamController<List<Project>> projController =
      StreamController.broadcast();
  final StreamController<List<Photo>> photoController =
      StreamController.broadcast();
  final StreamController<List<Video>> videoController =
      StreamController.broadcast();
  final StreamController<List<Audio>> audioController =
      StreamController.broadcast();

  final StreamController<List<ProjectPosition>> projPositionsController =
      StreamController.broadcast();
  final StreamController<List<ProjectPolygon>> projPolygonsController =
      StreamController.broadcast();
  final StreamController<List<ProjectPosition>> projectPositionsController =
      StreamController.broadcast();
  final StreamController<List<FieldMonitorSchedule>>
      fieldMonitorScheduleController = StreamController.broadcast();
  final StreamController<List<Country>> countryController =
      StreamController.broadcast();
  final StreamController<List<ActivityModel>> activityController =
      StreamController.broadcast();

  final StreamController<Questionnaire> activeQuestionnaireController =
      StreamController.broadcast();

  Stream<DataBag> get dataBagStream => dataBagController.stream;

  Stream<SettingsModel> get settingsStream => settingsController.stream;

  Stream<List<MonitorReport>> get reportStream => _reportController.stream;

  Stream<List<Community>> get communityStream => communityController.stream;

  Stream<List<Questionnaire>> get questionnaireStream => questController.stream;

  Stream<List<Project>> get projectStream => projController.stream;

  Stream<List<ProjectPosition>> get projectPositionsStream =>
      projPositionsController.stream;

  Stream<List<ProjectPolygon>> get projectPolygonsStream =>
      projPolygonsController.stream;

  Stream get countryStream => countryController.stream;

  Stream<List<User>> get usersStream => userController.stream;

  Stream<List<ActivityModel>> get activityStream => activityController.stream;

  Stream get activeQuestionnaireStream => activeQuestionnaireController.stream;

  Stream<List<FieldMonitorSchedule>> get fieldMonitorScheduleStream =>
      fieldMonitorScheduleController.stream;
  Stream<List<Photo>> get photoStream => photoController.stream;

  Stream<List<Video>> get videoStream => videoController.stream;
  Stream<List<Audio>> get audioStream => audioController.stream;

  //
  Future<void> addProjectToStream(Project project) async {
    try {
      var p = await cacheManager.getOrganizationProjects();
      pp('$mm .... adding new project -- sending ${p.length} photos to project Stream ');
      projController.sink.add(p);
    } catch (e) {
      pp('$mm problem with stream? 🔴🔴🔴 $e');
    }
  }

  Future<void> addPhotoToStream(Photo photo) async {
    pp('\n\n$mm ......... addPhotoToStream ... ');
    try {
      var p = await cacheManager.getOrganizationPhotos();
      pp('$mm .... adding new photo -- sending ${p.length} photos to photoStream ');
      photoController.sink.add(p);
    } catch (e) {
      pp('$mm problem with stream? 🔴🔴🔴 $e');
    }
  }

  Future<void> addVideoToStream(Video video) async {
    pp('$mm addVideoToStream ...');
    var p = await cacheManager.getOrganizationVideos();
    pp('$mm added new video -- sending ${p.length} videos to videoStream ');
    videoController.sink.add(p);
  }

  Future<void> addAudioToStream(Audio audio) async {
    pp('$mm addAudioToStream ...');
    var p = await cacheManager.getOrganizationAudios();
    pp('$mm added new audio -- sending ${p.length} audios to audioStream ');
    audioController.sink.add(p);
  }

  Future<void> addProjectPositionToStream(
      ProjectPosition projectPosition) async {
    pp('$mm addProjectPositionToStream ...');
    var p = await cacheManager.getOrganizationProjectPositions();
    pp('$mm added new projectPosition -- sending ${p.length} projectPositions to projectPositionsStream ');
    projectPositionsController.sink.add(p);
  }

  Future<void> addProjectPolygonToStream(ProjectPolygon projectPolygon) async {
    pp('$mm addProjectPolygonToStream ...');
    var p = await cacheManager.getOrganizationProjectPolygons();
    pp('$mm added new projectPolygon -- sending ${p.length} projectPolygons to projectPolygonsStream ');
    projPolygonsController.sink.add(p);
  }

  Future<SettingsModel?> getLatestSettings(String organizationId) async {
    var list = await DataAPI.getOrganizationSettings(organizationId);

    if (list.isNotEmpty) {
      themeBloc.changeToTheme(list.first.themeIndex!);
      await mTx.translate('settings', list.first.locale!);
      return list.first;
    }

    return null;
  }

  Future<DataBag> getOrganizationData(
      {required String organizationId,
      required bool forceRefresh,
      required String startDate,
      required String endDate}) async {

    pp('$mm getOrganizationData ... photos, videos and schedules'
        ' ... forceRefresh: $forceRefresh');

    final start = DateTime.now();
    DataBag? bag;
    final sDate = DateTime.parse(startDate);
    final eDate = DateTime.parse(endDate);
    final numberOfDays = eDate.difference(sDate).inDays;
    final projects = await getOrganizationProjects(organizationId: organizationId, forceRefresh: false);
    final users = await cacheManager.getUsers();
    if (forceRefresh) {
      pp('$mm get data from server .....................; '
          'forceRefresh: $forceRefresh; if true do the refresh ...');
      await getLatestSettings(organizationId);
      bag = await dataRefresher.manageRefresh(numberOfDays: numberOfDays,
          organizationId: organizationId, projectId: null, userId: null);
      bag!.projects = projects;
      bag.users = users;
      printDataBag(bag!);
      return bag;
    } else {
      bag = await cacheManager.getOrganizationData(organizationId: organizationId);
      if (bag.isEmpty()) {
        pp('$mm bag is empty. No organization data anywhere yet? ... '
            'will force refresh, forceRefresh: $forceRefresh');
        bag = await dataRefresher.manageRefresh(numberOfDays: numberOfDays,
            organizationId: organizationId, projectId: null, userId: null);
        bag!.projects = projects;
        bag.users = users;
        printDataBag(bag);
        return bag;
      }
    }
    final end = DateTime.now();
    pp('$mm getOrganizationData: 🍎 ${end.difference(start).inSeconds} seconds elapsed, will start filter ...');

    final start2 = DateTime.now();
    pp('\n\n$mm ... filter bag by the dates .... before filter');

    printDataBag(bag);
    var mBag = filterBagContentsByDate(
        bag: bag, startDate: startDate, endDate: endDate);

    mBag.projects = projects;
    mBag.users = users;
    dataBagController.sink.add(mBag);
    final end2 = DateTime.now();
    pp('\n$mm filtered bag .... ${end2.difference(start2)} seconds elapsed for filter');
    printDataBag(mBag);
    return mBag;
  }

  Future<DataBag> refreshOrganizationData(
      {required String organizationId,
      required String startDate,
      required String endDate}) async {

    pp('$mm getOrganizationData ... photos, videos and schedules etc.');
    pp('$mm get data from server .....................');
    var bag = await zipBloc.getOrganizationDataZippedFile(
        organizationId, startDate, endDate);

    return bag!;
  }

  void _putContentsOfBagIntoStreams(DataBag bag) {
    // pp('$mm _putContentsOfBagIntoStreams: .................................... '
    try {
      dataBagController.sink.add(bag);
    } catch (e) {
      pp('$mm _putContentsOfBagIntoStreams ERROR - $e');
    }
  }

  Future<List<User>> getUsers(
      {required String organizationId, required bool forceRefresh}) async {
    var users = await cacheManager.getUsers();

    if (users.isEmpty || forceRefresh) {
      users = await DataAPI.findUsersByOrganization(organizationId);
      pp('$mm getOrganizationUsers ... _users: ${users.length} ... will add to cache');
    }
    userController.sink.add(users);

    return users;
  }

  Future<List<ProjectPosition>> getProjectPositions(
      {required String organizationId,
      required bool forceRefresh,
      required String startDate,
      required String endDate}) async {
    var projectPositions = await cacheManager.getOrganizationProjectPositions();
    pp('$mm getOrganizationProjectPositions found ${projectPositions.length} positions in local cache ');

    if (projectPositions.isEmpty || forceRefresh) {
      projectPositions = await DataAPI.getOrganizationProjectPositions(
          organizationId, startDate, endDate);
      pp('$mm getOrganizationProjectPositions found ${projectPositions.length} positions from remote database ');
      await cacheManager.addProjectPositions(positions: projectPositions);
    }
    var list = <ProjectPosition>[];
    for (var pos in projectPositions) {
      if (pos.created != null) {
        list.add(pos);
      }
    }
    projPositionsController.sink.add(list);
    pp('$mm getOrganizationProjectPositions found: 💜 ${list.length} projectPositions from local or remote db ');

    return list;
  }

  Future<List<ProjectPolygon>> getProjectPolygons(
      {required String organizationId,
      required bool forceRefresh,
      required String startDate,
      required String endDate}) async {
    var projectPolygons = await cacheManager.getOrganizationProjectPolygons();
    pp('$mm getProjectPolygons found ${projectPolygons.length} polygons in local cache ');

    if (projectPolygons.isEmpty || forceRefresh) {
      projectPolygons =
          await DataAPI.getProjectPolygons(organizationId, startDate, endDate);
      pp('$mm getProjectPolygons found ${projectPolygons.length} polygons from remote database ');
      await cacheManager.addProjectPolygons(polygons: projectPolygons);
    }
    projPolygonsController.sink.add(projectPolygons);
    pp('$mm getProjectPolygons found: 💜 ${projectPolygons.length} polygons from local or remote db ');
    return projectPolygons;
  }

  Future<List<FieldMonitorSchedule>> getFieldMonitorSchedules(
      {required String organizationId,
      required bool forceRefresh,
      required String startDate,
      required String endDate}) async {
    var schedules = await cacheManager.getOrganizationMonitorSchedules();

    if (schedules.isEmpty || forceRefresh) {
      schedules = await DataAPI.getOrgFieldMonitorSchedules(
          organizationId, startDate, endDate);
      await cacheManager.addFieldMonitorSchedules(schedules: schedules);
    }

    fieldMonitorScheduleController.sink.add(schedules);
    pp('$mm getOrgFieldMonitorSchedules found: 🔵 ${schedules.length} schedules ');

    return schedules;
  }

  Future<List<SettingsModel>> getSettings(
      {required String organizationId, required bool forceRefresh}) async {
    var settingsList = <SettingsModel>[];
    try {
      pp('$mm getSettings org settings from hive cache .... 💜 ');
      settingsList = await cacheManager.getOrganizationSettings();
      pp('$mm getSettings found in cache: 💜 ${settingsList.length} org settings 💜 ');
      if (settingsList.isEmpty || forceRefresh) {
        settingsList = await DataAPI.getOrganizationSettings(organizationId);
        pp('$mm getSettings list from remote db: 💜 ${settingsList.length} org settings 💜 ');
      }
      pp('$mm getSettings found: 💜 ${settingsList.length} org settings 💜 ');
    } catch (e) {
      pp('\n$mm 😈😈😈😈😈 getSettings FAILED: 😈😈😈😈😈 $e\n');
      pp(e);
      rethrow;
    }

    return settingsList;
  }

  Future<List<Video>> getVideos(
      {required String organizationId,
      required bool forceRefresh,
      required String startDate,
      required String endDate}) async {
    var videos = <Video>[];
    try {
      videos = await cacheManager.getVideos();

      if (videos.isEmpty || forceRefresh) {
        videos = await DataAPI.getOrganizationVideos(
            organizationId, startDate, endDate);
        await cacheManager.addVideos(videos: videos);
      }
      videoController.sink.add(videos);
      pp('$mm getVideos found: 💜 ${videos.length} videos ');
    } catch (e) {
      pp('😈😈😈😈😈 MonitorBloc: getOrganizationVideos FAILED');
      rethrow;
    }

    return videos;
  }

  Future<List<Project>> getOrganizationProjects(
      {required String organizationId, required bool forceRefresh}) async {
    var projects = await cacheManager.getOrganizationProjects();

    try {
      if (projects.isEmpty || forceRefresh) {
        projects = await DataAPI.findProjectsByOrganization(organizationId);
      }
      projController.sink.add(projects);
      pp('💜💜💜💜 OrgBloc: OrganizationProjects found: 💜 ${projects.length} projects ; organizationId: $organizationId💜');
      for (var project in projects) {
        // pp('💜💜 Org PROJECT: ${project.name} 🍏 ${project.organizationName}  🍏 ${project.organizationId}');
      }
    } catch (e) {
      pp('$mm $e');
      rethrow;
    }

    return projects;
  }

  Future<List<ActivityModel>> getOrganizationActivity(
      {required String organizationId,
      required int hours,
      required bool forceRefresh}) async {
    try {
      var activities = await cacheManager.getActivitiesWithinHours(hours);
      pp('$mm 💜💜💜💜 getOrganizationActivity found in cache: 💜 ${activities.length} activities ; organizationId: $organizationId 💜');
      if (activities.isEmpty || forceRefresh) {
        activities =
            await DataAPI.getOrganizationActivity(organizationId, hours);
      }
      activityController.sink.add(activities);
      pp('$mm 💜💜💜💜 getOrganizationActivity found: 💜 ${activities.length} activities ; organizationId: $organizationId 💜');
      return activities;
    } catch (e) {
      pp('$mm $e');
      rethrow;
    }
  }

  Future<List<ProjectSummary>> getOrganizationDailySummaries(
      {required String organizationId,
      required String startDate,
      required String endDate,
      required bool forceRefresh}) async {
    try {
      var summaries =
          await cacheManager.getOrganizationSummaries(startDate, endDate);

      if (summaries.isEmpty || forceRefresh) {
        summaries = await DataAPI.getOrganizationDailySummary(
            organizationId, startDate, endDate);
      }
      return summaries;
    } catch (e) {
      pp('$mm $e');
      rethrow;
    }
  }

  Future<List<ProjectSummary>> getProjectDailySummaries(
      {required String projectId,
      required String startDate,
      required String endDate,
      required bool forceRefresh}) async {
    try {
      var summaries =
          await cacheManager.getProjectSummaries(projectId, startDate, endDate);

      if (summaries.isEmpty || forceRefresh) {
        summaries =
            await DataAPI.getProjectDailySummary(projectId, startDate, endDate);
      }
      return summaries;
    } catch (e) {
      pp('$mm $e');
      rethrow;
    }
  }

  Future<Organization?> getOrganizationById(
      {required String organizationId}) async {
    var org =
        await cacheManager.getOrganizationById(organizationId: organizationId);

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

DataBag filterBagContentsByDate(
    {required DataBag bag,
    required String startDate,
    required String endDate}) {

  final photos = <Photo>[];
  bag.photos?.forEach((p) {
    if (checkDate(date: p.created!, startDate: startDate, endDate: endDate)) {
      photos.add(p);
    }
  });
  final videos = <Video>[];
  bag.videos?.forEach((p) {
    if (checkDate(date: p.created!, startDate: startDate, endDate: endDate)) {
      videos.add(p);
    }
  });
  final audios = <Audio>[];
  bag.audios?.forEach((p) {
    if (checkDate(date: p.created!, startDate: startDate, endDate: endDate)) {
      audios.add(p);
    }
  });

  bag.photos = photos;
  bag.videos = videos;
  bag.audios = audios;

  return bag;
}

bool checkDate(
    {required String date,
    required String startDate,
    required String endDate}) {
  final userDate = DateTime.parse(date);
  final sDate = DateTime.parse(startDate);
  final eDate = DateTime.parse(endDate);
  if (userDate.millisecondsSinceEpoch >= sDate.millisecondsSinceEpoch &&
      userDate.millisecondsSinceEpoch <= eDate.millisecondsSinceEpoch) {
    return true;
  }
  return false;
}
