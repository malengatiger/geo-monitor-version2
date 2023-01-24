import 'dart:async';

import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
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


class OrganizationBlocWithGet extends GetxController{
  OrganizationBlocWithGet() {
    pp('$mm OrganizationBlocWithGet constructed');
  }
  final mm = '${Emoji.blueDot}${Emoji.blueDot}${Emoji.blueDot}${Emoji.blueDot}${Emoji.blueDot}${Emoji.appleRed} '
      'OrganizationBlocWithGet: ';
  //
  Future<void> addProjectToStream(Project project) async {

  }

  Future<void> addPhotoToStream(Photo photo) async {
    pp('\n\n$mm ......... addPhotoToStream ... ');
    try {
      var p = await hiveUtil.getOrganizationPhotos(photo.organizationId!);
      pp('$mm .... adding new photo -- sending ${p
          .length} photos to photoStream ');
      // _photoController.sink.add(p);
    } catch (e) {
      pp('$mm problem with stream? 🔴🔴🔴 $e');
    }
  }

  Future<void> addVideoToStream(Video video) async {
    pp('$mm addVideoToStream ...');
    var p = await hiveUtil.getOrganizationVideos(video.organizationId!);
    pp('$mm added new video -- sending ${p.length} videos to videoStream ');
    // _videoController.sink.add(p);
  }

  Future<void> addAudioToStream(Audio audio) async {
    pp('$mm addAudioToStream ...');
    var p = await hiveUtil.getOrganizationAudios();
    p.add(audio);
    pp('$mm added new audio -- sending ${p.length} audios to audioStream ');
    // _audioController.sink.add(p);
  }

  Future<void> addProjectPositionToStream(
      ProjectPosition projectPosition) async {
    pp('$mm addProjectPositionToStream ...');
    var p = await hiveUtil.getOrganizationProjectPositions(organizationId: projectPosition.organizationId!);
    pp('$mm added new projectPosition -- sending ${p.length} projectPositions to projectPositionsStream ');
    // _projectPositionsController.sink.add(p);
  }

  Future<void> addProjectPolygonToStream(ProjectPolygon projectPolygon) async {
    pp('$mm addProjectPolygonToStream ...');
    var p = await hiveUtil.getOrganizationProjectPolygons(organizationId: projectPolygon.organizationId!);
    pp('$mm added new projectPolygon -- sending ${p.length} projectPolygons to projectPolygonsStream ');
    // _projPolygonsController.sink.add(p);
  }

  DataBag? organizationDataBag;
  Future<DataBag> getOrganizationData(
      {required String organizationId, required bool forceRefresh}) async {
    pp('$mm refreshing organization data ... photos, videos and schedules'
        ' ...forceRefresh: $forceRefresh');

    var bag =
        await hiveUtil.getOrganizationData(organizationId: organizationId);

    if (forceRefresh) {
      pp('$mm get data from server .....................; forceRefresh: $forceRefresh');
      bag = await DataAPI.getOrganizationData(organizationId);
    } else {
      if (bag.isEmpty()) {
        pp('$mm bag is empty. No organization data anywhere yet? ... '
            'will force refresh, forceRefresh: $forceRefresh');
        bag = await DataAPI.getOrganizationData(organizationId);
      }
    }

    organizationDataBag = bag;
    update();
    _putContentsOfBagIntoStreams(bag);
    return bag;
  }

