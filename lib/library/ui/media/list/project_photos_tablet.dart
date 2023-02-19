import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geo_monitor/library/bloc/fcm_bloc.dart';
import 'package:geo_monitor/library/ui/media/photo_grid.dart';

import '../../../bloc/project_bloc.dart';
import '../../../data/photo.dart';
import '../../../data/project.dart';
import '../../../functions.dart';

class ProjectPhotosTablet extends StatefulWidget {
  final Project project;
  final bool refresh;
  final Function(Photo) onPhotoTapped;

  const ProjectPhotosTablet(
      {super.key,
      required this.project,
      required this.refresh,
      required this.onPhotoTapped});

  @override
  State<ProjectPhotosTablet> createState() => ProjectPhotosTabletState();
}

class ProjectPhotosTabletState extends State<ProjectPhotosTablet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  var photos = <Photo>[];
  bool loading = false;

  late StreamSubscription<Photo> photoStreamSubscriptionFCM;

  @override
  void initState() {
    _animationController = AnimationController(
        value: 0.0, duration: const Duration(milliseconds: 2000), vsync: this);
    super.initState();
    _subscribeToStreams();
    _getPhotos();
  }

  @override
  void dispose() {
    _animationController.dispose();
    photoStreamSubscriptionFCM.cancel();
    super.dispose();
  }

  void _subscribeToStreams() async {
    photoStreamSubscriptionFCM = fcmBloc.photoStream.listen((event) async {
      if (mounted) {
        _getPhotos();
      }
    });
  }

  Future _getPhotos() async {
    setState(() {
      loading = true;
    });
    try {
      photos = await projectBloc.getPhotos(
          projectId: widget.project.projectId!, forceRefresh: widget.refresh);
      photos.sort((a, b) => b.created!.compareTo(a.created!));
    } catch (e) {
      pp(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return photos.isEmpty
        ? Center(
            child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0)),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No photos in project yet ...'),
                )),
          )
        : PhotoGrid(
            photos: photos,
            crossAxisCount: 5,
            onPhotoTapped: (photo) {
              widget.onPhotoTapped(photo);
            },
            badgeColor: Colors.indigo);
  }
}
