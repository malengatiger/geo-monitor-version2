import 'dart:async';

import 'package:badges/badges.dart' as bd;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:geo_monitor/library/bloc/fcm_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../bloc/project_bloc.dart';
import '../../../data/photo.dart';
import '../../../data/project.dart';
import '../../../functions.dart';

class ProjectPhotosTablet extends StatefulWidget {


  final Project project;
  final bool refresh;
  final Function(Photo) onPhotoTapped;

  const ProjectPhotosTablet({super.key, required this.project, required this.refresh, required this.onPhotoTapped});

  @override
  State<ProjectPhotosTablet> createState() => ProjectPhotosTabletState();
}

class ProjectPhotosTabletState extends State<ProjectPhotosTablet> with SingleTickerProviderStateMixin{
  late AnimationController _animationController;
  var photos = <Photo>[];
  bool loading = false;

  late StreamSubscription<Photo> photoStreamSubscriptionFCM;

  @override
  void initState() {
    _animationController = AnimationController(
        value: 0.0,
        duration: const Duration(milliseconds: 2000),
        vsync: this);
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
    return photos.isEmpty?  Center(
      child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0)),
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No photos in project'),
          )),
    ) :Column(
      children: [
        // SizedBox(
        //   height: 60,
        //   child: Padding(
        //     padding: const EdgeInsets.symmetric(vertical: 16.0),
        //     child: Text(widget.project.name!,
        //       style: myTextStyleMediumBold(context),),
        //   ),
        // ),
         Expanded(
            child: bd.Badge(
              position: bd.BadgePosition.topEnd(top: 4, end: 4),
              badgeStyle:  bd.BadgeStyle(
                badgeColor: Theme.of(context).primaryColor,
                elevation: 8, padding: const EdgeInsets.all(8),
              ),
              badgeContent: Text('${photos.length}', style: GoogleFonts.lato(
                textStyle: Theme.of(context).textTheme.bodySmall,
                fontWeight: FontWeight.normal, color: Colors.white, fontSize: 10
              ),),
              child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisSpacing: 1, crossAxisCount: 5, mainAxisSpacing: 1),
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    var photo = photos.elementAt(index);
                    // var dt =
                    // getFormattedDateShortestWithTime(photo.created!, context);

                    return Stack(
                      children: [
                        SizedBox(
                          width: 360,
                          child: GestureDetector(
                            onTap: () {
                              widget.onPhotoTapped(photo);
                            },
                            child: RotatedBox(
                              quarterTurns: photo.landscape == 0? 3:0,
                              child: CachedNetworkImage(
                                  imageUrl: photo.thumbnailUrl!, fit: BoxFit.cover),
                              // child: FadeInImage(placeholder: const AssetImage('assets/avatar.png'),
                              //     image: NetworkImage('${photo.thumbnailUrl}',)),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
            )),
      ],
    );
  }
}