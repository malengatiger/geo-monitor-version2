import 'package:badges/badges.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../bloc/project_bloc.dart';
import '../../../data/photo.dart';
import '../../../data/project.dart';
import '../../../functions.dart';

class ProjectPhotos extends StatefulWidget {


  final Project project;
  final bool refresh;
  final Function(Photo) onPhotoTapped;

  const ProjectPhotos({super.key, required this.project, required this.refresh, required this.onPhotoTapped});

  @override
  State<ProjectPhotos> createState() => ProjectPhotosState();
}

class ProjectPhotosState extends State<ProjectPhotos> with SingleTickerProviderStateMixin{
  late AnimationController _animationController;
  var photos = <Photo>[];
  bool loading = false;
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
    super.dispose();
  }

  void _subscribeToStreams() async {}
  void _getPhotos() async {
    setState(() {
      loading = true;
    });
    try {
      var bag = await projectBloc.refreshProjectData(
          projectId: widget.project.projectId!, forceRefresh: widget.refresh);
      photos = bag.photos!;
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
        SizedBox(
          height: 60,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(widget.project.name!,
              style: myTextStyleMediumBold(context),),
          ),
        ),
         Expanded(
            child: Badge(
              position: BadgePosition.topEnd(top: 4, end: 4),
              padding: const EdgeInsets.all(12.0),
              badgeContent: Text('${photos.length}', style: GoogleFonts.lato(
                textStyle: Theme.of(context).textTheme.bodySmall,
                fontWeight: FontWeight.normal, color: Colors.white, fontSize: 10
              ),),
              badgeColor: Colors.pink,
              elevation: 16,
              child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisSpacing: 1, crossAxisCount: 2, mainAxisSpacing: 1),
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