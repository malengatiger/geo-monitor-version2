import 'dart:async';

import 'package:geo_monitor/library/bloc/downloader.dart';
import 'package:geo_monitor/library/data/settings_model.dart';
import 'package:universal_platform/universal_platform.dart';

import '../api/data_api.dart';
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
import '../hive_util.dart';
import 'zip_bloc.dart';

final OrganizationBloc organizationBloc = OrganizationBloc();

class OrganizationBloc {
  OrganizationBloc() {
    pp('$mm OrganizationBloc constructed');
  }
  final mm = '${E.blueDot}${E.blueDot}${E.blueDot} '
      'OrganizationBloc: ';
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

  final StreamController<Questionnaire> activeQuestionnaireController =
      StreamController.broadcast();

  Stream<List<MonitorReport>> get reportStream => _reportController.stream;

  Stream<List<Community>> get communityStream => communityController.stream;

  Stream<List<Questionnaire>> get questionnaireStream =>
      questController.stream;

  Stream<List<Project>> get projectStream => projController.stream;

  Stream<List<ProjectPosition>> get projectPositionsStream =>
      projPositionsController.stream;

  Stream<List<ProjectPolygon>> get projectPolygonsStream =>
      projPolygonsController.stream;

  Stream get countryStream => countryController.stream;

