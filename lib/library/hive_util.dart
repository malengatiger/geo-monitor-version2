import 'dart:io';
import 'dart:math';

import 'package:geo_monitor/library/bloc/failed_bag.dart';
import 'package:geo_monitor/library/data/organization_registration_bag.dart';
import 'package:geo_monitor/library/data/project_polygon.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import 'api/sharedprefs.dart';
import 'data/audio.dart';
import 'data/city.dart';
import 'data/community.dart';
import 'data/condition.dart';
import 'data/country.dart';
import 'data/data_bag.dart';
import 'data/field_monitor_schedule.dart';
import 'data/geofence_event.dart';
import 'data/monitor_report.dart';
import 'data/org_message.dart';
import 'data/organization.dart';
import 'data/photo.dart';
import 'data/place_mark.dart';
import 'data/position.dart';
import 'data/project.dart';
import 'data/project_position.dart';
import 'data/section.dart';
import 'data/user.dart';
import 'data/video.dart';
import 'emojis.dart';
import 'functions.dart';
import 'generic_functions.dart';

const stillWorking = 201, doneCaching = 200;
HiveUtil hiveUtil = HiveUtil._instance;

var fileCounter = 0;
const databaseFileName = 'db';
const boxCollection = 'BoxCollection';

class HiveUtil {
  static final HiveUtil _instance = HiveUtil._internal();

  factory HiveUtil() {
    return _instance;
  }

  HiveUtil._internal() {}

  BoxCollection? _boxCollection;
  CollectionBox<Organization>? _orgBox;
  CollectionBox<Project>? _projectBox;
  CollectionBox<ProjectPosition>? _positionBox;
  CollectionBox<City>? _cityBox;
  CollectionBox<Photo>? _photoBox;
  CollectionBox<Video>? _videoBox;
  CollectionBox<Community>? _communityBox;
  CollectionBox<Condition>? _conditionBox;
  CollectionBox<FieldMonitorSchedule>? _scheduleBox;
  CollectionBox<OrgMessage>? _orgMessageBox;
  CollectionBox<User>? _userBox;
  CollectionBox<MonitorReport>? _reportBox;
  CollectionBox<GeofenceEvent>? _geofenceEventBox;
  CollectionBox<ProjectPolygon>? _projectPolygonBox;
  CollectionBox<Photo>? _failedPhotoBox;
  CollectionBox<Video>? _failedVideoBox;
  CollectionBox<FailedBag>? _failedBagBox;
  CollectionBox<Country>? _countryBox;
  CollectionBox<OrganizationRegistrationBag>? _registrationBox;
  CollectionBox<Audio>? _audioBox;

  bool _isInitialized = false;

