import 'package:flutter/material.dart';

import '../../api/data_api.dart';
import '../../api/sharedprefs.dart';
import '../../bloc/organization_bloc.dart';
import '../../bloc/user_bloc.dart';
import '../../data/project.dart';
import '../../data/user.dart';
import '../../data/field_monitor_schedule.dart';
import 'package:page_transition/page_transition.dart';
import 'package:uuid/uuid.dart';

import '../../functions.dart';

class SchedulerMobile extends StatefulWidget {
  final User user;

  const SchedulerMobile(this.user, {super.key});

  @override
  SchedulerMobileState createState() => SchedulerMobileState();
}

class SchedulerMobileState extends State<SchedulerMobile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool busy = false;
  User? _adminUser;
  List<Project> _projects = [];
  final _key = GlobalKey<ScaffoldState>();
  static const mm = 'SchedulerMobile: 🍏 🍏 🍏 🍏 ';
  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getData(false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _getData(bool refresh) async {
    pp('$mm getting list of projects ...');
    setState(() {
      busy = true;
    });
    try {
      _adminUser = await Prefs.getUser();
      _projects = await organizationBloc.getProjects(
          organizationId: widget.user.organizationId!, forceRefresh: refresh);
      pp('$mm ${_projects.length} projects ...');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('List failed: $e')));

    }
    setState(() {
      busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            key: _key,
            appBar: AppBar(
              title: Text('FieldMonitor Schedule', style: Styles.whiteSmall),
              bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(100),
                  child: Column(
                    children: [
                      Text(
                        widget.user.name!,
                        style: Styles.blackBoldMedium,
                      ),
                      Text(
                        'FieldMonitor',
                        style: Styles.blackSmall,
                      ),
                      const SizedBox(
                        height: 48,
                      ),
                    ],
                  )),
            ),
            backgroundColor: Colors.brown[100],
            body: busy
                ? const Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 8,
                        backgroundColor: Colors.amber,
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: ListView.builder(
                            itemCount: _projects.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  _navigateToFrequencyEditor(
                                      _projects.elementAt(index));
                                },
                                child: Card(
                                  elevation: 2,
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.home,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    title: Text(
                                      _projects.elementAt(index).name!,
                                      style: Styles.blackBoldSmall,
                                    ),
                                  ),
                                ),
                              );
                            }),
                      ),
                    ],
                  )));
  }

  void _navigateToFrequencyEditor(Project project) async {
    pp('$mm _navigateToFrequencyEditor: project.name: ${project.name}');
    var result = await Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.bottomRight,
            duration: const Duration(seconds: 1),
            child: FrequencyEditor(
              project: project,
              adminUser: _adminUser!,
              fieldUser: widget.user,
            )));
    if (result is bool) {
      pp('$mm Yebo Yes!!! schedule has been written to database 🍎');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scheduling for FieldMonitor saved')));

      }
    }
  }
}

class FrequencyEditor extends StatefulWidget {
  final Project project;
  final User adminUser, fieldUser;

  const FrequencyEditor({Key? key, required this.project, required this.adminUser, required this.fieldUser})
      : super(key: key);

  @override
  FrequencyEditorState createState() => FrequencyEditorState();
}

class FrequencyEditorState extends State<FrequencyEditor> {
  final _perDayController = TextEditingController(text: "3");
  final _perWeekController = TextEditingController(text: "0");
  final _perMonthController = TextEditingController(text: "0");
  bool busy = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text(
          'Project Monitoring Frequency',
          style: Styles.whiteSmall,
        ),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Column(
              children: [
                Text(
                  widget.fieldUser.name!,
                  style: Styles.blackBoldMedium,
                ),
                Text(
                  'FieldMonitor',
                  style: Styles.blackSmall,
                ),
                const SizedBox(
                  height: 48,
                ),
              ],
            )),
      ),
      backgroundColor: Colors.brown[100],
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          elevation: 16,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: busy
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 8,
                        backgroundColor: Colors.amber,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 20,
                        ),
                        Text(
                          '${widget.project.name}',
                          style: Styles.blackBoldMedium,
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Text(
                          'Project to be Monitored',
                          style: Styles.blackSmall,
                        ),
                        const SizedBox(
                          height: 28,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 28.0, right: 28),
                          child: SizedBox(
                            width: 300,
                            child: TextFormField(
                              controller: _perDayController,
                              keyboardType: TextInputType.number,
                              style: Styles.blackBoldMedium,
                              decoration: const InputDecoration(
                                icon: Icon(
                                  Icons.alarm,
                                  color: Colors.blue,
                                ),
                                hintText: 'Enter frequency per day',
                                labelText: 'Frequency Per Day',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 28.0, right: 28),
                          child: SizedBox(
                            width: 300,
                            child: TextFormField(
                              controller: _perWeekController,
                              keyboardType: TextInputType.number,
                              style: Styles.blackBoldMedium,
                              decoration: const InputDecoration(
                                icon: Icon(
                                  Icons.alarm,
                                  color: Colors.blue,
                                ),
                                hintText: 'Enter frequency per week',
                                labelText: 'Frequency Per Week',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 28.0, right: 28),
                          child: SizedBox(
                            width: 300,
                            child: TextFormField(
                              controller: _perMonthController,
                              keyboardType: TextInputType.number,
                              style: Styles.blackBoldMedium,
                              decoration: const InputDecoration(
                                icon: Icon(
                                  Icons.alarm,
                                  color: Colors.blue,
                                ),
                                hintText: 'Enter frequency per month',
                                labelText: 'Frequency Per Month',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                        ElevatedButton(
                            onPressed: () {
                              _doSubmit(
                                  perDay: _perDayController.text,
                                  perWeek: _perWeekController.text,
                                  perMonth: _perMonthController.text);
                            },
                            style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                textStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal)),
                            child: const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Text('Submit Schedule'),
                            )),
                        const SizedBox(
                          height: 48,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    ));
  }

  void _doSubmit({required String perDay, required String perWeek, required String perMonth}) async {
    pp('SchedulerMobile: ............. '
        '🍏 🍏 🍏 🍏 _doSubmit: ...perDay: $perDay perWeek: $perWeek perMonth: $perMonth');
    Uuid uuid = const Uuid();
    String id = uuid.v4();
    setState(() {
      busy = true;
    });
    try {
      int mPerDay = int.parse(perDay);
      int mPerWeek = int.parse(perWeek);
      int mPerMonth = int.parse(perMonth);

      var sc = FieldMonitorSchedule(
          fieldMonitorId: widget.fieldUser.userId,
          adminId: widget.adminUser.userId,
          projectId: widget.project.projectId,
          date: DateTime.now().toIso8601String(),
          organizationId: widget.project.organizationId,
          perDay: mPerDay,
          perWeek: mPerWeek,
          perMonth: mPerMonth,
          organizationName: widget.project.organizationName,
          projectName: widget.project.name,
          fieldMonitorScheduleId: id, userId: '');

      var result = await DataAPI.addFieldMonitorSchedule(sc);
      pp('SchedulerMobile: 🍏 🍏 🍏 🍏 RESULT: ${result.toJson()}');
      setState(() {
        busy = false;
      });
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      // AppSnackbar.showErrorSnackbar(
      //     scaffoldKey: widget.key, message: 'Scheduling failed: $e');
    }
    setState(() {
      busy = false;
    });
  }
}
