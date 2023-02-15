import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';

import '../../../data/photo.dart';
import '../../../data/project.dart';
import '../../../emojis.dart';
import '../../../functions.dart';
import '../../ratings/rating_adder_mobile.dart';

class FullPhotoMobile extends StatefulWidget {
  final Photo photo;
  final Project project;

  const FullPhotoMobile(
      {super.key, required this.photo, required this.project});

  @override
  FullPhotoMobileState createState() => FullPhotoMobileState();
}

class FullPhotoMobileState extends State<FullPhotoMobile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    _animationController = AnimationController(vsync: this);
    super.initState();
    if (widget.photo.landscape != null) {
      landscape = widget.photo.landscape!;
      if (landscape == 0) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeRight,
          DeviceOrientation.landscapeLeft,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      }
    } else {
      pp(widget.photo.toJson());
    }
  }

  int landscape = 1;

  @override
  void dispose() {
    _animationController.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _onFavorite() async {
    pp(' 😡😡😡 on favorite tapped - do da bizness! navigate to RatingAdder');

    Future.delayed(const Duration(milliseconds: 10), () {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.leftToRightWithFade,
              alignment: Alignment.topLeft,
              duration: const Duration(milliseconds: 1000),
              child: RatingAdderMobile(
                projectId: widget.project.projectId!,
                photoId: widget.photo.photoId!,
              )));
    });
  }

  @override
  Widget build(BuildContext context) {
    var height = 800.0;
    var width = 600.0;
    if (widget.photo.landscape == 0) {
      width = 800.0;
      height = 600.0;
    }
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: widget.photo.url!,
                  fadeInDuration: const Duration(milliseconds: 500),
                  fit: BoxFit.cover,
                  width: width,
                  height: height,
                  progressIndicatorBuilder: (context, url, downloadProgress) =>
                      Center(
                          child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  backgroundColor: Colors.white,
                                  value: downloadProgress.progress))),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: 2,
              child: Card(
                elevation: 8,
                color: Colors.black38,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0, bottom: 8, top: 8),
                  child: Row(
                    children: [
                      Text(
                        'Distance from Project',
                        style: GoogleFonts.lato(
                            textStyle: Theme.of(context).textTheme.bodySmall,
                            fontWeight: FontWeight.normal,
                            fontSize: 10),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Text(
                        widget.photo.distanceFromProjectPosition!
                            .toStringAsFixed(1),
                        style: GoogleFonts.lato(
                          textStyle: Theme.of(context).textTheme.bodySmall,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Text(
                        'metres',
                        style: GoogleFonts.lato(
                            textStyle: Theme.of(context).textTheme.bodySmall,
                            fontWeight: FontWeight.normal,
                            fontSize: 10),
                      ),
                      const SizedBox(
                        width: 28,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
                right: 12,
                top: 2,
                child: Card(
                  color: Colors.black12,
                  child: TextButton(
                    onPressed: _onFavorite,
                    child: Text(E.heartOrange),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
