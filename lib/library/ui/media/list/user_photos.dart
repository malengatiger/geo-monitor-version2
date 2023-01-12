import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../bloc/user_bloc.dart';
import '../../../data/photo.dart';
import '../../../data/user.dart';
import '../../../functions.dart';

class UserPhotos extends StatefulWidget {


  final User user;
  final bool refresh;
  final Function(Photo) onPhotoTapped;

  const UserPhotos({super.key, required this.user, required this.refresh, required this.onPhotoTapped});


  @override
  State<UserPhotos> createState() => UserPhotosState();
}

class UserPhotosState extends State<UserPhotos> {
  var photos = <Photo>[];
  bool loading = false;
  @override
  void initState() {
    super.initState();
    _subscribeToStreams();
    _getPhotos();
  }

  void _subscribeToStreams() async {}
  void _getPhotos() async {
    setState(() {
      loading = true;
    });
    photos = await userBloc.getPhotos(
        userId: widget.user.userId!, forceRefresh: widget.refresh);
    photos.sort((a,b) => b.created!.compareTo(a.created!));
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.blue,
          height: 1,
        ),
        Expanded(
            child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisSpacing: 1, crossAxisCount: 2, mainAxisSpacing: 1),
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  var photo = photos.elementAt(index);
                  var dt =
                  getFormattedDateShortestWithTime(photo.created!, context);
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
                          ),
                        ),
                      ),
                      // Positioned(
                      //   child: Container(
                      //     color: Colors.black38,
                      //     child: Padding(
                      //       padding: const EdgeInsets.all(8.0),
                      //       child: Text(
                      //         dt,
                      //         style: GoogleFonts.lato(
                      //             textStyle:
                      //                 Theme.of(context).textTheme.bodySmall,
                      //             fontWeight: FontWeight.normal,
                      //             fontSize: 10),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      // Positioned(
                      //   bottom: 8, left: 0,
                      //   child: Container(
                      //     color: Colors.black38,
                      //     child: Row(
                      //       mainAxisAlignment: MainAxisAlignment.center,
                      //       children: [
                      //         Padding(
                      //           padding: const EdgeInsets.all(8.0),
                      //           child: Text(
                      //             photo.projectName!,
                      //             overflow: TextOverflow.ellipsis,
                      //             style: GoogleFonts.lato(
                      //                 textStyle:
                      //                 Theme.of(context).textTheme.bodySmall,
                      //                 fontWeight: FontWeight.normal,
                      //                 fontSize: 11),
                      //           ),
                      //         ),
                      //       ],
                      //     ),
                      //   ),
                      // ),
                    ],
                  );
                })),
      ],
    );
  }
}