  initialize({bool? forceInitialization = false}) async {
    fileCounter = await Prefs.getFileCounter();
    if (forceInitialization != null) {
      if (forceInitialization) {
        pp('\n\n$mm Setting Hive files to new suffix: $fileCounter');
        await _clearAllBoxes();
        await _doTheInitializationWork();
        return;
      }
    }
    if (!_isInitialized) {
      pp('\n\n$mm Setting Hive files to existing suffix: $fileCounter');
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
    _conditionBox?.clear();
    _audioBox?.clear();
    pp('$mm all Hive boxes cleared 💚💚');
  }

  static final xx =
      '${Emoji.peach}${Emoji.peach}${Emoji.peach}${Emoji.peach} HiveUtil: ';
  Future<void> _doTheInitializationWork() async {
    p('$mm ... Creating a Hive box collection');
    var appDir = await getApplicationDocumentsDirectory();
    File file = File('${appDir.path}/$databaseFileName$fileCounter.file');

    try {
      _boxCollection = await BoxCollection.open(
        '$boxCollection$fileCounter', // Name of your database
        {
          'organizations',
          'projects',
          'positions',
          'cities',
          'photos',
          'videos',
          'communities',
          'conditions',
          'schedules',
          'messages',
          'users',
          'reports',
          'geofenceEvents',
          'failedPhotos',
          'failedVideos',
          'projectPolygons',
          'failedBags',
          'registrations',
          'countries',
          'audios',
        },
        // Names of your boxes
        path: file
            .path, // Path where to store your boxes (Only used in Flutter / Dart IO)
      );
    } catch (e) {
      pp('$mm 🔴🔴 There is some problem with 🔴initialization 🔴');
    }
    p('$xx Registering Hive object adapters ...');
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

    var bb = file.path.lastIndexOf("/");
    var cc = file.path.substring(bb + 1);
    p('$mm Hive box collection created and types registered; 🍎file: $cc '
        '🍎_boxCollection: ${_boxCollection!.name}');

    try {
      _orgBox = await _boxCollection!.openBox<Organization>('organizations');
      _projectBox = await _boxCollection!.openBox<Project>('projects');
      _positionBox =
          await _boxCollection!.openBox<ProjectPosition>('positions');
      _cityBox = await _boxCollection!.openBox<City>('cities');
      _photoBox = await _boxCollection!.openBox<Photo>('photos');
      _videoBox = await _boxCollection!.openBox<Video>('videos');
      _communityBox = await _boxCollection!.openBox<Community>('communities');
      _conditionBox = await _boxCollection!.openBox<Condition>('conditions');
      _countryBox = await _boxCollection!.openBox<Country>('countries');
      _scheduleBox =
          await _boxCollection!.openBox<FieldMonitorSchedule>('schedules');
      _orgMessageBox = await _boxCollection!.openBox<OrgMessage>('messages');
      _reportBox = await _boxCollection!.openBox<MonitorReport>('reports');
      _geofenceEventBox =
          await _boxCollection!.openBox<GeofenceEvent>('geofenceEvents');

      _userBox = await _boxCollection!.openBox<User>('users');
      _projectPolygonBox =
          await _boxCollection!.openBox<ProjectPolygon>('projectPolygons');

      _failedPhotoBox = await _boxCollection!.openBox<Photo>('failedPhotos');
      _failedVideoBox = await _boxCollection!.openBox<Video>('failedVideos');
      _failedBagBox = await _boxCollection!.openBox<FailedBag>('failedBags');
      _registrationBox = await _boxCollection!
          .openBox<OrganizationRegistrationBag>('registrations');
      _audioBox = await _boxCollection!.openBox<Audio>('audios');

      //
      _isInitialized = true;
      p('$mm'
          ' Hive has been initialized and boxes opened ${Emoji.leaf}${Emoji.leaf}${Emoji.leaf}');
    } catch (e) {
      p('🔴🔴 We have a problem 🔴 opening Hive boxes: $e');
    }
  }

  final mm =
      '${Emoji.appleRed}${Emoji.appleRed}${Emoji.appleRed}${Emoji.appleRed} HiveUtil: ';
  var random = Random(DateTime.now().millisecondsSinceEpoch);

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
    var keys = await _scheduleBox?.getAllKeys();
    var list = <FieldMonitorSchedule>[];
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
    List<FieldMonitorSchedule> schedules = [];

    var map = await _scheduleBox?.getAllValues();
    if (map != null) {
      schedules = map.values.toList();
    }
    pp('$mm ${schedules.length} schedules found in cache 🔵');

    return schedules;
  }

  Future<List<GeofenceEvent>> getGeofenceEventsByUser(String userId) async {
    var keys = await _geofenceEventBox?.getAllKeys();
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
    var keys = await _geofenceEventBox?.getAllKeys();
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
    pp('\mm$mm getOrganizationData starting ...');
    final projects = await getOrganizationProjects();
    final users = await getUsers(organizationId: organizationId);
    final photos = await getOrganizationPhotos(organizationId);
    final videos = await getOrganizationVideos(organizationId);
    final audios = await getOrganizationAudios(organizationId);

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
        users: users);

    pp('$mm getOrganizationData: 🍎projects: ${projects.length} '
        '🍎users: ${users.length} 🍎photos: ${photos.length}'
        ' 🍎videos: ${videos.length} 🍎schedules: ${schedules.length} '
        '🍎positions: ${positions.length} '
        '🍎polygons: ${polygons.length} 🍎audios: ${audios.length}');

