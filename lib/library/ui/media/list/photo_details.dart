import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/photo.dart';
import '../../../functions.dart';

class PhotoDetails extends StatelessWidget {
  const PhotoDetails({Key? key, required this.photo, required this.onClose})
      : super(key: key);
  final Photo photo;
  final Function onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      // height: 420,
      child: Card(
        elevation: 8,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                      onPressed: () {
                        onClose();
                      },
                      icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(
                height: 2,
              ),
              Text(
                photo.projectName!,
                style: GoogleFonts.lato(
                    textStyle: Theme.of(context).textTheme.bodySmall,
                    fontWeight: FontWeight.normal,
                    fontSize: 12),
              ),
              const SizedBox(
                height: 0,
              ),
              Text(
                getFormattedDateShortWithTime(photo.created!, context),
                style: GoogleFonts.lato(
                  textStyle: Theme.of(context).textTheme.bodyMedium,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(
                width: 240,
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0)),
                  child: RotatedBox(
                    quarterTurns: photo.landscape == 0? 3:0,
                    child: CachedNetworkImage(
                        fit: BoxFit.cover,
                        fadeInCurve: Curves.easeIn,
                        fadeInDuration: const Duration(milliseconds: 1000),
                        imageUrl: photo.thumbnailUrl!),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
