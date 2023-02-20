import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../library/bloc/downloader.dart';
import '../../library/data/data_bag.dart';
import '../../library/functions.dart';

class DashboardGrid extends StatelessWidget {
  final mm = '🔵🔵🔵🔵 DashboardGrid:  🍎 ';
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
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SizedBox(
        height: totalHeight == null ? 900 : totalHeight!,
        child: Padding(
          padding: EdgeInsets.all(gridPadding),
          child: GridView.count(
            crossAxisCount: crossAxisCount,
            children: [
              GestureDetector(
                onTap: () {
                  pp('$mm widget on tapped: typeProjects $typeProjects ...');
                  onTypeTapped(typeProjects);
                },
                child: DashboardElement(
                  title: 'Projects',
                  topPadding: elementPadding,
                  number: dataBag.projects!.length,
                  onTapped: () {
                    onTypeTapped(typeProjects);
                  },
                ),
              ),
              GestureDetector(
                onTap: () {
                  pp('$mm widget on tapped: typeUsers $typeUsers ...');

                  onTypeTapped(typeUsers);
                },
                child: DashboardElement(
                  title: 'Members',
                  number: dataBag.users!.length,
                  topPadding: elementPadding,
                  onTapped: () {
                    onTypeTapped(typeUsers);
                  },
                ),
              ),
              GestureDetector(
                onTap: () {
                  pp('$mm widget on tapped: typePhotos $typePhotos ...');

                  onTypeTapped(typePhotos);
                },
                child: DashboardElement(
                  title: 'Photos',
                  number: dataBag.photos!.length,
                  topPadding: elementPadding,
                  textStyle: GoogleFonts.secularOne(
                      textStyle: Theme.of(context).textTheme.titleLarge,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).primaryColor),
                  onTapped: () {
                    onTypeTapped(typePhotos);
                  },
                ),
              ),
              GestureDetector(
                onTap: () {
                  pp('$mm widget on tapped: typeVideos $typeVideos ...');

                  onTypeTapped(typeVideos);
                },
                child: DashboardElement(
                  title: 'Videos',
                  topPadding: elementPadding,
                  number: dataBag.videos!.length,
                  onTapped: () {
                    onTypeTapped(typeVideos);
                  },
                ),
              ),
              GestureDetector(
                onTap: () {
                  pp('$mm widget on tapped: typeAudios $typeAudios ...');

                  onTypeTapped(typeAudios);
                },
                child: DashboardElement(
                  title: 'Audio Clips',
                  topPadding: elementPadding,
                  number: dataBag.audios!.length,
                  textStyle: GoogleFonts.secularOne(
                      textStyle: Theme.of(context).textTheme.titleLarge,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).primaryColor),
                  onTapped: () {
                    onTypeTapped(typeAudios);
                  },
                ),
              ),
              GestureDetector(
                onTap: () {
                  pp('$mm widget on tapped: typePositions $typePositions ...');

                  onTypeTapped(typePositions);
                },
                child: DashboardElement(
                  title: 'Locations',
                  topPadding: elementPadding,
                  number: dataBag.projectPositions!.length,
                  onTapped: () {
                    onTypeTapped(typePositions);
                  },
                ),
              ),
              GestureDetector(
                onTap: () {
                  pp('$mm widget on tapped: typePolygons $typePolygons ...');

                  onTypeTapped(typePolygons);
                },
                child: DashboardElement(
                  title: 'Areas',
                  topPadding: elementPadding,
                  number: dataBag.projectPolygons!.length,
                  textStyle: GoogleFonts.secularOne(
                      textStyle: Theme.of(context).textTheme.titleLarge,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).primaryColor),
                  onTapped: () {
                    onTypeTapped(typePolygons);
                  },
                ),
              ),
              GestureDetector(
                onTap: () {
                  pp('$mm widget on tapped: typeSchedules $typeSchedules ...');

                  onTypeTapped(typeSchedules);
                },
                child: DashboardElement(
                  title: 'Schedules',
                  topPadding: elementPadding,
                  number: dataBag.fieldMonitorSchedules!.length,
                  onTapped: () {
                    onTypeTapped(typeSchedules);
                  },
                ),
              ),
            ],
          ),
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
          height: height == null ? 240 : height!,
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
