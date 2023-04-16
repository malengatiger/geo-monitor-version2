import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geo_monitor/from_xd/my_badge.dart';
import 'package:geo_monitor/from_xd/project_list.dart';
import 'package:geo_monitor/from_xd/recent_event_list.dart';
import 'package:geo_monitor/from_xd/xd_header.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/data/activity_model.dart';
import 'package:geo_monitor/library/data/user.dart';
import 'package:geo_monitor/library/functions.dart';
import 'package:page_transition/page_transition.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../library/data/project.dart';
import '../library/ui/settings/settings_main.dart';
import 'member_list.dart';

class DashboardKhaya extends StatefulWidget {
  const DashboardKhaya({Key? key}) : super(key: key);

  @override
  State<DashboardKhaya> createState() => _DashboardKhayaState();
}

class _DashboardKhayaState extends State<DashboardKhaya> {
  var totalEvents = 0;
  var totalProjects = 0;
  var totalUsers = 0;
  User? user;
  void _setTotals() {}
  @override
  void initState() {
    super.initState();
    _getUser();
  }

  void _getUser() async {
    user = await prefsOGx.getUser();
    setState(() {});
  }

  void _navigateToSettings() {
    pp(' 🌀🌀🌀🌀 .................. _navigateToSettings to Settings ....');
    if (mounted) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.center,
              duration: const Duration(seconds: 1),
              child: const SettingsMain()));
    }
  }

  void _onSearchTapped() {
    pp(' ✅✅✅ _onSearchTapped ...');
  }

  void _onDeviceUserTapped() {
    pp(' ✅✅✅ _onDeviceUserTapped ...');
  }

  void _onRefreshRequested() {
    pp(' ✅✅✅ _onRefreshRequested ...');
  }

  void _onSettingsRequested() {
    pp(' ✅✅✅ _onSettingsRequested ...');
    _navigateToSettings();
  }

  void _onEventsSubtitleTapped() {
    pp('💚💚💚💚 events subtitle tapped');
  }

  void _onProjectSubtitleTapped() {
    pp('💚💚💚💚 projects subtitle tapped');
  }

  void _onUserSubtitleTapped() {
    pp('💚💚💚💚 users subtitle tapped');
  }

  void _onEventTapped(ActivityModel act) async {
    pp('🌀🌀🌀🌀 _onEventTapped; activityModel: ${act.toJson()}');
  }

  void _onProjectTapped(Project project) async {
    pp('🌀🌀🌀🌀 _onProjectTapped; project: ${project.toJson()}');
  }

  void _onUserTapped(User user) async {
    pp('🌀🌀🌀🌀 _onUserTapped; user: ${user.toJson()}');
  }

  void _onProjectsAcquired(int projects) async {
    pp('🌀🌀🌀🌀 _onProjectsAcquired; $projects');
    setState(() {
      totalProjects = projects;
    });
  }

  void _onEventsAcquired(int events) async {
    pp('🌀🌀🌀🌀 _onEventsAcquired; $events');
    setState(() {
      totalEvents = events;
    });
  }

  void _onUsersAcquired(int users) async {
    pp('🌀🌀🌀🌀 _onUsersAcquired; $users');
    setState(() {
      totalUsers = users;
    });
  }

  @override
  Widget build(BuildContext context) {
    var sigmaX = 12.0;
    var sigmaY = 12.0;
    if (checkIfDarkMode()) {
      sigmaX = 200.0;
      sigmaY = 200.0;
      pp('💜💜 We are in darkMode now: sigmaX: $sigmaX sigmaY: $sigmaY');
    } else {
      pp('💜💜 We are in lightMode now: sigmaX: $sigmaX sigmaY: $sigmaY');
    }
    var width = MediaQuery.of(context).size.width;
    final deviceType = getThisDeviceType();
    if (deviceType != 'phone') {}
    return Scaffold(
      body: ScreenTypeLayout(
        mobile: user == null
            ? const SizedBox()
            : RealDashboard(
                totalEvents: totalEvents,
                totalProjects: totalProjects,
                totalUsers: totalUsers,
                sigmaX: sigmaX,
                sigmaY: sigmaY,
                user: user!,
                width: width,
                onEventTapped: (event) {
                  _onEventTapped(event);
                },
                onProjectSubtitleTapped: () {
                  _onProjectSubtitleTapped();
                },
                onProjectsAcquired: (projects) {
                  _onProjectsAcquired(projects);
                },
                onProjectTapped: (project) {
                  _onProjectTapped(project);
                },
                onUserSubtitleTapped: () {
                  _onUserSubtitleTapped();
                },
                onUsersAcquired: (users) {
                  _onUsersAcquired(users);
                },
                onUserTapped: (user) {
                  _onUserTapped(user);
                },
                onEventsSubtitleTapped: () {
                  _onEventsSubtitleTapped();
                },
                onEventsAcquired: (events) {
                  _onEventsAcquired(events);
                },
                onRefreshRequested: () {
                  _onRefreshRequested();
                },
                onSearchTapped: () {
                  _onSearchTapped();
                },
                onSettingsRequested: () {
                  _onSettingsRequested();
                },
                onDeviceUserTapped: () {
                  _onDeviceUserTapped();
                }),
        tablet: OrientationLayoutBuilder(
          portrait: (context) {
            return user == null
                ? const SizedBox()
                : RealDashboard(
                    totalEvents: totalEvents,
                    totalProjects: totalProjects,
                    totalUsers: totalUsers,
                    sigmaX: sigmaX,
                    sigmaY: sigmaY,
                    user: user!,
                    width: width,
                    onEventTapped: (event) {
                      _onEventTapped(event);
                    },
                    onProjectSubtitleTapped: () {
                      _onProjectSubtitleTapped();
                    },
                    onProjectsAcquired: (projects) {
                      _onProjectsAcquired(projects);
                    },
                    onProjectTapped: (project) {
                      _onProjectTapped(project);
                    },
                    onUserSubtitleTapped: () {
                      _onUserSubtitleTapped();
                    },
                    onUsersAcquired: (users) {
                      _onUsersAcquired(users);
                    },
                    onUserTapped: (user) {
                      _onUserTapped(user);
                    },
                    onEventsSubtitleTapped: () {
                      _onEventsSubtitleTapped();
                    },
                    onEventsAcquired: (events) {
                      _onEventsAcquired(events);
                    },
                    onRefreshRequested: () {
                      _onRefreshRequested();
                    },
                    onSearchTapped: () {
                      _onSearchTapped();
                    },
                    onSettingsRequested: () {
                      _onSettingsRequested();
                    },
                    onDeviceUserTapped: () {
                      _onDeviceUserTapped();
                    });
          },
          landscape: (context) {
            return user == null
                ? const SizedBox()
                : RealDashboard(
                    totalEvents: totalEvents,
                    totalProjects: totalProjects,
                    totalUsers: totalUsers,
                    sigmaX: sigmaX,
                    sigmaY: sigmaY,
                    user: user!,
                    width: width,
                    onEventTapped: (event) {
                      _onEventTapped(event);
                    },
                    onProjectSubtitleTapped: () {
                      _onProjectSubtitleTapped();
                    },
                    onProjectsAcquired: (projects) {
                      _onProjectsAcquired(projects);
                    },
                    onProjectTapped: (project) {
                      _onProjectTapped(project);
                    },
                    onUserSubtitleTapped: () {
                      _onUserSubtitleTapped();
                    },
                    onUsersAcquired: (users) {
                      _onUsersAcquired(users);
                    },
                    onUserTapped: (user) {
                      _onUserTapped(user);
                    },
                    onEventsSubtitleTapped: () {
                      _onEventsSubtitleTapped();
                    },
                    onEventsAcquired: (events) {
                      _onEventsAcquired(events);
                    },
                    onRefreshRequested: () {
                      _onRefreshRequested();
                    },
                    onSearchTapped: () {
                      _onSearchTapped();
                    },
                    onSettingsRequested: () {
                      _onSettingsRequested();
                    },
                    onDeviceUserTapped: () {
                      _onDeviceUserTapped();
                    });
          },
        ),
      ),
    );
  }
}

