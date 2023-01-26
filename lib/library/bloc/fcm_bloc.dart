import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_messaging/firebase_messaging.dart' as fb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:universal_platform/universal_platform.dart';

import '../api/data_api.dart';
import '../api/sharedprefs.dart';
import '../data/audio.dart';
import '../data/condition.dart';
import '../data/org_message.dart';
import '../data/video.dart';
import '../functions.dart';
import '../generic_functions.dart';
import '../hive_util.dart';
import '../data/photo.dart';
import '../data/project.dart';
import '../data/user.dart';
import 'organization_bloc.dart';

FCMBloc fcmBloc = FCMBloc();
const mm = '🔵 🔵 🔵 🔵 🔵 🔵 FCMBloc: ';

Future<void> firebaseMessagingBackgroundHandler(
    fb.RemoteMessage message) async {
  p("Handling a background message: ${message.messageId}");
}

class FCMBloc {
  fb.FirebaseMessaging messaging = fb.FirebaseMessaging.instance;

  final StreamController<User> _userController = StreamController.broadcast();
  final StreamController<Project> _projectController =
      StreamController.broadcast();
  final StreamController<Photo> _photoController = StreamController.broadcast();
  final StreamController<Video> _videoController = StreamController.broadcast();
  final StreamController<Audio> _audioController = StreamController.broadcast();

  final StreamController<Condition> _conditionController =
      StreamController.broadcast();
  final StreamController<OrgMessage> _messageController =
      StreamController.broadcast();
  final StreamController<String> _killController =
  StreamController.broadcast();

  Stream<User> get userStream => _userController.stream;
  Stream<Project> get projectStream => _projectController.stream;
  Stream<Photo> get photoStream => _photoController.stream;
  Stream<Video> get videoStream => _videoController.stream;
  Stream<Audio> get audioStream => _audioController.stream;
  Stream<Condition> get conditionStream => _conditionController.stream;
  Stream<OrgMessage> get messageStream => _messageController.stream;
  Stream<String> get killStream => _killController.stream;

  User? user;
  void closeStreams() {
    _userController.close();
    _projectController.close();
    _photoController.close();
    _videoController.close();
    _conditionController.close();
    _messageController.close();
  }

  FCMBloc() {
    initialize();
  }

  void initialize() async {
    pp("\n$mm initialize FIREBASE MESSAGING ...........................");
    user = await Prefs.getUser();
    var android = UniversalPlatform.isAndroid;
    var ios = UniversalPlatform.isIOS;

    if (android || ios) {
      messaging.setAutoInitEnabled(true);
      messaging.onTokenRefresh.listen((newToken) {
        pp("$mm onTokenRefresh: 🍎 🍎 🍎 update user: token: $newToken ... 🍎 🍎 ");
        // _updateUser(newToken);
      });

      // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');

      final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
          onDidReceiveLocalNotification: onDidReceiveLocalNotification);

      const LinuxInitializationSettings initializationSettingsLinux =
      LinuxInitializationSettings(defaultActionName: 'Open notification');

      final InitializationSettings initializationSettings =
      InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
          linux: initializationSettingsLinux);

      FlutterLocalNotificationsPlugin().initialize(initializationSettings,
          onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // RemoteNotification? notification = message.notification;
        // AndroidNotification? android = message.notification?.android;
        pp("\n\n$mm onMessage: 🍎 🍎 data: ${message.data} ... 🍎 🍎 ");
        //todo - save photo or video in cache if not yours ...
        processFCMMessage(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        pp(
            '$mm onMessageOpenedApp:  🍎 🍎 A new onMessageOpenedApp event was published! ${message
                .data}');
      });