  Stream<List<User>> get usersStream => userController.stream;

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
    var p = await cacheManager.getOrganizationProjectPositions(
        organizationId: projectPosition.organizationId!);
    pp('$mm added new projectPosition -- sending ${p.length} projectPositions to projectPositionsStream ');
    projectPositionsController.sink.add(p);
  }

  Future<void> addProjectPolygonToStream(ProjectPolygon projectPolygon) async {
    pp('$mm addProjectPolygonToStream ...');
    var p = await cacheManager.getOrganizationProjectPolygons(
        organizationId: projectPolygon.organizationId!);
    pp('$mm added new projectPolygon -- sending ${p.length} projectPolygons to projectPolygonsStream ');
    projPolygonsController.sink.add(p);
  }

  Future<DataBag> getOrganizationData(
      {required String organizationId, required bool forceRefresh}) async {
    pp('$mm refreshing organization data ... photos, videos and schedules'
        ' ...forceRefresh: $forceRefresh');

    DataBag? bag =
        await cacheManager.getOrganizationData(organizationId: organizationId);

    if (forceRefresh) {
      pp('$mm get data from server .....................; forceRefresh: $forceRefresh');
      bag = await zipBloc.getOrganizationDataZippedFile(organizationId);
    } else {
      if (bag.isEmpty()) {
        pp('$mm bag is empty. No organization data anywhere yet? ... '
            'will force refresh, forceRefresh: $forceRefresh');
        bag = await zipBloc.getOrganizationDataZippedFile(organizationId);
      }
    }

    _putContentsOfBagIntoStreams(bag!);
    return bag;
  }

  void _putContentsOfBagIntoStreams(DataBag bag) {
    pp('$mm _putContentsOfBagIntoStreams: .................................... '
        '🔵 send data to streams ...');
    try {
      try {
        if (bag.photos != null) {
          bag.photos!.sort((a, b) => b.created!.compareTo(a.created!));
          photoController.sink.add(bag.photos!);
        }
      } catch (e) {
        pp('$mm _putContentsOfBagIntoStreams photos ERROR - $e');
      }
      try {
        if (bag.videos != null) {
          bag.videos!.sort((a, b) => b.created!.compareTo(a.created!));
          videoController.sink.add(bag.videos!);
        }
      } catch (e) {
        pp('$mm _putContentsOfBagIntoStreams videos ERROR - $e');
      }
      try {
        if (bag.audios != null) {
          bag.audios!.sort((a, b) => b.created!.compareTo(a.created!));
          audioController.sink.add(bag.audios!);
        }
      } catch (e) {
        pp('$mm _putContentsOfBagIntoStreams audios ERROR - $e');
      }
      try {
        if (bag.fieldMonitorSchedules != null) {
          bag.fieldMonitorSchedules!.sort((a, b) => b.date!.compareTo(a.date!));
          fieldMonitorScheduleController.sink.add(bag.fieldMonitorSchedules!);
        }
      } catch (e) {
        pp('$mm _putContentsOfBagIntoStreams fieldMonitorSchedules ERROR - $e');
      }
      try {
        if (bag.users != null) {
          bag.users!.sort((a, b) => a.name!.compareTo(b.name!));
          userController.sink.add(bag.users!);
        }
      } catch (e) {
        pp('$mm _putContentsOfBagIntoStreams users ERROR - $e');
      }
      try {
        if (bag.projects != null) {
          bag.projects!.sort((a, b) => a.name!.compareTo(b.name!));
          projController.sink.add(bag.projects!);
        }
      } catch (e) {
        pp('$mm _putContentsOfBagIntoStreams projects ERROR - $e');
      }
      try {
        if (bag.projectPositions != null) {
          // bag.projectPositions!
          //     .sort((a, b) => b.created!.compareTo(a.created!));
          projPositionsController.sink.add(bag.projectPositions!);
        }
      } catch (e) {
        pp('$mm _putContentsOfBagIntoStreams projectPositions ERROR - $e');
      }
      try {
        if (bag.projectPolygons != null) {
          bag.projectPolygons!.sort((a, b) => b.created!.compareTo(a.created!));
          projPolygonsController.sink.add(bag.projectPolygons!);
        }
      } catch (e) {
        pp('$mm _putContentsOfBagIntoStreams projectPolygons ERROR - $e');
      }

      pp('$mm _putContentsOfBagIntoStreams: .................................... '
          '🔵🔵🔵🔵 send data to streams completed...');
    } catch (e) {
      pp('$mm _putContentsOfBagIntoStreams ERROR - $e');
    }
  }

  Future<List<User>> getUsers(
      {required String organizationId, required bool forceRefresh}) async {
    pp('$mm getOrganizationUsers ... forceRefresh: $forceRefresh');
    var users = await cacheManager.getUsers();

    if (users.isEmpty || forceRefresh) {
      users = await DataAPI.findUsersByOrganization(organizationId);
      pp('$mm getOrganizationUsers ... _users: ${users.length} ... will add to cache');
    }
    pp('$mm getOrganizationUsers found: 💜 ${users.length} users. adding to stream ... ');
    userController.sink.add(users);

    for (var element in users) {
      pp('$mm 😲 😡 USER:  🍏 ${element.name} 🍏 ${element.organizationName}');
    }

    return users;
  }

  Future<List<ProjectPosition>> getProjectPositions(
      {required String organizationId, required bool forceRefresh}) async {
    var projectPositions = await cacheManager.getOrganizationProjectPositions(
        organizationId: organizationId);
    pp('$mm getOrganizationProjectPositions found ${projectPositions.length} positions in local cache ');

    if (projectPositions.isEmpty || forceRefresh) {
      projectPositions =
          await DataAPI.getOrganizationProjectPositions(organizationId);
      pp('$mm getOrganizationProjectPositions found ${projectPositions.length} positions from remote database ');
      await cacheManager.addProjectPositions(positions: projectPositions);
    }
    projPositionsController.sink.add(projectPositions);
    pp('$mm getOrganizationProjectPositions found: 💜 ${projectPositions.length} projectPositions from local or remote db ');
    return projectPositions;
  }

  Future<List<ProjectPolygon>> getProjectPolygons(
      {required String organizationId, required bool forceRefresh}) async {
    var projectPolygons = await cacheManager.getOrganizationProjectPolygons(
        organizationId: organizationId);
    pp('$mm getProjectPolygons found ${projectPolygons.length} polygons in local cache ');

    if (projectPolygons.isEmpty || forceRefresh) {
      projectPolygons =
      await DataAPI.getProjectPolygons(organizationId);
      pp('$mm getProjectPolygons found ${projectPolygons.length} polygons from remote database ');
      await cacheManager.addProjectPolygons(polygons: projectPolygons);
    }
    projPolygonsController.sink.add(projectPolygons);
    pp('$mm getProjectPolygons found: 💜 ${projectPolygons.length} polygons from local or remote db ');
    return projectPolygons;
  }

  Future<List<FieldMonitorSchedule>> getFieldMonitorSchedules(
      {required String organizationId, required bool forceRefresh}) async {
    var schedules =
        await cacheManager.getOrganizationMonitorSchedules(organizationId);

    if (schedules.isEmpty || forceRefresh) {
      schedules = await DataAPI.getOrgFieldMonitorSchedules(organizationId);
      await cacheManager.addFieldMonitorSchedules(schedules: schedules);
    }

    fieldMonitorScheduleController.sink.add(schedules);
    pp('$mm getOrgFieldMonitorSchedules found: 🔵 ${schedules.length} schedules ');

    return schedules;
  }

  Future<List<Photo>> getPhotos(
      {required String organizationId, required bool forceRefresh}) async {
    var photos = <Photo>[];
    try {
      photos = await cacheManager.getOrganizationPhotos();
      if (photos.isEmpty || forceRefresh) {
        photos = await DataAPI.getOrganizationPhotos(organizationId);
        await cacheManager.addPhotos(photos: photos);
      }
      photoController.sink.add(photos);
      pp('$mm getPhotos found: 💜 ${photos.length} photos 💜 ');
    } catch (e) {
      pp('😈😈😈😈😈 MonitorBloc: getOrganizationPhotos FAILED: 😈😈😈😈😈 $e');
      rethrow;
    }

    return photos;
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
      {required String organizationId, required bool forceRefresh}) async {
    var videos = <Video>[];
    try {

        videos = await cacheManager.getVideos();

      if (videos.isEmpty || forceRefresh) {
        videos = await DataAPI.getOrganizationVideos(organizationId);
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

  Future<List<Audio>> getAudios(
      {required String organizationId, required bool forceRefresh}) async {
    var audios = <Audio>[];
    var android = UniversalPlatform.isAndroid;

    try {
      audios = await cacheManager.getOrganizationAudios();
      if (audios.isEmpty || forceRefresh) {
        audios = await DataAPI.getOrganizationAudios(organizationId);
        if (android) await cacheManager.addAudios(audios: audios);
      }
      audioController.sink.add(audios);
      pp('$mm getAudios found: 💜 ${audios.length} Audios ');
    } catch (e) {
      pp('😈😈😈😈😈 MonitorBloc: getOrganizationAudios FAILED');
      rethrow;
    }

    return audios;
  }

  Future<List<Project>> getOrganizationProjects(
      {required String organizationId, required bool forceRefresh}) async {
    var projects = await cacheManager.getOrganizationProjects();

    try {
      if (projects.isEmpty || forceRefresh) {
        projects = await DataAPI.findProjectsByOrganization(organizationId);
      }
      projController.sink.add(projects);
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