    return bag;
  }

  Future<List<Photo>> getOrganizationPhotos(String organizationId) async {
    List<Photo> mList = [];
    var photoMap = await _photoBox?.getAllValues();
    if (photoMap != null) {
      mList = photoMap.values.toList();
    }

    pp('$mm ${mList.length} photos found in cache');
    return mList;
  }

  Future<List<FieldMonitorSchedule>> getProjectMonitorSchedules(
      String projectId) async {
    var keys = await _scheduleBox?.getAllValues();
    List<FieldMonitorSchedule> mList = [];
    if (keys != null) {
      keys.values
          .where((item) => item.projectId == projectId)
          .forEach((item) => mList.add(item));
    }
    pp('$mm Project schedules found: ${mList.length}');
    return mList;
  }

  Future<List<Photo>> getProjectPhotos(String projectId) async {
    var keys = await _photoBox?.getAllValues();
    List<Photo> mList = [];
    if (keys != null) {
      keys.values
          .where((item) => item.projectId == projectId)
          .forEach((item) => mList.add(item));
    }
    pp('$mm Project photos found: ${mList.length}');
    return mList;
  }

  Future<List<ProjectPolygon>> getProjectPolygons(
      {required String projectId}) async {
    var keys = await _projectPolygonBox?.getAllValues();
    List<ProjectPolygon> mList = [];

    if (keys != null) {
      keys.values
          .where((item) => item.projectId == projectId)
          .forEach((item) => mList.add(item));
    }
    pp('$mm ProjectPolygons found: ${mList.length}');
    return mList;
  }

  Future<List<Video>> getProjectVideos(String projectId) async {
    var keys = await _videoBox?.getAllKeys();
    List<Video> mList = [];
    if (keys != null) {
      for (var key in keys) {
        if (key.contains(projectId)) {
          var video = await _videoBox?.get(key);
          mList.add(video!);
        }
      }
    }
    pp('$mm Project videos found: ${mList.length}');
    return mList;
  }
  Future<List<Audio>> getProjectAudios(String projectId) async {
    var keys = await _audioBox?.getAllKeys();
    List<Audio> mList = [];
    if (keys != null) {
      for (var key in keys) {
        if (key.contains(projectId)) {
          var audio = await _audioBox?.get(key);
          mList.add(audio!);
        }
      }
    }
    pp('$mm Project audio clips found: ${mList.length}');
    return mList;
  }

  Future<List<Video>> getOrganizationVideos(String organizationId) async {
    List<Video> mList = [];
    var videoMap = await _videoBox?.getAllValues();
    if (videoMap != null) {
      mList = videoMap.values.toList();
    }
    pp('$mm ${mList.length} videos found in cache');
    return mList;
  }

  Future<List<Audio>> getOrganizationAudios(String organizationId) async {
    List<Audio> mList = [];
    var audioMap = await _audioBox?.getAllValues();
    if (audioMap != null) {
      mList = audioMap.values.toList();
    }
    pp('$mm ${mList.length} audios found in cache');
    return mList;
  }

  Future<List<Photo>> getUserPhotos(String userId) async {
    var keys = await _photoBox?.getAllKeys();
    List<Photo> mList = [];
    if (keys != null) {
      for (var key in keys) {
        if (key.contains(userId)) {
          var photo = await _photoBox?.get(key);
          mList.add(photo!);
        }
      }
    }
    pp('$mm User photos found: ${mList.length}');
    return mList;
  }

  Future<List<User>> getUsers({required String organizationId}) async {
    var keys = await _userBox?.getAllValues();
    var mList = <User>[];
    if (keys != null) {
      mList = keys.values.toList();
    }
    pp('$mm ${mList.length} users found in cache');
    return mList;
  }

  Future<List<Video>> getVideos() async {
    List<Video> videos = [];

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
        '${photo.organizationId}_${photo.projectId}_${photo.userId}_${photo.created}';
    await _photoBox?.put(key, photo);
    // pp('$mm Photo added to local cache:  🔵 🔵 ${photo.projectName}');
  }

  Future addFailedPhoto({required Photo photo}) async {
    var key =
        '${photo.organizationId}_${photo.projectId}_${photo.userId}_${photo.created}';
    await _failedPhotoBox?.put(key, photo);
    pp('$mm Failed Photo added to local cache:  🔵 🔵 ${photo.projectName}');
  }

  Future removeFailedPhoto({required Photo photo}) async {
    var key =
        '${photo.organizationId}_${photo.projectId}_${photo.userId}_${photo.created}';
    await _failedPhotoBox?.delete(key);
    pp('$mm Failed Photo deleted from local cache:  🔵 🔵 ${photo.projectName}');
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
    pp('$mm Project added to local cache:  🔵 🔵 ${project.name} ');
  }

  Future addProjectPosition({required ProjectPosition projectPosition}) async {
    var key =
        '${projectPosition.organizationId}_${projectPosition.projectId}_${projectPosition.projectPositionId}';
    await _positionBox?.put(key, projectPosition);
    pp('$mm ProjectPosition added to local cache:  🔵 🔵 ${projectPosition.projectName} organizationId: ${projectPosition.organizationId} ');
  }

  Future addUser({required User user}) async {
    var key = '${user.organizationId}_${user.userId}';
    await _userBox?.put(key, user);
    pp('$mm User added to local cache:  🔵 🔵 ${user.name} organizationId: ${user.organizationId} ');
  }

  Future addVideo({required Video video}) async {
    var key =
        '${video.organizationId}_${video.projectId}_${video.userId}_${video.created}';
    await _videoBox?.put(key, video);
    // pp('$mm Video added to local cache:  🔵 🔵 ${video.projectName}');
  }

  Future addAudio({required Audio audio}) async {
    try {
      var key =
          '${audio.organizationId}_${audio.projectId}_${audio.userId}_${audio.created}';
      await _audioBox?.put(key, audio);
      var list = await getOrganizationAudios(audio.organizationId!);
      pp('$mm looks like hive has cached ${list.length} audios');
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

  Future removeFailedVideo({required Video video}) async {
    var key =
        '${video.organizationId}_${video.projectId}_${video.userId}_${video.created}';
    await _failedVideoBox?.delete(key);
    pp('$mm failed Video deleted from local cache:  🔵 🔵 ${video.projectName}');
  }

  Future<List<Project>> getOrganizationProjects() async {
    var keys = await _projectBox?.getAllValues();

    var mList = <Project>[];
    if (keys != null) {
      mList = keys.values.toList();
    }
    pp('$mm ${mList.length} projects found in cache');
    return mList;
  }

  Future<List<Photo>> getFailedPhotos() async {
    var photoMap = await _failedPhotoBox?.getAllValues();
    var mList = <Photo>[];
    if (photoMap != null) {
      mList = photoMap.values.toList();
    }
    pp('$mm ${mList.length} failed Photos found in cache');
    return mList;
  }

  Future<List<Video>> getFailedVideos() async {
    var videoMap = await _failedVideoBox?.getAllValues();

    var mList = <Video>[];
    if (videoMap != null) {
      mList = videoMap.values.toList();
    }
    pp('$mm ${mList.length} failed Videos found in cache');
    return mList;
  }

  Future<List<FailedBag>> getFailedBags() async {
    var bagMap = await _failedBagBox?.getAllValues();
    var mList = <FailedBag>[];
    if (bagMap != null) {
      mList = bagMap.values.toList();
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
    var key = '${geofenceEvent.userId}_${geofenceEvent.projectPositionId}';
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
    var keys = await _communityBox?.getAllKeys();
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
    var keys = await _countryBox?.getAllValues();
    var mList = <Country>[];

    if (keys != null) {
      mList = keys.values.toList();
    }
    pp('$mm .... getCountries ..... found:  🌼 ${mList.length} 🌼');
    return mList;
  }

  Future<List<Organization>> getOrganizations() async {
    var keys = await _orgBox?.getAllKeys();
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
    var keys = await _orgBox?.getAllKeys();
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
    var map = await _positionBox?.getAllValues();
    if (map != null) {
      mList = map.values.toList();
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
    var polygonMap = await _projectPolygonBox?.getAllValues();
    if (polygonMap != null) {
      mList = polygonMap.values.toList();
    }

    pp('$mm ${mList.length} ProjectPolygons (all) found in cache');
    return mList;
  }

  Future<List<ProjectPosition>> getProjectPositions(String projectId) async {
    var keys = await _positionBox?.getAllKeys();
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
    var keys = await _positionBox?.getAllKeys();
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
    var keys = await _videoBox?.getAllKeys();
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