      await subscribeToTopics();
    }
  }

  Future requestPermissions() async {
    fb.NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    p('User granted permission: ${settings.authorizationStatus}');
  }

  Future subscribeToTopics() async {
    var user = await Prefs.getUser();
    if (user != null) {
      pp("$mm subscribeToTopics ...........................");
      await messaging.subscribeToTopic('projects_${user.organizationId}');
      await messaging.subscribeToTopic('photos_${user.organizationId}');
      await messaging.subscribeToTopic('videos_${user.organizationId}');
      await messaging.subscribeToTopic('conditions_${user.organizationId}');
      await messaging.subscribeToTopic('messages_${user.organizationId}');
      await messaging.subscribeToTopic('users_${user.organizationId}');
      await messaging.subscribeToTopic('audios_${user.organizationId}');
      await messaging.subscribeToTopic('kill_${user.organizationId}');
      pp("$mm subscribeToTopics: 🍎 subscribed to all 8 organization topics 🍎");
    } else {
      pp("$mm subscribeToTopics:  👿 👿 👿 user not cached on device yet  👿 👿 👿");
    }
    return null;
  }

  final blue = '🔵 🔵 🔵';
  Future processFCMMessage(fb.RemoteMessage message) async {
    pp('\n\n$mm processFCMMessage: $blue processing newly arrived FCM message; messageId:: ${message.messageId}');
    Map data = message.data;
    User? user = await Prefs.getUser();

    if (data['kill'] != null) {
      pp("$mm processFCMMessage:  $blue ........................... 🍎🍎🍎🍎🍎🍎kill USER!!  🍎  🍎 ");
      var m = jsonDecode(data['kill']);
      var receivedUser = User.fromJson(m);
      if (receivedUser.userId! == user!.userId!) {
        pp("$mm processFCMMessage  $blue This user is about to be killed: ${receivedUser.name!} ......");
        Prefs.deleteUser();
        auth.FirebaseAuth.instance.signOut();
        pp('$mm 🌀🌀🌀🌀  🍎 Signed out of Firebase!!! 🍎 ');

        await _handleCache(receivedUser);
        _killController.sink.add("Your app has been disabled. If you need to, please talk to your supervisor or administrator");

      } else {
        await _handleCache(receivedUser);
        pp('🌀🌀🌀🌀🍎 User should be deleted from Hive cache by now! 🍎 ');
      }
    }
    if (data['user'] != null) {
      pp("$mm processFCMMessage  🔵 🔵 🔵 ........................... cache USER  🍎  🍎 ");
      var m = jsonDecode(data['receivedUser']);
      var user = User.fromJson(m);
      await cacheManager.addUser(user: user);
      _userController.sink.add(user);
    }
    if (data['project'] != null) {
      pp("$mm processFCMMessage  🔵 🔵 🔵 ........................... cache PROJECT  🍎  🍎");
      var m = jsonDecode(data['project']);
      var project = Project.fromJson(m);
      await cacheManager.addProject(project: project);
      _projectController.sink.add(project);
    }
    if (data['photo'] != null) {
      pp("$mm processFCMMessage  🔵 🔵 🔵 ........................... cache PHOTO  🍎  🍎");
      var m = jsonDecode(data['photo']);
      var photo = Photo.fromJson(m);
      if (photo.userId == user!.userId) {
        pp('$mm This message is about my own photo - not caching');
      } else {
        var res = await cacheManager.addPhoto(photo: photo);
        pp('$mm Photo received added to local cache:  🔵 🔵 ${photo.projectName} result: $res, sending to photo stream');
        _photoController.sink.add(photo);
      }
    }
    if (data['video'] != null) {
      pp("$mm processFCMMessage  🔵 🔵 🔵 ........................... cache VIDEO  🍎  🍎");
      var m = jsonDecode(data['video']);
      var video = Video.fromJson(m);
      if (video.userId == user!.userId) {
        pp('$mm This message is about my own audio - not caching');
      } else {
        await cacheManager.addVideo(video: video);
        pp('$mm Video received added to local cache:  🔵 🔵 ${video.projectName}, sending to video stream');
        _videoController.sink.add(video);
      }
    }
    if (data['audio'] != null) {
      pp("$mm processFCMMessage  🔵 🔵 🔵 ........................... cache AUDIO  🍎  🍎");
      var m = jsonDecode(data['audio']);
      var audio = Audio.fromJson(m);
      if (audio.userId == user!.userId) {
        pp('$mm This message is about my own audio - not caching');
      } else {
        await cacheManager.addAudio(audio: audio);
        pp('$mm Audio received added to local cache:  🔵 🔵 ${audio.projectName}, sending to audio stream');
        _audioController.sink.add(audio);
      }
    }
    if (data['condition'] != null) {
      pp("$mm processFCMMessage  🔵 🔵 🔵 ........................... cache CONDITION  🍎  🍎");
      var m = jsonDecode(data['condition']);
      var condition = Condition.fromJson(m);
      await cacheManager.addCondition(condition: condition);
      pp('$mm condition received added to local cache:  🔵 🔵 ${condition.projectName}, sending to condition stream');
      _conditionController.sink.add(condition);
    }
    if (data['message'] != null) {
      pp("$mm processFCMMessage  🔵 🔵 🔵 ........................... cache ORG MESSAGE  🍎  🍎");
      var m = jsonDecode(data['message']);
      var msg = OrgMessage.fromJson(m);
      await cacheManager.addOrgMessage(message: msg);
      if (user!.userId != msg.adminId) {
        _messageController.sink.add(msg);
      }
    }

    return null;
  }

  Future<void> _handleCache(User receivedUser) async {
    pp('$mm handling cache and removing user from cache');
    await cacheManager.deleteUser(user: receivedUser);
    var list = await cacheManager.getUsers();
    organizationBloc.userController.sink.add(list);
  }

  // Future _updateUser(String newToken) async {
  //   if (user != null) {
  //     pp("$mm updateUser: 🍎🍎🍎🍎🍎🍎🍎🍎 USER: 🍎 ${user!.toJson()} ... 🍎🍎 ");
  //     user!.fcmRegistration = newToken;
  //     await DataAPI.updateUser(user!);
  //     await Prefs.saveUser(user!);
  //   }
  // }

  void onDidReceiveNotificationResponse(NotificationResponse details) {
  pp('$mm onDidReceiveNotificationResponse ... details: ${details.payload}');
}

  void onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) {
    pp(
        '$mm onDidReceiveLocalNotification:  🍎 maybe display a dialog with the notification details - maybe put this on a stream ...');
    pp('$mm title: $title  🍎 body: $body with some payload ...');
    pp('$mm payload: $payload  🍎');
  }
}