class RealDashboard extends StatelessWidget {
  const RealDashboard({
    Key? key,
    required this.totalEvents,
    required this.totalProjects,
    required this.totalUsers,
    required this.sigmaX,
    required this.sigmaY,
    required this.user,
    required this.width,
    required this.onEventTapped,
    required this.onProjectSubtitleTapped,
    required this.onProjectsAcquired,
    required this.onProjectTapped,
    required this.onUserSubtitleTapped,
    required this.onUsersAcquired,
    required this.onUserTapped,
    required this.onEventsSubtitleTapped,
    required this.onEventsAcquired,
    required this.onRefreshRequested,
    required this.onSearchTapped,
    required this.onSettingsRequested,
    required this.onDeviceUserTapped,
  }) : super(key: key);

  final Function onEventsSubtitleTapped;
  final Function(int) onEventsAcquired;
  final Function(ActivityModel) onEventTapped;
  final Function onProjectSubtitleTapped;
  final int totalEvents, totalProjects, totalUsers;
  final Function(int) onProjectsAcquired;
  final Function(Project) onProjectTapped;
  final Function onUserSubtitleTapped;
  final Function(int) onUsersAcquired;
  final Function(User) onUserTapped;
  final double sigmaX, sigmaY;
  final Function onRefreshRequested,
      onSearchTapped,
      onSettingsRequested,
      onDeviceUserTapped;
  final User user;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Stack(
        children: [
          Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 150),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: const [
                          Text(
                            'Dashboard',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),
                      SubTitleWidget(
                          title: 'Recent Events',
                          onTapped: () {
                            onEventsSubtitleTapped();
                          },
                          number: totalEvents,
                          color: Colors.blue),
                      const SizedBox(height: 12),
                      RecentEventList(
                        onEventsAcquired: (events) {
                          onEventsAcquired(events);
                        },
                        onEventTapped: (act) {
                          onEventTapped(act);
                        },
                      ),
                      const SizedBox(
                        height: 36,
                      ),
                      SubTitleWidget(
                          title: 'Projects',
                          onTapped: () {
                            pp('💚💚💚💚 project subtitle tapped');
                            onProjectSubtitleTapped();
                          },
                          number: totalProjects,
                          color: Colors.blue),
                      const SizedBox(
                        height: 12,
                      ),
                      ProjectList(
                        onProjectsAcquired: (projects) {
                          onProjectsAcquired(projects);
                        },
                        onProjectTapped: (project) {
                          onProjectTapped(project);
                        },
                      ),
                      const SizedBox(height: 36),
                      SubTitleWidget(
                          title: 'Members',
                          onTapped: () {
                            onUserSubtitleTapped();
                          },
                          number: totalUsers,
                          color: Theme.of(context).indicatorColor),
                      const SizedBox(
                        height: 12,
                      ),
                      UserList(
                        onUsersAcquired: (users) {
                          onUsersAcquired(users);
                        },
                        onUserTapped: (user) {
                          onUserTapped(user);
                        },
                      ),
                      const SizedBox(height: 200),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            child: SizedBox(
              height: 112,
              child: AppBar(
                // centerTitle: false,
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
                    child: Container(
                      decoration:
                          BoxDecoration(color: Colors.white.withOpacity(0.0)),
                    ),
                  ),
                ),
                title: const XdHeader(),
                actions: [
                  IconButton(
                      onPressed: (){
                        onSearchTapped();
                      },
                      icon: const Icon(
                        Icons.search,
                      )),
                  IconButton(
                      onPressed: (){
                        onRefreshRequested();
                      },
                      icon: const Icon(
                        Icons.refresh,
                      )),
                  IconButton(
                      onPressed: (){
                        onSettingsRequested();
                      },
                      icon: const Icon(
                        Icons.settings,
                      )),
                  const SizedBox(
                    width: 8,
                  ),
                  GestureDetector(
                    onTap: onDeviceUserTapped(),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage(user.thumbnailUrl!),
                    ),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SubTitleWidget extends StatelessWidget {
  const SubTitleWidget(
      {Key? key,
      required this.title,
      required this.onTapped,
      required this.number,
      required this.color})
      : super(key: key);

  final String title;
  final Function onTapped;
  final int number;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTapped();
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            title,
            style: myTextStyleSubtitle(context),
          ),
          const SizedBox(
            width: 12,
          ),
          MyBadge(number: number),
          SizedBox(
            width: 1,
            child: IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 20,
                )),
          )
        ],
      ),
    );
  }
}
