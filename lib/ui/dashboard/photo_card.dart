import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../library/data/photo.dart';
import '../../library/data/user.dart';
import '../../library/emojis.dart';
import '../../library/functions.dart';

class PhotoCard extends StatelessWidget {
  const PhotoCard(
      {Key? key,
        required this.photo,
        required this.onMapRequested,
        required this.onRatingRequested, required this.elevation, required this.onPhotoCardClose})
      : super(key: key);

  final Photo photo;
  final Function(Photo) onMapRequested;
  final Function(Photo) onRatingRequested;
  final Function onPhotoCardClose;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: getRoundedBorder(radius: 16),
      elevation: elevation,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(
              height: 12,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                      onPressed: () {
                        onMapRequested(photo);
                      },
                      icon: Icon(
                        Icons.location_on,
                        color: Theme.of(context).primaryColor,
                        size: 18,
                      )),
                  TextButton(
                    onPressed: () {
                      onRatingRequested(photo);
                    },
                    child: Text(
                      E.heartRed,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  IconButton(
                      onPressed: () {
                        onPhotoCardClose();
                      },
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                      )),
                ],
              ),
            ),
            const SizedBox(
              height: 8,
            ),

            Text(
              '${photo.projectName}',
              style: myTextStyleLargePrimaryColor(context),
            ),
            const SizedBox(
              height: 24,
            ),

            Text(
              '${photo.userName}',
              style: myTextStyleSmallBold(context),
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              getFormattedDateShortWithTime(photo.created!, context),
              style: myTextStyleTiny(context),
            ),
            const SizedBox(
              height: 12,
            ),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
              child: InteractiveViewer(
                  child: CachedNetworkImage(
                      fit: BoxFit.fill,
                      progressIndicatorBuilder:
                          (context, url, downloadProgress) => Center(
                          child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  backgroundColor: Colors.pink,
                                  value: downloadProgress.progress))),
                      errorWidget: (context, url, error) =>
                      const Icon(Icons.error),
                      fadeInDuration: const Duration(milliseconds: 1500),
                      fadeInCurve: Curves.easeInOutCirc,
                      placeholderFadeInDuration:
                      const Duration(milliseconds: 1500),
                      imageUrl: photo.url!)),
            ),
            const SizedBox(
              height: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class Headline extends StatelessWidget {
  const Headline({Key? key, required this.user, required this.paddingLeft})
      : super(key: key);
  final User user;
  final double paddingLeft;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Column(
        children: [
          const SizedBox(
            height: 12,
          ),
          user.organizationName == null
              ? const SizedBox()
              : Text(
            '${user.organizationName}',
            style: GoogleFonts.lato(
                textStyle: Theme.of(context).textTheme.bodyLarge,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).primaryColor,
                fontSize: 20),
          ),
          const SizedBox(
            height: 24,
          ),
          Padding(
            padding: EdgeInsets.only(left: paddingLeft),
            child: Row(
              children: [
                user.thumbnailUrl == null
                    ? const CircleAvatar(
                  radius: 24,
                )
                    : CircleAvatar(
                  backgroundImage: NetworkImage(user.thumbnailUrl!),
                  radius: 24,
                ),
                const SizedBox(
                  width: 28,
                ),
                Text(
                  '${user.name}',
                  style: myTextStyleMediumBold(context),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 0,
          ),
        ],
      ),
    );
  }
}