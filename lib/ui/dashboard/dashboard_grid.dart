import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geo_monitor/library/bloc/fcm_bloc.dart';
import 'package:geo_monitor/ui/dashboard/project_dashboard_mobile.dart';

import '../../library/bloc/downloader.dart';
import '../../library/data/data_bag.dart';
import '../../library/data/settings_model.dart';
import '../../library/functions.dart';
import 'dashboard_element.dart';

class DashboardGrid extends StatefulWidget {
  final Function(int) onTypeTapped;
  final double? totalHeight;
  final double? topPadding, elementPadding;
  final double? leftPadding;
  final DataBag dataBag;
  final double gridPadding;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const DashboardGrid(
      {super.key,
      required this.onTypeTapped,
      this.totalHeight,
      this.topPadding,
      this.elementPadding,
      this.leftPadding,
      required this.dataBag,
      required this.gridPadding,
      required this.crossAxisCount, required this.crossAxisSpacing, required this.mainAxisSpacing});

  @override
  State<DashboardGrid> createState() => _DashboardGridState();
}

class _DashboardGridState extends State<DashboardGrid> {
  final mm = '🔵🔵🔵🔵DashboardGrid:  🍎 ';

  // String? projects, members, photos,
  //     videos, audios, areas, locations, schedules, audioClips;
  late StreamSubscription<SettingsModel> settingsSubscription;
  SettingsModel? settingsModel;
  DashboardStrings? dashboardStrings;

  @override
  void initState() {
    super.initState();
    _listen();
    _setTexts();
  }
  @override
  void dispose() {
    settingsSubscription.cancel();
    super.dispose();
  }

  Future _setTexts() async {

    dashboardStrings = await DashboardStrings.getTranslated();
    // settingsModel = await prefsOGx.getSettings();
    // projects = await mTx.translate('projects', settingsModel!.locale!);
    // members = await mTx.translate('members', settingsModel!.locale!);
    // areas = await mTx.translate('areas', settingsModel!.locale!);
    // schedules = await mTx.translate('schedules', settingsModel!.locale!);
    // videos = await mTx.translate('videos', settingsModel!.locale!);
    // audioClips = await mTx.translate('audioClips', settingsModel!.locale!);
    // locations = await mTx.translate('locations', settingsModel!.locale!);

    setState(() {

    });
  }

  void _listen() async {
    settingsSubscription =
        fcmBloc.settingsStream.listen((SettingsModel settings) async {
          pp('$mm settingsStream delivered settings ... ${settings.locale!}, will set titles');
          settingsModel = settings;
          await _setTexts();
          if (mounted) {
            setState(() {});
          }
        });
  }
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // height: totalHeight == null ? 1000 : totalHeight!,
      child: Padding(
        padding: EdgeInsets.all(widget.gridPadding),
        child: dashboardStrings == null? const SizedBox(): GridView.count(
          crossAxisCount: widget.crossAxisCount,
          crossAxisSpacing: widget.crossAxisSpacing,
          mainAxisSpacing: widget.mainAxisSpacing,
          children: [
            GestureDetector(
              onTap: () {
                widget.onTypeTapped(typeProjects);
              },
              child: DashboardElement(
                title: dashboardStrings!.projects,
                topPadding: widget.elementPadding,
                number: widget.dataBag.projects!.length,
                onTapped: () {
                  widget.onTypeTapped(typeProjects);
                },
              ),
            ),
            GestureDetector(
              onTap: () {
                pp('$mm widget on tapped: typeUsers $typeUsers ...');

                widget.onTypeTapped(typeUsers);
              },
              child: DashboardElement(
                title: dashboardStrings!.members,
                number: widget.dataBag.users!.length,
                topPadding: widget.elementPadding,
                onTapped: () {
                  widget.onTypeTapped(typeUsers);
                },
              ),
            ),
            GestureDetector(
              onTap: () {
                widget.onTypeTapped(typePhotos);
              },
              child: DashboardElement(
                title: dashboardStrings!.photos,
                number: widget.dataBag.photos!.length,
                topPadding: widget.elementPadding,
                textStyle: myNumberStyleLargePrimaryColor(context),
                onTapped: () {
                  widget.onTypeTapped(typePhotos);
                },
              ),
            ),
            GestureDetector(
              onTap: () {
                widget.onTypeTapped(typeVideos);
              },
              child: DashboardElement(
                title: dashboardStrings!.videos,
                topPadding: widget.elementPadding,
                number: widget.dataBag.videos!.length,
                textStyle: myNumberStyleLargePrimaryColor(context),
                onTapped: () {
                  widget.onTypeTapped(typeVideos);
                },
              ),
            ),
            GestureDetector(
              onTap: () {
                widget.onTypeTapped(typeAudios);
              },
              child: DashboardElement(
                title: dashboardStrings!.audioClips,
                topPadding: widget.elementPadding,
                number: widget.dataBag.audios!.length,
                textStyle: myNumberStyleLargePrimaryColor(context),
                onTapped: () {
                  widget.onTypeTapped(typeAudios);
                },
              ),
            ),
            GestureDetector(
              onTap: () {
                widget.onTypeTapped(typePositions);
              },
              child: DashboardElement(
                title: dashboardStrings!.locations,
                topPadding: widget.elementPadding,
                number: widget.dataBag.projectPositions!.length,
                onTapped: () {
                  widget.onTypeTapped(typePositions);
                },
              ),
            ),
            GestureDetector(
              onTap: () {
                widget.onTypeTapped(typePolygons);
              },
              child: DashboardElement(
                title: dashboardStrings!.areas,
                topPadding: widget.elementPadding,
                number: widget.dataBag.projectPolygons!.length,

                onTapped: () {
                  widget.onTypeTapped(typePolygons);
                },
              ),
            ),
            GestureDetector(
              onTap: () {
                widget.onTypeTapped(typeSchedules);
              },
              child: DashboardElement(
                title: dashboardStrings!.schedules,
                topPadding: widget.elementPadding,
                number: widget.dataBag.fieldMonitorSchedules!.length,
                onTapped: () {
                  widget.onTypeTapped(typeSchedules);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


