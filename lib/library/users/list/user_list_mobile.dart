import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geo_monitor/library/data/location_response.dart';
import 'package:geo_monitor/library/ui/maps/location_response_map.dart';
import 'package:geo_monitor/library/ui/schedule/scheduler_mobile.dart';
import 'package:geo_monitor/library/users/kill_user_page.dart';
import 'package:geo_monitor/library/users/list/user_list_card.dart';
import 'package:geo_monitor/ui/dashboard/user_dashboard.dart';
import 'package:page_transition/page_transition.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/translation_handler.dart';
import '../../api/prefs_og.dart';
import '../../bloc/fcm_bloc.dart';
import '../../bloc/location_request_handler.dart';
import '../../bloc/organization_bloc.dart';
import '../../data/user.dart';
import '../../emojis.dart';
import '../../functions.dart';
import '../../generic_functions.dart';
import '../../ui/message/message_mobile.dart';
import '../edit/user_edit_main.dart';

class UserListMobile extends StatefulWidget {
  // final User user;
  const UserListMobile({super.key});

  @override
  UserListMobileState createState() => UserListMobileState();
}

class UserListMobileState extends State<UserListMobile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool busy = false;
  var users = <User>[];
  final _key = GlobalKey<ScaffoldState>();
  bool sortedByName = false;
  bool _showPlusIcon = false;
  bool _showEditorIcon = false;

  User? user;
  final mm =
      '${E.diamond}${E.diamond}${E.diamond}${E.diamond} UserListMobile: ';

  @override
  void initState() {
    _animationController = AnimationController(
        value: 0.0,
        duration: const Duration(milliseconds: 3000),
        reverseDuration: const Duration(milliseconds: 2000),
        vsync: this);
    super.initState();
    _getData(false);
    _listen();
  }

  late StreamSubscription<User> _streamSubscription;
  late StreamSubscription<LocationResponse> _locationResponseSubscription;

  void _listen() {
    _streamSubscription = fcmBloc.userStream.listen((User user) {
      pp('$mm new user just arrived: ${user.toJson()}');
      if (mounted) {
        _getData(false);
      }
    });
    _locationResponseSubscription = fcmBloc.locationResponseStream.listen((LocationResponse response) {
      pp('$mm LocationResponse just arrived: ${response.toJson()}');
      if (mounted) {
        navigateToLocationResponse(response);
      }
    });
  }

  String? subTitle, title;
  Future _getData(bool forceRefresh) async {
    setState(() {
      busy = true;
    });
    try {
      var sett = await prefsOGx.getSettings();
      if (sett != null) {
        title = await mTx.translate('organizationMembers', sett!.locale!);
        subTitle = await mTx.translate('administratorsMembers', sett!.locale!);
      }
      user = await prefsOGx.getUser();
      if (user!.userType == UserType.orgAdministrator ||
          user!.userType == UserType.orgExecutive) {
        _showPlusIcon = true;
      }
      if (user!.userType == UserType.fieldMonitor) {
        _showEditorIcon = true;
      }
      users = await organizationBloc.getUsers(
          organizationId: user!.organizationId!, forceRefresh: forceRefresh);
      users.sort((a, b) => (a.name!.compareTo(b.name!)));
      pp('.......................... users to work with: ${users.length}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Organization user refresh failed: $e')));
    }
    setState(() {
      busy = false;
    });
    _animationController.reset();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _streamSubscription.cancel();
    _locationResponseSubscription.cancel();
    super.dispose();
  }

  void navigateToLocationResponse(LocationResponse response) {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.fade,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: LocationResponseMap(locationResponse: response)));
  }

  void navigateToUserDashboard(User user) {
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

  void navigateToScheduler(User user) {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.bottomLeft,
            duration: const Duration(seconds: 1),
            child: SchedulerMobile(user)));
  }

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
            child: UserEditMain(user)));
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
    return SafeArea(
      child: Scaffold(
        key: _key,
        appBar: AppBar(
          title: Text(title == null?
            'Members': title!,
            style: myTextStyleLarge(context),
          ),
          actions: busy
              ? []
              : [
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      size: 20,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: () {
                      _getData(true);
                    },
                  ),
                  _showPlusIcon
                      ? IconButton(
                          icon: Icon(Icons.add,
                              size: 20, color: Theme.of(context).primaryColor),
                          onPressed: () {
                            navigateToUserEdit(null);
                          },
                        )
                      : const SizedBox(),
                  _showEditorIcon
                      ? IconButton(
                          icon: Icon(Icons.edit,
                              size: 20, color: Theme.of(context).primaryColor),
                          onPressed: () {
                            navigateToUserEdit(user);
                          },
                        )
                      : const SizedBox(),
                ],
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(
                    height: 24,
                  ),
                  user == null? const SizedBox(): Expanded(
                    child: UserListCard(
                      subTitle: subTitle == null?'Admins & Monitors': subTitle!,
                      amInLandscape: true,
                      users: users,
                      avatarRadius: 20,
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
                        navigateToUserDashboard(user);
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
                    ),
                  ),
                ],
              ),
            ),
            busy? const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      backgroundColor: Colors.pink,
                    ),
                  ),
                ),
              ),
            ) : const SizedBox(),
          ],
        ),
      ),
    );
  }
}
