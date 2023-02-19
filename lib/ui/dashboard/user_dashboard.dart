import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geo_monitor/library/bloc/downloader.dart';
import 'package:geo_monitor/library/bloc/user_bloc.dart';
import 'package:geo_monitor/library/ui/camera/video_player_tablet.dart';
import 'package:geo_monitor/library/users/full_user_photo.dart';
import 'package:geo_monitor/ui/activity/geo_activity_tablet.dart';
import 'package:geo_monitor/ui/audio/audio_player_page.dart';
import 'package:page_transition/page_transition.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../../library/api/prefs_og.dart';
import '../../library/bloc/connection_check.dart';
import '../../library/data/audio.dart';
import '../../library/data/data_bag.dart';
import '../../library/data/geofence_event.dart';
import '../../library/data/photo.dart';
import '../../library/data/user.dart';
import '../../library/data/video.dart';
import '../../library/functions.dart';
import '../../library/generic_functions.dart';
import '../../library/geofence/geofencer_two.dart';
import '../../library/ui/project_list/project_list_mobile.dart';
import '../intro/intro_page_viewer_portrait.dart';
import 'user_dashboard_grid.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({
    Key? key,
    required this.user,
  }) : super(key: key);
  final User user;

  @override
  UserDashboardState createState() => UserDashboardState();
}

