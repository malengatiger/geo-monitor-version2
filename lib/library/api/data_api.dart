import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart' as dot;
import 'package:geo_monitor/library/bloc/connection_check.dart';
import 'package:geo_monitor/library/data/organization_registration_bag.dart';
import 'package:geo_monitor/library/data/project_polygon.dart';
import 'package:geo_monitor/library/emojis.dart';
import 'package:http/http.dart' as http;
import '../auth/app_auth.dart';
import '../data/audio.dart';
import '../data/city.dart';
import '../data/community.dart';
import '../data/condition.dart';
import '../data/counters.dart';
import '../data/country.dart';
import '../data/data_bag.dart';
import '../data/field_monitor_schedule.dart';
import '../data/geofence_event.dart';
import '../data/org_message.dart';
import '../data/organization.dart';
import '../data/photo.dart';
import '../data/project.dart';
import '../data/project_position.dart';
import '../data/questionnaire.dart';
import '../data/section.dart';
import '../data/user.dart';
import '../data/video.dart';

import '../functions.dart';
import '../generic_functions.dart' as gen;
import '../hive_util.dart';

class DataAPI {
  static Map<String, String> headers = {
    'Content-type': 'application/json',
    'Accept': 'application/json',
  };

  static String? activeURL;
  static bool isDevelopmentStatus = true;
  static String? url;

  static Future<String?> getUrl() async {
    var conn = await connectionCheck.internetAvailable();
    if (!conn) {
      throw Exception('Internet connection not available');
    }
    if (url == null) {
      pp('$mm 🐤🐤🐤🐤 Getting url via .env settings: ${url ?? 'NO URL YET'}');
      String? status = dot.dotenv.env['CURRENT_STATUS'];
      pp('$mm 🐤🐤🐤🐤 DataAPI: getUrl: Status from .env: $status');
      if (status == 'dev') {
        isDevelopmentStatus = true;
        url = dot.dotenv.env['DEV_URL'];
        pp('$mm Status of the app is  DEVELOPMENT 🌎 🌎 🌎 $url');
        return url!;
      } else {
        isDevelopmentStatus = false;
        url = dot.dotenv.env['PROD_URL'];
        pp('$mm Status of the app is PRODUCTION 🌎 🌎 🌎 $url');
        return url!;
      }
    } else {
      return url!;
    }
  }

