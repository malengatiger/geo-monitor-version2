import 'package:flutter/material.dart';
import 'helpers.dart';

/*

 */
class MediaGrid extends StatelessWidget {
  final List<MediaBag> imageList;
  final MediaGridListener mediaGridListener;

  const MediaGrid(
      {Key? key, required this.imageList, required this.mediaGridListener})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    // return Container(
    //   margin: EdgeInsets.all(12),
    //   child: GridView.countBuilder(
    //       crossAxisCount: 2,
    //       crossAxisSpacing: 4,
    //       mainAxisSpacing: 4,
    //       itemCount: imageList.length,
    //       itemBuilder: (context, index) {
    //         var bag = imageList.elementAt(index);
    //         return GestureDetector(
    //           onTap: () {
    //             pp('MediaGrid:  🍎 🍎 🍎 : MediaBag tapped, telling listener: photo? ... ${bag.photo == null ? '' : bag.photo!.toJson()}');
    //             pp('MediaGrid:  🍎 🍎 🍎 : MediaBag tapped, telling listener: video? ... ${bag.video == null ? '' : bag.video!.toJson()}');
    //
    //             mediaGridListener.onMediaSelected(bag);
    //           },
    //           child: Container(
    //             decoration: const BoxDecoration(
    //                 color: Colors.transparent,
    //                 borderRadius: BorderRadius.all(Radius.circular(12))),
    //             child: ClipRRect(
    //               borderRadius: const BorderRadius.all(Radius.circular(12)),
    //               child: bag.photo != null
    //                   ? CachedNetworkImage(
    //                       placeholder: (_, __) => const Center(
    //                         child: CircularProgressIndicator(),
    //                       ),
    //                       imageUrl: bag.photo!.thumbnailUrl!,
    //                       fit: BoxFit.cover,
    //                       fadeInDuration: const Duration(milliseconds: 500),
    //                       fadeOutDuration: const Duration(milliseconds: 300),
    //                     )
    //                   : SizedBox(
    //                       width: 100,
    //                       height: 100,
    //                       child: Card(
    //                         elevation: 2,
    //                         child: Center(
    //                           child: Column(
    //                             children: [
    //                               const SizedBox(
    //                                 height: 8,
    //                               ),
    //                               IconButton(
    //                                   icon: Icon(
    //                                     Icons.videocam,
    //                                     color: Theme.of(context).primaryColor,
    //                                     size: 32,
    //                                   ),
    //                                   onPressed: () {
    //                                     pp('Video icon pressed: ${bag.video!.userName!}');
    //                                   }),
    //                               Text(
    //                                   getFormattedDateShortestWithTime(bag.video!.created!, context),
    //                                   style: Styles.blackTiny)
    //                             ],
    //                           ),
    //                         ),
    //                       )),
    //             ),
    //           ),
    //         );
    //       },
    //       staggeredTileBuilder: (index) {
    //         var mBag = imageList.elementAt(index);
    //         var mm = 1.2;
    //
    //           if (mBag.photo!.height! > mBag.photo!.width!) {
    //             mm = 1.6;
    //           } else {
    //             mm = 0.6;
    //           }
    //
    //
    //         return const SizedBox(); //StaggeredTile.count(1, mm);
    //       }),
    // );
    return Container(height: 200, color: Colors.red, );
  }
}

abstract class MediaGridListener {
  onMediaSelected(MediaBag mediaBag);
}
