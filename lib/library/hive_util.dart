import 'dart:math';

import 'package:geo_monitor/library/bloc/audio_for_upload.dart';
import 'package:geo_monitor/library/bloc/photo_for_upload.dart';
import 'package:geo_monitor/library/bloc/video_for_upload.dart';
import 'package:geo_monitor/library/data/activity_model.dart';
import 'package:geo_monitor/library/data/activity_type_enum.dart';
import 'package:geo_monitor/library/data/project_assignment.dart';
import 'package:geo_monitor/library/data/settings_model.dart';
import 'package:geo_monitor/library/data/weather/daily_forecast.dart';
import 'package:geo_monitor/library/data/weather/daily_units.dart';
import 'package:geo_monitor/library/data/weather/hourly_forecast.dart';
import 'package:geo_monitor/library/data/weather/hourly_units.dart';
import 'package:hive/hive.dart';

import 'bloc/failed_audio.dart';
import 'bloc/failed_bag.dart';
import 'data/audio.dart';
import 'data/city.dart';
import 'data/community.dart';
import 'data/condition.dart';
import 'data/country.dart';
import 'data/data_bag.dart';
import 'data/field_monitor_schedule.dart';
import 'data/geofence_event.dart';
import 'data/location_response.dart';
import 'data/monitor_report.dart';
import 'data/org_message.dart';
import 'data/organization.dart';
import 'data/organization_registration_bag.dart';
import 'data/photo.dart';
import 'data/place_mark.dart';
import 'data/position.dart';
import 'data/project.dart';
import 'data/project_polygon.dart';
import 'data/project_position.dart';
import 'data/rating.dart';
import 'data/section.dart';
import 'data/user.dart';
import 'data/video.dart';
import 'emojis.dart';
import 'functions.dart';
import 'generic_functions.dart';

const stillWorking = 201, doneCaching = 200;
CacheManager cacheManager = CacheManager._instance;

class CacheManager {
  static final CacheManager _instance = CacheManager._internal();

  factory CacheManager() {
    return _instance;
  }

  CacheManager._internal();

  LazyBox<Organization>? _orgBox;
  LazyBox<Project>? _projectBox;
  LazyBox<ProjectPosition>? _positionBox;
  LazyBox<City>? _cityBox;
  LazyBox<Photo>? _photoBox;
  LazyBox<Video>? _videoBox;
  LazyBox<Community>? _communityBox;
  LazyBox<Condition>? _conditionBox;
  LazyBox<FieldMonitorSchedule>? _scheduleBox;
  LazyBox<OrgMessage>? _orgMessageBox;
  LazyBox<User>? _userBox;
  LazyBox<MonitorReport>? _reportBox;
  LazyBox<GeofenceEvent>? _geofenceEventBox;
  LazyBox<ProjectPolygon>? _projectPolygonBox;
  LazyBox<Photo>? _failedPhotoBox;
  LazyBox<Video>? _failedVideoBox;
  LazyBox<FailedBag>? _failedBagBox;
  LazyBox<Country>? _countryBox;
  LazyBox<OrganizationRegistrationBag>? _registrationBox;
  LazyBox<Audio>? _audioBox;
  LazyBox<FailedAudio>? _failedAudioBox;
  LazyBox<Rating>? _ratingBox;
  LazyBox<LocationResponse>? _locationResponseBox;
  LazyBox<SettingsModel>? _settingsBox;

  LazyBox<PhotoForUpload>? _uploadPhotoBox;
  LazyBox<VideoForUpload>? _uploadVideoBox;
  LazyBox<AudioForUpload>? _uploadAudioBox;
  LazyBox<ProjectAssignment>? _assignmentBox;

  LazyBox<DailyForecast>? _dailyForecastBox;
  LazyBox<HourlyForecast>? _hourlyForecastBox;

  LazyBox<ActivityModel>? _activityBox;

  bool _isInitialized = false;

  initialize({bool? forceInitialization = false}) async {
    // fileCounter = await prefsOGx.getFileCounter();
    if (forceInitialization != null) {
      if (forceInitialization) {
        pp('\n\n$mm Setting up Hive');
        await _clearAllBoxes();
        await _doTheInitializationWork();
        return;
      }
    }
    if (!_isInitialized) {
      pp('\n\n$mm Setting Hive files to existing suffix');
      await _doTheInitializationWork();
      return;
    }
  }

  Future _clearAllBoxes() async {
    pp('$mm clearing all Hive boxes ....');
    _countryBox?.clear();
    _registrationBox?.clear();
    _failedBagBox?.clear();
    _failedVideoBox?.clear();
    _failedPhotoBox?.clear();
    _scheduleBox?.clear();
    _projectPolygonBox?.clear();
    _projectBox?.clear();
    _positionBox?.clear();
    _userBox?.clear();
    _geofenceEventBox?.clear();
    _orgBox?.clear();
    _photoBox?.clear();
    _reportBox?.clear();
    _cityBox?.clear();
    _settingsBox?.clear();
    _conditionBox?.clear();
    _audioBox?.clear();
    _failedAudioBox?.clear();
    _ratingBox?.clear();
    _videoBox?.clear();
    _locationResponseBox?.clear();
    pp('$mm all Hive boxes cleared 💚💚');
  }

  static final xx = '${E.peach}${E.peach}${E.peach}${E.peach} CacheManager: ';

  Future<void> _doTheInitializationWork() async {
    p('$mm ... Initializing Hive boxes ...');
    try {
      _registerAdapters();
      await _openBoxes();
      _isInitialized = true;
      p('\n$mm'
          ' Hive has been initialized and boxes opened ${E.leaf}${E.leaf}${E.leaf}\n');
    } catch (e) {
      p('🔴🔴 We have a problem 🔴 opening Hive boxes: $e');
      throw Exception('Problem with device database');
    }
  }

