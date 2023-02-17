import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geo_monitor/library/hive_util.dart';
import 'package:uuid/uuid.dart';

import '../../../device_location/device_location_bloc.dart';
import '../../api/data_api.dart';
import '../../api/prefs_og.dart';
import '../../data/position.dart';
import '../../data/project.dart';
import '../../data/rating.dart';
import '../../functions.dart';
import '../../generic_functions.dart';

class RatingAdderMobile extends StatefulWidget {
  const RatingAdderMobile(
      {Key? key,
      required this.projectId,
      this.audioId,
      this.videoId,
      this.photoId})
      : super(key: key);

  final String projectId;
  final String? audioId, videoId, photoId;

  @override
  RatingAdderMobileState createState() => RatingAdderMobileState();
}

class RatingAdderMobileState extends State<RatingAdderMobile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool busy = false;
  final mm = '🌀🌀🌀🌀Rating Adder: ';
  Project? project;
  @override
  void initState() {
    _animationController = AnimationController(vsync: this);
    super.initState();
    _checkMedia();
    _getProject();
  }

  void _getProject() async {
    project = await cacheManager.getProjectById(projectId: widget.projectId);
    setState(() {});
  }

  void _checkMedia() {
    if (widget.videoId == null &&
        widget.audioId == null &&
        widget.photoId == null) {
      throw Exception('You need one of audio, video or photo id');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text(
          'Project Rating',
          style: myTextStyleSmall(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            left: 24,
            right: 24,
            top: 80,
            bottom: 80,
            child: Card(
              elevation: 4,
              shape: getRoundedBorder(radius: 16),
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 100,
                    ),
                    project == null
                        ? const SizedBox()
                        : Text(
                            '${project!.name}',
                            style: myTextStyleMediumBold(context),
                          ),
                    const SizedBox(
                      height: 60,
                    ),
                    RatingBar.builder(
                      initialRating: 1,
                      minRating: 1,
                      maxRating: 5,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemSize: 40,
                      glow: true,
                      glowColor: Colors.teal,
                      glowRadius: 8,
                      itemCount: 5,
                      itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                      itemBuilder: (context, _) => Icon(
                        Icons.star,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      onRatingUpdate: (rating) {
                        pp('$mm $rating is the rating picked!');
                        _rating = rating;
                      },
                    ),
                    const SizedBox(
                      height: 60,
                    ),
                    busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 4,
                              backgroundColor: Colors.pink,
                            ),
                          )
                        : TextButton(
                            onPressed: _submitRating,
                            child: const Text('Send Rating')),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    ));
  }

  double _rating = 1.0;

  Future<void> _submitRating() async {
    pp('$mm _submitRating ....');
    setState(() {
      busy = true;
    });
    try {
      var user = await prefsOGx.getUser();
      var loc = await locationBloc.getLocation();
      if (loc != null) {
        var rating = Rating(
            remarks: null,
            created: DateTime.now().toUtc().toIso8601String(),
            position: Position(
                coordinates: [loc.longitude, loc.latitude], type: 'Point'),
            userId: user!.userId,
            userName: user.name,
            ratingCode: _rating.round(),
            projectId: widget.projectId,
            audioId: widget.audioId,
            videoId: widget.videoId,
            photoId: widget.photoId,
            ratingId: const Uuid().v4(),
            organizationId: project!.organizationId,
            projectName: project!.name);

        var res = await DataAPI.addRating(rating);
        pp('$mm rating added; ${res.toJson()}');
        if (mounted) {
          showToast(
              textStyle: myTextStyleMedium(context),
              padding: 8,
              duration: const Duration(seconds: 3),
              toastGravity: ToastGravity.TOP,
              backgroundColor: Theme.of(context).primaryColor,
              message: "Rating added, thank you!",
              context: context);
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      pp(e);
      if (mounted) {
        showToast(message: '$e', context: context);
      }
    }

    setState(() {
      busy = false;
    });
  }
}
