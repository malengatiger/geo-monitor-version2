import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/bloc/organization_bloc.dart';
import 'package:geo_monitor/library/data/photo.dart';
import 'package:geo_monitor/library/data/video.dart';
import 'package:geo_monitor/library/users/edit/user_edit_tablet.dart';
import 'package:geo_monitor/library/users/list/user_list_card.dart';
import 'package:geo_monitor/ui/activity/geo_activity.dart';
import 'package:geo_monitor/ui/dashboard/user_dashboard.dart';
import 'package:page_transition/page_transition.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/translation_handler.dart';
import '../../bloc/fcm_bloc.dart';
import '../../bloc/location_request_handler.dart';
import '../../data/audio.dart';
import '../../data/location_response.dart';
import '../../data/settings_model.dart';
import '../../data/user.dart';
import '../../functions.dart';
import '../../generic_functions.dart';
import '../../ui/maps/location_response_map.dart';
import '../../ui/maps_field_monitor/field_monitor_map_mobile.dart';
import '../../ui/message/message_mobile.dart';
import '../../ui/schedule/scheduler_mobile.dart';
import '../kill_user_page.dart';

class UserListTablet extends StatefulWidget {
  const UserListTablet({
    Key? key,
  }) : super(key: key);

  @override
  State<UserListTablet> createState() => _UserListTabletState();
}

class _UserListTabletState extends State<UserListTablet> {
  var users = <User>[];
  User? user;

  @override
  void initState() {
    super.initState();
    _setTexts();
    _getData(false);
    _listen();
  }

  late StreamSubscription<User> _streamSubscription;
  late StreamSubscription<LocationResponse> _locationResponseSubscription;
  late StreamSubscription<SettingsModel> settingsSubscriptionFCM;

  LocationResponse? locationResponse;

  String? title;

  void _listen() {
    settingsSubscriptionFCM = fcmBloc.settingsStream.listen((event) async {
      if (mounted) {
        await _setTexts();
        _getData(false);
      }
    });
    _streamSubscription = fcmBloc.userStream.listen((User user) {
      pp('$mm new user just arrived: ${user.toJson()}');
      if (mounted) {
        _getData(false);
      }
    });
    _locationResponseSubscription =
        fcmBloc.locationResponseStream.listen((LocationResponse event) {
      pp('$mm locationResponseStream delivered ... response: ${event.toJson()}');
      locationResponse = event;
      if (mounted) {
        setState(() {});
        _showLocationResponseDialog();
      }
    });
  }

