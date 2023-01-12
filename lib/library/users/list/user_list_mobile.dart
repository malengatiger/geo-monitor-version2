import 'package:flutter/material.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';

import 'package:page_transition/page_transition.dart';

import '../../api/sharedprefs.dart';
import '../../bloc/fcm_bloc.dart';
import '../../bloc/organization_bloc.dart';
import '../../bloc/user_bloc.dart';
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
  const UserListMobile(this.user);

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
        size: 20,
      ),
      onPressed: () {
        _getData(true);
      },
    ));
    if (widget.user.userType == ORG_ADMINISTRATOR) {
      list.add(IconButton(
        icon: Icon(
          Icons.add,
          size: 20,
        ),
        onPressed: () {
          _navigateToUserEdit(null);
        },
      ));
    }
    return list;
  }

  List<FocusedMenuItem> _getMenuItems(User user) {
    assert(user != null);
    List<FocusedMenuItem> list = [];

    if (widget.user.userType == ORG_ADMINISTRATOR) {
      list.add(FocusedMenuItem(
          title: Text('Send Message'),
          trailingIcon: Icon(
            Icons.send,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            _navigateToMessaging(user);
          }));
      list.add(FocusedMenuItem(
          title: Text('Edit User'),
          trailingIcon: Icon(
            Icons.create,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            _navigateToUserEdit(user);
          }));
      list.add(FocusedMenuItem(
          title: Text('View Report'),
          trailingIcon: Icon(
            Icons.report,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            _navigateToUserReport(user);
          }));
      list.add(FocusedMenuItem(
          title: Text('Schedule FieldMonitor'),
          trailingIcon: Icon(
            Icons.person,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            _navigateToScheduler(user);
          }));
      list.add(FocusedMenuItem(
          title: Text('FieldMonitor Home Base'),
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
            title: Text('FieldMonitor Home Base'),
            trailingIcon: Icon(
              Icons.location_pin,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              _navigateToMap(user);
            }));
      } else {
        list.add(FocusedMenuItem(
            title: Text('Send Message'),
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
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(100),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Text(
                          widget.user.organizationName!,
                          style: Styles.whiteBoldSmall,
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Admins & Field Monitors',
                              style: Styles.whiteTiny,
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Text(
                              '${_users.length}',
                              style: Styles.whiteBoldSmall,
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              backgroundColor: Colors.brown[100],
              body: isBusy
                  ? const Center(
                      child: SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (BuildContext context, int index) {
                          var user = _users.elementAt(index);
                          var mType = 'Field Monitor';
                          switch (user.userType) {
                            case ORG_ADMINISTRATOR:
                              mType = 'Team Administrator';
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
                            animateMenuItems: true,
                            openWithTap: true,
                            onPressed: () {
                              pp('.... 💛️ 💛️ 💛️ not sure what I pressed ...');
                            },
                            child: Card(
                              elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.0)),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Column(
                                  children: [
                                    ListTile(
                                      // leading: Icon(
                                      //   Icons.person,
                                      //   color: Theme.of(context).primaryColor,
                                      // ),
                                      subtitle: Text(
                                        user.email!,
                                        style: Styles.greyLabelTiny,
                                      ),
                                      title: Text(
                                        user.name!,
                                        style: Styles.blackBoldSmall,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const SizedBox(
                                          width: 12,
                                        ),
                                        Text(
                                          mType,
                                          style: Styles.greyLabelTiny,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 4,
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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
            child: UserEditMain(user)));

    if (user != null) {
      _users = await hiveUtil.getUsers(organizationId: user.organizationId!);
    }
    setState(() {

    });
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