class UserDashboardState extends State<UserDashboard>
    with TickerProviderStateMixin {
  late AnimationController _gridViewAnimationController;

  var busy = false;
  User? user;

  static const mm = '🎽🎽🎽🎽🎽🎽 UserDashboard: 🎽';
  bool networkAvailable = false;
  final dur = 3000;
  DataBag? dataBag;

  @override
  void initState() {
    _gridViewAnimationController = AnimationController(
        duration: Duration(milliseconds: dur),
        reverseDuration: Duration(milliseconds: dur),
        vsync: this);
    super.initState();
    _setItems();
    _getAuthenticationStatus();
    _subscribeToConnectivity();
    _subscribeToGeofenceStream();
    _startTimer();
    _getData(false);
  }

  void _getData(bool forceRefresh) async {
    setState(() {
      busy = true;
    });
    try {
      user = await prefsOGx.getUser();
      dataBag = await userBloc.getUserData(
          userId: widget.user.userId!, forceRefresh: forceRefresh);
    } catch (e) {
      pp(e);
      if (mounted) {
        showToast(message: '$e', context: context);
      }
    }

    setState(() {
      busy = false;
    });
  }

  final fb.FirebaseAuth firebaseAuth = fb.FirebaseAuth.instance;
  bool authed = false;

  void _getAuthenticationStatus() async {
    var cUser = firebaseAuth.currentUser;
    if (cUser == null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _navigateToIntro();
      });
      //
    }
  }

  late StreamSubscription<bool> connectionSubscription;
  Future<void> _subscribeToConnectivity() async {
    connectionSubscription =
        connectionCheck.connectivityStream.listen((bool connected) {
      if (connected) {
        pp('$mm We have a connection! - $connected');
      } else {
        pp('$mm We DO NOT have a connection! - show snackbar ...  🍎 mounted? $mounted');
        if (mounted) {
          //showConnectionProblemSnackBar(context: context);
        }
      }
    });
    var isConnected = await connectionCheck.internetAvailable();
    pp('$mm Are we connected? answer: $isConnected');
  }

  late StreamSubscription<GeofenceEvent> geofenceSubscription;

  void _subscribeToGeofenceStream() async {
    geofenceSubscription =
        theGreatGeofencer.geofenceEventStream.listen((event) {
      pp('\n$mm geofenceEvent delivered by geofenceStream: ${event.projectName} ...');
    });
  }

  void _startTimer() async {
    Future.delayed(const Duration(seconds: 5), () {
      Timer.periodic(const Duration(minutes: 30), (timer) async {
        pp('$mm ........ set state timer tick: ${timer.tick}');
        try {
          //_refreshData(false);
        } catch (e) {
          //ignore
        }
      });
    });
  }

  bool _showPhoto = false;
  bool _showVideo = false;
  bool _showAudio = false;

  void _displayPhoto(Photo photo) async {
    pp('$mm _displayPhoto ...');
    this.photo = photo;
    setState(() {
      _showPhoto = true;
      _showVideo = false;
      _showAudio = false;
    });
  }

  void _displayVideo(Video video) async {
    pp('$mm _displayVideo ...');
    this.video = video;
    setState(() {
      _showPhoto = false;
      _showVideo = true;
      _showAudio = false;
    });
  }

  void _displayAudio(Audio audio) async {
    pp('$mm _displayAudio ...');
    this.audio = audio;
    setState(() {
      _showPhoto = false;
      _showVideo = false;
      _showAudio = true;
    });
  }

  Photo? photo;
  Video? video;
  Audio? audio;

  @override
  void dispose() {
    _gridViewAnimationController.dispose();
    connectionSubscription.cancel();
    geofenceSubscription.cancel();
    super.dispose();
  }

  var items = <BottomNavigationBarItem>[];

  void _setItems() {
    items.add(const BottomNavigationBarItem(
        icon: Icon(
          Icons.person,
          color: Colors.pink,
        ),
        label: 'My Work'));

    items.add(const BottomNavigationBarItem(
        icon: Icon(
          Icons.send,
          color: Colors.blue,
        ),
        label: 'Send Message'));

    items.add(const BottomNavigationBarItem(
        icon: Icon(
          Icons.radar,
          color: Colors.teal,
        ),
        label: 'Weather'));
  }

  String type = 'Unknown Rider';

  final _key = GlobalKey<ScaffoldState>();

  int instruction = stayOnList;

  void _navigateToMessageSender() {
    // Navigator.push(
    //     context,
    //     PageTransition(
    //         type: PageTransitionType.scale,
    //         alignment: Alignment.topLeft,
    //         duration: const Duration(seconds: 1),
    //         child: const ChatPage()));
    showToast(
        textStyle: myTextStyleMediumBold(context),
        toastGravity: ToastGravity.TOP,
        message: 'Messaging under construction, see you later!',
        context: context);
  }

  void _navigateToIntro() {
    pp('$mm .................. _navigateToIntro to Intro ....');
    if (mounted) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(seconds: 1),
              child: const IntroPageViewerPortrait()));
    }
  }

  void _showUserPhotos() {}
  void _showUserVideos() {}
  void _showUserAudios() {}

  Future<void> _navigateToFullUserPhoto() async {
    pp('$mm .................. _navigateToFullUserPhoto  ....');
    user = await prefsOGx.getUser();
    if (user != null) {
      if (mounted) {
        Navigator.push(
            context,
            PageTransition(
                type: PageTransitionType.scale,
                alignment: Alignment.topLeft,
                duration: const Duration(seconds: 1),
                child: FullUserPhoto(user: user!)));
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final ori = MediaQuery.of(context).orientation.name;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Member Dashboard'),
        actions: [
          IconButton(
              icon: Icon(
                Icons.info_outline,
                size: 28,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: _navigateToIntro),
          IconButton(
            icon: Icon(
              Icons.refresh,
              size: 28,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              _getData(true);
            },
          )
        ],
      ),
      body: busy
          ? Center(
              child: Card(
                elevation: 16,
                shape: getRoundedBorder(radius: 12),
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 6,
                      backgroundColor: Colors.pink,
                    ),
                  ),
                ),
              ),
            )
          : Stack(
              children: [
                dataBag == null
                    ? const SizedBox()
                    : Row(
                        children: [
                          SizedBox(
                            width: (width / 2) + 100,
                            child: UserDashboardGrid(
                                user: widget.user,
                                topPadding: 40,
                                onTypeTapped: (type) {
                                  switch (type) {
                                    case typePhotos:
                                      _showUserPhotos();
                                      break;
                                    case typeVideos:
                                      _showUserVideos();
                                      break;
                                    case typeAudios:
                                      _showUserAudios();
                                      break;
                                  }
                                }),
                          ),
                          ScreenTypeLayout(
                            mobile: const SizedBox(),
                            tablet: GeoActivityTablet(
                              width: ori == 'portrait' ? 280 : 360,
                              forceRefresh: true,
                              user: widget.user,
                              thinMode: ori == 'portrait' ? true : false,
                              showPhoto: (photo) {
                                _displayPhoto(photo);
                              },
                              showVideo: (video) {
                                _displayVideo(video);
                              },
                              showAudio: (audio) {
                                _displayAudio(audio);
                              },
                            ),
                          ),
                        ],
                      ),
                _showPhoto
                    ? Positioned(
                        left: 100,
                        right: 100,
                        top: 12,
                        child: SizedBox(
                          width: 600,
                          height: 800,
                          // color: Theme.of(context).primaryColor,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showPhoto = false;
                                });
                              },
                              child: Card(
                                shape: getRoundedBorder(radius: 16),
                                elevation: 8,
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      const SizedBox(
                                        height: 12,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 48.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${photo!.projectName}',
                                              style:
                                                  myTextStyleLargePrimaryColor(
                                                      context),
                                            ),
                                            // IconButton(
                                            //     onPressed: () {
                                            //       pp('$mm .... put photo on a map!');
                                            //       _navigateToPhotoMap();
                                            //     },
                                            //     icon: Icon(
                                            //       Icons.location_on,
                                            //       color: Theme.of(context)
                                            //           .primaryColor,
                                            //       size: 24,
                                            //     )),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 12,
                                      ),
                                      Text(
                                        '${photo!.userName}',
                                        style: myTextStyleSmallBold(context),
                                      ),
                                      const SizedBox(
                                        height: 4,
                                      ),
                                      Text(
                                        getFormattedDateShortWithTime(
                                            photo!.created!, context),
                                        style: myTextStyleTiny(context),
                                      ),
                                      const SizedBox(
                                        height: 12,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 2.0, vertical: 2.0),
                                        child: InteractiveViewer(
                                            child: CachedNetworkImage(
                                                fit: BoxFit.fill,
                                                progressIndicatorBuilder: (context,
                                                        url,
                                                        downloadProgress) =>
                                                    Center(
                                                        child: SizedBox(
                                                            width: 20,
                                                            height: 20,
                                                            child: CircularProgressIndicator(
                                                                backgroundColor:
                                                                    Colors.pink,
                                                                value: downloadProgress
                                                                    .progress))),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        const Icon(Icons.error),
                                                fadeInDuration: const Duration(
                                                    milliseconds: 1500),
                                                fadeInCurve:
                                                    Curves.easeInOutCirc,
                                                placeholderFadeInDuration:
                                                    const Duration(milliseconds: 1500),
                                                imageUrl: photo!.url!)),
                                      ),
                                      const SizedBox(
                                        height: 24,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ))
                    : const SizedBox(),
                _showVideo
                    ? Positioned(
                        left: 100,
                        right: 100,
                        top: 12,
                        child: VideoPlayerTabletPage(
                          video: video!,
                          onCloseRequested: () {
                            if (mounted) {
                              setState(() {
                                _showVideo = false;
                              });
                            }
                          },
                        ),
                      )
                    : const SizedBox(),
                _showAudio
                    ? Positioned(
                        left: 100,
                        right: 100,
                        top: 160,
                        child: AudioPlayerCard(
                          audio: audio!,
                          onCloseRequested: () {
                            if (mounted) {
                              setState(() {
                                _showAudio = false;
                              });
                            }
                          },
                        ))
                    : const SizedBox(),
              ],
            ),
    );
  }
}
