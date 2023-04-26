import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geo_monitor/library/bloc/geo_exception.dart';
import 'package:geo_monitor/library/data/activity_model.dart';
import 'package:geo_monitor/library/data/app_error.dart';
import 'package:geo_monitor/library/data/location_request.dart';
import 'package:geo_monitor/library/data/organization_registration_bag.dart';
import 'package:geo_monitor/library/data/project_polygon.dart';
import 'package:geo_monitor/library/data/project_summary.dart';
import 'package:geo_monitor/library/emojis.dart';
import 'package:http/http.dart' as http;

import '../auth/app_auth.dart';
import '../bloc/organization_bloc.dart';
import '../bloc/project_bloc.dart';
import '../bloc/user_bloc.dart';
import '../cache_manager.dart';
import '../data/audio.dart';
import '../data/city.dart';
import '../data/community.dart';
import '../data/condition.dart';
import '../data/counters.dart';
import '../data/country.dart';
import '../data/data_bag.dart';
import '../data/field_monitor_schedule.dart';
import '../data/geofence_event.dart';
import '../data/kill_response.dart';
import '../data/location_response.dart';
import '../data/org_message.dart';
import '../data/organization.dart';
import '../data/photo.dart';
import '../data/project.dart';
import '../data/project_position.dart';
import '../data/questionnaire.dart';
import '../data/rating.dart';
import '../data/section.dart';
import '../data/settings_model.dart';
import '../data/translation_bag.dart';
import '../data/user.dart';
import '../data/video.dart';
import '../data/weather/daily_forecast.dart';
import '../data/weather/hourly_forecast.dart';
import '../functions.dart';
import '../generic_functions.dart' as gen;
import 'prefs_og.dart';

final http.Client client = http.Client();
const String devUrl = 'http://192.168.86.230:8080/geo/v1/';
final dataProvider = Provider<DataApiDog>((ref) => DataApiDog(client,devUrl));

/// Handles all data requests to backend api using Riverpod
class DataApiDog {
  Map<String, String> headers = {
    'Content-type': 'application/json',
    'Accept': 'application/json',
  };
  Map<String, String> zipHeaders = {
    'Content-type': 'application/json',
    'Accept': 'application/zip',
  };

  final String url;
  static const timeOutInSeconds = 120;
  final http.Client client;
  DataApiDog( this.client, this.url);


  String shoutOut() {
    return '${E.heartRed}${E.heartRed}${E.heartRed} Hey! I am a RiverPod Provider for managing database data!';
  }

