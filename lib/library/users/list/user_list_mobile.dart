import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';
import 'package:geo_monitor/library/emojis.dart';
import 'package:geo_monitor/library/users/edit/user_edit_mobile.dart';

import 'package:page_transition/page_transition.dart';

import '../../api/sharedprefs.dart';
import '../../bloc/fcm_bloc.dart';
import '../../bloc/organization_bloc.dart';
import '../../functions.dart';
import '../../hive_util.dart';
import '../../snack.dart';
import '../../ui/maps_field_monitor/field_monitor_map_main.dart';
import '../../ui/message/message_main.dart';
import '../../ui/schedule/scheduler_main.dart';
import '../edit/user_edit_main.dart';
import '../../data/user.dart';
import '../report/user_rpt_main.dart';

class UserListMobile extends StatefulWidget {
  final User user;
  const UserListMobile(this.user, {super.key});

  @override
  UserListMobileState createState() => UserListMobileState();
}

class UserListMobileState extends State<UserListMobile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool isBusy = false;
  var _users = <User>[];
  final _key = GlobalKey<ScaffoldState>();
  User? _user;
  final mm = '${Emoji.diamond}${Emoji.diamond}${Emoji.diamond}${Emoji.diamond} UserListMobile: ';

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getData(false);
    _listen();
  }

  void _listen() {
    fcmBloc.userStream.listen((User user) {
      if (mounted) {
        AppSnackbar.showSnackbar(
            scaffoldKey: _key,
            message: 'User has been added OK',
            textColor: Colors.white,
            backgroundColor: Theme.of(context).primaryColor);
      }
    });
  }

  void _getData(bool forceRefresh) async {
    setState(() {
      isBusy = true;
    });
    try {
      _user = await Prefs.getUser();
      _users = await organizationBloc.getUsers(
          organizationId: widget.user.organizationId!,
          forceRefresh: forceRefresh);
      _users.sort((a, b) => (a.name!.compareTo(b.name!)));
      pp('.......................... users to work with: ${_users.length}');

    } catch (e) {
      AppSnackbar.showErrorSnackbar(
          scaffoldKey: _key, message: 'Organization user refresh failed: $e');
    }
    setState(() {
      isBusy = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<IconButton> getIconButtons() {
    List<IconButton> list = [];
    list.add(IconButton(
      icon: Icon(
        Icons.refresh,
        size: 20, color: Theme.of(context).primaryColor,
      ),
      onPressed: () {
        _getData(true);
      },
    ));
    if (widget.user.userType == ORG_ADMINISTRATOR) {
      list.add(IconButton(
        icon: Icon(
          Icons.add,
          size: 20, color: Theme.of(context).primaryColor
        ),
        onPressed: () {
          _navigateToUserEdit(null);
        },
      ));
    }
    return list;
  }

  List<FocusedMenuItem> _getMenuItems(User user) {
    List<FocusedMenuItem> list = [];

    if (widget.user.userType == ORG_ADMINISTRATOR) {
      list.add(FocusedMenuItem(
          title: Text('Send Message',style: myTextStyleSmall(context)),
          backgroundColor: Theme.of(context).primaryColor,
          trailingIcon: Icon(
            Icons.send,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            _navigateToMessaging(user);
          }));
      list.add(FocusedMenuItem(
          title: Text('Edit User',style: myTextStyleSmall(context),),
          backgroundColor: Theme.of(context).primaryColor,
          trailingIcon: Icon(
            Icons.create,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            _navigateToUserEdit(user);
          }));
      list.add(FocusedMenuItem(
          title:  Text('View Report',style: myTextStyleSmall(context)),
          backgroundColor: Theme.of(context).primaryColor,
          trailingIcon: Icon(
            Icons.report,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            _navigateToUserReport(user);
          }));
      list.add(FocusedMenuItem(
          title:  Text('Schedule FieldMonitor',style: myTextStyleSmall(context)),
          backgroundColor: Theme.of(context).primaryColor,
          trailingIcon: Icon(
            Icons.person,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            _navigateToScheduler(user);
          }));
      list.add(FocusedMenuItem(
          title:  Text('FieldMonitor Home Base',style: myTextStyleSmall(context)),
          backgroundColor: Theme.of(context).primaryColor,
          trailingIcon: Icon(
            Icons.location_pin,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            _navigateToMap(user);
          }));
    }
    if (widget.user.userType == FIELD_MONITOR) {
      if (_user!.userId == user.userId) {
        list.add(FocusedMenuItem(
            title:  Text('FieldMonitor Home Base',style: myTextStyleSmall(context)),
            backgroundColor: Theme.of(context).primaryColor,
            trailingIcon: Icon(
              Icons.location_pin,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              _navigateToMap(user);
            }));
      } else {
        list.add(FocusedMenuItem(
            title:  Text('Send Message', style: myTextStyleSmall(context),),
            backgroundColor: Theme.of(context).primaryColor,
            trailingIcon: Icon(
              Icons.send,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              _navigateToMessaging(user);
            }));
      }
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<List<User>>(
          stream: organizationBloc.usersStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              _users = snapshot.data!;
            }
            return Scaffold(
              key: _key,
              appBar: AppBar(
                title: Text(
                  'Organization Users',
                  style: Styles.whiteTiny,
                ),
                actions: getIconButtons(),
              ),
              body: isBusy
                  ? const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          backgroundColor: Colors.pink,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Card(
                        elevation: 4,
                        shape: getRoundedBorder(radius: 16),
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 24,
                            ),
                            Text(
                              widget.user.organizationName!,
                              style: myTextStyleLarge(context),
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Admins & Field Monitors',
                                  style: myTextStyleSmall(context),
                                ),
                                const SizedBox(
                                  width: 8,
                                ),

                              ],
                            ),
                            const SizedBox(
                              height: 16,
                            ),
                            Expanded(
                              child: Badge(
                                badgeContent: Text('${_users.length}'),
                                badgeColor: Theme.of(context).primaryColor,
                                position: const BadgePosition(top: -12, end: 12),
                                child: ListView.builder(
                                  itemCount: _users.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    var user = _users.elementAt(index);
                                    var mType = 'Field Monitor';
                                    switch (user.userType) {
                                      case ORG_ADMINISTRATOR:
                                        mType = 'Administrator';
                                        break;
                                      case ORG_EXECUTIVE:
                                        mType = 'Executive';
                                        break;
                                      case FIELD_MONITOR:
                                        mType = 'Field Monitor';
                                        break;
                                    }
                                    return FocusedMenuHolder(
                                      menuItems: _getMenuItems(user),
                                      blurBackgroundColor: Theme.of(context).backgroundColor,
                                      animateMenuItems: true,
                                      openWithTap: true,
                                      onPressed: () {
                                        pp('.... 💛️ 💛️ 💛️ not sure what I pressed ...');
                                      },
                                      child: Card(
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16.0)),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Column(
                                            children: [
                                              Row(
                                                children: [
                                                  const SizedBox(width:24, height: 24,
                                                    child: CircleAvatar(
                                                        backgroundImage: AssetImage(
                                                            'assets/batman.png')),
                                                  ),
                                                  const SizedBox(
                                                    width: 8,
                                                  ),
                                                  Text(
                                                    user.name!,
                                                    style:
                                                        myTextStyleSmall(context),
                                                  ),
                                                ],
                                              ),
                                              Row(mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  Text(_user!.cellphone!, style: myTextStyleSmall(context)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            );
          }),
    );
  }

  void _navigateToUserEdit(User? user) async {
    await Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: UserEditMobile(user)));

    if (user != null) {
      _users = await hiveUtil.getUsers(organizationId: user.organizationId!);
    }
    setState(() {});
  }

  void _navigateToUserReport(User user) {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: UserReportMain(user)));
  }

  void _navigateToMessaging(User user) {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.bottomLeft,
            duration: const Duration(seconds: 1),
            child: MessageMain(
              user: user,
            )));
  }

  void _navigateToMap(User user) {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.bottomLeft,
            duration: const Duration(seconds: 1),
            child: FieldMonitorMapMain(user)));
  }

  void _navigateToScheduler(User user) {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.bottomLeft,
            duration: const Duration(seconds: 1),
            child: SchedulerMain(user)));
  }
}