  Future<void> _openBoxes() async {
    _activityBox = await Hive.openLazyBox<ActivityModel>('activities');

    _orgBox = await Hive.openLazyBox<Organization>('organizations');
    _settingsBox = await Hive.openLazyBox<SettingsModel>('settings');
    _projectBox = await Hive.openLazyBox<Project>('projects');
    _positionBox = await Hive.openLazyBox<ProjectPosition>('positions');

    _dailyForecastBox = await Hive.openLazyBox<DailyForecast>('dailyForecasts');
    _hourlyForecastBox = await Hive.openLazyBox<HourlyForecast>('hourlyForecasts');

    _cityBox = await Hive.openLazyBox<City>('cities');
    _photoBox = await Hive.openLazyBox<Photo>('photos');
    _videoBox = await Hive.openLazyBox<Video>('videos');

    _uploadAudioBox = await Hive.openLazyBox<AudioForUpload>('uploadAudios');
    _uploadPhotoBox = await Hive.openLazyBox<PhotoForUpload>('uploadPhotos');
    _uploadVideoBox = await Hive.openLazyBox<VideoForUpload>('uploadVideos');

    _communityBox = await Hive.openLazyBox<Community>('communities');
    _conditionBox = await Hive.openLazyBox<Condition>('conditions');
    _countryBox = await Hive.openLazyBox<Country>('countries');

    _scheduleBox = await Hive.openLazyBox<FieldMonitorSchedule>('schedules');
    _orgMessageBox = await Hive.openLazyBox<OrgMessage>('messages');
    _reportBox = await Hive.openLazyBox<MonitorReport>('reports');
    _geofenceEventBox = await Hive.openLazyBox<GeofenceEvent>('geofenceEvents');

    _userBox = await Hive.openLazyBox<User>('users');
    _projectPolygonBox =
        await Hive.openLazyBox<ProjectPolygon>('projectPolygons');

    _assignmentBox = await Hive.openLazyBox<ProjectAssignment>('assignments');


    _failedPhotoBox = await Hive.openLazyBox<Photo>('failedPhotos');
    _failedVideoBox = await Hive.openLazyBox<Video>('failedVideos');
    _failedBagBox = await Hive.openLazyBox<FailedBag>('failedBags');

    _registrationBox =
        await Hive.openLazyBox<OrganizationRegistrationBag>('registrations');
    _audioBox = await Hive.openLazyBox<Audio>('audios');
    _failedAudioBox = await Hive.openLazyBox<FailedAudio>('failedAudios');
    _ratingBox = await Hive.openLazyBox<Rating>('ratings');
    _locationResponseBox =
        await Hive.openLazyBox<LocationResponse>('locationResponses');
  }