  static Future<FieldMonitorSchedule> addFieldMonitorSchedule(
      FieldMonitorSchedule monitorSchedule) async {
    String? mURL = await getUrl();
    Map bag = monitorSchedule.toJson();
    pp('DataAPI: ☕️ ☕️ ☕️ bag about to be sent to backend: check name: ☕️ $bag');
    try {
      var result =
          await _callWebAPIPost('${mURL!}addFieldMonitorSchedule', bag);
      var s = FieldMonitorSchedule.fromJson(result);
      await hiveUtil.addFieldMonitorSchedule(schedule: s);
      return s;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<GeofenceEvent> addGeofenceEvent(
      GeofenceEvent geofenceEvent) async {
    String? mURL = await getUrl();
    Map bag = geofenceEvent.toJson();

    try {
      var result = await _callWebAPIPost('${mURL!}addGeofenceEvent', bag);
      var s = GeofenceEvent.fromJson(result);
      await hiveUtil.addGeofenceEvent(geofenceEvent: s);
      return s;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<List<FieldMonitorSchedule>> getProjectFieldMonitorSchedules(
      String projectId) async {
    String? mURL = await getUrl();
    List<FieldMonitorSchedule> mList = [];
    try {
      List result = await _sendHttpGET(
          '${mURL!}getProjectFieldMonitorSchedules?projectId=$projectId');
      for (var element in result) {
        mList.add(FieldMonitorSchedule.fromJson(element));
      }
      pp('🌿 🌿 🌿 getProjectFieldMonitorSchedules returned: 🌿 ${mList.length}');
      await hiveUtil.addFieldMonitorSchedules(schedules: mList);
      return mList;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<List<FieldMonitorSchedule>> getUserFieldMonitorSchedules(
      String userId) async {
    String? mURL = await getUrl();
    List<FieldMonitorSchedule> mList = [];
    try {
      List result = await _sendHttpGET(
          '${mURL!}getUserFieldMonitorSchedules?projectId=$userId');
      for (var element in result) {
        mList.add(FieldMonitorSchedule.fromJson(element));
      }
      pp('🌿 🌿 🌿 getProjectFieldMonitorSchedules returned: 🌿 ${mList.length}');
      await hiveUtil.addFieldMonitorSchedules(schedules: mList);
      return mList;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<String> testUploadPhoto() async {
    String? mURL = await getUrl();
    dynamic result;
    try {
      result = await _sendHttpGET('${mURL!}testUploadPhoto');

      pp('$mm 🌿🌿🌿 testUploadPhoto returned: 🌿 $result');
      return result["url"];
    } catch (e) {
      pp('$mm 🌿🌿🌿 testUploadPhoto returned with error below: 🌿 $result');
      pp(e);
      rethrow;
    }
  }

  static Future<List<FieldMonitorSchedule>> getMonitorFieldMonitorSchedules(
      String userId) async {
    String? mURL = await getUrl();
    List<FieldMonitorSchedule> mList = [];
    try {
      List result = await _sendHttpGET(
          '${mURL!}getMonitorFieldMonitorSchedules?userId=$userId');
      for (var element in result) {
        mList.add(FieldMonitorSchedule.fromJson(element));
      }
      pp('🌿 🌿 🌿 getMonitorFieldMonitorSchedules returned: 🌿 ${mList.length}');
      await hiveUtil.addFieldMonitorSchedules(schedules: mList);
      return mList;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<List<FieldMonitorSchedule>> getOrgFieldMonitorSchedules(
      String organizationId) async {
    String? mURL = await getUrl();
    List<FieldMonitorSchedule> mList = [];
    try {
      List result = await _sendHttpGET(
          '${mURL!}getOrgFieldMonitorSchedules?organizationId=$organizationId');
      for (var element in result) {
        mList.add(FieldMonitorSchedule.fromJson(element));
      }
      pp('🌿 🌿 🌿 getOrgFieldMonitorSchedules returned: 🌿 ${mList.length}');
      await hiveUtil.addFieldMonitorSchedules(schedules: mList);
      return mList;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<User> addUser(User user) async {
    String? mURL = await getUrl();
    Map bag = user.toJson();
    pp('DataAPI: ☕️ ☕️ ☕️ bag about to be sent to backend: check name: ☕️ $bag');
    try {
      var result = await _callWebAPIPost('${mURL!}addUser', bag);
      var u = User.fromJson(result);
      await hiveUtil.addUser(user: u);
      return u;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<OrganizationRegistrationBag> registerOrganization(
      OrganizationRegistrationBag orgBag) async {
    String? mURL = await getUrl();
    Map bag = orgBag.toJson();
    pp('$mm️ OrganizationRegistrationBag about to be sent to backend: check name: ☕️ $bag');
    try {
      var result = await _callWebAPIPost('${mURL!}registerOrganization', bag);
      var u = OrganizationRegistrationBag.fromJson(result);
      await hiveUtil.addRegistration(bag: u);
      await hiveUtil.addUsers(users: u.sampleUsers!);
      await hiveUtil.addProject(project: u.sampleProject!);
      await hiveUtil.addProjectPosition(
          projectPosition: u.sampleProjectPosition!);
      pp('$mm️ Organization RegistrationBag complete: org:: ☕️ ${u.organization!.name!}');

      return u;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }


  static Future<User> registerUser( User user) async {
    String? mURL = await getUrl();
    Map bag = user.toJson();
    pp('$mm️ User about to be sent to backend: check name: ☕️ $bag');
    try {
      var result = await _callWebAPIPost('${mURL!}createUser', bag);
      var u = User.fromJson(result);
      await hiveUtil.addUser(user: u);

      pp('$mm️ User creation complete: user: ☕️ ${u.toJson()}');

      return u;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<User> updateUser(User user) async {
    String? mURL = await getUrl();
    Map bag = user.toJson();
    try {
      var result = await _callWebAPIPost('${mURL!}updateUser', bag);
      var users = findUsersByOrganization(user.organizationId!);
      return User.fromJson(result);
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<ProjectCount> getProjectCount(String projectId) async {
    String? mURL = await getUrl();
    try {
      var result =
          await _sendHttpGET('${mURL!}getCountsByProject?projectId=$projectId');
      var cnt = ProjectCount.fromJson(result);
      pp('🌿 🌿 🌿 Project count returned: 🌿 ${cnt.toJson()}');
      return cnt;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<UserCount> getUserCount(String userId) async {
    String? mURL = await getUrl();
    try {
      var result = await _sendHttpGET('${mURL!}getCountsByUser?userId=$userId');
      var cnt = UserCount.fromJson(result);
      pp('🌿 🌿 🌿 User count returned: 🌿 ${cnt.toJson()}');
      return cnt;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<Project> findProjectById(String projectId) async {
    String? mURL = await getUrl();
    Map bag = {
      'projectId': projectId,
    };
    try {
      var result = await _callWebAPIPost('${mURL!}findProjectById', bag);
      var p = Project.fromJson(result);
      await hiveUtil.addProject(project: p);
      return p;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<List<ProjectPosition>> findProjectPositionsById(
      String projectId) async {
    String? mURL = await getUrl();
    Map bag = {
      'projectId': projectId,
    };
    try {
      var result = await _sendHttpGET(
          '${mURL!}getProjectPositions?projectId=$projectId');
      List<ProjectPosition> list = [];
      result.forEach((m) {
        list.add(ProjectPosition.fromJson(m));
      });
      await hiveUtil.addProjectPositions(positions: list);
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<List<ProjectPolygon>> findProjectPolygonsById(
      String projectId) async {
    String? mURL = await getUrl();

    try {
      var result =
          await _sendHttpGET('${mURL!}getProjectPolygons?projectId=$projectId');
      List<ProjectPolygon> list = [];
      result.forEach((m) {
        list.add(ProjectPolygon.fromJson(m));
      });
      await hiveUtil.addProjectPolygons(polygons: list);
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<List<ProjectPosition>> getOrganizationProjectPositions(
      String organizationId) async {
    String? mURL = await getUrl();

    try {
      var result = await _sendHttpGET(
          '${mURL!}getOrganizationProjectPositions?organizationId=$organizationId');
      List<ProjectPosition> list = [];
      result.forEach((m) {
        list.add(ProjectPosition.fromJson(m));
      });
      await hiveUtil.addProjectPositions(positions: list);
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<DataBag> getOrganizationData(String organizationId) async {
    String? mURL = await getUrl();

    try {
      var result = await _sendHttpGET(
          '${mURL!}getOrganizationData?organizationId=$organizationId');

      final bag = DataBag.fromJson(result);
      pp('\n$mm Data returned from server, adding to Hive cache ...');
      await hiveUtil.addProjects(projects: bag.projects!);
      await hiveUtil.addProjectPolygons(polygons: bag.projectPolygons!);
      await hiveUtil.addProjectPositions(positions: bag.projectPositions!);
      await hiveUtil.addUsers(users: bag.users!);
      await hiveUtil.addPhotos(photos: bag.photos!);
      await hiveUtil.addVideos(videos: bag.videos!);
      await hiveUtil.addFieldMonitorSchedules(
          schedules: bag.fieldMonitorSchedules!);
      pp('\n$mm Data returned from server, sending to caller ...');
      return bag;
    } catch (e) {
      pp('$mm getOrganizationData: $e');
      rethrow;
    }
  }

  static Future<User?> getUser({required String userId}) async {
    String? mURL = await getUrl();
    User? user;
    var result = await _sendHttpGET('${mURL!}getUserById?userId=$userId');
    user = User.fromJson(result);
    return user;
  }

  static Future<DataBag?> getUserData(String userId) async {
    String? mURL = await getUrl();
    DataBag? bag;
    try {
      var result = await _sendHttpGET('${mURL!}getUserData?userId=$userId');

      bag = DataBag.fromJson(result);
      await hiveUtil.addProjects(projects: bag.projects!);
      await hiveUtil.addProjectPolygons(polygons: bag.projectPolygons!);
      await hiveUtil.addProjectPositions(positions: bag.projectPositions!);
      await hiveUtil.addUsers(users: bag.users!);
      await hiveUtil.addPhotos(photos: bag.photos!);
      await hiveUtil.addVideos(videos: bag.videos!);
      await hiveUtil.addFieldMonitorSchedules(
          schedules: bag.fieldMonitorSchedules!);

      return bag;
    } catch (e) {
      pp(e);
      throw Exception('User data refresh fell down!: $e');
    }
  }

  static Future<List<ProjectPosition>> getProjectPositions(
      String projectId) async {
    String? mURL = await getUrl();

    try {
      var result = await _sendHttpGET(
          '${mURL!}getProjectPositions?projectId=$projectId');
      List<ProjectPosition> list = [];
      result.forEach((m) {
        list.add(ProjectPosition.fromJson(m));
      });
      await hiveUtil.addProjectPositions(positions: list);
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<List<Photo>> findPhotosByProject(String projectId) async {
    String? mURL = await getUrl();

    try {
      var result =
          await _sendHttpGET('${mURL!}getProjectPhotos?projectId=$projectId');
      List<Photo> list = [];
      result.forEach((m) {
        list.add(Photo.fromJson(m));
      });
      await hiveUtil.addPhotos(photos: list);
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<List<Photo>> getUserProjectPhotos(String userId) async {
    String? mURL = await getUrl();

    try {
      var result =
          await _sendHttpGET('${mURL!}getUserProjectPhotos?userId=$userId');
      List<Photo> list = [];
      result.forEach((m) {
        list.add(Photo.fromJson(m));
      });
      await hiveUtil.addPhotos(photos: list);
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<DataBag> getProjectData(String projectId) async {
    String? mURL = await getUrl();

    var bag = DataBag(
        photos: [],
        videos: [],
        fieldMonitorSchedules: [],
        projects: [],
        users: [],
        audios: [],
        projectPositions: [],
        projectPolygons: [],
        date: DateTime.now().toIso8601String());
    try {
      var result =
          await _sendHttpGET('${mURL!}getProjectData?projectId=$projectId');

      bag = DataBag.fromJson(result);
      await hiveUtil.addProjects(projects: bag.projects!);
      await hiveUtil.addProjectPolygons(polygons: bag.projectPolygons!);
      await hiveUtil.addProjectPositions(positions: bag.projectPositions!);
      await hiveUtil.addUsers(users: bag.users!);
      await hiveUtil.addPhotos(photos: bag.photos!);
      await hiveUtil.addVideos(videos: bag.videos!);
      await hiveUtil.addAudios(audios: bag.audios!);
      await hiveUtil.addFieldMonitorSchedules(
          schedules: bag.fieldMonitorSchedules!);
    } catch (e) {
      pp(e);
      rethrow;
    }
    return bag;
  }

  static Future<List<Video>> getUserProjectVideos(String userId) async {
    String? mURL = await getUrl();

    try {
      var result =
          await _sendHttpGET('${mURL!}getUserProjectVideos?userId=$userId');
      List<Video> list = [];
      result.forEach((m) {
        list.add(Video.fromJson(m));
      });
      await hiveUtil.addVideos(videos: list);
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<List<Video>> findVideosById(String projectId) async {
    String? mURL = await getUrl();

    try {
      var result =
          await _sendHttpGET('${mURL!}getProjectVideos?projectId=$projectId');
      List<Video> list = [];
      result.forEach((m) {
        list.add(Video.fromJson(m));
      });
      await hiveUtil.addVideos(videos: list);
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<List<User>> findUsersByOrganization(
      String organizationId) async {
    String? mURL = await getUrl();
    var cmd = 'getOrganizationUsers?organizationId=$organizationId';
    var url = '$mURL$cmd';
    try {
      List result = await _sendHttpGET(url);
      pp('$mm findUsersByOrganization: 🍏 found: ${result.length} users');
      List<User> list = [];
      for (var m in result) {
        list.add(User.fromJson(m));
      }
      await hiveUtil.addUsers(users: list);
      pp('$mm findUsersByOrganization: 🍏 returning objects for: ${list.length} users');
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static const mm = '🍏🍏🍏 DataAPI: ';
  static Future<List<Project>> findProjectsByOrganization(
      String organizationId) async {
    pp('$mm findProjectsByOrganization: 🍏 id: $organizationId');
    String? mURL = await getUrl();
    var cmd = 'findProjectsByOrganization';
    var url = '$mURL$cmd?organizationId=$organizationId';
    try {
      List result = await _sendHttpGET(url);
      pp('$mm findProjectsByOrganization: 🍏 result: ${result.length} projects');
      List<Project> list = [];
      for (var m in result) {
        list.add(Project.fromJson(m));
      }
      pp('$mm ${list.length} project objects built .... about to cache in local mongo');
      await hiveUtil.addProjects(projects: list);
      return list;
    } catch (e) {
      pp('Houston, 😈😈😈😈😈 we have a problem! 😈😈😈😈😈 $e');
      gen.p(e);
      rethrow;
    }
  }

  static Future<Organization?> findOrganizationById(
      String organizationId) async {
    pp('$mm findOrganizationById: 🍏 id: $organizationId');
    String? mURL = await getUrl();
    var cmd = 'findOrganizationById';
    var url = '$mURL$cmd?organizationId=$organizationId';
    try {
      var result = await _sendHttpGET(url);
      pp('$mm findOrganizationById: 🍏 result: $result ');
      Organization? org = Organization.fromJson(result);
      await hiveUtil.addOrganization(organization: org);
      return org;
    } catch (e) {
      pp('Houston, 😈😈😈😈😈 we have a problem! 😈😈😈😈😈 $e');
      gen.p(e);
      rethrow;
    }
  }

  static Future<List<Photo>> getOrganizationPhotos(
      String organizationId) async {
    pp('$mm getOrganizationPhotos: 🍏 id: $organizationId');
    String? mURL = await getUrl();
    var cmd = 'getOrganizationPhotos';
    var url = '$mURL$cmd?organizationId=$organizationId';
    try {
      List result = await _sendHttpGET(url);
      pp('$mm getOrganizationPhotos: 🍏 found: ${result.length} org photos');
      List<Photo> list = [];
      for (var m in result) {
        list.add(Photo.fromJson(m));
      }
      await hiveUtil.addPhotos(photos: list);
      return list;
    } catch (e) {
      pp('Houston, 😈😈😈😈😈 we have a problem! 😈😈😈😈😈');
      gen.p(e);
      rethrow;
    }
  }

  static Future<List<Video>> getOrganizationVideos(
      String organizationId) async {
    pp('$mm getOrganizationVideos: 🍏 id: $organizationId');
    String? mURL = await getUrl();
    var cmd = 'getOrganizationVideos';
    var url = '$mURL$cmd?organizationId=$organizationId';
    try {
      List result = await _sendHttpGET(url);
      List<Video> list = [];
      for (var m in result) {
        list.add(Video.fromJson(m));
      }
      await hiveUtil.addVideos(videos: list);
      return list;
    } catch (e) {
      pp('Houston, 😈😈😈😈😈 we have a problem! 😈😈😈😈😈');
      gen.p(e);
      rethrow;
    }
  }

  static Future<List<Project>> getOrganizationProjects(
      String organizationId) async {
    pp('$mm getOrganizationProjects: 🍏 id: $organizationId');
    String? mURL = await getUrl();
    var cmd = 'getOrganizationProjects';
    var url = '$mURL$cmd?organizationId=$organizationId';
    try {
      List result = await _sendHttpGET(url);
      List<Project> list = [];
      for (var m in result) {
        list.add(Project.fromJson(m));
      }
      await hiveUtil.addProjects(projects: list);
      return list;
    } catch (e) {
      pp('Houston, 😈😈😈😈😈 we have a problem! 😈😈😈😈😈');
      gen.p(e);
      rethrow;
    }
  }

  static Future<List<GeofenceEvent>> getGeofenceEventsByProjectPosition(
      String projectPositionId) async {
    String? mURL = await getUrl();
    var cmd = 'getGeofenceEventsByProjectPosition';
    var url = '$mURL$cmd?projectPositionId=$projectPositionId';
    try {
      List result = await _sendHttpGET(url);
      List<GeofenceEvent> list = [];
      for (var m in result) {
        list.add(GeofenceEvent.fromJson(m));
      }

      for (var b in list) {
        await hiveUtil.addGeofenceEvent(geofenceEvent: b);
      }
      return list;
    } catch (e) {
      pp('Houston, 😈😈😈😈😈 we have a problem! 😈😈😈😈😈');
      gen.p(e);
      rethrow;
    }
  }

  static Future<List<GeofenceEvent>> getGeofenceEventsByUser(
      String userId) async {
    String? mURL = await getUrl();
    var cmd = 'getGeofenceEventsByUser';
    var url = '$mURL$cmd?userId=$userId';
    try {
      List result = await _sendHttpGET(url);
      List<GeofenceEvent> list = [];
      for (var m in result) {
        list.add(GeofenceEvent.fromJson(m));
      }

      for (var b in list) {
        await hiveUtil.addGeofenceEvent(geofenceEvent: b);
      }
      return list;
    } catch (e) {
      pp('Houston, 😈😈😈😈😈 we have a problem! 😈😈😈😈😈');
      gen.p(e);
      rethrow;
    }
  }

  static Future<List<Project>> findProjectsByLocation(
      {required double latitude,
      required double longitude,
      required double radiusInKM}) async {
    pp('$mm findProjectsByLocation: 🍏 radiusInKM: $radiusInKM');
    String? mURL = await getUrl();
    var cmd = 'findProjectsByLocation';
    var url =
        '$mURL$cmd?latitude=$latitude&longitude=$longitude&radiusInKM=$radiusInKM';
    try {
      List result = await _sendHttpGET(url);
      List<Project> list = [];
      for (var m in result) {
        list.add(Project.fromJson(m));
      }
      await hiveUtil.addProjects(projects: list);
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<List<City>> findCitiesByLocation(
      {required double latitude,
      required double longitude,
      required double radiusInKM}) async {
    pp('$mm findCitiesByLocation: 🍏 radiusInKM: $radiusInKM');
    String? mURL = await getUrl();
    var cmd = 'findCitiesByLocation';
    var url =
        '$mURL$cmd?latitude=$latitude&longitude=$longitude&radiusInKM=$radiusInKM';
    try {
      List result = await _sendHttpGET(url);
      List<City> list = [];
      for (var m in result) {
        list.add(City.fromJson(m));
      }
      pp('$mm findCitiesByLocation: 🍏 found: ${list.length} cities');
      await hiveUtil.addCities(cities: list);
      for (var city in list) {
        pp('$mm city found by findCitiesByLocation call: ${city.toJson()} \n');
      }
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<List<Questionnaire>> getQuestionnairesByOrganization(
      String organizationId) async {
    pp('$mm getQuestionnairesByOrganization: 🍏 id: $organizationId');
    String? mURL = await getUrl();
    var cmd = 'getQuestionnairesByOrganization?organizationId=$organizationId';
    var url = '$mURL$cmd';
    try {
      List result = await _sendHttpGET(url);
      List<Questionnaire> list = [];
      for (var m in result) {
        list.add(Questionnaire.fromJson(m));
      }
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<Community> updateCommunity(Community community) async {
    String? mURL = await getUrl();
    Map bag = community.toJson();
    try {
      var result = await _callWebAPIPost('${mURL!}updateCommunity', bag);
      return Community.fromJson(result);
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<Community> addCommunity(Community community) async {
    String? mURL = await getUrl();
    Map bag = community.toJson();
    try {
      var result = await _callWebAPIPost('${mURL!}addCommunity', bag);
      var c = Community.fromJson(result);
      await hiveUtil.addCommunity(community: c);
      return c;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  // static Future<GeofenceEvent> addGeofenceEvent(GeofenceEvent geofenceEvent) async {
  //   String? mURL = await getUrl();
  //   Map bag = geofenceEvent.toJson();
  //   try {
  //     var result = await _callWebAPIPost(mURL! + 'addGeofenceEvent', bag);
  //     var c = GeofenceEvent.fromJson(result);
  //     await hiveUtil.addGeofenceEvent(geofenceEvent: c);
  //     return c;
  //   } catch (e) {
  //     pp(e);
  //     rethrow;
  //   }
  // }

  static Future addPointToPolygon(
      {required String communityId,
      required double latitude,
      required double longitude}) async {
    String? mURL = await getUrl();
    Map bag = {
      'communityId': communityId,
      'latitude': latitude,
      'longitude': longitude,
    };
    try {
      var result = await _callWebAPIPost('${mURL!}addPointToPolygon', bag);
      return result;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future addQuestionnaireSection(
      {required String questionnaireId, required Section section}) async {
    String? mURL = await getUrl();
    Map bag = {
      'questionnaireId': questionnaireId,
      'section': section.toJson(),
    };
    try {
      var result =
          await _callWebAPIPost('${mURL!}addQuestionnaireSection', bag);
      return result;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<List<Community>> findCommunitiesByCountry(
      String countryId) async {
    String? mURL = await getUrl();

    pp('🍏🍏🍏🍏 ..... findCommunitiesByCountry ');
    var cmd = 'findCommunitiesByCountry';
    var url = '$mURL$cmd?countryId=$countryId';

    List result = await _sendHttpGET(url);
    List<Community> communityList = [];
    for (var m in result) {
      communityList.add(Community.fromJson(m));
    }
    pp('🍏 🍏 🍏 findCommunitiesByCountry found ${communityList.length}');
    await hiveUtil.addCommunities(communities: communityList);
    return communityList;
  }

  static Future<Project> addProject(Project project) async {
    String? mURL = await getUrl();
    Map bag = project.toJson();
    try {
      var result = await _callWebAPIPost('${mURL!}addProject', bag);
      var p = Project.fromJson(result);
      await hiveUtil.addProject(project: p);
      return p;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<Project> updateProject(Project project) async {
    String? mURL = await getUrl();
    Map bag = project.toJson();
    try {
      var result = await _callWebAPIPost('${mURL!}updateProject', bag);
      var p = Project.fromJson(result);
      await hiveUtil.addProject(project: p);
      return p;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<Project> addSettlementToProject(
      {required String projectId, required String settlementId}) async {
    String? mURL = await getUrl();
    Map bag = {
      'projectId': projectId,
      'settlementId': settlementId,
    };
    try {
      var result = await _callWebAPIPost('${mURL!}addSettlementToProject', bag);
      var proj = Project.fromJson(result);
      await hiveUtil.addProject(project: proj);
      return proj;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<ProjectPosition> addProjectPosition(
      {required ProjectPosition position}) async {
    String? mURL = await getUrl();
    Map bag = position.toJson();
    try {
      var result = await _callWebAPIPost('${mURL!}addProjectPosition', bag);

      var pp = ProjectPosition.fromJson(result);
      await hiveUtil.addProjectPosition(projectPosition: pp);
      return pp;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<ProjectPolygon> addProjectPolygon(
      {required ProjectPolygon polygon}) async {
    String? mURL = await getUrl();
    Map bag = polygon.toJson();
    try {
      var result = await _callWebAPIPost('${mURL!}addProjectPolygon', bag);

      var pp = ProjectPolygon.fromJson(result);
      await hiveUtil.addProjectPolygon(projectPolygon: pp);
      return pp;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future addPhoto(Photo photo) async {
    String? mURL = await getUrl();
    try {
      var result = await _callWebAPIPost('${mURL!}addPhoto', photo.toJson());
      pp('\n\n\n$mm 🔴🔴🔴 DataAPI addPhoto succeeded. Everything OK?? 🔴🔴🔴\n\n');

      pp(result);
      var px = Photo.fromJson(result);
      await hiveUtil.addPhoto(photo: px);
      pp('\n\n$mm addPhoto has added photo to DB and to Hive cache');
      return result;
    } catch (e) {
      pp('\n\n\n$mm 🔴🔴🔴 DataAPI addPhoto failed. Something fucked up here! ... 🔴🔴🔴\n\n');
      pp(e);
      rethrow;
    }
  }

  static Future addVideo(Video video) async {
    String? mURL = await getUrl();

    try {
      var result = await _callWebAPIPost('${mURL!}addVideo', video.toJson());
      pp('$mm addVideo has added photo to DB and to Hive cache');
      var vx = Video.fromJson(result);
      await hiveUtil.addVideo(video: vx);
      return result;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }
  static Future<Audio> addAudio(Audio audio) async {
    String? mURL = await getUrl();

    try {
      var result = await _callWebAPIPost('${mURL!}addAudio', audio.toJson());
      var audiox = Audio.fromJson(result);
      pp('$mm addAudio has added audio to DB : 😡😡😡 fromJson:: ${audiox.toJson()}');

      var x = await hiveUtil.addAudio(audio: audiox);
      pp('$mm addAudio has added audio to Hive??? : 😡😡😡 result from hive: $x');

      return audiox;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future addCondition(Condition condition) async {
    String? mURL = await getUrl();

    try {
      var result =
          await _callWebAPIPost('${mURL!}addCondition', condition.toJson());
      pp(result);
      await hiveUtil.addCondition(condition: condition);
      return result;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<Photo> addSettlementPhoto(
      {required String settlementId,
      required String url,
      required String comment,
      required double latitude,
      longitude,
      required String userId}) async {
    String? mURL = await getUrl();
    Map bag = {
      'settlementId': settlementId,
      'url': url,
      'comment': comment,
      'latitude': latitude,
      'longitude': longitude,
      'userId': userId,
    };
    try {
      var result = await _callWebAPIPost('${mURL!}addSettlementPhoto', bag);

      var photo = Photo.fromJson(result);
      await hiveUtil.addPhoto(photo: photo);
      return photo;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<Video> addProjectVideo(
      {required String projectId,
      required String url,
      required String comment,
      required double latitude,
      longitude,
      required String userId}) async {
    String? mURL = await getUrl();
    Map bag = {
      'projectId': projectId,
      'url': url,
      'comment': comment,
      'latitude': latitude,
      'longitude': longitude,
      'userId': userId
    };
    try {
      var result = await _callWebAPIPost('${mURL!}addProjectVideo', bag);
      var video = Video.fromJson(result);
      await hiveUtil.addVideo(video: video);
      return video;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<Project> addProjectRating(
      {required String projectId,
      required String rating,
      required String comment,
      required double latitude,
      longitude,
      required String userId}) async {
    String? mURL = await getUrl();
    Map bag = {
      'projectId': projectId,
      'rating': rating,
      'comment': comment,
      'latitude': latitude,
      'longitude': longitude,
      'userId': userId
    };
    try {
      var result = await _callWebAPIPost('${mURL!}addProjectRating', bag);
      return Project.fromJson(result);
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<Questionnaire> addQuestionnaire(
      Questionnaire questionnaire) async {
    String? mURL = await getUrl();
    Map bag = questionnaire.toJson();
    prettyPrint(bag,
        'DataAPI  💦 💦 💦 addQuestionnaire: 🔆🔆 Sending to web api ......');
    try {
      var result = await _callWebAPIPost('${mURL!}addQuestionnaire', bag);
      return Questionnaire.fromJson(result);
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<List<Project>> findAllProjects(String organizationId) async {
    String? mURL = await getUrl();
    Map bag = {};
    try {
      List result = await _callWebAPIPost('${mURL!}findAllProjects', bag);
      List<Project> list = [];
      for (var m in result) {
        list.add(Project.fromJson(m));
      }
      await hiveUtil.addProjects(projects: list);
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<Organization> addOrganization(Organization org) async {
    String? mURL = await getUrl();
    Map bag = org.toJson();

    pp('DataAPI_addOrganization:  🍐 org Bag to be sent, check properties:  🍐 $bag');
    try {
      var result = await _callWebAPIPost('${mURL!}addOrganization', bag);
      var o = Organization.fromJson(result);
      await hiveUtil.addOrganization(organization: o);
      return o;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<OrgMessage> sendMessage(OrgMessage message) async {
    String? mURL = await getUrl();
    Map bag = message.toJson();

    pp('DataAPI_sendMessage:  🍐 org message to be sent, check properties:  🍐 $bag');
    try {
      var result = await _callWebAPIPost('${mURL!}sendMessage', bag);
      var m = OrgMessage.fromJson(result);
      await hiveUtil.addOrgMessage(message: m);
      return m;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<User?> findUserByEmail(String email) async {
    pp('🐤🐤🐤🐤 DataAPI : ... findUserByEmail $email ');
    String? mURL = await getUrl();
    assert(mURL != null);
    var command = "findUserByEmail?email=$email";

    try {
      pp('🐤🐤🐤🐤 DataAPI : ... 🥏 calling _callWebAPIPost .. 🥏 findUserByEmail $mURL$command ');
      var result = await _sendHttpGET(
        '$mURL$command',
      );
      pp(result);
      return User.fromJson(result);
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<User> findUserByUid(String uid) async {
    String? mURL = await getUrl();
    Map bag = {
      'uid': uid,
    };
    try {
      var result = await _callWebAPIPost('${mURL!}findUserByUid', bag);
      return User.fromJson(result);
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future<List<Country>> getCountries() async {
    String? mURL = await getUrl();
    var cmd = 'getCountries';
    var url = '$mURL$cmd';
    try {
      List result = await _sendHttpGET(url);
      List<Country> list = [];
      for (var m in result) {
        var entry = Country.fromJson(m);
        list.add(entry);
      }
      pp('🐤🐤🐤🐤 ${list.length} Countries found 🥏');
      list.sort((a, b) => a.name!.compareTo(b.name!));
      for (var value in list) {
        await hiveUtil.addCountry(country: value);
      }
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  static Future hello() async {
    String? mURL = await getUrl();
    var result = await _sendHttpGET(mURL!);
    pp('DataAPI: 🔴 🔴 🔴 hello: $result');
  }

  static Future ping() async {
    String? mURL = await getUrl();
    var result = await _sendHttpGET('${mURL!}ping');
    pp('DataAPI: 🔴 🔴 🔴 ping: $result');
  }

  static Future _callWebAPIPost(String mUrl, Map? bag) async {
    pp('$xz http POST call: 🔆 🔆 🔆  calling : 💙  $mUrl  💙 ');

    String? mBag;
    if (bag != null) {
      mBag = json.encode(bag);
    }
    var start = DateTime.now();
    var client = http.Client();
    var token = await AppAuth.getAuthToken();
    if (token != null) {
      pp('$xz http POST call: 😡 😡 😡 Firebase Auth Token: 💙️ Token is GOOD! 💙 ');
    }
    headers['Authorization'] = 'Bearer $token';
    try {
      var resp = await client.post(
        Uri.parse(mUrl),
        body: mBag,
        headers: headers,
      );
      if (resp.statusCode == 200) {
        pp('$xz http POST call RESPONSE: 💙💙 statusCode: 👌👌👌 ${resp.statusCode} 👌👌👌 💙 for $mUrl');
      } else {
        pp('👿👿👿 DataAPI._callWebAPIPost: 🔆 statusCode: 👿👿👿 ${resp.statusCode} 🔆🔆🔆 for $mUrl');
        pp(resp.body);
        throw Exception(
            '🚨 🚨 Status Code 🚨 ${resp.statusCode} 🚨 ${resp.body}');
      }
      var end = DateTime.now();
      pp('$xz http POST call: 🔆 elapsed time: ${end.difference(start).inSeconds} seconds 🔆 \n\n');
      try {
        var mJson = json.decode(resp.body);
        return mJson;
      } catch (e) {
        pp("👿👿👿👿👿👿👿 json.decode failed, returning response body");
        return resp.body;
      }
    } on SocketException {
      pp('\n\n$xz ${Emoji.redDot}${Emoji.redDot} ${Emoji.redDot} '
          'GeoMonitor Server not available. ${Emoji.redDot} Possible Internet Connection issue '
          '${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot}\n');
      throw 'GeoMonitor Server not available. Possible Internet Connection issue';
    } on HttpException {
      pp("$xz Couldn't find the post 😱");
      throw 'Could not find the post';
    } on FormatException {
      pp("$xz Bad response format 👎");
      throw 'Bad response format';
    } on TimeoutException {
      pp("$xz POST Request has timed out in $timeOutInSeconds seconds 👎");
      throw 'Request has timed out in $timeOutInSeconds seconds';
    }
  }

  static const timeOutInSeconds = 180;

  static const xz = '🌎🌎🌎🌎🌎🌎 DataAPI: ';
  static Future _sendHttpGET(String mUrl) async {
    pp('$xz http GET call:  🔆 🔆 🔆 calling : 💙  $mUrl  💙');
    var start = DateTime.now();
    var client = http.Client();
    var token = await AppAuth.getAuthToken();
    if (token != null) {
      pp('$xz http GET call: 😡😡😡 Firebase Auth Token: 💙️ Token is GOOD! 💙 ');
    }

    headers['Authorization'] = 'Bearer $token';

    try {
      var resp = await client.get(
        Uri.parse(mUrl),
        headers: headers,
      );
      pp('$xz http GET call RESPONSE: .... : 💙 statusCode: 👌👌👌 ${resp.statusCode} 👌👌👌 💙 for $mUrl');
      var end = DateTime.now();
      pp('$xz http GET call: 🔆 elapsed time for http: ${end.difference(start).inSeconds} seconds 🔆 \n\n');
      sendError(resp);
      var mJson = json.decode(resp.body);
      return mJson;
    } on SocketException {
      pp('$xz No Internet connection, really means that server cannot be reached 😑');
      throw 'GeoMonitor server cannot be reached at this time. Please try later';
    } on HttpException {
      pp("$xz Couldn't find the post 😱");
      throw 'Could not find the post';
    } on FormatException {
      pp("$xz Bad response format 👎");
      throw 'Bad response format';
    } on TimeoutException {
      pp("$xz GET Request has timed out in $timeOutInSeconds seconds 👎");
      throw 'Request has timed out in $timeOutInSeconds seconds';
    }
  }

  static void sendError(http.Response resp) {
    if (resp.statusCode != 200) {
      var msg =
          '😡 😡 The response is not 200; it is ${resp.statusCode}, NOT GOOD, throwing up !! 🥪 🥙 🌮  😡 ${resp.body}';
      pp(msg);
      throw Exception(msg);
    }
  }
}
