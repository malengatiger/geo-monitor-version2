import 'dart:io';
import 'dart:math';

import 'package:geo_monitor/library/data/project_polygon.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import 'data/city.dart';
import 'data/community.dart';
import 'data/condition.dart';
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
  CollectionBox<DataBag>? _dataBagBox;
  CollectionBox<ProjectPolygon>? _polygonBox;

  bool _isInitialized = false;

  initialize() async {
    if (!_isInitialized) {
      p('${Emoji.peach}${Emoji.peach}${Emoji.peach} ... Creating a Hive box collection');
      var appDir = await getApplicationDocumentsDirectory();
      File file = File('${appDir.path}/db1d.file');

      try {
        _boxCollection = await BoxCollection.open(
          'DataBoxOneA03', // Name of your database
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
            'dataBags'
            'polygons'
          },
          // Names of your boxes
          path: file
              .path, // Path where to store your boxes (Only used in Flutter / Dart IO)
        );
      } catch (e) {
        pp('🔴🔴 There is some problem with 🔴initialization 🔴');
      }

      p('Registering Hive object adapters ...');
      if (!Hive.isAdapterRegistered(8)) {
        Hive.registerAdapter(OrganizationAdapter());
        p('${Emoji.peach}${Emoji.peach}${Emoji.peach} Hive OrganizationAdapter registered');
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(ProjectAdapter());
        p('${Emoji.peach}${Emoji.peach}${Emoji.peach} Hive ProjectAdapter registered');
      }
      if (!Hive.isAdapterRegistered(6)) {
        Hive.registerAdapter(ProjectPositionAdapter());
        p('${Emoji.peach}${Emoji.peach}${Emoji.peach} Hive ProjectPositionAdapter registered');
      }
      if (!Hive.isAdapterRegistered(7)) {
        Hive.registerAdapter(CityAdapter());
        p('${Emoji.peach}${Emoji.peach}${Emoji.peach} Hive CityAdapter registered');
      }

      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(PhotoAdapter());
        p('${Emoji.peach}${Emoji.peach}${Emoji.peach} Hive PhotoAdapter registered');
      }
      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(VideoAdapter());
        p('${Emoji.peach}${Emoji.peach}${Emoji.peach} Hive VideoAdapter registered');
      }
      if (!Hive.isAdapterRegistered(13)) {
        Hive.registerAdapter(CommunityAdapter());
        p('${Emoji.peach}${Emoji.peach}${Emoji.peach} Hive CommunityAdapter registered');
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(FieldMonitorScheduleAdapter());
        p('${Emoji.peach}${Emoji.peach}${Emoji.peach} Hive FieldMonitorScheduleAdapter registered');
      }
      if (!Hive.isAdapterRegistered(14)) {
        Hive.registerAdapter(OrgMessageAdapter());
        p('${Emoji.peach}${Emoji.peach}${Emoji.peach} Hive OrgMessageAdapter registered');
      }

      if (!Hive.isAdapterRegistered(9)) {
        Hive.registerAdapter(MonitorReportAdapter());
        p('${Emoji.peach}${Emoji.peach}${Emoji.peach} Hive MonitorReportAdapter registered');
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(GeofenceEventAdapter());
        p('${Emoji.peach}${Emoji.peach}${Emoji.peach} Hive GeofenceEventAdapter registered');
      }
      if (!Hive.isAdapterRegistered(16)) {
        Hive.registerAdapter(PositionAdapter());
        p('${Emoji.peach}${Emoji.peach}${Emoji.peach} Hive PositionAdapter registered');
      }
      if (!Hive.isAdapterRegistered(17)) {
        Hive.registerAdapter(PlaceMarkAdapter());
        p('${Emoji.peach}${Emoji.peach}${Emoji.peach} Hive PlaceMarkAdapter registered');
      }
      if (!Hive.isAdapterRegistered(18)) {
        Hive.registerAdapter(DataBagAdapter());
        p('${Emoji.peach}${Emoji.peach}${Emoji.peach} Hive DataBagAdapter registered');
      }
      if (!Hive.isAdapterRegistered(11)) {
        Hive.registerAdapter(UserAdapter());
        p('${Emoji.peach}${Emoji.peach}${Emoji.peach} Hive UserAdapter registered');
      }
      if (!Hive.isAdapterRegistered(19)) {
        Hive.registerAdapter(ProjectPolygonAdapter());
        p('${Emoji.peach}${Emoji.peach}${Emoji.peach} Hive ProjectPolygonAdapter registered');
      }

      p('${Emoji.peach}${Emoji.peach}${Emoji.peach}${Emoji.peach} Hive box collection created and types registered');

      try {
        // Open your boxes. Optional: Give it a type.
        _orgBox = await _boxCollection!.openBox<Organization>('organizations');
        _projectBox = await _boxCollection!.openBox<Project>('projects');
        _positionBox =
            await _boxCollection!.openBox<ProjectPosition>('positions');
        _cityBox = await _boxCollection!.openBox<City>('cities');
        _photoBox = await _boxCollection!.openBox<Photo>('photos');
        _videoBox = await _boxCollection!.openBox<Video>('videos');
        _communityBox = await _boxCollection!.openBox<Community>('communities');
        _conditionBox = await _boxCollection!.openBox<Condition>('conditions');
        _scheduleBox =
            await _boxCollection!.openBox<FieldMonitorSchedule>('schedules');
        _orgMessageBox = await _boxCollection!.openBox<OrgMessage>('messages');
        _reportBox = await _boxCollection!.openBox<MonitorReport>('reports');
        _geofenceEventBox = await _boxCollection!.openBox<GeofenceEvent>('geofenceEvents');
        _dataBagBox = await _boxCollection!.openBox<DataBag>('dataBags');
        _userBox = await _boxCollection!.openBox<User>('users');
        _polygonBox = await _boxCollection!.openBox<ProjectPolygon>('polygons');


        _isInitialized = true;
        p('${Emoji.peach}${Emoji.peach}${Emoji.peach}${Emoji.peach}'
            ' Hive has been initialized and boxes opened');
      } catch (e) {
        p('🔴🔴 We have a problem 🔴 opening Hive boxes');
      }
    }
  }

  final mm = '${Emoji.appleRed}${Emoji.appleRed}${Emoji.appleRed}';
  var random = Random(DateTime.now().millisecondsSinceEpoch);
  //
  Future addDataBag({required DataBag dataBag}) async {
    pp('$mm .... addDataBag .....');
    var key = '${dataBag.date}';
    await _dataBagBox?.put(key, dataBag);

    pp('$mm DataBag added to local cache: ${dataBag.date}');
  }
  Future<DataBag?> getLatestDataBag() async {
    DataBag? bag;
    var keys = await _dataBagBox?.getAllKeys();
    if (keys != null) {
      keys.sort((a, b) => b.compareTo(a));
      if (keys.isNotEmpty) {
        bag = await _dataBagBox?.get(keys.first);
      }
    }
    return bag;
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
    return photos.length;
  }

  Future addProjectPositions({required List<ProjectPosition> positions}) async {
    for (var v in positions) {
      await addProjectPosition(projectPosition: v);
    }
    return positions.length;
  }

  Future addProjectPolygons({required List<ProjectPolygon> polygons}) async {
    for (var v in polygons) {
      await addProjectPolygon(projectPolygon: v);
    }
    return polygons.length;
  }

  Future addProjects({required List<Project> projects}) async {
    for (var v in projects) {
      await addProject(project: v);
    }
    return projects.length;
  }

  Future addUsers({required List<User> users}) async {
    pp('$mm adding ${users.length} users to local cache ...');
    for (var v in users) {
      await addUser(user: v);
    }
    return users.length;
  }

  Future addVideos({required List<Video> videos}) async {
    for (var v in videos) {
      await addVideo(video: v);
    }
    return videos.length;
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
    var keys = await _scheduleBox?.getAllKeys();

    List<FieldMonitorSchedule> schedules = [];
    if (keys != null) {
      for (var r in keys) {
        var x = await _scheduleBox?.get(r);
        if (x?.organizationId == organizationId) {
          schedules.add(x!);
        }
      }
    }
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

  Future<List<Photo>> getPhotos() async {

    return [];
  }

  Future<List<FieldMonitorSchedule>> getProjectMonitorSchedules(
      String projectId) async {

    return [];
  }

  Future<List<Photo>> getProjectPhotos(String projectId) async {
    var keys = await _photoBox?.getAllKeys();
    List<Photo> mList = [];
    if (keys != null) {
      for (var key in keys) {
        if (key.contains(projectId)) {
          var photo = await _photoBox?.get(key);
            mList.add(photo!);

        }
      }
    }
    pp('$mm Project photos found: ${mList.length}');
    return mList;
  }

  Future<List<ProjectPolygon>> getProjectPolygons(String projectId) async {
    var keys = await _polygonBox?.getAllKeys();
    List<ProjectPolygon> mList = [];
    if (keys != null) {
      for (var key in keys) {
        if (key.contains(projectId)) {
          var polygon = await _polygonBox?.get(key);
          mList.add(polygon!);

        }
      }
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

    var keys = await _userBox?.getAllKeys();
    var mList = <User>[];
    if (keys != null) {
      for (var key in keys) {
        if (key.contains(organizationId)) {
          var u = await _userBox?.get(key);
          mList.add(u!);
        }
      }
    }
    List<User> users = [];

    return users;
  }

  Future<List<Video>> getVideos() async {

    List<Video> videos = [];

    return videos;
  }

  Future addFieldMonitorSchedule(
      {required FieldMonitorSchedule schedule}) async {
    pp('$mm .... addFieldMonitorSchedule .....');
    var key = '${schedule.projectId}_${schedule.fieldMonitorScheduleId}';
    await _scheduleBox?.put(key, schedule);
    pp('$mm FieldMonitorSchedule added to local cache:  🔵 🔵 ${schedule.projectName}');
  }

  Future addPhoto({required Photo photo}) async {
    var key = '${photo.projectId}_${photo.organizationId}_${photo.userId}';
    await _photoBox?.put(key, photo);
    // pp('$mm Photo added to local cache:  🔵 🔵 ${photo.projectName}');
  }

  Future addProject({required Project project}) async {
    var key = '${project.projectId}_${project.organizationId}';
    await _projectBox?.put(key, project);
    pp('$mm Project added to local cache:  🔵 🔵 ${project.name} ');
  }

  Future addProjectPosition({required ProjectPosition projectPosition}) async {
    var key = '${projectPosition.organizationId}_${projectPosition.projectId}_${projectPosition.projectPositionId}';
    await _positionBox?.put(key, projectPosition);
    pp('$mm ProjectPosition added to local cache:  🔵 🔵 ${projectPosition.projectName} organizationId: ${projectPosition.organizationId} ');
  }

  Future addProjectPolygon({required ProjectPolygon projectPolygon}) async {
    var key = '${projectPolygon.organizationId}_${projectPolygon.projectId}_${projectPolygon.projectPolygonId}';
    await _polygonBox?.put(key, projectPolygon);
    pp('$mm ProjectPolygon added to local cache:  🔵 🔵 ${projectPolygon.projectName} organizationId: ${projectPolygon.organizationId} ');
  }


  Future addUser({required User user}) async {
    var key = '${user.organizationId}_${user.userId}';
    await _userBox?.put(key, user);
    pp('$mm User added to local cache: 🔵 🔵  ${user.name} ');
  }

  Future addVideo({required Video video}) async {
    var key = '${video.projectId}_${video.videoId}';
    await _videoBox?.put(key, video);
    pp('$mm Video added to local cache:  🔵 🔵 ${video.projectName}');
  }

  Future<List<Project>> getProjects(String organizationId) async {
    pp('$mm .... getProjects ..... organizationId: $organizationId');
    var keys = await _projectBox?.getAllKeys();
    var mList = <Project>[];
    if (keys != null) {
      for (var key in keys) {
        if (key.contains(organizationId)) {
          var p = await _projectBox?.get(key);
          mList.add(p!);
        }
      }
    }
    pp('$mm .... getProjects ..... found:  🌼 ${mList.length}  🌼');
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

  Future addMonitorReport({required MonitorReport monitorReport}) async {
    var key = '${monitorReport.projectId}_${monitorReport.monitorReportId}';
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

  Future<Organization?> getOrganizationById({required String organizationId}) async {
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

  Future<List<ProjectPosition>> getOrganizationProjectPositions({required String organizationId}) async {
    pp('$mm .... getOrganizationProjectPositions ..... ');
    var keys = await _positionBox?.getAllKeys();
    var mList = <ProjectPosition>[];
    if (keys != null) {
      for (var key in keys) {
        if (key.contains(organizationId)) {
          var pos = await _positionBox?.get(key);
          mList.add(pos!);
        }
      }
    }

    pp('$mm .... getOrganizationProjectPositions ..... 🌺 found:  🌼 ${mList.length}  🌼');
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
    pp('$mm .... getProjectPositions ..... 🌺 found:  🌼 ${mList.length}  🌼');
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
