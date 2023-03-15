import 'package:flutter/material.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/translation_handler.dart';
import '../../library/bloc/downloader.dart';
import '../../library/data/data_bag.dart';
import '../../library/functions.dart';

class DashboardGrid extends StatefulWidget {
  final Function(int) onTypeTapped;
  final double? totalHeight;
  final double? topPadding, elementPadding;
  final double? leftPadding;
  final DataBag dataBag;
  final double gridPadding;
  final int crossAxisCount;

  const DashboardGrid(
      {super.key,
      required this.onTypeTapped,
      this.totalHeight,
      this.topPadding,
      this.elementPadding,
      this.leftPadding,
      required this.dataBag,
      required this.gridPadding,
      required this.crossAxisCount});

  @override
  State<DashboardGrid> createState() => _DashboardGridState();
}

class _DashboardGridState extends State<DashboardGrid> {
  final mm = '🔵🔵🔵🔵 DashboardGrid:  🍎 ';

  String? projects, members, photos,
      videos, audios, areas, locations, schedules, audioClips;
  @override
  void initState() {
    super.initState();
    _setTitles();
  }
  void _setTitles() async {
    var sett = await prefsOGx.getSettings();
    projects = await mTx.translate('projects', sett!.locale!);
    members = await mTx.translate('members', sett.locale!);
    photos = await mTx.translate('photos', sett.locale!);
    audioClips = await mTx.translate('audioClips', sett.locale!);
    locations = await mTx.translate('locations', sett.locale!);
    areas = await mTx.translate('areas', sett.locale!);
    schedules = await mTx.translate('schedules', sett.locale!);
    setState(() {

    });
  }
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // height: totalHeight == null ? 1000 : totalHeight!,
      child: Padding(
        padding: EdgeInsets.all(widget.gridPadding),
        child: GridView.count(
          crossAxisCount: widget.crossAxisCount,
          children: [
            GestureDetector(
              onTap: () {
                pp('$mm widget on tapped: typeProjects $typeProjects ...');
                widget.onTypeTapped(typeProjects);
              },
              child: DashboardElement(
                title: projects == null? 'Projects':projects!,
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
                title: members == null? 'Members': members!,
                number: widget.dataBag.users!.length,
                topPadding: widget.elementPadding,
                onTapped: () {
                  widget.onTypeTapped(typeUsers);
                },
              ),
            ),
            GestureDetector(
              onTap: () {
                pp('$mm widget on tapped: typePhotos $typePhotos ...');

                widget.onTypeTapped(typePhotos);
              },
              child: DashboardElement(
                title: photos == null?'Photos':photos!,
                number: widget.dataBag.photos!.length,
                topPadding: widget.elementPadding,
                textStyle: GoogleFonts.secularOne(
                    textStyle: Theme.of(context).textTheme.titleLarge,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).primaryColor),
                onTapped: () {
                  widget.onTypeTapped(typePhotos);
                },
              ),
            ),
            GestureDetector(
              onTap: () {
                pp('$mm widget on tapped: typeVideos $typeVideos ...');

                widget.onTypeTapped(typeVideos);
              },
              child: DashboardElement(
                title: videos == null? 'Videos':videos!,
                topPadding: widget.elementPadding,
                number: widget.dataBag.videos!.length,
                textStyle: GoogleFonts.secularOne(
                    textStyle: Theme.of(context).textTheme.titleLarge,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).primaryColor),
                onTapped: () {
                  widget.onTypeTapped(typeVideos);
                },
              ),
            ),
            GestureDetector(
              onTap: () {
                pp('$mm widget on tapped: typeAudios $typeAudios ...');

                widget.onTypeTapped(typeAudios);
              },
              child: DashboardElement(
                title: audioClips == null? 'Audio Clips': audioClips!,
                topPadding: widget.elementPadding,
                number: widget.dataBag.audios!.length,
                textStyle: GoogleFonts.secularOne(
                    textStyle: Theme.of(context).textTheme.titleLarge,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).primaryColor),
                onTapped: () {
                  widget.onTypeTapped(typeAudios);
                },
              ),
            ),
            GestureDetector(
              onTap: () {
                pp('$mm widget on tapped: typePositions $typePositions ...');

                widget.onTypeTapped(typePositions);
              },
              child: DashboardElement(
                title: locations == null? 'Locations': locations!,
                topPadding: widget.elementPadding,
                number: widget.dataBag.projectPositions!.length,
                onTapped: () {
                  widget.onTypeTapped(typePositions);
                },
              ),
            ),
            GestureDetector(
              onTap: () {
                pp('$mm widget on tapped: typePolygons $typePolygons ...');

                widget.onTypeTapped(typePolygons);
              },
              child: DashboardElement(
                title: areas == null? 'Areas': areas!,
                topPadding: widget.elementPadding,
                number: widget.dataBag.projectPolygons!.length,

                onTapped: () {
                  widget.onTypeTapped(typePolygons);
                },
              ),
            ),
            GestureDetector(
              onTap: () {
                pp('$mm widget on tapped: typeSchedules $typeSchedules ...');

                widget.onTypeTapped(typeSchedules);
              },
              child: DashboardElement(
                title: 'Schedules',
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

class DashboardElement extends StatelessWidget {
  const DashboardElement(
      {Key? key,
      required this.number,
      required this.title,
      this.height,
      this.topPadding,
      this.textStyle,
      this.labelTitleStyle,
      required this.onTapped})
      : super(key: key);
  final int number;
  final String title;
  final double? height, topPadding;
  final TextStyle? textStyle, labelTitleStyle;
  final Function() onTapped;

  @override
  Widget build(BuildContext context) {

    var style = GoogleFonts.secularOne(
        textStyle: Theme.of(context).textTheme.titleLarge,
        fontWeight: FontWeight.w900);

    return GestureDetector(
      onTap: () {
        onTapped();
      },
      child: Card(
        shape: getRoundedBorder(radius: 16),
        child: SizedBox(
          height: height == null ? 260 : height!,
          child: Center(
            child: Column(
              children: [
                SizedBox(
                  height: topPadding == null ? 72 : topPadding!,
                ),
                Text('$number', style: textStyle == null ? style : textStyle!),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  title,
                  style: Styles.greyLabelSmall,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Life extends StatelessWidget {
  const Life({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