  void _putContentsOfBagIntoStreams(DataBag bag) {
    pp('$mm _putContentsOfBagIntoStreams: .................................... '
        '🔵 send data to streams ...');
    try {
      try {
        if (bag.photos != null) {
          bag.photos!.sort((a, b) => b.created!.compareTo(a.created!));
          // _photoController.sink.add(bag.photos!);
        }
      } catch (e) {
        pp('$mm _putContentsOfBagIntoStreams photos ERROR - $e');
      }
      try {
        if (bag.videos != null) {
          bag.videos!.sort((a, b) => b.created!.compareTo(a.created!));
          // _videoController.sink.add(bag.videos!);
        }
      } catch (e) {
        pp('$mm _putContentsOfBagIntoStreams videos ERROR - $e');
      }
      try {
        if (bag.audios != null) {
          bag.audios!.sort((a, b) => b.created!.compareTo(a.created!));
          // _audioController.sink.add(bag.audios!);
        }
      } catch (e) {
        pp('$mm _putContentsOfBagIntoStreams audios ERROR - $e');
      }
      try {
        if (bag.fieldMonitorSchedules != null) {
          bag.fieldMonitorSchedules!.sort((a, b) => b.date!.compareTo(a.date!));
          // _fieldMonitorScheduleController.sink.add(bag.fieldMonitorSchedules!);
        }
      } catch (e) {
        pp('$mm _putContentsOfBagIntoStreams fieldMonitorSchedules ERROR - $e');
      }
      try {
        if (bag.users != null) {
          bag.users!.sort((a, b) => a.name!.compareTo(b.name!));
          // _userController.sink.add(bag.users!);
        }
      } catch (e) {
        pp('$mm _putContentsOfBagIntoStreams users ERROR - $e');
      }
      try {
        if (bag.projects != null) {
          bag.projects!.sort((a, b) => a.name!.compareTo(b.name!));
          // _projController.sink.add(bag.projects!);
        }
      } catch (e) {
        pp('$mm _putContentsOfBagIntoStreams projects ERROR - $e');
      }
      try {
        if (bag.projectPositions != null) {
          // bag.projectPositions!
          //     .sort((a, b) => b.created!.compareTo(a.created!));
          // _projPositionsController.sink.add(bag.projectPositions!);
        }
      } catch (e) {
        pp('$mm _putContentsOfBagIntoStreams projectPositions ERROR - $e');
      }
      try {
        if (bag.projectPolygons != null) {
          bag.projectPolygons!.sort((a, b) => b.created!.compareTo(a.created!));
          // _projPolygonsController.sink.add(bag.projectPolygons!);
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
    var users = await hiveUtil.getUsers(organizationId: organizationId);

    if (users.isEmpty || forceRefresh) {
      users = await DataAPI.findUsersByOrganization(organizationId);
      pp('$mm getOrganizationUsers ... _users: ${users.length} ... will add to cache');
    }
    pp('$mm getOrganizationUsers found: 💜 ${users.length} users. adding to stream ... ');
    // _userController.sink.add(users);

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
    // _projPositionsController.sink.add(projectPositions);
    pp('$mm getOrganizationProjectPositions found: 💜 ${projectPositions.length} projectPositions from local or remote db ');
    return projectPositions;
  }

  Future<List<FieldMonitorSchedule>> getFieldMonitorSchedules(
      {required String organizationId, required bool forceRefresh}) async {
    var schedules =
        await hiveUtil.getOrganizationMonitorSchedules(organizationId);

    if (schedules.isEmpty || forceRefresh) {
      schedules = await DataAPI.getOrgFieldMonitorSchedules(organizationId);
      await hiveUtil.addFieldMonitorSchedules(schedules: schedules);
    }

    // _fieldMonitorScheduleController.sink.add(schedules);
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
      // _photoController.sink.add(photos);
      pp('$mm getPhotos found: 💜 ${photos.length} photos 💜 ');
    } catch (e) {
      pp('😈😈😈😈😈 MonitorBloc: getOrganizationPhotos FAILED: 😈😈😈😈😈 $e');
      rethrow;
    }

    return photos;
  }
  List<Video> videos = <Video>[];
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
      // _videoController.sink.add(videos);
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
    try {
      var android = UniversalPlatform.isAndroid;
      if (android) {
        //_videos = await hiveUtil.getVideos();
      } else {
        audios.clear();
      }
      if (audios.isEmpty || forceRefresh) {
        audios = await DataAPI.getOrganizationAudios(organizationId);
        if (android) await hiveUtil.addAudios(audios: audios);
      }
      // _audioController.sink.add(audios);
      pp('$mm getVideos found: 💜 ${audios.length} videos ');
    } catch (e) {
      pp('😈😈😈😈😈 MonitorBloc: getOrganizationAudios FAILED');
      rethrow;
    }

    return audios;
  }

  Future<List<Project>> getOrganizationProjects(
      {required String organizationId, required bool forceRefresh}) async {
    var projects = await hiveUtil.getOrganizationProjects();

    try {
      if (projects.isEmpty || forceRefresh) {
        projects = await DataAPI.findProjectsByOrganization(organizationId);
      }
      // _projController.sink.add(projects);
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
        await hiveUtil.getOrganizationById(organizationId: organizationId);

    try {
      org ??= await DataAPI.findOrganizationById(organizationId);

      pp('$mm OrganizationBlocWithGet: Organization found: 💜 ${org!.toJson()} ');
    } catch (e) {
      pp('$mm $e');
      rethrow;
    }

    return org;
  }
}
