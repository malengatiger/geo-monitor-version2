import 'dart:ui' as ui;

import 'package:adobe_xd/pinned.dart';
import 'package:flutter/material.dart';

class GIOHomeDashboard extends StatelessWidget {
  GIOHomeDashboard({
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffffffff),
      body: Stack(
        children: <Widget>[
          Pinned.fromPins(
            Pin(start: -94.0, end: -81.0),
            Pin(size: 852.0, start: 0.0),
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage(''),
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
          ClipRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
              child: Container(
                color: const Color(0x16f9f9f9),
                margin: EdgeInsets.fromLTRB(0.0, -33.0, 0.0, 318.0),
              ),
            ),
          ),
          Pinned.fromPins(
            Pin(size: 174.0, start: 16.0),
            Pin(size: 40.0, start: 102.0),
            child: Text(
              'Dashboard',
              style: TextStyle(
                fontFamily: 'SF Pro',
                fontSize: 34,
                color: const Color(0xffffffff),
                fontWeight: FontWeight.w700,
              ),
              softWrap: false,
            ),
          ),
          Container(),
          Pinned.fromPins(
            Pin(start: 0.0, end: 0.0),
            Pin(size: 76.0, middle: 0.5105),
            child: Stack(
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    ClipRect(
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                        child: Container(
                          color: const Color(0x16f9f9f9),
                        ),
                      ),
                    ),
                    Container(),
                    Container(),
                    Container(),
                    Container(),
                    Pinned.fromPins(
                      Pin(size: 48.0, start: 18.0),
                      Pin(size: 50.0, start: 0.0),
                      child: Container(),
                    ),
                    Pinned.fromPins(
                      Pin(size: 48.0, start: 18.0),
                      Pin(size: 12.0, middle: 0.5313),
                      child: Text(
                        'Label',
                        style: TextStyle(
                          fontFamily: 'SF Pro',
                          fontSize: 10,
                          color: const Color(0xfeffffff),
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                        textHeightBehavior:
                            TextHeightBehavior(applyHeightToFirstAscent: false),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                Pinned.fromPins(
                  Pin(size: 140.0, middle: 0.5),
                  Pin(size: 5.0, end: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xfeffffff),
                      borderRadius: BorderRadius.circular(100.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Pinned.fromPins(
            Pin(size: 147.0, start: 16.0),
            Pin(size: 24.0, start: 165.0),
            child: Stack(
              children: <Widget>[
                Pinned.fromPins(
                  Pin(startFraction: 0.0, endFraction: 0.1088),
                  Pin(size: 24.0, middle: 0.5),
                  child: Text(
                    'Recent Events',
                    style: TextStyle(
                      fontFamily: 'SF Pro',
                      fontSize: 20,
                      color: const Color(0xffffffff),
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    textHeightBehavior:
                        TextHeightBehavior(applyHeightToFirstAscent: false),
                    softWrap: false,
                  ),
                ),
                Pinned.fromPins(
                  Pin(size: 13.0, start: 134.0),
                  Pin(size: 21.0, middle: 0.6667),
                  child: Transform.rotate(
                    angle: 3.1416,
                    child: Text(
                      '􀆉',
                      style: TextStyle(
                        fontFamily: 'SF Pro',
                        fontSize: 18,
                        color: const Color(0x4cffffff),
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
          Pinned.fromPins(
            Pin(size: 165.0, start: 16.0),
            Pin(size: 46.0, start: 201.0),
            child: Stack(
              children: <Widget>[
                ClipRect(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 21.0, sigmaY: 21.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment(0.315, 0.0),
                  child: SizedBox(
                    width: 92.0,
                    height: 30.0,
                    child: Stack(
                      children: <Widget>[
                        Pinned.fromPins(
                          Pin(startFraction: 0.0, endFraction: 0.087),
                          Pin(size: 14.0, middle: 0.0),
                          child: Text(
                            'NY Cab Repair',
                            style: TextStyle(
                              fontFamily: 'SF Pro',
                              fontSize: 12,
                              color: const Color(0xffffffff),
                              fontWeight: FontWeight.w500,
                              height: 1.3333333333333333,
                            ),
                            textHeightBehavior: TextHeightBehavior(
                                applyHeightToFirstAscent: false),
                            softWrap: false,
                          ),
                        ),
                        Pinned.fromPins(
                          Pin(startFraction: 0.0, endFraction: 0.0),
                          Pin(size: 14.0, middle: 1.0),
                          child: Text(
                            '25 seconds ago',
                            style: TextStyle(
                              fontFamily: 'SF Pro',
                              fontSize: 12,
                              color: const Color(0x99ebebf5),
                              fontWeight: FontWeight.w500,
                              height: 1.3333333333333333,
                            ),
                            textHeightBehavior: TextHeightBehavior(
                                applyHeightToFirstAscent: false),
                            softWrap: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Pinned.fromPins(
                  Pin(size: 32.0, start: 8.0),
                  Pin(size: 32.0, middle: 0.5),
                  child: Stack(
                    children: <Widget>[
                      ClipOval(
                        child: BackdropFilter(
                          filter:
                              ui.ImageFilter.blur(sigmaX: 21.0, sigmaY: 21.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.all(
                                  Radius.elliptical(9999.0, 9999.0)),
                            ),
                          ),
                        ),
                      ),
                      Container(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Pinned.fromPins(
            Pin(size: 165.0, end: 39.0),
            Pin(size: 46.0, start: 201.0),
            child: Stack(
              children: <Widget>[
                ClipRect(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 21.0, sigmaY: 21.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment(0.185, 0.0),
                  child: SizedBox(
                    width: 84.0,
                    height: 30.0,
                    child: Stack(
                      children: <Widget>[
                        Pinned.fromPins(
                          Pin(startFraction: 0.0, endFraction: 0.0),
                          Pin(size: 14.0, middle: 0.0),
                          child: Text(
                            'Apt Inspection',
                            style: TextStyle(
                              fontFamily: 'SF Pro',
                              fontSize: 12,
                              color: const Color(0xffffffff),
                              fontWeight: FontWeight.w500,
                              height: 1.3333333333333333,
                            ),
                            textHeightBehavior: TextHeightBehavior(
                                applyHeightToFirstAscent: false),
                            softWrap: false,
                          ),
                        ),
                        Pinned.fromPins(
                          Pin(startFraction: 0.0, endFraction: 0.1905),
                          Pin(size: 14.0, middle: 1.0),
                          child: Text(
                            '2 hours ago',
                            style: TextStyle(
                              fontFamily: 'SF Pro',
                              fontSize: 12,
                              color: const Color(0x99ebebf5),
                              fontWeight: FontWeight.w500,
                              height: 1.3333333333333333,
                            ),
                            textHeightBehavior: TextHeightBehavior(
                                applyHeightToFirstAscent: false),
                            softWrap: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Pinned.fromPins(
                  Pin(size: 32.0, start: 8.0),
                  Pin(size: 32.0, middle: 0.5),
                  child: Stack(
                    children: <Widget>[
                      ClipOval(
                        child: BackdropFilter(
                          filter:
                              ui.ImageFilter.blur(sigmaX: 21.0, sigmaY: 21.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.all(
                                  Radius.elliptical(9999.0, 9999.0)),
                            ),
                          ),
                        ),
                      ),
                      Container(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Pinned.fromPins(
            Pin(size: 165.0, end: -134.0),
            Pin(size: 46.0, start: 201.0),
            child: Stack(
              children: <Widget>[
                ClipRect(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 21.0, sigmaY: 21.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ),
                Pinned.fromPins(
                  Pin(size: 94.0, end: 23.0),
                  Pin(size: 30.0, middle: 0.5),
                  child: Stack(
                    children: <Widget>[
                      Pinned.fromPins(
                        Pin(startFraction: 0.0, endFraction: 0.0),
                        Pin(size: 14.0, middle: 0.0),
                        child: Text(
                          'Resident Inquiry',
                          style: TextStyle(
                            fontFamily: 'SF Pro',
                            fontSize: 12,
                            color: const Color(0xffffffff),
                            fontWeight: FontWeight.w500,
                            height: 1.3333333333333333,
                          ),
                          textHeightBehavior: TextHeightBehavior(
                              applyHeightToFirstAscent: false),
                          softWrap: false,
                        ),
                      ),
                      Pinned.fromPins(
                        Pin(startFraction: 0.0, endFraction: 0.266),
                        Pin(size: 14.0, middle: 1.0),
                        child: Text(
                          '4 hours ago',
                          style: TextStyle(
                            fontFamily: 'SF Pro',
                            fontSize: 12,
                            color: const Color(0x99ebebf5),
                            fontWeight: FontWeight.w500,
                            height: 1.3333333333333333,
                          ),
                          textHeightBehavior: TextHeightBehavior(
                              applyHeightToFirstAscent: false),
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                ),
                Pinned.fromPins(
                  Pin(size: 32.0, start: 8.0),
                  Pin(size: 32.0, middle: 0.5),
                  child: Stack(
                    children: <Widget>[
                      ClipOval(
                        child: BackdropFilter(
                          filter:
                              ui.ImageFilter.blur(sigmaX: 21.0, sigmaY: 21.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.all(
                                  Radius.elliptical(9999.0, 9999.0)),
                            ),
                          ),
                        ),
                      ),
                      Container(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(),
          Pinned.fromPins(
            Pin(size: 24.0, end: 16.0),
            Pin(size: 24.0, start: 64.0),
            child: Stack(
              children: <Widget>[
                Container(),
                Container(),
              ],
            ),
          ),
          Container(),
          Pinned.fromPins(
            Pin(size: 127.0, middle: 0.5),
            Pin(size: 37.0, start: 11.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xff000000),
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(width: 1.0, color: const Color(0xff000000)),
              ),
            ),
          ),
          Pinned.fromPins(
            Pin(size: 92.0, start: 16.0),
            Pin(size: 24.0, start: 283.0),
            child: Stack(
              children: <Widget>[
                Pinned.fromPins(
                  Pin(startFraction: 0.0, endFraction: 0.1848),
                  Pin(size: 24.0, middle: 0.5),
                  child: Text(
                    'Projects',
                    style: TextStyle(
                      fontFamily: 'SF Pro',
                      fontSize: 20,
                      color: const Color(0xffffffff),
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
                    child: Text(
                      '􀆉',
                      style: TextStyle(
                        fontFamily: 'SF Pro',
                        fontSize: 18,
                        color: const Color(0x4cffffff),
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
          Container(),
          Pinned.fromPins(
            Pin(size: 241.0, start: 16.0),
            Pin(size: 211.0, middle: 0.23),
            child: Stack(
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    ClipRect(
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 21.0, sigmaY: 21.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                    ),
                    Pinned.fromPins(
                      Pin(size: 164.0, end: 29.0),
                      Pin(size: 30.0, start: 8.0),
                      child: Stack(
                        children: <Widget>[
                          Pinned.fromPins(
                            Pin(startFraction: 0.0, endFraction: 0.4878),
                            Pin(size: 14.0, middle: 0.0),
                            child: Text(
                              'NY Cab Repair',
                              style: TextStyle(
                                fontFamily: 'SF Pro',
                                fontSize: 12,
                                color: const Color(0xffffffff),
                                fontWeight: FontWeight.w500,
                                height: 1.3333333333333333,
                              ),
                              textHeightBehavior: TextHeightBehavior(
                                  applyHeightToFirstAscent: false),
                              softWrap: false,
                            ),
                          ),
                          Pinned.fromPins(
                            Pin(startFraction: 0.0, endFraction: 0.0),
                            Pin(size: 14.0, middle: 1.0),
                            child: Text(
                              'City of New York Renovation',
                              style: TextStyle(
                                fontFamily: 'SF Pro',
                                fontSize: 12,
                                color: const Color(0x99ebebf5),
                                fontWeight: FontWeight.w500,
                                height: 1.3333333333333333,
                              ),
                              textHeightBehavior: TextHeightBehavior(
                                  applyHeightToFirstAscent: false),
                              softWrap: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Pinned.fromPins(
                      Pin(size: 32.0, start: 8.0),
                      Pin(size: 32.0, start: 7.0),
                      child: Stack(
                        children: <Widget>[
                          ClipOval(
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(
                                  sigmaX: 21.0, sigmaY: 21.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.all(
                                      Radius.elliptical(9999.0, 9999.0)),
                                ),
                              ),
                            ),
                          ),
                          Container(),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: const AssetImage(''),
                      fit: BoxFit.fill,
                    ),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  margin: EdgeInsets.fromLTRB(0.0, 46.0, 0.0, 0.0),
                ),
              ],
            ),
          ),
          Pinned.fromPins(
            Pin(size: 241.0, end: -121.0),
            Pin(size: 211.0, middle: 0.23),
            child: Stack(
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    ClipRect(
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 21.0, sigmaY: 21.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                    ),
                    Pinned.fromPins(
                      Pin(size: 111.0, middle: 0.3692),
                      Pin(size: 30.0, start: 8.0),
                      child: Stack(
                        children: <Widget>[
                          Pinned.fromPins(
                            Pin(startFraction: 0.0, endFraction: 0.2432),
                            Pin(size: 14.0, middle: 0.0),
                            child: Text(
                              'Apt Inspection',
                              style: TextStyle(
                                fontFamily: 'SF Pro',
                                fontSize: 12,
                                color: const Color(0xffffffff),
                                fontWeight: FontWeight.w500,
                                height: 1.3333333333333333,
                              ),
                              textHeightBehavior: TextHeightBehavior(
                                  applyHeightToFirstAscent: false),
                              softWrap: false,
                            ),
                          ),
                          Pinned.fromPins(
                            Pin(startFraction: 0.0, endFraction: 0.0),
                            Pin(size: 14.0, middle: 1.0),
                            child: Text(
                              'Andy’s Apartments',
                              style: TextStyle(
                                fontFamily: 'SF Pro',
                                fontSize: 12,
                                color: const Color(0x99ebebf5),
                                fontWeight: FontWeight.w500,
                                height: 1.3333333333333333,
                              ),
                              textHeightBehavior: TextHeightBehavior(
                                  applyHeightToFirstAscent: false),
                              softWrap: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Pinned.fromPins(
                      Pin(size: 32.0, start: 8.0),
                      Pin(size: 32.0, start: 7.0),
                      child: Stack(
                        children: <Widget>[
                          ClipOval(
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(
                                  sigmaX: 21.0, sigmaY: 21.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.all(
                                      Radius.elliptical(9999.0, 9999.0)),
                                ),
                              ),
                            ),
                          ),
                          Container(),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: const AssetImage(''),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  margin: EdgeInsets.fromLTRB(0.0, 46.0, 0.0, 0.0),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage(''),
                fit: BoxFit.fill,
              ),
            ),
            margin: EdgeInsets.symmetric(horizontal: -172.0, vertical: 0.0),
          ),
          Pinned.fromPins(
            Pin(size: 28.0, start: 16.0),
            Pin(size: 28.0, start: 64.0),
            child: Stack(
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xffffffff),
                        borderRadius:
                            BorderRadius.all(Radius.elliptical(9999.0, 9999.0)),
                        border: Border.all(
                            width: 1.0, color: const Color(0xffffffff)),
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: const AssetImage(''),
                      fit: BoxFit.fill,
                    ),
                  ),
                  margin: EdgeInsets.all(3.0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
