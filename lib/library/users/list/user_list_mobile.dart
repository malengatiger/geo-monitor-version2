import 'package:animations/animations.dart';
import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter_libphonenumber/flutter_libphonenumber.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';
import 'package:geo_monitor/library/ui/maps_field_monitor/field_monitor_map_mobile.dart';
import 'package:geo_monitor/library/ui/schedule/scheduler_mobile.dart';
import 'package:geo_monitor/library/users/kill_user_page.dart';
import 'package:geo_monitor/library/users/report/user_rpt_mobile.dart';

import 'package:page_transition/page_transition.dart';

import '../../api/sharedprefs.dart';
import '../../bloc/fcm_bloc.dart';
import '../../bloc/organization_bloc.dart';
import '../../emojis.dart';
import '../../functions.dart';
import '../../hive_util.dart';
import '../../ui/message/message_mobile.dart';
import '../../data/user.dart';
import '../edit/user_edit_mobile.dart';

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
  var _users = <User>[];
  final _key = GlobalKey<ScaffoldState>();
  User? _user;
  final mm =
      '${Emoji.diamond}${Emoji.diamond}${Emoji.diamond}${Emoji.diamond} UserListMobile: ';

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

  void _listen() {
    fcmBloc.userStream.listen((User user) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User has been added OK')));
      }
    });
  }

  bool _showPlusIcon = false;
  void _getData(bool forceRefresh) async {
    setState(() {
      busy = true;
    });
    try {
      _user = await Prefs.getUser();
      if (_user!.userType == UserType.orgAdministrator || _user!.userType == UserType.orgExecutive) {
        _showPlusIcon = true;
      }
      _users = await organizationBloc.getUsers(
          organizationId: _user!.organizationId!, forceRefresh: forceRefresh);
      _users.sort((a, b) => (a.name!.compareTo(b.name!)));
      pp('.......................... users to work with: ${_users.length}');
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
    super.dispose();
  }

  List<FocusedMenuItem> _getMenuItems(User user) {
    List<FocusedMenuItem> list = [];

    list.add(FocusedMenuItem(
        title: Text('Send Message', style: myTextStyleSmallBlack(context)),
        backgroundColor: Theme.of(context).primaryColor,
        trailingIcon: Icon(
          Icons.send,
          color: Theme.of(context).primaryColor,
        ),
        onPressed: () {
          _navigateToMessaging(user);
        }));
    list.add(FocusedMenuItem(
        title: Text(
          'Edit User',
          style: myTextStyleSmallBlack(context),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        trailingIcon: Icon(
          Icons.create,
          color: Theme.of(context).primaryColor,
        ),
        onPressed: () {
          _navigateToUserEdit(user);
        }));
    list.add(FocusedMenuItem(
        title: Text('View Report', style: myTextStyleSmallBlack(context)),
        backgroundColor: Theme.of(context).primaryColor,
        trailingIcon: Icon(
          Icons.report,
          color: Theme.of(context).primaryColor,
        ),
        onPressed: () {
          _navigateToUserReport(user);
        }));
    if (_user!.userType == UserType.orgAdministrator ||
        _user!.userType == UserType.orgExecutive) {
      list.add(FocusedMenuItem(
          title: Text('Schedule FieldMonitor',
              style: myTextStyleSmallBlack(context)),
          backgroundColor: Theme.of(context).primaryColor,
          trailingIcon: Icon(
            Icons.person,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            _navigateToScheduler(user);
          }));

      list.add(FocusedMenuItem(
          title: Text('FieldMonitor Home Base',
              style: myTextStyleSmallBlack(context)),
          backgroundColor: Theme.of(context).primaryColor,
          trailingIcon: Icon(
            Icons.location_pin,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            _navigateToMap(user);
          }));
      list.add(FocusedMenuItem(
          title: Text('Remove User', style: myTextStyleSmallBlack(context)),
          backgroundColor: Theme.of(context).primaryColor,
          trailingIcon: Icon(
            Icons.cut,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            _navigateToKillPage(user);
          }));
    }
    // }
    if (_user!.userType == UserType.fieldMonitor) {
      if (_user!.userId == user.userId) {
        list.add(FocusedMenuItem(
            title: Text('FieldMonitor Home Base',
                style: myTextStyleSmallBlack(context)),
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
            title: Text(
              'Send Message',
              style: myTextStyleSmall(context),
            ),
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

  String _getFormatted(String cellphone) {
    final formattedNumber = FlutterLibphonenumber().formatNumberSync(cellphone,
        country: CountryWithPhoneCode(
            phoneCode: '27',
            countryCode: 'ZA',
            exampleNumberMobileNational: '0825678899',
            exampleNumberFixedLineNational: '0124456766',
            phoneMaskMobileNational: '00000 000000',
            phoneMaskFixedLineNational: '00000 000000',
            exampleNumberMobileInternational: '+27 65 747 1234',
            exampleNumberFixedLineInternational: '+27 65 747 1234',
            phoneMaskMobileInternational: '+00 00 000 0000',
            phoneMaskFixedLineInternational: '+00 00 000 0000',
            countryName: 'South Africa'));
    return formattedNumber;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text(
          'Organization Users',
          style: Styles.whiteTiny,
        ),
        actions: busy? [] : [
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
          _showPlusIcon? IconButton(
            icon: Icon(Icons.add, size: 20, color: Theme.of(context).primaryColor),
            onPressed: () {
              _navigateToUserEdit(null);
            },
          ): const SizedBox()
        ],
      ),
      body: busy
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
                      _user!.organizationName!,
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
                      height: 48,
                    ),
                    Expanded(
                      child: Badge(
                        badgeContent: Text(
                          '${_users.length}',
                          style: myTextStyleSmallBlack(context),
                        ),
                        badgeColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.all(8.0),
                        position: const BadgePosition(top: -16, end: 12),
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (BuildContext context, Widget? child) {
                            return FadeScaleTransition(
                              animation: _animationController,
                              child: child,
                            );
                          },
                          child: ListView.builder(
                            itemCount: _users.length,
                            itemBuilder: (BuildContext context, int index) {
                              var user = _users.elementAt(index);
                              final formattedNumber =
                                  _getFormatted(user.cellphone!);
                              return FocusedMenuHolder(
                                menuOffset: 20,
                                duration: const Duration(milliseconds: 300),
                                menuItems: _getMenuItems(user),
                                animateMenuItems: true,
                                openWithTap: true,
                                onPressed: () {
                                  pp('$mm. 💛️💛️💛️ tapped FocusedMenuHolder ...');
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
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 6.0),
                                          child: Row(
                                            children: [
                                              Text(
                                                formattedNumber,
                                                style: const TextStyle(
                                                    fontSize: 8,
                                                    fontWeight:
                                                        FontWeight.normal),
                                              ),
                                              const SizedBox(
                                                width: 4,
                                              ),
                                              SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: Card(
                                                    color: Theme.of(context)
                                                        .primaryColor),
                                              ),
                                              const SizedBox(
                                                width: 8,
                                              ),
                                              Flexible(
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      user.name!,
                                                      style: myTextStyleSmall(
                                                          context),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 8,
                                              ),

                                              // const SizedBox(width:24, height: 24,
                                              //   child: CircleAvatar(
                                              //       backgroundImage: AssetImage(
                                              //           'assets/batman.png')),
                                              // ),
                                            ],
                                          ),
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
                    ),
                  ],
                ),
              ),
            ),
    ));
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
      _users = await cacheManager.getUsers();
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
            child: UserReportMobile(user)));
  }

  void _navigateToMessaging(User user) {
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

  void _navigateToMap(User user) {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.bottomLeft,
            duration: const Duration(seconds: 1),
            child: FieldMonitorMapMobile(user)));
  }

  void _navigateToScheduler(User user) {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.bottomLeft,
            duration: const Duration(seconds: 1),
            child: SchedulerMobile(user)));
  }

  Future<void> _navigateToKillPage(User user) async {
    await Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.bottomLeft,
            duration: const Duration(seconds: 1),
            child: KillUserPage(
              user: user,
            )));
    pp('$mm ... back from KillPage; will refresh user list ....');
    _getData(true);
  }
}
