import 'dart:async';

import 'package:animations/animations.dart';
import 'package:badges/badges.dart' as bd;
import 'package:flutter/material.dart';
import 'package:flutter_libphonenumber/flutter_libphonenumber.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';
import 'package:geo_monitor/library/generic_functions.dart';
import 'package:geo_monitor/library/ui/maps_field_monitor/field_monitor_map_mobile.dart';
import 'package:geo_monitor/library/ui/schedule/scheduler_mobile.dart';
import 'package:geo_monitor/library/users/edit/user_edit_main.dart';
import 'package:geo_monitor/library/users/kill_user_page.dart';
import 'package:geo_monitor/library/users/list/user_list_card.dart';
import 'package:geo_monitor/library/users/report/user_rpt_mobile.dart';

import 'package:page_transition/page_transition.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/prefs_og.dart';
import '../../bloc/fcm_bloc.dart';
import '../../bloc/organization_bloc.dart';
import '../../emojis.dart';
import '../../functions.dart';
import '../../hive_util.dart';
import '../../ui/message/message_mobile.dart';
import '../../data/user.dart';

class UserListTabletPortrait extends StatefulWidget {
  // final User user;
  const UserListTabletPortrait({super.key, required this.amInLandscape});

  final bool amInLandscape;
  @override
  UserListTabletPortraitState createState() => UserListTabletPortraitState();
}

class UserListTabletPortraitState extends State<UserListTabletPortrait>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool busy = false;
  var _users = <User>[];
  final _key = GlobalKey<ScaffoldState>();
  User? _user;
  final mm =
      '${E.diamond}${E.diamond}${E.diamond}${E.diamond} UserListTabletPortrait: ';

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
  void _listen() {
    _streamSubscription = fcmBloc.userStream.listen((User user) {
      pp('$mm new user just arrived: ${user.toJson()}');

      if (mounted) {
        _getData(false);
        showToast(message: 'User added or modified!', context: context);
      }
    });
  }

  bool _showPlusIcon = false;
  bool _showEditorIcon = false;
  Future _getData(bool forceRefresh) async {
    setState(() {
      busy = true;
    });
    try {
      _user = await prefsOGx.getUser();
      if (_user!.userType == UserType.orgAdministrator || _user!.userType == UserType.orgExecutive) {
        _showPlusIcon = true;
      }
      if (_user!.userType == UserType.fieldMonitor) {
        _showEditorIcon = true;
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
    _streamSubscription.cancel();
    super.dispose();
  }

  List<FocusedMenuItem> _getMenuItems(User someUser) {
    List<FocusedMenuItem> list = [];

    if (someUser.userId != _user!.userId) {
      list.add(FocusedMenuItem(
          title: Text('Call User', style: myTextStyleSmallBlack(context)),
          // backgroundColor: Theme.of(context).primaryColor,
          trailingIcon: Icon(
            Icons.phone,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            _navigateToPhone(someUser);
          }));
      list.add(FocusedMenuItem(
          title: Text('Send Message', style: myTextStyleSmallBlack(context)),
          // backgroundColor: Theme.of(context).primaryColor,
          trailingIcon: Icon(
            Icons.send,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            _navigateToMessaging(someUser);
          }));
    }

    if (_user!.userType == UserType.fieldMonitor) {
       // pp('$mm Field monitor cannot edit any other users');
    } else {
      list.add(FocusedMenuItem(
          title: Text('View Report', style: myTextStyleSmallBlack(context)),
          trailingIcon: Icon(
            Icons.report,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            _navigateToUserReport(someUser);
          }));
      list.add(FocusedMenuItem(
          title: Text(
            'Edit User',
            style: myTextStyleSmallBlack(context),
          ),

          trailingIcon: Icon(
            Icons.create,
            color: Theme
                .of(context)
                .primaryColor,
          ),
          onPressed: () {
            _navigateToUserEdit(someUser);
          }));
    }

    if (_user!.userType == UserType.orgAdministrator ||
        _user!.userType == UserType.orgExecutive) {
      list.add(FocusedMenuItem(
          title: Text('Schedule FieldMonitor',
              style: myTextStyleSmallBlack(context)),
          trailingIcon: Icon(
            Icons.person,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            _navigateToScheduler(someUser);
          }));
//Sg55CHHMCsBzSxi

      list.add(FocusedMenuItem(
          title: Text('Remove User', style: myTextStyleSmallBlack(context)),
          trailingIcon: Icon(
            Icons.cut,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            _navigateToKillPage(someUser);
          }));
    }
    // }
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

  void _navigateToUserEdit(User? user) async {
    if (_user!.userType == UserType.fieldMonitor) {
      if (_user!.userId != user?.userId!) {

        return;
      }
    }
    var result = await Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: UserEditMain(user)));

    if (result != null) {
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

  Future<void> _navigateToPhone(User user) async {
    pp('$mm ... starting phone call ....');
    final Uri phoneUri = Uri(
        scheme: "tel",
        path: user.cellphone!
    );
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    } catch (error) {
      throw("Cannot dial");
    }
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

  bool sortedByName = false;

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

  void _sort() {
    if (sortedByName) {
      _sortByNameDesc();
    } else {
      _sortByName();
    }
  }
  void _sortByName() {
    _users.sort((a,b) => a.name!.compareTo(b.name!));
    sortedByName = true;
    setState(() {

    });
  }
  void _sortByNameDesc() {
    _users.sort((a,b) => b.name!.compareTo(a.name!));
    sortedByName = false;
    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
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
          ): const SizedBox(),

          _showEditorIcon? IconButton(
            icon: Icon(Icons.edit, size: 20, color: Theme.of(context).primaryColor),
            onPressed: () {
              _navigateToUserEdit(_user);
            },
          ): const SizedBox(),
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
        padding: const EdgeInsets.all(72.0),
        child: UserListCard(
          amInLandscape: false,
          badgeTapped: _sort,
          users: _users, deviceUser: _user!, navigateToPhone: (user ) {
          _navigateToPhone(user);
        }, navigateToMessaging: (user ) {
          _navigateToMessaging(user);
        }, navigateToUserReport: (user ) {
          _navigateToUserReport(user);
        }, navigateToUserEdit: (user ) {
          _navigateToUserEdit(user);
        }, navigateToScheduler: (user ) {
          _navigateToScheduler(user);
        }, navigateToKillPage: (user ) {
          _navigateToKillPage(user);
        },
        ),
      ),
    );
  }
}