  void _registerAdapters() {
    p('\n$xx ... Registering Hive object adapters ...');
    if (!Hive.isAdapterRegistered(61)) {
      Hive.registerAdapter(ActivityTypeAdapter());
      p('$xx Hive ActivityTypeAdapter registered');
    }
    if (!Hive.isAdapterRegistered(60)) {
      Hive.registerAdapter(ActivityModelAdapter());
      p('$xx Hive ActivityModelAdapter registered');
    }
    if (!Hive.isAdapterRegistered(50)) {
      Hive.registerAdapter(DailyForecastAdapter());
      p('$xx Hive DailyForecastAdapter registered');
    }
    if (!Hive.isAdapterRegistered(51)) {
      Hive.registerAdapter(DailyUnitsAdapter());
      p('$xx Hive DailyUnitsAdapter registered');
    }
    if (!Hive.isAdapterRegistered(52)) {
      Hive.registerAdapter(HourlyForecastAdapter());
      p('$xx Hive HourlyForecastAdapter registered');
    }
    if (!Hive.isAdapterRegistered(53)) {
      Hive.registerAdapter(HourlyUnitsAdapter());
      p('$xx Hive HourlyUnitsAdapter registered');
    }
    if (!Hive.isAdapterRegistered(38)) {
      Hive.registerAdapter(ProjectAssignmentAdapter());
      p('$xx Hive ProjectAssignmentAdapter registered');
    }
    if (!Hive.isAdapterRegistered(35)) {
      Hive.registerAdapter(AudioForUploadAdapter());
      p('$xx Hive AudioForUploadAdapter registered');
    }
    if (!Hive.isAdapterRegistered(34)) {
      Hive.registerAdapter(VideoForUploadAdapter());
      p('$xx Hive VideoForUploadAdapter registered');
    }
    if (!Hive.isAdapterRegistered(33)) {
      Hive.registerAdapter(PhotoForUploadAdapter());
      p('$xx Hive PhotoForUploadAdapter registered');
    }
    if (!Hive.isAdapterRegistered(30)) {
      Hive.registerAdapter(SettingsModelAdapter());
      p('$xx Hive SettingsModelAdapter registered');
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(OrganizationAdapter());
      p('$xx Hive OrganizationAdapter registered');
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(ProjectAdapter());
      p('$xx Hive ProjectAdapter registered');
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(ProjectPositionAdapter());
      p('$xx Hive ProjectPositionAdapter registered');
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(CityAdapter());
      p('$xx Hive CityAdapter registered');
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(PhotoAdapter());
      p('$xx Hive PhotoAdapter registered');
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(VideoAdapter());
      p('$xx Hive VideoAdapter registered');
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(CommunityAdapter());
      p('$xx Hive CommunityAdapter registered');
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(FieldMonitorScheduleAdapter());
      p('$xx Hive FieldMonitorScheduleAdapter registered');
    }
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(OrgMessageAdapter());
      p('$xx Hive OrgMessageAdapter registered');
    }

    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(MonitorReportAdapter());
      p('$xx Hive MonitorReportAdapter registered');
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(GeofenceEventAdapter());
      p('$xx Hive GeofenceEventAdapter registered');
    }
    if (!Hive.isAdapterRegistered(16)) {
      Hive.registerAdapter(PositionAdapter());
      p('$xx Hive PositionAdapter registered');
    }
    if (!Hive.isAdapterRegistered(17)) {
      Hive.registerAdapter(PlaceMarkAdapter());
      p('$xx Hive PlaceMarkAdapter registered');
    }

    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(UserAdapter());
      p('$xx Hive UserAdapter registered');
    }
    if (!Hive.isAdapterRegistered(19)) {
      Hive.registerAdapter(ProjectPolygonAdapter());
      p('$xx Hive ProjectPolygonAdapter registered');
    }
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(FailedBagAdapter());
      p('$xx Hive FailedBagAdapter registered');
    }
    if (!Hive.isAdapterRegistered(21)) {
      Hive.registerAdapter(OrganizationRegistrationBagAdapter());
      p('$xx Hive OrganizationRegistrationBagAdapter registered');
    }

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CountryAdapter());
      p('$xx Hive CountryAdapter registered');
    }
    if (!Hive.isAdapterRegistered(23)) {
      Hive.registerAdapter(AudioAdapter());
      p('$xx Hive AudioAdapter registered');
    }
    if (!Hive.isAdapterRegistered(24)) {
      Hive.registerAdapter(FailedAudioAdapter());
      p('$xx Hive FailedAudioAdapter registered');
    }
    if (!Hive.isAdapterRegistered(26)) {
      Hive.registerAdapter(RatingAdapter());
      p('$xx Hive RatingAdapter registered');
    }
    if (!Hive.isAdapterRegistered(27)) {
      Hive.registerAdapter(LocationResponseAdapter());
      p('$xx Hive LocationResponseAdapter registered');
    }
  }

  final mm =
      '${E.appleRed}${E.appleRed}${E.appleRed}${E.appleRed} CacheManager: ';
  var random = Random(DateTime.now().millisecondsSinceEpoch);

  Future addActivityModel(
      {required ActivityModel activity}) async {
    late String key;
    if (activity.projectId == null) {
      key = '${DateTime.parse(activity.date!).millisecondsSinceEpoch}_${activity.userId}';
    } else {
      key = '${DateTime.parse(activity.date!).millisecondsSinceEpoch}_${activity.projectId}_${activity.userId}';
    }
    await _activityBox?.put(key, activity);

    pp('$mm ActivityModel added to local cache}');
  }
  Future<List<ActivityModel>> getActivities() async {
    List<ActivityModel> list = [];
    var keys = _activityBox?.keys;
    if (keys != null) {
      for (var key in keys) {
        var act = await _activityBox?.get(key);
        list.add(act!);
      }
    }
    pp('$mm ${list.length} org activities list found in cache 🔵');
    return list;
  }


  Future addLocationResponse(
      {required LocationResponse locationResponse}) async {
    pp('$mm .... addLocationResponse .....');
    var key = '${locationResponse.userId}_${locationResponse.date}';
    await _locationResponseBox?.put(key, locationResponse);

    pp('$mm locationResponse added to local cache}');
  }

  Future addDailyForecasts(
      {required List<DailyForecast> forecasts}) async {
    for (var fc in forecasts) {
      await addDailyForecast(forecast: fc);
    }
  }

  Future addDailyForecast(
      {required DailyForecast forecast}) async {
    var key = '${DateTime.now().millisecondsSinceEpoch}';
    await _dailyForecastBox?.put(key, forecast);

    pp('$mm DailyForecast added to local cache}');
  }
  Future addHourlyForecasts(
      {required List<HourlyForecast> forecasts}) async {
    for (var fc in forecasts) {
      await addHourlyForecast(forecast: fc);
    }
  }
  Future addHourlyForecast(
      {required HourlyForecast forecast}) async {
    var key = '${DateTime.now().millisecondsSinceEpoch}';
    await _hourlyForecastBox?.put(key, forecast);

    pp('$mm HourlyForecast added to local cache}');
  }

  Future addProjectAssignments(
      {required List<ProjectAssignment> assignments}) async {
    for (var ass in assignments) {
      await addProjectAssignment(assignment: ass);
    }

    pp('$mm ProjectAssignments added to local cache: ${assignments.length}');
  }
  Future addProjectAssignment(
      {required ProjectAssignment assignment}) async {
    var key = '${assignment.projectId}_${assignment.userId}_${assignment.date}';
    await _assignmentBox?.put(key, assignment);

    pp('$mm ProjectAssignment added to local cache}');
  }

  Future addRegistration({required OrganizationRegistrationBag bag}) async {
    pp('$mm .... addRegistration .....');
    var key = '${bag.date}';
    await _registrationBox?.put(key, bag);

    pp('$mm OrganizationRegistrationBag added to local cache: ${bag.organization!.name}');
  }

  Future addCondition({required Condition condition}) async {
    pp('$mm .... addCondition .....');
    var key = '${condition.conditionId}';
    await _conditionBox?.put(key, condition);

    pp('$mm Condition added to local cache: ${condition.projectName}');
  }

  Future addAudioForUpload({required AudioForUpload audio}) async {
    var key = '${audio.project!.projectId!}_${audio.date}';
    await _uploadAudioBox?.put(key, audio);

    pp('$mm AudioForUpload added to local cache: ${audio.project!.name}');
  }
  Future addVideoForUpload({required VideoForUpload video}) async {
    var key = '${video.project!.projectId!}_${video.date}';
    await _uploadVideoBox?.put(key, video);

    pp('$mm VideoForUpload added to local cache: ${video.project!.name}');
  }
  Future addPhotoForUpload({required PhotoForUpload photo}) async {
    var key = '${photo.project!.projectId!}_${photo.date}';
    await _uploadPhotoBox?.put(key, photo);

    pp('$mm PhotoForUpload added to local cache: ${photo.project!.name}');
  }
  Future addOrganizationSettingsList(List<SettingsModel> settings) async {
    for (var value in settings) {
      await addSettings(settings: value);
    }
  }

  Future addSettingsList({required List<SettingsModel> settings}) async {
   for (var m in settings) {
     await addSettings(settings: m);
   }

    pp('$mm SettingsModels added to local cache: ${settings.length}');
  }

  Future addSettings({required SettingsModel settings}) async {
    var key = '${settings.organizationId}_';
    if (settings.projectId != null) {
      key = '$key${settings.projectId}';
    }

    await _settingsBox?.put(key, settings);

    pp('$mm SettingsModel added to local cache: ${settings.organizationId}');
  }

  Future addRating({required Rating rating}) async {
    var key = '${rating.projectId}_${rating.ratingId}_${rating.created}';
    await _ratingBox?.put(key, rating);
  }

  Future addRatings({required List<Rating> ratings}) async {
    for (var value in ratings) {
      await addRating(rating: value);
    }
    pp('$mm Ratings added to local cache: ${ratings.length}');
  }

  Future<List<Rating>> getProjectRatings({required String projectId}) async {
    var mList = <Rating>[];
    var keys = _ratingBox?.keys;
    keys?.forEach((key) async {
      if (key.contains(projectId)) {
        var rating = await _ratingBox?.get(key);
        if (rating != null) {
          mList.add(rating);
        }
      }
    });

    return mList;
  }

  Future<int> countOrganizationRatings() async {
    var keys = _ratingBox?.keys;
    if (keys != null) {
      return keys.length;
    }
    return 0;
  }

  Future addFieldMonitorSchedules(
      {required List<FieldMonitorSchedule> schedules}) async {
    for (var s in schedules) {
      await addFieldMonitorSchedule(schedule: s);
    }
    pp('$mm FieldMonitorSchedules added to local cache: 🔵 🔵  ${schedules.length} ');

    return 0;
  }

  Future addOrgMessage({required OrgMessage message}) async {
    pp('$mm .... addOrgMessage .....');
    var key = '${message.created}_${message.organizationId}';
    await _orgMessageBox?.put(key, message);
    pp('$mm OrgMessage added to local cache: ${message.projectName}');
  }

  Future addPhotos({required List<Photo> photos}) async {
    for (var v in photos) {
      await addPhoto(photo: v);
    }
    pp('$mm Photos added to local cache: 🔵 🔵  ${photos.length} ');

    return photos.length;
  }

  Future addProjectPositions({required List<ProjectPosition> positions}) async {
    for (var v in positions) {
      await addProjectPosition(projectPosition: v);
    }
    pp('$mm ProjectPositions added to local cache: 🔵 🔵  ${positions.length} ');

    return positions.length;
  }

  Future addProjectPolygons({required List<ProjectPolygon> polygons}) async {
    for (var polygon in polygons) {
      await addProjectPolygon(projectPolygon: polygon);
    }
    pp('$mm ProjectPolygons added to local cache: 🔵 🔵  ${polygons.length} ');

    return polygons.length;
  }

  Future addProjects({required List<Project> projects}) async {
    for (var v in projects) {
      await addProject(project: v);
    }
    pp('$mm Projects added to local cache: 🔵 🔵  ${projects.length} ');

    return projects.length;
  }

  Future addUsers({required List<User> users}) async {
    pp('$mm adding ${users.length} users to local cache ...');
    for (var v in users) {
      await addUser(user: v);
    }
    pp('$mm Users added to local cache: 🔵 🔵  ${users.length} ');

    return users.length;
  }

  Future deleteUsers() async {
    _userBox?.clear();
    pp('$mm all users removed from cache 🔆🔆');
  }

  Future addVideos({required List<Video> videos}) async {
    for (var v in videos) {
      await addVideo(video: v);
    }
    pp('$mm Videos added to local cache: 🔵 🔵  ${videos.length} ');

    return videos.length;
  }

  Future addAudios({required List<Audio> audios}) async {
    for (var v in audios) {
      await addAudio(audio: v);
    }
    pp('$mm Audios added to local cache: 🔵 🔵  ${audios.length} ');

    return audios.length;
  }

  List<FieldMonitorSchedule> filterSchedulesByProject(
      List<FieldMonitorSchedule> mList, String projectId) {
    List<FieldMonitorSchedule> list = [];
    for (var element in mList) {
      if (element.projectId == projectId) {
        list.add(element);
      }
    }
    return list;
  }

  Future<Project?> getProjectById({required String projectId}) async {
    return null;
  }

  Future<List<FieldMonitorSchedule>> getFieldMonitorSchedules(
      String userId) async {
    var keys = _scheduleBox?.keys;
    List<FieldMonitorSchedule> schedules = [];
    if (keys != null) {
      for (var r in keys) {
        if (r.contains(userId)) {
          var x = await _scheduleBox?.get(r);
          schedules.add(x!);
        }
      }
    }

    return schedules;
  }

  Future<List<FieldMonitorSchedule>> getOrganizationMonitorSchedules(
      String organizationId) async {
    List<FieldMonitorSchedule> list = [];

    var keys = _scheduleBox?.keys;

    if (keys != null) {
      for (var key in keys) {
        var m = await _scheduleBox!.get(key);
        if (m != null) {
          list.add(m);
        }
      }
    }
    pp('$mm ${list.length} list found in cache 🔵');

    return list;
  }
  Future<List<AudioForUpload>> getAudioForUpload() async {
    List<AudioForUpload> list = [];
    var keys = _uploadAudioBox?.keys;

    if (keys != null) {
      for (var key in keys) {
        var mSettings = await _uploadAudioBox?.get(key);
        list.add(mSettings!);
      }
    }
    if (list.isNotEmpty) {
      pp('$mm ${list.length} org settings list found in cache 🔵');
    }
    return list;
  }
  Future<List<VideoForUpload>> getVideosForUpload() async {
    List<VideoForUpload> list = [];
    var keys = _uploadVideoBox?.keys;

    if (keys != null) {
      for (var key in keys) {
        var video = await _uploadVideoBox?.get(key);
        list.add(video!);
      }
    }
    if (list.isNotEmpty) {
      pp('$mm ${list.length} VideoForUpload list found in cache 🔵');
    }
    return list;
  }
  Future<List<PhotoForUpload>> getPhotosForUpload() async {
    List<PhotoForUpload> list = [];
    var keys = _uploadPhotoBox?.keys;

    if (keys != null) {
      for (var key in keys) {
        var photo = await _uploadPhotoBox?.get(key);
        list.add(photo!);
      }
    }
    if (list.isNotEmpty) {
      pp('$mm ${list.length} PhotoForUpload list found in cache 🔵');
    }
    return list;
  }


  Future<List<SettingsModel>> getOrganizationSettings() async {
    List<SettingsModel> list = [];
    pp('$mm org settings search in cache ..........');
    var keys = _settingsBox?.keys;

    if (keys != null) {
      pp('$mm org settings search in cache ..........  🔵 keys: ${keys.length}');
      for (var key in keys) {
        var mSettings = await _settingsBox?.get(key);
        pp('$mm org settings search in cache .......... mSettings:  😡 ${mSettings!.toJson()}');
        list.add(mSettings);
      }
    }
    pp('$mm ${list.length} org settings list found in cache 🔵');
    return list;
  }

  Future<List<SettingsModel>> getProjectSettings(String projectId) async {
    List<SettingsModel> list = [];
    var keys = _settingsBox?.keys;

    if (keys != null) {
      for (var key in keys) {
        var m = await _settingsBox!.get(key);
        if (m != null) {
          if (projectId == m.projectId) {
            list.add(m);
          }
        }
      }
    }
    pp('$mm ${list.length} list found in cache 🔵');
    return list;
  }

  Future<List<ProjectAssignment>> getProjectAssignments(String projectId) async {
    List<ProjectAssignment> list = [];
    var keys = _assignmentBox?.keys;

    if (keys != null) {
      for (var key in keys) {
        var m = await _assignmentBox!.get(key);
        if (m != null) {
          if (projectId == m.projectId) {
            list.add(m);
          }
        }
      }
    }
    pp('$mm ${list.length} assignments found in cache 🔵');
    return list;
  }
  Future<List<ProjectAssignment>> getUserProjectAssignments(String userId) async {
    List<ProjectAssignment> list = [];
    var keys = _assignmentBox?.keys;

    if (keys != null) {
      for (var key in keys) {
        var m = await _assignmentBox!.get(key);
        if (m != null) {
          if (userId == m.userId) {
            list.add(m);
          }
        }
      }
    }
    pp('$mm ${list.length} assignments found in cache 🔵');
    return list;
  }
  Future<List<ProjectAssignment>> getOrganizationProjectAssignments() async {
    List<ProjectAssignment> list = [];
    var keys = _assignmentBox?.keys;

    if (keys != null) {
      for (var key in keys) {
        var m = await _assignmentBox!.get(key);
        if (m != null) {
            list.add(m);

        }
      }
    }
    pp('$mm ${list.length} assignments found in cache 🔵');
    return list;
  }


  Future<List<GeofenceEvent>> getGeofenceEventsByUser(String userId) async {
    var keys = _geofenceEventBox?.keys;
    var mList = <GeofenceEvent>[];
    if (keys != null) {
      for (var key in keys) {
        if (key.contains(userId)) {
          var e = await _geofenceEventBox?.get(key);
          mList.add(e!);
        }
      }
    }
    pp('$mm getGeofenceEventsByUser found: ${mList.length}');
    return mList;
  }

  Future<List<GeofenceEvent>> getGeofenceEventsByProjectPosition(
      String projectPositionId) async {
    var keys = _geofenceEventBox?.keys;
    var mList = <GeofenceEvent>[];
    if (keys != null) {
      for (var key in keys) {
        if (key.contains(projectPositionId)) {
          var e = await _geofenceEventBox?.get(key);
          mList.add(e!);
        }
      }
    }
    pp('$mm getGeofenceEventsByProjectPosition found: ${mList.length}');
    return mList;
  }

  Future<DataBag> getOrganizationData({required String organizationId}) async {
    pp('$mm$mm getOrganizationData starting ...');
    final projects = await getOrganizationProjects();
    final users = await getUsers();
    final photos = await getOrganizationPhotos();
    final videos = await getOrganizationVideos();
    final audios = await getOrganizationAudios();
    final settings = await getOrganizationSettings();

    final schedules = await getOrganizationMonitorSchedules(organizationId);
    final positions =
        await getOrganizationProjectPositions(organizationId: organizationId);
    final polygons =
        await getOrganizationProjectPolygons(organizationId: organizationId);

    final bag = DataBag(
        photos: photos,
        videos: videos,
        fieldMonitorSchedules: schedules,
        projectPositions: positions,
        projects: projects,
        audios: audios,
        projectPolygons: polygons,
        date: DateTime.now().toUtc().toIso8601String(),
        users: users, settings: settings);

    pp('$mm getOrganizationData: 🍎projects: ${projects.length} '
        '🍎users: ${users.length} 🍎photos: ${photos.length}'
        ' 🍎videos: ${videos.length} 🍎schedules: ${schedules.length} '
        '🍎positions: ${positions.length} '
        '🍎polygons: ${polygons.length} 🍎audios: ${audios.length}');

    return bag;
  }

  Future<List<Photo>> getOrganizationPhotos() async {
    List<Photo> mList = [];
    var keys = _photoBox?.keys;
    if (keys != null) {
      for (var key in keys) {
        var m = await _photoBox!.get(key);
        if (m != null) {
          mList.add(m);
        }
      }
    }

    pp('$mm ${mList.length} photos found in cache');
    return mList;
  }

  Future<List<FieldMonitorSchedule>> getProjectMonitorSchedules(
      String projectId) async {
    var keys = _scheduleBox?.keys;
    List<FieldMonitorSchedule> mList = [];
    if (keys != null) {
      for (var key in keys) {
        var m = await _scheduleBox!.get(key);
        if (m != null) {
          if (m.projectId == projectId) {
            mList.add(m);
          }
        }
      }
    }
    pp('$mm Project schedules found: ${mList.length}');
    return mList;
  }

  Future<List<Photo>> getProjectPhotos(String projectId) async {
    var keys = _photoBox?.keys;
    List<Photo> mList = [];
    if (keys != null) {
      for (var key in keys) {
        var m = await _photoBox!.get(key);
        if (m != null) {
          if (m.projectId == projectId) {
            mList.add(m);
          }
        }
      }
    }
    pp('$mm Project photos found: ${mList.length}');
    return mList;
  }

  Future<List<ProjectPolygon>> getProjectPolygons(
      {required String projectId}) async {
    var keys = _projectPolygonBox?.keys;
    List<ProjectPolygon> mList = [];

    if (keys != null) {
      for (var key in keys) {
        var m = await _projectPolygonBox!.get(key);
        if (m != null) {
          if (m.projectId == projectId) {
            mList.add(m);
          }
        }
      }
    }
    pp('$mm ProjectPolygons found: ${mList.length}');
    return mList;
  }

  Future<List<Video>> getProjectVideos(String projectId) async {
    var keys = _videoBox?.keys;
    List<Video> mList = [];
    if (keys != null) {
      for (var key in keys) {
        var m = await _videoBox!.get(key);
        if (m != null) {
          if (m.projectId == projectId) {
            mList.add(m);
          }
        }
      }
    }
    pp('$mm Project videos found: ${mList.length}');
    return mList;
  }

  Future<Video?> getVideoById(String id) async {
    var keys = _videoBox?.keys;
    Video? vid;
    if (keys != null) {
      for (var key in keys) {
        var m = await _videoBox!.get(key);
        if (m != null) {
          if (m.videoId == id) {
            vid = m;
            break;
          }
        }
      }
    }
    return vid;
  }
  Future<Photo?> getPhotoById(String id) async {
    var keys = _photoBox?.keys;
    Photo? photo;
    if (keys != null) {
      for (var key in keys) {
        var m = await _photoBox!.get(key);
        if (m != null) {
          if (m.photoId == id) {
            photo = m;
            break;
          }
        }
      }
    }
    return photo;
  }
  Future<Audio?> getAudioById(String id) async {
    var keys = _audioBox?.keys;
    Audio? audio;
    if (keys != null) {
      for (var key in keys) {
        var m = await _audioBox!.get(key);
        if (m != null) {
          if (m.audioId == id) {
            audio = m;
            break;
          }
        }
      }
    }
    return audio;
  }

  Future<List<Audio>> getProjectAudios(String projectId) async {
    var keys = _audioBox?.keys;
    List<Audio> mList = [];
    if (keys != null) {
      for (var key in keys) {
        var m = await _audioBox!.get(key);
        if (m != null) {
          if (m.projectId == projectId) {
            mList.add(m);
          }
        }
      }
    }
    pp('$mm Project audio clips found: ${mList.length}');
    return mList;
  }

  Future<List<Video>> getOrganizationVideos() async {
    List<Video> mList = [];
    var keys = _videoBox?.keys;
    if (keys != null) {
      for (var key in keys) {
        var m = await _videoBox!.get(key);
        if (m != null) {
          mList.add(m);
        }
      }
    }
    pp('$mm ${mList.length} videos found in cache');
    return mList;
  }

  Future<List<Audio>> getOrganizationAudios() async {
    List<Audio> mList = [];
    var keys = _audioBox?.keys;
    if (keys != null) {
      for (var key in keys) {
        var m = await _audioBox!.get(key);
        if (m != null) {
          mList.add(m);
        }
      }
    }
    pp('$mm ${mList.length} audios found in cache');
    return mList;
  }

  Future<List<Photo>> getUserPhotos(String userId) async {
    var keys = _photoBox?.keys;
    List<Photo> mList = [];
    if (keys != null) {
      for (var key in keys) {
        if (key.contains(userId)) {
          var photo = await _photoBox?.get(key);
          if (photo != null) {
            mList.add(photo);
          }
        }
      }
    }
    pp('$mm User photos found: ${mList.length}');
    return mList;
  }

  Future<List<User>> getUsers() async {
    var keys = _userBox?.keys;
    var mList = <User>[];
    if (keys != null) {
      for (var value in keys) {
        var m = await _userBox?.get(value);
        if (m != null) {
          mList.add(m);
        }
      }
    }
    pp('$mm ${mList.length} users found in cache');
    return mList;
  }

  Future<List<Video>> getVideos() async {
    List<Video> videos = [];
    var keys = _videoBox?.keys;
    var mList = <Video>[];
    if (keys != null) {
      for (var value in keys) {
        var m = await _videoBox?.get(value);
        if (m != null) {
          mList.add(m);
        }
      }
    }
    return videos;
  }

  Future addFieldMonitorSchedule(
      {required FieldMonitorSchedule schedule}) async {
    var key = '${schedule.projectId}_${schedule.fieldMonitorScheduleId}';
    await _scheduleBox?.put(key, schedule);
    // pp('$mm FieldMonitorSchedule added to local cache:  🔵 🔵 ${schedule.projectName}');
  }

  Future addPhoto({required Photo photo}) async {
    var key =
        '${photo.organizationId}_${photo.projectId}_${photo.userId}_${photo.photoId}_${photo.created}';
    await _photoBox?.put(key, photo);
    // pp('$mm Photo added to local cache:  🔵 🔵 ${photo.projectName}');
  }

  Future addFailedPhoto({required Photo photo}) async {
    var key =
        '${photo.organizationId}_${photo.projectId}_${photo.userId}_${photo.created}';
    await _failedPhotoBox?.put(key, photo);
    pp('$mm Failed Photo added to local cache:  🔵 🔵 ${photo.projectName}');
  }

  Future addFailedAudio({required FailedAudio failedAudio}) async {
    var key = '${failedAudio.date}';
    await _failedAudioBox?.put(key, failedAudio);
    pp('$mm Failed Audio added to local cache  🔵');
  }

  Future removeUploadedPhoto({required PhotoForUpload photo}) async {
    var key =
        '${photo.project!.projectId}_${photo.date}';
    await _uploadPhotoBox?.delete(key);
    pp('$mm PhotoForUpload deleted from local cache:  🔵 🔵 ${photo.project!.name}');
  }

  Future removeUploadedAudio({required AudioForUpload audio}) async {
    var key =
        '${audio.project!.projectId}_${audio.date}';
    await _uploadAudioBox?.delete(key);
    pp('$mm AudioForUpload deleted from local cache: 🔵 🔵 ${audio.project!.name}');
  }

  Future removeUploadedVideo({required VideoForUpload video}) async {
    var key =
        '${video.project!.projectId}_${video.date}';
    await _uploadVideoBox?.delete(key);
    pp('$mm VideoForUpload deleted from local cache:  🔵 🔵 ${video.project!.name}');
  }

  Future removeFailedPhoto({required Photo photo}) async {
    var key =
        '${photo.organizationId}_${photo.projectId}_${photo.userId}_${photo.created}';
    await _failedPhotoBox?.delete(key);
    pp('$mm Failed Photo deleted from local cache:  🔵 🔵 ${photo.projectName}');
  }

  Future removeFailedVideo({required Video video}) async {
    var key =
        '${video.organizationId}_${video.projectId}_${video.userId}_${video.created}';
    await _failedVideoBox?.delete(key);
    pp('$mm Failed Video deleted from local cache:  🔵 🔵 ${video.projectName}');
  }

  Future removeFailedAudio({required FailedAudio failedAudio}) async {
    var key = '${failedAudio.date}';
    await _failedAudioBox?.delete(key);
    pp('$mm Failed Audio deleted from local cache  🔵');
  }

  Future addFailedBag({required FailedBag bag}) async {
    var key = bag.date!;
    await _failedBagBox?.put(key, bag);
    pp('$mm FailedBag added to local cache:  🔵 🔵 '
        '${bag.date!} - ${bag.project!.name!}');
  }

  Future removeFailedBag({required FailedBag bag}) async {
    var key = bag.date!;
    await _failedBagBox?.delete(key);
    pp('$mm FailedBag deleted from local cache:  🔵 🔵  '
        '${bag.date!} - ${bag.project!.name!}');
  }

  Future addProject({required Project project}) async {
    var key = '${project.organizationId}_${project.projectId}';
    await _projectBox?.put(key, project);
    // pp('$mm Project added to local cache:  🔵 🔵 ${project.name} ');
  }

  Future addProjectPosition({required ProjectPosition projectPosition}) async {
    var key =
        '${projectPosition.organizationId}_${projectPosition.projectId}_${projectPosition.projectPositionId}';
    await _positionBox?.put(key, projectPosition);
    // pp('$mm ProjectPosition added to local cache:  🔵 🔵 ${projectPosition.projectName} ');
  }

  Future addUser({required User user}) async {
    var key = '${user.organizationId}_${user.userId}';
    await _userBox?.put(key, user);
    pp('$mm User added to local cache:  🔵 🔵 ${user.name} organizationId: ${user.organizationId} ');
  }

  Future deleteUser({required User user}) async {
    var key = '${user.organizationId}_${user.userId}';
    var keys = _userBox?.keys;
    if (keys != null) {
      for (var mKey in keys) {
        if (mKey == key) {
          await _userBox?.delete(mKey);
          break;
        }
      }
    }
    pp('$mm User deleted from hive cache:  🔵 🔵 ${user.name} organizationId: ${user.organizationId} ');
  }

  Future addVideo({required Video video}) async {
    var key =
        '${video.organizationId}_${video.projectId}_${video.userId}_${video.videoId}_${video.created}';
    await _videoBox?.put(key, video);
    // pp('$mm Video added to local cache:  🔵 🔵 ${video.projectName}');
  }

  Future addAudio({required Audio audio}) async {
    try {
      var key =
          '${audio.organizationId}_${audio.projectId}_${audio.userId}_${audio.audioId}_${audio.created}';
      await _audioBox?.put(key, audio);
      // pp('$mm looks like hive has cached an audio object');
      return 0;
    } catch (e) {
      pp('$mm hive ERROR: $e');
      return 9;
    }
    // pp('$mm Video added to local cache:  🔵 🔵 ${video.projectName}');
  }

  Future addFailedVideo({required Video video}) async {
    var key =
        '${video.organizationId}_${video.projectId}_${video.userId}_${video.created}';
    await _failedVideoBox?.put(key, video);
    pp('$mm failed Video added to local cache:  🔵 🔵 ${video.projectName}');
  }

  Future<List<Project>> getOrganizationProjects() async {
    var keys = _projectBox?.keys;

    var mList = <Project>[];
    if (keys != null) {
      for (var value in keys) {
        var m = await _projectBox?.get(value);
        if (m != null) {
          mList.add(m);
        }
      }
    }
    pp('$mm ${mList.length} projects found in cache');
    return mList;
  }

  Future<List<FailedAudio>> getFailedAudios() async {
    var keys = _failedAudioBox?.keys;

    var mList = <FailedAudio>[];
    if (keys != null) {
      for (var value in keys) {
        var m = await _failedAudioBox?.get(value);
        if (m != null) {
          mList.add(m);
        }
      }
    }
    pp('$mm ${mList.length} failed Audios found in cache');
    return mList;
  }

  Future<List<FailedBag>> getFailedBags() async {
    var keys = _failedBagBox?.keys;
    var mList = <FailedBag>[];
    if (keys != null) {
      for (var value in keys) {
        var m = await _failedBagBox?.get(value);
        if (m != null) {
          mList.add(m);
        }
      }
    }
    pp('$mm ${mList.length} FailedBags found in cache');
    return mList;
  }

  Future addCities({required List<City> cities}) async {
    for (var city in cities) {
      await addCity(city: city);
    }
    return 0;
  }

  Future addCity({required City city}) async {
    var key = '${city.cityId}';
    await _cityBox?.put(key, city);
    pp('$mm City added to local cache: 🌿 ${city.name}');
  }

  Future addCountry({required Country country}) async {
    var key = '${country.countryId}';
    await _countryBox?.put(key, country);
    pp('$mm Country added to local cache: 🌿 ${country.name}');
  }

  Future addMonitorReport({required MonitorReport monitorReport}) async {
    var key =
        '${monitorReport.organizationId}_${monitorReport.projectId}_${monitorReport.monitorReportId}';
    await _reportBox?.put(key, monitorReport);
    pp('$mm MonitorReport added to local cache: 🌿 ${monitorReport.projectId}');
  }

  Future addMonitorReports(
      {required List<MonitorReport> monitorReports}) async {
    for (var r in monitorReports) {
      await addMonitorReport(monitorReport: r);
    }
    return 0;
  }

  Future addCommunities({required List<Community> communities}) async {
    for (var c in communities) {
      await addCommunity(community: c);
    }
    return 0;
  }

  Future addGeofenceEvent({required GeofenceEvent geofenceEvent}) async {
    var key =
        '${geofenceEvent.user!.userId!}_${geofenceEvent.projectPositionId}';
    await _geofenceEventBox?.put(key, geofenceEvent);
    pp('$mm GeofenceEvent added to local cache: ${geofenceEvent.projectName}');
  }

  Future addCommunity({required Community community}) async {
    var key = '${community.countryId}_${community.communityId}';
    await _communityBox?.put(key, community);
    pp('$mm Community added to local cache: ${community.name}');
  }

  Future addOrganization({required Organization organization}) async {
    var key = '${organization.countryId}_${organization.organizationId}';
    await _orgBox?.put(key, organization);
    pp('$mm Organization added to local cache: ${organization.name}');
  }

  Future<List<Community>> getCommunities() async {
    var keys = _communityBox?.keys;
    var mList = <Community>[];
    if (keys != null) {
      for (var key in keys) {
        var comm = await _communityBox?.get(key);
        mList.add(comm!);
      }
    }
    pp('$mm .... getCommunities ..... found:  🌼 ${mList.length} 🌼');
    return mList;
  }

  Future<List<Country>> getCountries() async {
    pp('$mm .... getCountries from hive ..... ');

    var keys = _countryBox?.keys;
    var mList = <Country>[];
    if (keys != null) {
      for (var value in keys) {
        var m = await _countryBox?.get(value);
        if (m != null) {
          mList.add(m);
        }
      }
    }
    pp('$mm .... getCountries ..... found:  🌼 ${mList.length} 🌼');
    return mList;
  }

  Future<List<Organization>> getOrganizations() async {
    var keys = _orgBox?.keys;
    var mList = <Organization>[];
    if (keys != null) {
      for (var key in keys) {
        var comm = await _orgBox?.get(key);
        mList.add(comm!);
      }
    }
    pp('$mm .... getOrganizations ..... found:  🌼 ${mList..length}  🌼');
    return mList;
  }

  Future addSection({required Section section}) async {
    pp('$mm section NOT added to local cache:  🔵 🔵 sectionNumber: ${section.sectionNumber}');
  }

  Future<List<Photo>> getSections(String questionnaireId) {
    // TODO: implement getSections
    throw UnimplementedError();
  }

  Future<Organization?> getOrganizationById(
      {required String organizationId}) async {
    pp('$mm .... getOrganizationById ..... ');
    var keys = _orgBox?.keys;
    Organization? org;
    if (keys != null) {
      for (var key in keys) {
        if (key.contains(organizationId)) {
          org = await _orgBox?.get(key);
        }
      }
    }

    pp('$mm .... getOrganizationById ..... 🌺 found:  🌼 ${org?.name}  🌼');
    return org;
  }

  Future<List<ProjectPosition>> getOrganizationProjectPositions(
      {required String organizationId}) async {
    var mList = <ProjectPosition>[];
    var keys = _positionBox?.keys;
    if (keys != null) {
      for (var value in keys) {
        var m = await _positionBox?.get(value);
        if (m != null) {
          mList.add(m);
        }
      }
    }

    pp('$mm ${mList.length} ProjectPositions found in cache');
    return mList;
  }

  Future addProjectPolygon({required ProjectPolygon projectPolygon}) async {
    var key =
        '${projectPolygon.organizationId}_${projectPolygon.projectId}_${projectPolygon.projectPolygonId}';
    await _projectPolygonBox?.put(key, projectPolygon);
    // pp('$mm ProjectPolygon added to local cache:  🔵 🔵 ${projectPolygon.projectName} ');
  }

  Future<List<ProjectPolygon>> getOrganizationProjectPolygons(
      {required String organizationId}) async {
    var mList = <ProjectPolygon>[];
    var keys = _projectPolygonBox?.keys;
    if (keys != null) {
      for (var value in keys) {
        var m = await _projectPolygonBox?.get(value);
        if (m != null) {
          mList.add(m);
        }
      }
    }

    pp('$mm ${mList.length} ProjectPolygons (all) found in cache');
    return mList;
  }

  Future<List<ProjectPosition>> getProjectPositions(String projectId) async {
    var keys = _positionBox?.keys;
    var mList = <ProjectPosition>[];
    if (keys != null) {
      for (var key in keys) {
        if (key.contains(projectId)) {
          var pos = await _positionBox?.get(key);
          mList.add(pos!);
        }
      }
    }
    pp('$mm ProjectPositions found: ${mList.length} ');
    return mList;
  }

  Future<ProjectPosition?> getProjectPosition(String projectPositionId) async {
    ProjectPosition? position;
    var keys = _positionBox?.keys;
    if (keys != null) {
      for (var key in keys) {
        if (key.contains(projectPositionId)) {
          position = await _positionBox?.get(key);
        }
      }
    }
    pp('$mm .... getProjectPosition ..... 🌺 found:  🌼 ${position == null ? 'Not Found' : position.projectPositionId}  🌼');
    return position;
  }

  Future<List<Video>> getUserVideos(String userId) async {
    var keys = _videoBox?.keys;
    List<Video> mList = [];
    if (keys != null) {
      for (var key in keys) {
        if (key.contains(userId)) {
          var video = await _videoBox?.get(key);
          mList.add(video!);
        }
      }
    }
    pp('$mm User videos found: ${mList.length}');
    return mList;
  }
}