  void _showLocationResponseDialog() async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
              shape: getRoundedBorder(radius: 16),
              title: Text(
                "Location Response",
                style: myTextStyleMediumBold(context),
              ),
              content: SizedBox(
                height: 260.0,
                width: 440.0,
                child: Card(
                  shape: getRoundedBorder(radius: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: <Widget>[
                        Text(
                          locationResponse == null
                              ? ''
                              : locationResponse!.userName!,
                          style: myTextStyleLargePrimaryColor(context),
                        ),
                        const SizedBox(
                          height: 48,
                        ),
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                              'Your location request has received a response. Do you want to see the response on a map?'),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text(
                    'NO',
                    style: TextStyle(color: Colors.grey),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  child: const Text(
                    'YES',
                    style: TextStyle(color: Colors.grey),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _navigateToLocationResponseMap();
                  },
                ),
              ],
            ));
  }

  void _navigateToLocationResponseMap() async {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: LocationResponseMap(
              locationResponse: locationResponse!,
            )));
  }

  final mm = '🔵🔵🔵🔵🔵🔵 UserListTabletLandscape: ';
  String? subTitle;
  Future _setTexts() async {
    var sett = await prefsOGx.getSettings();
    if (sett != null) {
      title = await mTx.translate('organizationMembers', sett!.locale!);
      subTitle = await mTx.translate('administratorsMembers', sett!.locale!);
      setState(() {

      });
    }
  }
  void _getData(bool forceRefresh) async {
    setState(() {
      busy = true;
    });
    try {
      user = await prefsOGx.getUser();

      users = await organizationBloc.getUsers(
          organizationId: user!.organizationId!, forceRefresh: forceRefresh);
      p('$mm data refreshed, users: ${users.length}');
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

  void navigateToUserReport(User user) {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: UserDashboard(user: user)));
  }

  void navigateToMessaging(User user) {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.bottomLeft,
            duration: const Duration(seconds: 1),
            child: MessageMobile(
              user: user,
            )));
  }

  Future<void> navigateToPhone(User user) async {
    pp('💛️💛️💛 ... starting phone call ....');
    final Uri phoneUri = Uri(scheme: "tel", path: user.cellphone!);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    } catch (error) {
      throw ("Cannot dial");
    }
  }

  void navigateToMap(User user) {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.bottomLeft,
            duration: const Duration(seconds: 1),
            child: FieldMonitorMapMobile(user)));
  }

  void navigateToScheduler(User user) {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.bottomLeft,
            duration: const Duration(seconds: 1),
            child: SchedulerMobile(user)));
  }

  bool sortedByName = false;

  void navigateToUserEdit(User? user) async {
    if (user != null) {
      if (user!.userType == UserType.fieldMonitor) {
        if (user.userId != user.userId!) {
          return;
        }
      }
    }
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: UserEditTablet(user: user)));
  }

  Future<void> navigateToKillPage(User user) async {
    await Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.bottomLeft,
            duration: const Duration(seconds: 1),
            child: KillUserPage(
              user: user,
            )));
    pp('💛️💛️💛 ... back from KillPage; will refresh user list ....');
  }

  void _sendLocationRequest(User otherUser) async {
    setState(() {
      busy = true;
    });
    try {
      var user = await prefsOGx.getUser();
      await locationRequestHandler.sendLocationRequest(
          requesterId: user!.userId!,
          requesterName: user.name!,
          userId: otherUser.userId!,
          userName: otherUser.name!);
      if (mounted) {
        showToast(message: 'Location request sent', context: context);
      }
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

  void _sort() {
    if (sortedByName) {
      _sortByNameDesc();
    } else {
      _sortByName();
    }
  }

  void _sortByName() {
    users.sort((a, b) => a.name!.compareTo(b.name!));
    sortedByName = true;
    setState(() {});
  }

  void _sortByNameDesc() {
    users.sort((a, b) => b.name!.compareTo(a.name!));
    sortedByName = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var mWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(title == null?
          'Organization Members': title!,
          style: myTextStyleLarge(context),
        ),
        actions: [
          IconButton(
              onPressed: () {
                navigateToUserEdit(null);
              },
              icon: Icon(
                Icons.add,
                color: Theme.of(context).primaryColor,
              )),
          IconButton(
              onPressed: () {
                _getData(true);
              },
              icon: Icon(
                Icons.refresh,
                color: Theme.of(context).primaryColor,
              ))
        ],
      ),
      body: OrientationLayoutBuilder(landscape: (ctx) {
        return Padding(
          padding: const EdgeInsets.only(
              left: 48.0, right: 24.0, top: 24.0, bottom: 24),
          child: Row(
            children: [
              user == null
                  ? const SizedBox()
                  : SizedBox(
                      width: (mWidth / 2) - 80,
                      child: UserListCard(
                        subTitle: subTitle == null?'Admins & Monitors': subTitle!,
                        amInLandscape: true,
                        avatarRadius: 20,
                        users: users,
                        deviceUser: user!,
                        navigateToLocationRequest: (mUser) {
                          _sendLocationRequest(mUser);
                        },
                        navigateToPhone: (mUser) {
                          navigateToPhone(mUser);
                        },
                        navigateToMessaging: (user) {
                          navigateToMessaging(user);
                        },
                        navigateToUserDashboard: (user) {
                          navigateToUserReport(user);
                        },
                        navigateToUserEdit: (user) {
                          navigateToUserEdit(user);
                        },
                        navigateToScheduler: (user) {
                          navigateToScheduler(user);
                        },
                        navigateToKillPage: (user) {
                          navigateToKillPage(user);
                        },
                        badgeTapped: () {
                          _sort();
                        },
                      )),
              GeoActivity(
                  width: mWidth / 2,
                  thinMode: false,
                  showPhoto: showPhoto,
                  showVideo: showVideo,
                  showAudio: showAudio,
                  showUser: (user) {},
                  showLocationRequest: (req) {},
                  showLocationResponse: (resp) {
                    locationResponse = resp;
                    _navigateToLocationResponseMap();
                  },
                  showGeofenceEvent: (event) {},
                  showProjectPolygon: (polygon) {},
                  showProjectPosition: (position) {},
                  showOrgMessage: (message) {},
                  forceRefresh: false),
            ],
          ),
        );
      }, portrait: (ctx) {
        return Padding(
          padding:
              const EdgeInsets.only(left: 16, right: 16.0, top: 48, bottom: 48),
          child: Row(
            children: [
              user == null
                  ? const SizedBox()
                  : SizedBox(
                      width: mWidth / 2,
                      child: UserListCard(
                        subTitle: subTitle == null?'Admins & Monitors': subTitle!,
                        amInLandscape: true,
                        avatarRadius: 20,
                        users: users,
                        deviceUser: user!,
                        navigateToLocationRequest: (mUser) {
                          _sendLocationRequest(mUser);
                        },
                        navigateToPhone: (mUser) {
                          navigateToPhone(mUser);
                        },
                        navigateToMessaging: (user) {
                          navigateToMessaging(user);
                        },
                        navigateToUserDashboard: (user) {
                          navigateToUserReport(user);
                        },
                        navigateToUserEdit: (user) {
                          navigateToUserEdit(user);
                        },
                        navigateToScheduler: (user) {
                          navigateToScheduler(user);
                        },
                        navigateToKillPage: (user) {
                          navigateToKillPage(user);
                        },
                        badgeTapped: () {
                          _sort();
                        },
                      )),
              const SizedBox(
                width: 32,
              ),
              GeoActivity(
                  width: (mWidth / 2) - 80,
                  thinMode: false,
                  showPhoto: showPhoto,
                  showVideo: showVideo,
                  showAudio: showAudio,
                  showUser: (user) {},
                  showLocationRequest: (req) {},
                  showLocationResponse: (resp) {
                    locationResponse = resp;
                    _navigateToLocationResponseMap();
                  },
                  showGeofenceEvent: (event) {},
                  showProjectPolygon: (polygon) {},
                  showProjectPosition: (position) {},
                  showOrgMessage: (message) {},
                  forceRefresh: false),
            ],
          ),
        );
      }),
    );
  }

  showPhoto(Photo p1) {}

  showVideo(Video p1) {}
  showAudio(Audio p1) {}
}
