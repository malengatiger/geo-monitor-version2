import 'dart:ui';

import 'package:adobe_xd/page_link.dart';
import 'package:adobe_xd/pinned.dart';
import 'package:flutter/material.dart';
import 'package:geo_monitor/library/functions.dart';

import 'GIOProjects.dart';
import 'GIORECENTEVENTS.dart';

class GIODASHBOARD extends StatelessWidget {
  const GIODASHBOARD({
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gio', style: myTextStyleLarge(context),),
        actions: [
          IconButton(onPressed: (){}, icon: const Icon(Icons.refresh))
        ],
      ),
      backgroundColor: const Color(0xffffffff),
      body: Stack(
        children:  <Widget>[
          Pinned.fromPins(
            Pin(start: 0.0, end: 0.0),
            Pin(size: 995.0, start: 102.0),
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xffffffff),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x26ffffff),
                        offset: Offset(0, 0.33000001311302185),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Pinned.fromPins(
            Pin(size: 174.0, start: 16.0),
            Pin(size: 40.0, start: 132.0),
            child: const Text(
              'Dashboard',
              style: TextStyle(
                fontFamily: 'SF Pro',
                fontSize: 34,
                color: Color(0xff424343),
                fontWeight: FontWeight.w700,
              ),
              softWrap: false,
            ),
          ),
          Pinned.fromPins(
            Pin(size: 147.0, start: 16.0),
            Pin(size: 24.0, start: 192.0),
            child: Stack(
              children: <Widget>[
                Pinned.fromPins(
                  Pin(startFraction: 0.0, endFraction: 0.1088),
                  Pin(size: 24.0, middle: 0.5),
                  child: PageLink(
                    links: [
                      PageLinkInfo(
                        ease: Curves.easeOut,
                        duration: 0.3,
                        pageBuilder: () => GIORECENTEVENTS(),
                      ),
                    ],
                    child: const Text(
                      'Recent Events',
                      style: TextStyle(
                        fontFamily: 'SF Pro',
                        fontSize: 20,
                        color: Color(0xff424343),
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      textHeightBehavior:
                      TextHeightBehavior(applyHeightToFirstAscent: false),
                      softWrap: false,
                    ),
                  ),
                ),
                Pinned.fromPins(
                  Pin(size: 13.0, start: 134.0),
                  Pin(size: 21.0, middle: 0.6667),
                  child: Transform.rotate(
                    angle: 3.1416,
                    child: const Text(
                      '􀆉',
                      style: TextStyle(
                        fontFamily: 'SF Pro',
                        fontSize: 18,
                        color: Color(0xfe00a6ed),
                        fontWeight: FontWeight.w500,
                        height: 1,
                      ),
                      textHeightBehavior:
                      TextHeightBehavior(applyHeightToFirstAscent: false),
                      softWrap: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Pinned.fromPins(
          //   Pin(start: 16.0, end: 0.0),
          //   Pin(size: 46.0, start: 228.0),
          //   child: SingleChildScrollView(
          //     primary: false,
          //     scrollDirection: Axis.horizontal,
          //     child: SizedBox(
          //       width: 1212.0,
          //       height: 46.0,
          //       child: Stack(
          //         children: <Widget>[
          //           Padding(
          //             padding: const EdgeInsets.fromLTRB(0.0, 0.0, -835.0, 0.0),
          //             child: GridView.count(
          //               mainAxisSpacing: 20,
          //               crossAxisSpacing: 8,
          //               crossAxisCount: 7,
          //               childAspectRatio: 3.59,
          //               children:
          //                   [{}, {}, {}, {}, {}, {}, {}, {}].map((itemData) {
          //                 return Stack(
          //                   children: <Widget>[
          //                     Container(
          //                       decoration: BoxDecoration(
          //                         color: const Color(0xfff4f3ee),
          //                         borderRadius: BorderRadius.circular(10.0),
          //                       ),
          //                     ),
          //                     Align(
          //                       alignment: Alignment(0.315, 0.0),
          //                       child: SizedBox(
          //                         width: 92.0,
          //                         height: 30.0,
          //                         child: Stack(
          //                           children: <Widget>[
          //                             Pinned.fromPins(
          //                               Pin(
          //                                   startFraction: 0.0,
          //                                   endFraction: 0.087),
          //                               Pin(size: 14.0, middle: 0.0),
          //                               child: const Text(
          //                                 'NY Cab Repair',
          //                                 style: TextStyle(
          //                                   fontFamily: 'SF Pro',
          //                                   fontSize: 12,
          //                                   color: Color(0xff424343),
          //                                   fontWeight: FontWeight.w500,
          //                                   height: 1.3333333333333333,
          //                                 ),
          //                                 textHeightBehavior:
          //                                     TextHeightBehavior(
          //                                         applyHeightToFirstAscent:
          //                                             false),
          //                                 softWrap: false,
          //                               ),
          //                             ),
          //                             Pinned.fromPins(
          //                               Pin(
          //                                   startFraction: 0.0,
          //                                   endFraction: 0.0),
          //                               Pin(size: 14.0, middle: 1.0),
          //                               child: const Text(
          //                                 '25 seconds ago',
          //                                 style: TextStyle(
          //                                   fontFamily: 'SF Pro',
          //                                   fontSize: 12,
          //                                   color: Color(0x67424343),
          //                                   fontWeight: FontWeight.w500,
          //                                   height: 1.3333333333333333,
          //                                 ),
          //                                 textHeightBehavior:
          //                                     TextHeightBehavior(
          //                                         applyHeightToFirstAscent:
          //                                             false),
          //                                 softWrap: false,
          //                               ),
          //                             ),
          //                           ],
          //                         ),
          //                       ),
          //                     ),
          //                     Pinned.fromPins(
          //                       Pin(size: 32.0, start: 8.0),
          //                       Pin(size: 32.0, middle: 0.5),
          //                       child: Stack(
          //                         children: <Widget>[
          //                           Container(
          //                             decoration: const BoxDecoration(
          //                               color: Color(0x24424343),
          //                               borderRadius: BorderRadius.all(
          //                                   Radius.elliptical(9999.0, 9999.0)),
          //                             ),
          //                           ),
          //                           Padding(
          //                             padding: EdgeInsets.all(4.0),
          //                             child: Stack(
          //                               children: <Widget>[
          //                                 Container(
          //                                   decoration: const BoxDecoration(),
          //                                 ),
          //                                 Transform.translate(
          //                                   offset: const Offset(2.1, 3.5),
          //                                   child: SizedBox(
          //                                     width: 20.0,
          //                                     height: 17.0,
          //                                     child: Stack(
          //                                       children: <Widget>[
          //                                         SizedBox(
          //                                           width: 20.0,
          //                                           height: 17.0,
          //                                           child: Stack(
          //                                             children: <Widget>[
          //                                               Transform.translate(
          //                                                 offset:
          //                                                     const Offset(0.0, 2.9),
          //                                                 child: Container(
          //                                                   width: 20.0,
          //                                                   height: 14.0,
          //                                                   decoration:
          //                                                       BoxDecoration(
          //                                                     borderRadius:
          //                                                         BorderRadius
          //                                                             .circular(
          //                                                                 2.0),
          //                                                     border: Border.all(
          //                                                         width: 1.5,
          //                                                         color: const Color(
          //                                                             0xff424343)),
          //                                                   ),
          //                                                 ),
          //                                               ),
          //                                               Transform.translate(
          //                                                 offset:
          //                                                     const Offset(7.2, 6.5),
          //                                                 child: Container(
          //                                                   width: 6.0,
          //                                                   height: 6.0,
          //                                                   decoration:
          //                                                       BoxDecoration(
          //                                                     borderRadius: const BorderRadius
          //                                                         .all(Radius
          //                                                             .elliptical(
          //                                                                 9999.0,
          //                                                                 9999.0)),
          //                                                     border: Border.all(
          //                                                         width: 1.5,
          //                                                         color: const Color(
          //                                                             0xff424343)),
          //                                                   ),
          //                                                 ),
          //                                               ),
          //                                               Transform.translate(
          //                                                 offset:
          //                                                     Offset(15.7, 6.0),
          //                                                 child: Container(
          //                                                   width: 1.0,
          //                                                   height: 1.0,
          //                                                   decoration:
          //                                                       BoxDecoration(
          //                                                     borderRadius: const BorderRadius
          //                                                         .all(Radius
          //                                                             .elliptical(
          //                                                                 9999.0,
          //                                                                 9999.0)),
          //                                                     border: Border.all(
          //                                                         width: 1.5,
          //                                                         color: const Color(
          //                                                             0xff424343)),
          //                                                   ),
          //                                                 ),
          //                                               ),
          //                                               Transform.translate(
          //                                                 offset:
          //                                                     Offset(2.4, 0.0),
          //                                                 child: SizedBox(
          //                                                   width: 4.0,
          //                                                   height: 1.0,
          //                                                   child: SvgPicture
          //                                                       .string(
          //                                                     _svg_spoahf,
          //                                                     allowDrawingOutsideViewBox:
          //                                                         true,
          //                                                   ),
          //                                                 ),
          //                                               ),
          //                                             ],
          //                                           ),
          //                                         ),
          //                                       ],
          //                                     ),
          //                                   ),
          //                                 ),
          //                               ],
          //                             ),
          //                           ),
          //                         ],
          //                       ),
          //                     ),
          //                   ],
          //                 );
          //               }).toList(),
          //             ),
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
          Pinned.fromPins(
            Pin(start: 0.0, end: 0.0),
            Pin(size: 98.0, start: 0.0),
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
          ),
          Pinned.fromPins(
            Pin(size: 92.0, start: 16.0),
            Pin(size: 24.0, middle: 0.197),
            child: PageLink(
              links: [
                PageLinkInfo(
                  ease: Curves.easeOut,
                  duration: 0.3,
                  pageBuilder: () => GIOProjects(),
                ),
              ],
              child: Stack(
                children: <Widget>[
                  Pinned.fromPins(
                    Pin(startFraction: 0.0, endFraction: 0.1848),
                    Pin(size: 24.0, middle: 0.5),
                    child: const Text(
                      'Projects',
                      style: TextStyle(
                        fontFamily: 'SF Pro',
                        fontSize: 20,
                        color: Color(0xff424343),
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      textHeightBehavior:
                      TextHeightBehavior(applyHeightToFirstAscent: false),
                      softWrap: false,
                    ),
                  ),
                  Pinned.fromPins(
                    Pin(size: 13.0, start: 79.0),
                    Pin(size: 21.0, middle: 0.6667),
                    child: Transform.rotate(
                      angle: 3.1416,
                      child: const Text(
                        'SomeText',
                        style: TextStyle(
                          fontFamily: 'SF Pro',
                          fontSize: 18,
                          color: Color(0xfe00a6ed),
                          fontWeight: FontWeight.w500,
                          height: 1,
                        ),
                        textHeightBehavior:
                        TextHeightBehavior(applyHeightToFirstAscent: false),
                        softWrap: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),


        ],
      ),
    );
  }
}

const String _svg_spoahf =
    '<svg viewBox="2.4 0.0 3.9 1.0" ><path transform="translate(2.44, 0.0)" d="M 0 0 L 3.919999837875366 0" fill="none" stroke="#424343" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" /></svg>';