Future<dynamic> myBackgroundMessageHandler(Map<String, dynamic> message) async {
  pp("$mm  🦠 🦠 🦠 🦠 🦠 myBackgroundMessageHandler   🦠 🦠 🦠 🦠 🦠 ........................... $message");
  Map data = message['data'];

  pp("$mm myBackgroundMessageHandler   🦠 🦠 🦠........................... cache USER  🍎  🍎 string data: $data");
  if (data['user'] != null) {
    var m = jsonDecode(data['user']);
    var user = User.fromJson(m);
    cacheManager.addUser(user: user);
  }
  if (data['project'] != null) {
    pp("$mm myBackgroundMessageHandler   🦠 🦠 🦠 ........................... cache PROJECT  🍎  🍎");
    var m = jsonDecode(data['project']);
    var project = Project.fromJson(m);
    cacheManager.addProject(project: project);
  }
  if (data['photo'] != null) {
    pp("$mm myBackgroundMessageHandler   🦠 🦠 🦠 ........................... cache PHOTO  🍎  🍎");
    var m = jsonDecode(data['photo']);
    var photo = Photo.fromJson(m);
    cacheManager.addPhoto(photo: photo);
  }
  if (data['video'] != null) {
    pp("$mm myBackgroundMessageHandler   🦠 🦠 🦠 ........................... cache VIDEO  🍎  🍎");
    var m = jsonDecode(data['video']);
    var video = Video.fromJson(m);
    cacheManager.addVideo(video: video);
  }
  if (data['condition'] != null) {
    pp("$mm myBackgroundMessageHandler   🦠 🦠 🦠 ........................... cache CONDITION  🍎  🍎");
    var m = jsonDecode(data['condition']);
    var condition = Condition.fromJson(m);
    cacheManager.addCondition(condition: condition);
  }
  if (data['message'] != null) {
    pp("$mm myBackgroundMessageHandler  🦠 🦠 🦠 ........................... cache ORG MESSAGE  🍎  🍎");
    var m = jsonDecode(data['message']);
    var msg = OrgMessage.fromJson(m);
    cacheManager.addOrgMessage(message: msg);
  }
}