  Future<FieldMonitorSchedule> addFieldMonitorSchedule(
      FieldMonitorSchedule monitorSchedule) async {
    Map bag = monitorSchedule.toJson();
    pp('DataAPI: ☕️ ☕️ ☕️ bag about to be sent to backend: check name: ☕️ $bag');
    try {
      var result = await _callWebAPIPost('${url!}addFieldMonitorSchedule', bag);
      var s = FieldMonitorSchedule.fromJson(result);
      await cacheManager.addFieldMonitorSchedule(schedule: s);
      return s;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<SettingsModel> addSettings(SettingsModel settings) async {
    Map bag = settings.toJson();
    try {
      var result = await _callWebAPIPost('${url!}addSettings', bag);
      var s = SettingsModel.fromJson(result);
      pp('$xz settings from db: ${s.toJson()}');
      await cacheManager.addSettings(settings: s);
      return s;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<GeofenceEvent> addGeofenceEvent(GeofenceEvent geofenceEvent) async {
    Map bag = geofenceEvent.toJson();

    var result = await _callWebAPIPost('${url!}addGeofenceEvent', bag);
    var s = GeofenceEvent.fromJson(result);
    await cacheManager.addGeofenceEvent(geofenceEvent: s);
    return s;
  }

  Future<LocationResponse> addLocationResponse(
      LocationResponse response) async {
    Map bag = response.toJson();

    var result = await _callWebAPIPost('${url!}addLocationResponse', bag);
    var s = LocationResponse.fromJson(result);
    await cacheManager.addLocationResponse(locationResponse: s);
    return s;
  }

  Future<List<FieldMonitorSchedule>> getProjectFieldMonitorSchedules(
      String projectId) async {
    List<FieldMonitorSchedule> mList = [];

    List result = await _sendHttpGET(
        '${url!}getProjectFieldMonitorSchedules?projectId=$projectId');
    for (var element in result) {
      mList.add(FieldMonitorSchedule.fromJson(element));
    }
    pp('🌿 🌿 🌿 getProjectFieldMonitorSchedules returned: 🌿 ${mList.length}');
    await cacheManager.addFieldMonitorSchedules(schedules: mList);
    return mList;
  }

  Future<List<FieldMonitorSchedule>> getUserFieldMonitorSchedules(
      String userId) async {
    List<FieldMonitorSchedule> mList = [];
    try {
      List result = await _sendHttpGET(
          '${url!}getUserFieldMonitorSchedules?projectId=$userId');
      for (var element in result) {
        mList.add(FieldMonitorSchedule.fromJson(element));
      }
      pp('🌿 🌿 🌿 getProjectFieldMonitorSchedules returned: 🌿 ${mList.length}');
      await cacheManager.addFieldMonitorSchedules(schedules: mList);
      return mList;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<String> testUploadPhoto() async {
    dynamic result;
    try {
      result = await _sendHttpGET('${url!}testUploadPhoto');

      pp('$xz 🌿🌿🌿 testUploadPhoto returned: 🌿 $result');
      return result["url"];
    } catch (e) {
      pp('$xz 🌿🌿🌿 testUploadPhoto returned with error below: 🌿 $result');
      pp(e);
      rethrow;
    }
  }

  Future<List<FieldMonitorSchedule>> getMonitorFieldMonitorSchedules(
      String userId) async {
    List<FieldMonitorSchedule> mList = [];
    try {
      List result = await _sendHttpGET(
          '${url!}getMonitorFieldMonitorSchedules?userId=$userId');
      for (var element in result) {
        mList.add(FieldMonitorSchedule.fromJson(element));
      }
      pp('🌿 🌿 🌿 getMonitorFieldMonitorSchedules returned: 🌿 ${mList.length}');
      await cacheManager.addFieldMonitorSchedules(schedules: mList);
      return mList;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<List<TranslationBag>> getTranslationBags() async {
    List<TranslationBag> mList = [];
    try {
      List result = await _sendHttpGET('${url!}getTranslationBags');
      for (var element in result) {
        mList.add(TranslationBag.fromJson(element));
      }
      pp('🌿 🌿 🌿 getTranslationBags returned: 🌿 ${mList.length}');
      return mList;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<List<SettingsModel>> getOrganizationSettings(
      String organizationId) async {
    List<SettingsModel> mList = [];

    List result = await _sendHttpGET(
        '${url!}getOrganizationSettings?organizationId=$organizationId');

    for (var element in result) {
      mList.add(SettingsModel.fromJson(element));
    }
    if (mList.isNotEmpty) {
      mList.sort((a, b) => DateTime.parse(b.created!)
          .millisecondsSinceEpoch
          .compareTo(DateTime.parse(a.created!).millisecondsSinceEpoch));
      await cacheManager.addSettings(settings: mList!.first);

      await prefsOGx.saveSettings(mList.first);
      await cacheManager.addSettings(settings: mList.first);
    }

    pp('🌿 🌿 🌿 getOrganizationSettings returned: 🌿 ${mList.length}');
    return mList;
  }

  Future<List<ActivityModel>> getOrganizationActivity(
      String organizationId, int hours) async {
    List<ActivityModel> mList = [];

    List result = await _sendHttpGET(
        '${url!}getOrganizationActivity?organizationId=$organizationId&hours=$hours');

    for (var element in result) {
      mList.add(ActivityModel.fromJson(element));
    }

    if (mList.isNotEmpty) {
      await cacheManager.deleteActivityModels();
      mList.sort((a, b) => b.date!.compareTo(a.date!));
      await cacheManager.addActivityModels(activities: mList);
      organizationBloc.activityController.sink.add(mList);
    }

    pp('$xz 🌿 🌿 🌿 getOrganizationActivity returned: 🌿 ${mList.length}');
    return mList;
  }

  Future<List<ProjectSummary>> getOrganizationDailySummary(
      String organizationId, String startDate, String endDate) async {
    List<ProjectSummary> mList = [];
    try {
      List result = await _sendHttpGET(
          '${url!}createDailyOrganizationSummaries?organizationId=$organizationId&startDate=$startDate&endDate=$endDate');

      for (var element in result) {
        mList.add(ProjectSummary.fromJson(element));
      }

      pp('$xz 🌿 🌿 🌿 getOrganization Summaries returned: 🌿 ${mList.length}');
      return mList;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<List<ProjectSummary>> getProjectDailySummary(
      String projectId, String startDate, String endDate) async {
    List<ProjectSummary> mList = [];
    try {
      List result = await _sendHttpGET(
          '${url!}createDailyProjectSummaries?projectId=$projectId&startDate=$startDate&endDate=$endDate');

      for (var element in result) {
        mList.add(ProjectSummary.fromJson(element));
      }

      pp('$xz 🌿 🌿 🌿 Daily Project Summaries returned: 🌿 ${mList.length}');
      return mList;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<List<ActivityModel>> getProjectActivity(
      String projectId, int hours) async {
    List<ActivityModel> mList = [];
    try {
      List result = await _sendHttpGET(
          '${url!}getProjectActivity?projectId=$projectId&hours=$hours');

      for (var element in result) {
        mList.add(ActivityModel.fromJson(element));
      }

      if (mList.isNotEmpty) {
        mList.sort((a, b) => b.date!.compareTo(a.date!));
        await cacheManager.addActivityModels(activities: mList);
        projectBloc.activityController.sink.add(mList);
      }

      pp('$xz 🌿 🌿 🌿 getProjectActivity returned: 🌿 ${mList.length}');
      return mList;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<List<ActivityModel>> getUserActivity(String userId, int hours) async {
    List<ActivityModel> mList = [];
    try {
      List result = await _sendHttpGET(
          '${url!}getUserActivity?userId=$userId&hours=$hours');

      for (var element in result) {
        mList.add(ActivityModel.fromJson(element));
      }

      if (mList.isNotEmpty) {
        mList.sort((a, b) => b.date!.compareTo(a.date!));
        await cacheManager.addActivityModels(activities: mList);
        userBloc.activityController.sink.add(mList);
      }

      pp('$xz 🌿 🌿 🌿 getProjectActivity returned: 🌿 ${mList.length}');
      return mList;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<List<FieldMonitorSchedule>> getOrgFieldMonitorSchedules(
      String organizationId, String startDate, String endDate) async {
    List<FieldMonitorSchedule> mList = [];
    try {
      List result = await _sendHttpGET(
          '${url!}getOrgFieldMonitorSchedules?organizationId=$organizationId&startDate=$startDate&endDate=$endDate');
      for (var element in result) {
        mList.add(FieldMonitorSchedule.fromJson(element));
      }
      pp('🌿 🌿 🌿 getOrgFieldMonitorSchedules returned: 🌿 ${mList.length}');
      await cacheManager.addFieldMonitorSchedules(schedules: mList);
      return mList;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<User> addUser(User user) async {
    user.active ??= 0;
    Map bag = user.toJson();
    pp('DataAPI: ☕️ ☕️ ☕️ bag about to be sent to backend: check name: ☕️ $bag');
    try {
      var result = await _callWebAPIPost('${url!}addUser', bag);
      var u = User.fromJson(result);
      await cacheManager.addUser(user: u);
      return u;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<int> deleteAuthUser(String userId) async {
    try {
      var result = await _sendHttpGET('${url!}deleteAuthUser?userId=$userId');
      var res = result['result'];
      pp('$xz 🌿 🌿 🌿 deleteAuthUser returned: 🌿 $result');
      return res;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<KillResponse> killUser(
      {required String userId, required String killerId}) async {
    try {
      var result = await _sendHttpGET(
          '${url!}killUser?userId=$userId&killerId=$killerId');
      var resp = KillResponse.fromJson(result);
      return resp;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<OrganizationRegistrationBag> registerOrganization(
      OrganizationRegistrationBag orgBag) async {
    Map bag = orgBag.toJson();
    pp('$xz️ OrganizationRegistrationBag about to be sent to backend: check name: ☕️ $bag');
    try {
      var result = await _callWebAPIPost('${url!}registerOrganization', bag);
      var u = OrganizationRegistrationBag.fromJson(result);

      await prefsOGx.saveUser(u.user!);
      await cacheManager.addRegistration(bag: u);
      await cacheManager.addUser(user: u.user!);
      await cacheManager.addProject(project: u.project!);
      await cacheManager.addSettings(settings: u.settings!);
      await cacheManager.addOrganization(organization: u.organization!);
      await cacheManager.addProjectPosition(
          projectPosition: u.projectPosition!);

      pp('$xz️ Organization registered! 😡😡 RegistrationBag arrived from backend server and cached in Hive; org:: ☕️ ${u.organization!.name!}');

      return u;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<User> createUser(User user) async {
    Map bag = user.toJson();
    try {
      var result = await _callWebAPIPost('${url!}createUser', bag);
      var u = User.fromJson(result);
      await cacheManager.addUser(user: u);

      pp('$xz️ User creation complete: user: ☕️ ${u.toJson()}');

      return u;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<User> updateUser(User user) async {
    Map bag = user.toJson();
    try {
      var result = await _callWebAPIPost('${url!}updateUser', bag);
      return User.fromJson(result);
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<int> updateAuthedUser(User user) async {
    pp('\n$xz updateAuthedUser started for ${user.name!}');

    Map bag = user.toJson();
    try {
      var result = await _callWebAPIPost('${url!}updateAuthedUser', bag);
      return result['returnCode'];
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<ProjectCount> getProjectCount(String projectId) async {
    try {
      var result =
          await _sendHttpGET('${url!}getCountsByProject?projectId=$projectId');
      var cnt = ProjectCount.fromJson(result);
      pp('🌿 🌿 🌿 Project count returned: 🌿 ${cnt.toJson()}');
      return cnt;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<UserCount> getUserCount(String userId) async {
    try {
      var result = await _sendHttpGET('${url!}getCountsByUser?userId=$userId');
      var cnt = UserCount.fromJson(result);
      pp('🌿 🌿 🌿 User count returned: 🌿 ${cnt.toJson()}');
      return cnt;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<Project> findProjectById(String projectId) async {
    Map bag = {
      'projectId': projectId,
    };
    try {
      var result = await _callWebAPIPost('${url!}findProjectById', bag);
      var p = Project.fromJson(result);
      await cacheManager.addProject(project: p);
      return p;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  //  Future<List<ProjectPosition>> findProjectPositionsById(
  //     String projectId, String startDate, String endDate) async {
  //
  //
  //   try {
  //     var result = await _sendHttpGET(
  //         '${url!}getProjectPositions?projectId=$projectId&startDate=$startDate&endDate=$endDate');
  //     List<ProjectPosition> list = [];
  //     result.forEach((m) {
  //       list.add(ProjectPosition.fromJson(m));
  //     });
  //     await cacheManager.addProjectPositions(positions: list);
  //     return list;
  //   } catch (e) {
  //     pp(e);
  //     rethrow;
  //   }
  // }

  Future<List<ProjectPolygon>> findProjectPolygonsById(String projectId) async {
    try {
      var result =
          await _sendHttpGET('${url!}getProjectPolygons?projectId=$projectId');
      List<ProjectPolygon> list = [];
      result.forEach((m) {
        list.add(ProjectPolygon.fromJson(m));
      });
      await cacheManager.addProjectPolygons(polygons: list);
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<List<ProjectPosition>> getOrganizationProjectPositions(
      String organizationId, String startDate, String endDate) async {
    try {
      var result = await _sendHttpGET(
          '${url!}getOrganizationProjectPositions?organizationId=$organizationId&startDate=$startDate&endDate=$endDate');
      List<ProjectPosition> list = [];
      result.forEach((m) {
        list.add(ProjectPosition.fromJson(m));
      });
      pp('$xz org project positions found .... ${list.length}');
      await cacheManager.addProjectPositions(positions: list);
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<List<ProjectPosition>> getAllOrganizationProjectPositions(
      String organizationId) async {
    try {
      var result = await _sendHttpGET(
          '${url!}getAllOrganizationProjectPositions?organizationId=$organizationId');
      List<ProjectPosition> list = [];
      result.forEach((m) {
        list.add(ProjectPosition.fromJson(m));
      });
      pp('$xz org project positions found .... ${list.length}');
      await cacheManager.addProjectPositions(positions: list);
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<List<ProjectPolygon>> getOrganizationProjectPolygons(
      String organizationId, String startDate, String endDate) async {
    try {
      var result = await _sendHttpGET(
          '${url!}getOrganizationProjectPolygons?organizationId=$organizationId&startDate=$startDate&endDate=$endDate');
      List<ProjectPolygon> list = [];
      result.forEach((m) {
        list.add(ProjectPolygon.fromJson(m));
      });
      pp('$xz org project positions found .... ${list.length}');
      await cacheManager.addProjectPolygons(polygons: list);
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<List<ProjectPolygon>> getAllOrganizationProjectPolygons(
      String organizationId) async {
    try {
      var result = await _sendHttpGET(
          '${url!}getAllOrganizationProjectPolygons?organizationId=$organizationId');
      List<ProjectPolygon> list = [];
      result.forEach((m) {
        list.add(ProjectPolygon.fromJson(m));
      });
      pp('$xz org project positions found .... ${list.length}');
      await cacheManager.addProjectPolygons(polygons: list);
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<LocationRequest> sendLocationRequest(LocationRequest request) async {
    try {
      var result =
          await _callWebAPIPost('${url!}sendLocationRequest', request.toJson());
      final bag = LocationRequest.fromJson(result);
      return bag;
    } catch (e) {
      pp('$xz sendLocationRequest: $e');
      rethrow;
    }
  }

  Future<User?> getUserById({required String userId}) async {
    User? user;
    try {
      var result = await _sendHttpGET('${url!}getUserById?userId=$userId');
      user = User.fromJson(result);
      return user;
    } catch (e) {
      pp(e);
      throw Exception('User failed: $e');
    }
  }

  Future<List<ProjectPosition>> getProjectPositions(
      String projectId, String startDate, String endDate) async {
    try {
      var result = await _sendHttpGET(
          '${url!}getProjectPositions?projectId=$projectId&startDate=$startDate&endDate=$endDate');
      List<ProjectPosition> list = [];
      result.forEach((m) {
        list.add(ProjectPosition.fromJson(m));
      });
      await cacheManager.addProjectPositions(positions: list);
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<List<ProjectPolygon>> getProjectPolygons(
      String projectId, String startDate, String endDate) async {
    try {
      var result = await _sendHttpGET(
          '${url!}getProjectPolygons?projectId=$projectId&startDate=$startDate&endDate=$endDate');
      List<ProjectPolygon> list = [];
      result.forEach((m) {
        list.add(ProjectPolygon.fromJson(m));
      });
      await cacheManager.addProjectPolygons(polygons: list);
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<List<DailyForecast>> getDailyForecast(
      {required double latitude,
      required double longitude,
      required String timeZone,
      required String projectPositionId,
      required String projectId,
      required String projectName}) async {
    try {
      var result = await _sendHttpGET(
          '${url!}getDailyForecasts?latitude=$latitude&longitude=$longitude&timeZone=$timeZone');
      List<DailyForecast> list = [];
      result.forEach((m) {
        var fc = DailyForecast.fromJson(m);
        fc.projectPositionId = projectPositionId;
        fc.date = DateTime.now().toIso8601String();
        fc.projectName = projectName;
        fc.projectId = projectId;
        list.add(fc);
      });
      await cacheManager.addDailyForecasts(forecasts: list);
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<List<HourlyForecast?>> getHourlyForecast(
      {required double latitude,
      required double longitude,
      required String timeZone,
      required String projectPositionId,
      required String projectId,
      required String projectName}) async {
    try {
      var result = await _sendHttpGET(
          '${url!}getDailyForecasts?latitude=$latitude&longitude=$longitude&timeZone=$timeZone');
      List<HourlyForecast> list = [];
      result.forEach((m) {
        var fc = HourlyForecast.fromJson(m);
        fc.projectPositionId = projectPositionId;
        fc.date = DateTime.now().toIso8601String();
        fc.projectName = projectName;
        fc.projectId = projectId;
        list.add(fc);
      });
      await cacheManager.addHourlyForecasts(forecasts: list);
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<List<Photo>> getProjectPhotos(
      {required String projectId,
      required String startDate,
      required String endDate}) async {
    try {
      var result = await _sendHttpGET(
          '${url!}getProjectPhotos?projectId=$projectId&startDate=$startDate&endDate=$endDate');
      List<Photo> list = [];
      result.forEach((m) {
        list.add(Photo.fromJson(m));
      });
      await cacheManager.addPhotos(photos: list);
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<List<Photo>> getUserProjectPhotos(String userId) async {
    try {
      var result =
          await _sendHttpGET('${url!}getUserProjectPhotos?userId=$userId');
      List<Photo> list = [];
      result.forEach((m) {
        list.add(Photo.fromJson(m));
      });
      await cacheManager.addPhotos(photos: list);
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<DataBag> getProjectData(
      String projectId, String startDate, String endDate) async {
    var bag = DataBag(
        photos: [],
        videos: [],
        fieldMonitorSchedules: [],
        projects: [],
        users: [],
        audios: [],
        projectPositions: [],
        projectPolygons: [],
        date: DateTime.now().toIso8601String(),
        settings: []);
    try {
      var result = await _sendHttpGET(
          '${url!}getProjectData?projectId=$projectId&startDate=$startDate&endDate=$endDate');

      bag = DataBag.fromJson(result);
      await cacheManager.addProjects(projects: bag.projects!);
      await cacheManager.addProjectPolygons(polygons: bag.projectPolygons!);
      await cacheManager.addProjectPositions(positions: bag.projectPositions!);
      await cacheManager.addUsers(users: bag.users!);
      await cacheManager.addPhotos(photos: bag.photos!);
      await cacheManager.addVideos(videos: bag.videos!);
      await cacheManager.addAudios(audios: bag.audios!);
      //get latest settings
      bag.settings!.sort((a, b) => DateTime.parse(b.created!)
          .millisecondsSinceEpoch
          .compareTo(DateTime.parse(a.created!).millisecondsSinceEpoch));
      if (bag.settings!.isNotEmpty) {
        await cacheManager.addSettings(settings: bag.settings!.first);
      }
      await cacheManager.addFieldMonitorSchedules(
          schedules: bag.fieldMonitorSchedules!);
    } catch (e) {
      pp(e);
      rethrow;
    }
    return bag;
  }

  Future<List<Video>> getUserProjectVideos(String userId) async {
    try {
      var result =
          await _sendHttpGET('${url!}getUserProjectVideos?userId=$userId');
      List<Video> list = [];
      result.forEach((m) {
        list.add(Video.fromJson(m));
      });
      await cacheManager.addVideos(videos: list);
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<List<Audio>> getUserProjectAudios(String userId) async {
    try {
      var result =
          await _sendHttpGET('${url!}getUserProjectAudios?userId=$userId');
      List<Audio> list = [];
      result.forEach((m) {
        list.add(Audio.fromJson(m));
      });
      await cacheManager.addAudios(audios: list);
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<List<Video>> getProjectVideos(
      String projectId, String startDate, String endDate) async {
    try {
      var result = await _sendHttpGET(
          '${url!}getProjectVideos?projectId=$projectId&startDate=$startDate&endDate=$endDate');
      List<Video> list = [];
      result.forEach((m) {
        list.add(Video.fromJson(m));
      });
      await cacheManager.addVideos(videos: list);
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<List<Audio>> getProjectAudios(
      String projectId, String startDate, String endDate) async {
    try {
      var result = await _sendHttpGET(
          '${url!}getProjectAudios?projectId=$projectId&startDate=$startDate&endDate=$endDate');
      List<Audio> list = [];
      result.forEach((m) {
        list.add(Audio.fromJson(m));
      });
      await cacheManager.addAudios(audios: list);
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<List<User>> findUsersByOrganization(String organizationId) async {
    var cmd = 'getAllOrganizationUsers?organizationId=$organizationId';
    var u = '$url$cmd';
    try {
      List result = await _sendHttpGET(u);
      pp('$xz findUsersByOrganization: 🍏 found: ${result.length} users');
      List<User> list = [];
      for (var m in result) {
        list.add(User.fromJson(m));
      }
      await cacheManager.addUsers(users: list);
      pp('$xz findUsersByOrganization: 🍏 returning objects for: ${list.length} users');
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  // const mm = '🍏🍏🍏 DataAPI: ';
  Future<List<Project>> findProjectsByOrganization(
      String organizationId) async {
    var cmd = 'findProjectsByOrganization';
    var u = '$url$cmd?organizationId=$organizationId';
    try {
      List result = await _sendHttpGET(u);
      pp('$xz findProjectsByOrganization: 🍏 result: ${result.length} projects');
      List<Project> list = [];
      for (var m in result) {
        list.add(Project.fromJson(m));
      }
      // pp('$xz ${list.length} project objects built .... about to cache in local mongo');
      await cacheManager.addProjects(projects: list);
      return list;
    } catch (e) {
      pp('Houston, 😈😈😈😈😈 we have a problem! 😈😈😈😈😈 $e');
      gen.p(e);
      rethrow;
    }
  }

  Future<Organization?> findOrganizationById(String organizationId) async {
    pp('$xz findOrganizationById: 🍏 id: $organizationId');

    var cmd = 'findOrganizationById';
    var u = '$url$cmd?organizationId=$organizationId';
    try {
      var result = await _sendHttpGET(u);
      pp('$xz findOrganizationById: 🍏 result: $result ');
      Organization? org = Organization.fromJson(result);
      await cacheManager.addOrganization(organization: org);
      return org;
    } catch (e) {
      pp('Houston, 😈😈😈😈😈 we have a problem! 😈😈😈😈😈 $e');
      gen.p(e);
      rethrow;
    }
  }

  Future<List<Photo>> getOrganizationPhotos(
      String organizationId, String startDate, String endDate) async {
    pp('$xz getOrganizationPhotos: 🍏 id: $organizationId');

    var cmd = 'getOrganizationPhotos';
    var u =
        '$url$cmd?organizationId=$organizationId&startDate=$startDate&endDate=$endDate';
    try {
      List result = await _sendHttpGET(u);
      pp('$xz getOrganizationPhotos: 🍏 found: ${result.length} org photos');
      List<Photo> list = [];
      for (var m in result) {
        list.add(Photo.fromJson(m));
      }
      await cacheManager.addPhotos(photos: list);
      return list;
    } catch (e) {
      pp('Houston, 😈😈😈😈😈 we have a problem! 😈😈😈😈😈');
      gen.p(e);
      rethrow;
    }
  }

  Future<List<Video>> getOrganizationVideos(
      String organizationId, String startDate, String endDate) async {
    pp('$xz getOrganizationVideos: 🍏 id: $organizationId');

    var cmd = 'getOrganizationVideos';
    var u =
        '$url$cmd?organizationId=$organizationId&startDate=$startDate&endDate=$endDate';
    try {
      List result = await _sendHttpGET(u);
      List<Video> list = [];
      for (var m in result) {
        list.add(Video.fromJson(m));
      }
      await cacheManager.addVideos(videos: list);
      return list;
    } catch (e) {
      pp('Houston, 😈😈😈😈😈 we have a problem! 😈😈😈😈😈');
      gen.p(e);
      rethrow;
    }
  }

  Future<List<Audio>> getOrganizationAudios(String organizationId) async {
    pp('$xz getOrganizationAudios: 🍏 id: $organizationId');

    var cmd = 'getOrganizationAudios';
    var u = '$url$cmd?organizationId=$organizationId';
    try {
      List result = await _sendHttpGET(u);
      List<Audio> list = [];
      for (var m in result) {
        list.add(Audio.fromJson(m));
      }
      await cacheManager.addAudios(audios: list);
      return list;
    } catch (e) {
      pp('Houston, 😈😈😈😈😈 we have a problem! 😈😈😈😈😈 $e');
      gen.p(e);
      rethrow;
    }
  }

  Future<List<Project>> getOrganizationProjects(String organizationId) async {
    pp('$xz getOrganizationProjects: 🍏 id: $organizationId');

    var cmd = 'getOrganizationProjects';
    var u = '$url$cmd?organizationId=$organizationId';
    try {
      List result = await _sendHttpGET(u);
      List<Project> list = [];
      for (var m in result) {
        list.add(Project.fromJson(m));
      }
      await cacheManager.addProjects(projects: list);
      return list;
    } catch (e) {
      pp('Houston, 😈😈😈😈😈 we have a problem! 😈😈😈😈😈');
      gen.p(e);
      rethrow;
    }
  }

  Future<List<User>> getOrganizationUsers(String organizationId) async {
    var cmd = 'getAllOrganizationUsers';
    var u = '$url$cmd?organizationId=$organizationId';
    try {
      List result = await _sendHttpGET(u);
      List<User> list = [];
      for (var m in result) {
        list.add(User.fromJson(m));
      }
      await cacheManager.addUsers(users: list);
      return list;
    } catch (e) {
      pp('Houston, 😈😈😈😈😈 we have a problem! 😈😈😈😈😈');
      gen.p(e);
      rethrow;
    }
  }

  Future<List<GeofenceEvent>> getGeofenceEventsByProjectPosition(
      String projectPositionId) async {
    var cmd = 'getGeofenceEventsByProjectPosition';
    var u = '$url$cmd?projectPositionId=$projectPositionId';
    try {
      List result = await _sendHttpGET(u);
      List<GeofenceEvent> list = [];
      for (var m in result) {
        list.add(GeofenceEvent.fromJson(m));
      }

      for (var b in list) {
        await cacheManager.addGeofenceEvent(geofenceEvent: b);
      }
      return list;
    } catch (e) {
      pp('Houston, 😈😈😈😈😈 we have a problem! 😈😈😈😈😈');
      gen.p(e);
      rethrow;
    }
  }

  Future<List<GeofenceEvent>> getGeofenceEventsByUser(String userId) async {
    var cmd = 'getGeofenceEventsByUser';
    var u = '$url$cmd?userId=$userId';
    try {
      List result = await _sendHttpGET(u);
      List<GeofenceEvent> list = [];
      for (var m in result) {
        list.add(GeofenceEvent.fromJson(m));
      }

      for (var b in list) {
        await cacheManager.addGeofenceEvent(geofenceEvent: b);
      }
      return list;
    } catch (e) {
      pp('Houston, 😈😈😈😈😈 we have a problem! 😈😈😈😈😈');
      gen.p(e);
      rethrow;
    }
  }

  Future<List<Project>> findProjectsByLocation(
      {required String organizationId,
      required double latitude,
      required double longitude,
      required double radiusInKM}) async {
    pp('\n$xz ......... findProjectsByLocation: 🍏 radiusInKM: $radiusInKM kilometres,  '
        '🥏 🥏 🥏about to call _sendHttpGET.........');

    var cmd = 'findProjectsByLocation';
    var u =
        '$url$cmd?latitude=$latitude&longitude=$longitude&radiusInKM=$radiusInKM&organizationId=$organizationId';
    try {
      List result = await _sendHttpGET(u);
      List<Project> list = [];
      for (var m in result) {
        list.add(Project.fromJson(m));
      }
      pp('\n$xz findProjectsByLocation: 🍏 radiusInKM: $radiusInKM kilometres; 🔵🔵 found ${list.length}');
      var map = HashMap<String, Project>();
      for (var element in list) {
        map[element.projectId!] = element;
      }

      var mList = map.values.toList();
      pp('\n$xz findProjectsByLocation: 🍏 radiusInKM: $radiusInKM kilometres; 🔵🔵 found ${mList.length} after filtering for duplicates');
      await cacheManager.addProjects(projects: mList);
      return mList;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<List<City>> findCitiesByLocation(
      {required double latitude,
      required double longitude,
      required double radiusInKM}) async {
    pp('$xz findCitiesByLocation: 🍏 radiusInKM: $radiusInKM');

    var cmd = 'findCitiesByLocation';
    var u =
        '$url$cmd?latitude=$latitude&longitude=$longitude&radiusInKM=$radiusInKM';
    try {
      List result = await _sendHttpGET(u);
      List<City> list = [];
      for (var m in result) {
        list.add(City.fromJson(m));
      }
      pp('$xz findCitiesByLocation: 🍏 found: ${list.length} cities');
      await cacheManager.addCities(cities: list);
      for (var city in list) {
        pp('$xz city found by findCitiesByLocation call: ${city.toJson()} \n');
      }
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<List<ProjectPosition>> findProjectPositionsByLocation(
      {required String organizationId,
      required double latitude,
      required double longitude,
      required double radiusInKM}) async {
    pp('$xz findProjectPositionsByLocation: 🍏 radiusInKM: $radiusInKM');

    var cmd = 'findProjectPositionsByLocation';
    var u =
        '$url$cmd?organizationId=$organizationId&latitude=$latitude&longitude=$longitude&radiusInKM=$radiusInKM';
    try {
      List result = await _sendHttpGET(u);
      List<ProjectPosition> list = [];
      for (var m in result) {
        list.add(ProjectPosition.fromJson(m));
      }
      pp('$xz findProjectPositionsByLocation: 🍏 found: ${list.length} project positions');
      await cacheManager.addProjectPositions(positions: list);
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<List<Questionnaire>> getQuestionnairesByOrganization(
      String organizationId) async {
    pp('$xz getQuestionnairesByOrganization: 🍏 id: $organizationId');

    var cmd = 'getQuestionnairesByOrganization?organizationId=$organizationId';
    var u = '$url$cmd';
    try {
      List result = await _sendHttpGET(u);
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

  Future<Community> updateCommunity(Community community) async {
    Map bag = community.toJson();
    try {
      var result = await _callWebAPIPost('${url!}updateCommunity', bag);
      return Community.fromJson(result);
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<Community> addCommunity(Community community) async {
    Map bag = community.toJson();
    try {
      var result = await _callWebAPIPost('${url!}addCommunity', bag);
      var c = Community.fromJson(result);
      await cacheManager.addCommunity(community: c);
      return c;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  //  Future<GeofenceEvent> addGeofenceEvent(GeofenceEvent geofenceEvent) async {
  //
  //   Map bag = geofenceEvent.toJson();
  //   try {
  //     var result = await _callWebAPIPost(url! + 'addGeofenceEvent', bag);
  //     var c = GeofenceEvent.fromJson(result);
  //     await hiveUtil.addGeofenceEvent(geofenceEvent: c);
  //     return c;
  //   } catch (e) {
  //     pp(e);
  //     rethrow;
  //   }
  // }

  Future addPointToPolygon(
      {required String communityId,
      required double latitude,
      required double longitude}) async {
    Map bag = {
      'communityId': communityId,
      'latitude': latitude,
      'longitude': longitude,
    };
    try {
      var result = await _callWebAPIPost('${url}addPointToPolygon', bag);
      return result;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future addQuestionnaireSection(
      {required String questionnaireId, required Section section}) async {
    Map bag = {
      'questionnaireId': questionnaireId,
      'section': section.toJson(),
    };
    try {
      var result = await _callWebAPIPost('${url!}addQuestionnaireSection', bag);
      return result;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<List<Community>> findCommunitiesByCountry(String countryId) async {
    pp('🍏🍏🍏🍏 ..... findCommunitiesByCountry ');
    var cmd = 'findCommunitiesByCountry';
    var u = '$url$cmd?countryId=$countryId';

    List result = await _sendHttpGET(u);
    List<Community> communityList = [];
    for (var m in result) {
      communityList.add(Community.fromJson(m));
    }
    pp('🍏 🍏 🍏 findCommunitiesByCountry found ${communityList.length}');
    await cacheManager.addCommunities(communities: communityList);
    return communityList;
  }

  Future<Project> addProject(Project project) async {
    Map bag = project.toJson();
    try {
      var result = await _callWebAPIPost('${url!}addProject', bag);
      var p = Project.fromJson(result);
      await cacheManager.addProject(project: p);
      return p;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<Project> updateProject(Project project) async {
    Map bag = project.toJson();
    try {
      var result = await _callWebAPIPost('${url!}updateProject', bag);
      var p = Project.fromJson(result);
      await cacheManager.addProject(project: p);
      return p;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<Project> addSettlementToProject(
      {required String projectId, required String settlementId}) async {
    Map bag = {
      'projectId': projectId,
      'settlementId': settlementId,
    };
    try {
      var result = await _callWebAPIPost('${url!}addSettlementToProject', bag);
      var proj = Project.fromJson(result);
      await cacheManager.addProject(project: proj);
      return proj;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<ProjectPosition> addProjectPosition(
      {required ProjectPosition position}) async {
    Map bag = position.toJson();
    try {
      var result = await _callWebAPIPost('${url!}addProjectPosition', bag);

      var pp = ProjectPosition.fromJson(result);
      await cacheManager.addProjectPosition(projectPosition: pp);
      return pp;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<ProjectPolygon> addProjectPolygon(
      {required ProjectPolygon polygon}) async {
    Map bag = polygon.toJson();
    try {
      var result = await _callWebAPIPost('${url!}addProjectPolygon', bag);

      var pp = ProjectPolygon.fromJson(result);
      await cacheManager.addProjectPolygon(projectPolygon: pp);
      return pp;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<AppError> addAppError(AppError appError) async {
    try {
      pp('$xz appError: ${appError.toJson()}');
      var result =
          await _callWebAPIPost('${url!}addAppError', appError.toJson());
      pp('\n\n\n$xz 🔴🔴🔴 DataAPI addAppError succeeded. Everything OK?? 🔴🔴🔴');
      var ae = AppError.fromJson(result);
      await cacheManager.addAppError(appError: ae);
      pp('$xz addAppError has added AppError to DB and to Hive cache\n');
      return appError;
    } catch (e) {
      pp('\n\n\n$xz 🔴🔴🔴 DataAPI addAppException failed. Something fucked up here! ... 🔴🔴🔴\n\n');
      pp(e);
      rethrow;
    }
  }

  Future<Photo> addPhoto(Photo photo) async {
    try {
      var result = await _callWebAPIPost('${url!}addPhoto', photo.toJson());
      pp('\n\n\n$xz 🔴🔴🔴 DataAPI addPhoto succeeded. Everything OK?? 🔴🔴🔴');
      var photoBack = Photo.fromJson(result);
      await cacheManager.addPhoto(photo: photoBack);
      pp('$xz addPhoto has added photo to DB and to Hive cache\n');
      return photo;
    } catch (e) {
      pp('\n\n\n$xz 🔴🔴🔴 DataAPI addPhoto failed. Something fucked up here! ... 🔴🔴🔴\n\n');
      pp(e);
      rethrow;
    }
  }

  Future<Video> addVideo(Video video) async {
    try {
      var result = await _callWebAPIPost('${url!}addVideo', video.toJson());
      pp('$xz addVideo has added photo to DB and to Hive cache');
      var vx = Video.fromJson(result);
      await cacheManager.addVideo(video: vx);
      return vx;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<Audio> addAudio(Audio audio) async {
    try {
      var result = await _callWebAPIPost('${url!}addAudio', audio.toJson());
      var audiox = Audio.fromJson(result);
      pp('$xz addAudio has added audio to DB : 😡😡😡 fromJson:: ${audiox.toJson()}');

      var x = await cacheManager.addAudio(audio: audiox);
      pp('$xz addAudio has added audio to Hive??? : 😡😡😡 result from hive: $x');

      return audiox;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<Rating> addRating(Rating rating) async {
    try {
      var result = await _callWebAPIPost('${url!}addRating', rating.toJson());
      var mRating = Rating.fromJson(result);
      pp('$xz addRating has added mRating to DB : 😡😡😡 fromJson:: ${mRating.toJson()}');

      var x = await cacheManager.addRating(rating: mRating);
      pp('$xz addRating has added result to Hive??? : 😡😡😡 result from hive: $x');

      return mRating;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<Condition> addCondition(Condition condition) async {
    try {
      var result =
          await _callWebAPIPost('${url!}addCondition', condition.toJson());
      var x = Condition.fromJson(result);
      await cacheManager.addCondition(condition: x);
      return x;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<Photo> addSettlementPhoto(
      {required String settlementId,
      required String url,
      required String comment,
      required double latitude,
      longitude,
      required String userId}) async {
    Map bag = {
      'settlementId': settlementId,
      'url': url,
      'comment': comment,
      'latitude': latitude,
      'longitude': longitude,
      'userId': userId,
    };
    try {
      var result = await _callWebAPIPost('${url!}addSettlementPhoto', bag);

      var photo = Photo.fromJson(result);
      await cacheManager.addPhoto(photo: photo);
      return photo;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<Video> addProjectVideo(
      {required String projectId,
      required String url,
      required String comment,
      required double latitude,
      longitude,
      required String userId}) async {
    Map bag = {
      'projectId': projectId,
      'url': url,
      'comment': comment,
      'latitude': latitude,
      'longitude': longitude,
      'userId': userId
    };
    try {
      var result = await _callWebAPIPost('${url!}addProjectVideo', bag);
      var video = Video.fromJson(result);
      await cacheManager.addVideo(video: video);
      return video;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<Project> addProjectRating(
      {required String projectId,
      required String rating,
      required String comment,
      required double latitude,
      longitude,
      required String userId}) async {
    Map bag = {
      'projectId': projectId,
      'rating': rating,
      'comment': comment,
      'latitude': latitude,
      'longitude': longitude,
      'userId': userId
    };
    try {
      var result = await _callWebAPIPost('${url!}addProjectRating', bag);
      return Project.fromJson(result);
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<Questionnaire> addQuestionnaire(Questionnaire questionnaire) async {
    Map bag = questionnaire.toJson();
    prettyPrint(bag,
        'DataAPI  💦 💦 💦 addQuestionnaire: 🔆🔆 Sending to web api ......');
    try {
      var result = await _callWebAPIPost('${url!}addQuestionnaire', bag);
      return Questionnaire.fromJson(result);
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<List<Project>> findAllProjects(String organizationId) async {
    Map bag = {};
    try {
      List result = await _callWebAPIPost('${url!}findAllProjects', bag);
      List<Project> list = [];
      for (var m in result) {
        list.add(Project.fromJson(m));
      }
      await cacheManager.addProjects(projects: list);
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<Organization> addOrganization(Organization org) async {
    Map bag = org.toJson();

    pp('DataAPI_addOrganization:  🍐 org Bag to be sent, check properties:  🍐 $bag');
    try {
      var result = await _callWebAPIPost('${url!}addOrganization', bag);
      var o = Organization.fromJson(result);
      await cacheManager.addOrganization(organization: o);
      return o;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<OrgMessage> sendMessage(OrgMessage message) async {
    Map bag = message.toJson();

    pp('DataAPI_sendMessage:  🍐 org message to be sent, check properties:  🍐 $bag');
    try {
      var result = await _callWebAPIPost('${url!}sendMessage', bag);
      var m = OrgMessage.fromJson(result);
      await cacheManager.addOrgMessage(message: m);
      return m;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<User?> findUserByEmail(String email) async {
    pp('🐤🐤🐤🐤 DataAPI : ... findUserByEmail $email ');

    var command = "findUserByEmail?email=$email";

    try {
      pp('🐤🐤🐤🐤 DataAPI : ... 🥏 calling _callWebAPIPost .. 🥏 findUserByEmail $url$command ');
      var result = await _sendHttpGET(
        '$url$command',
      );

      return User.fromJson(result);
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<Photo?> findPhotoById(String photoId) async {
    var command = "findPhotoById?photoId=$photoId";

    try {
      pp('🐤🐤🐤🐤 DataAPI : ... 🥏 calling _callWebAPIPost .. 🥏 $url$command ');
      var result = await _sendHttpGET(
        '$url$command',
      );
      if (result is bool) {
        return null;
      }

      return Photo.fromJson(result);
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<Video?> findVideoById(String videoId) async {
    var command = "findVideoById?videoId=$videoId";

    try {
      var result = await _sendHttpGET(
        '$url$command',
      );
      if (result is bool) {
        return null;
      }

      return Video.fromJson(result);
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<Audio?> findAudioById(String audioId) async {
    var command = "findAudioById?audioId=$audioId";

    try {
      var result = await _sendHttpGET(
        '$url$command',
      );
      if (result is bool) {
        return null;
      }

      return Audio.fromJson(result);
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<User> findUserByUid(String uid) async {
    Map bag = {
      'uid': uid,
    };
    try {
      var result = await _callWebAPIPost('${url!}findUserByUid', bag);
      return User.fromJson(result);
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<List<Country>> getCountries() async {
    var cmd = 'getCountries';
    var u = '$url$cmd';
    try {
      List result = await _sendHttpGET(u);
      List<Country> list = [];
      for (var m in result) {
        var entry = Country.fromJson(m);
        list.add(entry);
      }
      pp('🐤🐤🐤🐤 ${list.length} Countries found 🥏');
      list.sort((a, b) => a.name!.compareTo(b.name!));
      for (var value in list) {
        await cacheManager.addCountry(country: value);
      }
      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future hello() async {
    var result = await _sendHttpGET(url!);
  }

  Future ping() async {
    var result = await _sendHttpGET('${url!}ping');
  }

  Future _callWebAPIPost(String mUrl, Map? bag) async {
    pp('$xz http POST call: 🔆 🔆 🔆  calling : 💙  $mUrl  💙 ');

    String? mBag;
    if (bag != null) {
      mBag = json.encode(bag);
    }
    var start = DateTime.now();
    var token = await AppAuth.getAuthToken();

    headers['Authorization'] = 'Bearer $token';
    try {
      var resp = await client
          .post(
            Uri.parse(mUrl),
            body: mBag,
            headers: headers,
          )
          .timeout(const Duration(seconds: timeOutInSeconds));
      if (resp.statusCode == 200) {
        pp('$xz http POST call RESPONSE: 💙💙 statusCode: 👌👌👌 ${resp.statusCode} 👌👌👌 💙 for $mUrl');
      } else {
        pp('👿👿👿 DataAPI._callWebAPIPost: 🔆 statusCode: 👿👿👿 ${resp.statusCode} 🔆🔆🔆 for $mUrl');
        pp(resp.body);
        throw GeoException(
            message: 'Bad status code: ${resp.statusCode} - ${resp.body}',
            url: mUrl,
            translationKey: 'serverProblem',
            errorType: GeoException.socketException);
      }
      var end = DateTime.now();
      pp('$xz http POST call: 🔆 elapsed time: ${end.difference(start).inSeconds} seconds 🔆');
      try {
        var mJson = json.decode(resp.body);
        return mJson;
      } catch (e) {
        pp("👿👿👿👿👿👿👿 json.decode failed, returning response body");
        return resp.body;
      }
    } on SocketException {
      pp('$xz No Internet connection, really means that server cannot be reached 😑');
      throw GeoException(
          message: 'No Internet connection',
          url: mUrl,
          translationKey: 'networkProblem',
          errorType: GeoException.socketException);
    } on HttpException {
      pp("$xz HttpException occurred 😱");
      throw GeoException(
          message: 'Server not around',
          url: mUrl,
          translationKey: 'serverProblem',
          errorType: GeoException.httpException);
    } on FormatException {
      pp("$xz Bad response format 👎");
      throw GeoException(
          message: 'Bad response format',
          url: mUrl,
          translationKey: 'serverProblem',
          errorType: GeoException.formatException);
    } on TimeoutException {
      pp("$xz GET Request has timed out in $timeOutInSeconds seconds 👎");
      throw GeoException(
          message: 'Request timed out',
          url: mUrl,
          translationKey: 'networkProblem',
          errorType: GeoException.timeoutException);
    }
  }

  //todo - create error object cached on device and uploaded to server when network is cool
  //todo - trying to see how many errors we get and on what devices ...

  static const xz = '🌎🌎🌎🌎🌎🌎 DataAPI: ';
  Future _sendHttpGET(String mUrl) async {
    pp('$xz http GET call:  🔆 🔆 🔆 calling : 💙  $mUrl  💙');
    var start = DateTime.now();
    var token = await AppAuth.getAuthToken();
    if (token != null) {
      pp('$xz http GET call: 😡😡😡 Firebase Auth Token: 💙️ Token is GOOD! 💙 ');
    }

    headers['Authorization'] = 'Bearer $token';

    try {
      var resp = await client
          .get(
            Uri.parse(mUrl),
            headers: headers,
          )
          .timeout(const Duration(seconds: timeOutInSeconds));
      pp('$xz http GET call RESPONSE: .... : 💙 statusCode: 👌👌👌 ${resp.statusCode} 👌👌👌 💙 for $mUrl');
      var end = DateTime.now();
      pp('$xz http GET call: 🔆 elapsed time for http: ${end.difference(start).inSeconds} seconds 🔆 \n\n');

      if (resp.body.contains('not found')) {
        return false;
      }

      if (resp.statusCode == 403) {
        var msg =
            '😡 😡 status code: ${resp.statusCode}, Request Forbidden 🥪 🥙 🌮  😡 ${resp.body}';
        pp(msg);
        throw GeoException(
            message: 'Forbidden call',
            url: mUrl,
            translationKey: 'serverProblem',
            errorType: GeoException.httpException);
      }

      if (resp.statusCode != 200) {
        var msg =
            '😡 😡 The response is not 200; it is ${resp.statusCode}, NOT GOOD, throwing up !! 🥪 🥙 🌮  😡 ${resp.body}';
        pp(msg);
        throw GeoException(
            message: 'Bad status code: ${resp.statusCode} - ${resp.body}',
            url: mUrl,
            translationKey: 'serverProblem',
            errorType: GeoException.socketException);
      }
      var mJson = json.decode(resp.body);
      return mJson;
    } on SocketException {
      pp('$xz No Internet connection, really means that server cannot be reached 😑');
      throw GeoException(
          message: 'No Internet connection',
          url: mUrl,
          translationKey: 'networkProblem',
          errorType: GeoException.socketException);
    } on HttpException {
      pp("$xz HttpException occurred 😱");
      throw GeoException(
          message: 'Server not around',
          url: mUrl,
          translationKey: 'serverProblem',
          errorType: GeoException.httpException);
    } on FormatException {
      pp("$xz Bad response format 👎");
      throw GeoException(
          message: 'Bad response format',
          url: mUrl,
          translationKey: 'serverProblem',
          errorType: GeoException.formatException);
    } on TimeoutException {
      pp("$xz GET Request has timed out in $timeOutInSeconds seconds 👎");
      throw GeoException(
          message: 'Request timed out',
          url: mUrl,
          translationKey: 'networkProblem',
          errorType: GeoException.timeoutException);
    }
  }
}
