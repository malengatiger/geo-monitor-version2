import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/photo.dart';
import '../../../functions.dart';

class FullPhotoMobile extends StatefulWidget {
  final Photo photo;

  const FullPhotoMobile({super.key, required this.photo});

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
        // appBar: AppBar(
        //   title: Text(
        //     '${widget.photo.projectName}',
        //     style: GoogleFonts.lato(
        //       textStyle: Theme.of(context).textTheme.bodySmall,
        //       fontWeight: FontWeight.w900,
        //     ),
        //   ),
        //   bottom: PreferredSize(
        //     preferredSize: const Size.fromHeight(8),
        //     child: Column(
        //       children: [
        //         Text(
        //           getFormattedDateLongWithTime(widget.photo.created!, context),
        //           style: GoogleFonts.lato(
        //             textStyle: Theme.of(context).textTheme.bodySmall,
        //             fontWeight: FontWeight.normal, fontSize: 10
        //           ),
        //         ),
        //         const SizedBox(
        //           height: 8,
        //         )
        //       ],
        //     ),
        //   ),
        // ),
        // backgroundColor: Colors.black,
        body: Stack(
          children: [
            GestureDetector(
              onTap: (){
                Navigator.of(context).pop();
              },
              child: CachedNetworkImage(
                imageUrl: widget.photo.url!,
                fadeInDuration: const Duration(milliseconds: 500),
                fit: BoxFit.cover, width: width, height: height,
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
                          fontWeight: FontWeight.normal, fontSize: 10
                        ),
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
                          fontWeight: FontWeight.normal, fontSize: 10
                        ),
                      ),
                      const SizedBox(
                        width: 28,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
