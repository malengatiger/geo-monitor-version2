import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geo_monitor/dashboard_khaya/project_list.dart';
import 'package:geo_monitor/dashboard_khaya/recent_event_list.dart';
import 'package:geo_monitor/dashboard_khaya/xd_header.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/bloc/organization_bloc.dart';
import 'package:geo_monitor/library/data/activity_model.dart';
import 'package:geo_monitor/library/data/user.dart';
import 'package:geo_monitor/library/functions.dart';
import 'package:geo_monitor/library/generic_functions.dart';
import 'package:geo_monitor/library/ui/project_list/project_list_main.dart';
import 'package:geo_monitor/library/users/list/user_list_mobile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../l10n/translation_handler.dart';
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
  String? dashboardText;
  String? eventsText;
  String? projectsText;
  String? membersText;
  bool busy = false;

  var projects = <Project>[];
  var events = <ActivityModel>[];
  var users = <User>[];

  @override
  void initState() {
    super.initState();
    _setTexts();
    _getData(false);
  }

  var images = <Image>[];

  void _getData(bool forceRefresh) async {
    user = await prefsOGx.getUser();
    try {
      setState(() {
        busy = true;
      });
      projects = await organizationBloc.getOrganizationProjects(
          organizationId: user!.organizationId!, forceRefresh: forceRefresh);
      users = await organizationBloc.getUsers(
          organizationId: user!.organizationId!, forceRefresh: forceRefresh);
      events = await organizationBloc.getOrganizationActivity(
          organizationId: user!.organizationId!,
          forceRefresh: forceRefresh,
          hours: 400);
      users = await organizationBloc.getUsers(organizationId: user!.organizationId!,
          forceRefresh: forceRefresh);

    } catch (e) {
      if (mounted) {
        showToast(message: '$e', context: context);
      }
    }
    setState(() {
      busy = false;
    });
  }
  void _refresh() async {

  }

  void _setTexts() async {
    var sett = await prefsOGx.getSettings();
    dashboardText = await translator.translate('dashboard', sett.locale!);
    eventsText = await translator.translate('activities', sett.locale!);
    projectsText = await translator.translate('projects', sett.locale!);
    membersText = await translator.translate('members', sett.locale!);
    setState(() {});
  }

  bool refreshRequired = false;

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

  void _navigateToProjects() {
    pp(' 🌀🌀🌀🌀 .................. _navigateToSettings to Settings ....');
    if (mounted) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.center,
              duration: const Duration(seconds: 1),
              child: const ProjectListMain()));
    }
  }
  void _navigateToMembers() {
    pp(' 🌀🌀🌀🌀 .................. _navigateToSettings to Settings ....');
    if (mounted) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.center,
              duration: const Duration(seconds: 1),
              child: const UserListMobile()));
    }
  }

  void _onSearchTapped() {
    pp(' ✅✅✅ _onSearchTapped ...');
  }

  void _onDeviceUserTapped() {
    pp(' ✅✅✅ _onDeviceUserTapped ...');
  }

  bool forceRefresh = false;
  void _onRefreshRequested() {
    pp(' ✅✅✅ _onRefreshRequested ...');
    _getData(true);
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
    _navigateToProjects();
  }

  void _onUserSubtitleTapped() {
    pp('💚💚💚💚 users subtitle tapped');
    _navigateToMembers();
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
      body: busy
          ? const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  backgroundColor: Colors.pink,
                ),
              ),
            )
          : ScreenTypeLayout(
              mobile: user == null
                  ? const SizedBox()
                  : RealDashboard(
                      projects: projects,
                      users: users,
                      events: events,
                      totalEvents: totalEvents,
                      totalProjects: totalProjects,
                      totalUsers: totalUsers,
                      sigmaX: sigmaX,
                      sigmaY: sigmaY,
                      user: user!,
                      width: width,
                      forceRefresh: forceRefresh,
                      membersText: membersText!,
                      projectsText: projectsText!,
                      eventsText: eventsText!,
                      dashboardText: dashboardText!,
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
                          projects: projects,
                          users: users,
                          events: events,
                          forceRefresh: forceRefresh,
                          totalEvents: totalEvents,
                          totalProjects: totalProjects,
                          totalUsers: totalUsers,
                          sigmaX: sigmaX,
                          sigmaY: sigmaY,
                          user: user!,
                          width: width,
                          membersText: membersText!,
                          projectsText: projectsText!,
                          eventsText: eventsText!,
                          dashboardText: dashboardText!,
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
                          forceRefresh: forceRefresh,
                          projects: projects,
                          users: users,
                          events: events,
                          totalEvents: totalEvents,
                          totalProjects: totalProjects,
                          totalUsers: totalUsers,
                          sigmaX: sigmaX,
                          sigmaY: sigmaY,
                          membersText: membersText!,
                          projectsText: projectsText!,
                          eventsText: eventsText!,
                          dashboardText: dashboardText!,
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
    required this.dashboardText,
    required this.eventsText,
    required this.projectsText,
    required this.membersText,
    required this.forceRefresh,
    required this.projects,
    required this.events,
    required this.users,
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
  final String dashboardText, eventsText, projectsText, membersText;
  final bool forceRefresh;

  final List<Project> projects;
  final List<ActivityModel> events;
  final List<User> users;

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
                      const SizedBox(height: 24),
                      SubTitleWidget(
                          title: 'Events',
                          onTapped: () {
                            onEventsSubtitleTapped();
                          },
                          number: totalEvents,
                          color: Colors.blue),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          DashboardTopCard(
                              number: events.length,
                              title: 'Events',
                              onTapped: () {}),
                          const SizedBox(width: 2,),
                          DashboardTopCard(
                              number: projects.length,
                              title: 'Projects',
                              onTapped: () {}),
                          const SizedBox(width: 2,),
                          DashboardTopCard(
                              number: users.length,
                              title: 'Users',
                              onTapped: () {}),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children:  [
                          Text(
                            'Recent Events', style: myTextStyleSubtitleSmall(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      RecentEventList(
                        onEventTapped: (act) {
                          onEventTapped(act);
                        },
                        activities: events,
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
                      ProjectListView(
                        projects: projects,
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
                      MemberList(
                        users: users,
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
                      onPressed: () {
                        onSearchTapped();
                      },
                      icon: const Icon(
                        Icons.search,
                      )),
                  IconButton(
                      onPressed: () {
                        onRefreshRequested();
                      },
                      icon: const Icon(
                        Icons.refresh,
                      )),
                  IconButton(
                      onPressed: () {
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
            width: 2,
          ),
          // MyBadge(number: number),
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

class DashboardTopCard extends StatelessWidget {
  const DashboardTopCard(
      {Key? key,
      required this.number,
      required this.title,
      this.height,
      this.topPadding,
      this.textStyle,
      this.labelTitleStyle,
      required this.onTapped,
      this.width})
      : super(key: key);
  final int number;
  final String title;
  final double? height, topPadding, width;
  final TextStyle? textStyle, labelTitleStyle;
  final Function() onTapped;

  @override
  Widget build(BuildContext context) {
    var style = GoogleFonts.roboto(
        textStyle: Theme.of(context).textTheme.titleLarge,
        fontSize: 40,
        color: Theme.of(context).canvasColor,
        fontWeight: FontWeight.w900);
    var style2 = GoogleFonts.roboto(
        textStyle: Theme.of(context).textTheme.bodyMedium,
        fontSize: 12,
        color: Theme.of(context).canvasColor,
        fontWeight: FontWeight.normal);


    return GestureDetector(
      onTap: () {
        onTapped();
      },
      child: Card(
        shape: getRoundedBorder(radius: 16),
        child: SizedBox(
          height: height == null ? 104 : height!,
          width: width == null ? 104 : width!,
          child: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: topPadding == null ? 8 : topPadding!,
                ),
                Text('$number', style: textStyle == null ? style : textStyle!),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  title,
                  style: style2,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
