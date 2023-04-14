import 'dart:ui' as ui;

import 'package:adobe_xd/pinned.dart';
import 'package:flutter/material.dart';

class iPadNavigationBarLargeTitleTabBarTemplateLight4 extends StatelessWidget {
  iPadNavigationBarLargeTitleTabBarTemplateLight4({
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffefeff4),
      body: Stack(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage(''),
                fit: BoxFit.cover,
              ),
            ),
            margin: EdgeInsets.fromLTRB(0.0, -22.0, 0.0, -35.0),
          ),
          ClipRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
              child: Container(
                color: const Color(0x16f9f9f9),
                margin: EdgeInsets.fromLTRB(0.0, 0.0, -1.0, -60.0),
              ),
            ),
          ),
          Align(
            alignment: Alignment(0.002, 1.0),
            child: SizedBox(
              width: 273.0,
              height: 20.0,
              child: Stack(
                children: <Widget>[
                  Container(),
                  Pinned.fromPins(
                    Pin(start: 0.0, end: 0.0),
                    Pin(size: 5.5, middle: 0.5517),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xff000000),
                        borderRadius: BorderRadius.circular(100.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Pinned.fromPins(
            Pin(start: 21.0, end: -1.0),
            Pin(size: 88.0, start: 25.0),
            child: Stack(
              children: <Widget>[
                Container(),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: SizedBox(
                    width: 174.0,
                    height: 40.0,
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
                ),
              ],
            ),
          ),
          Container(),
          Pinned.fromPins(
            Pin(size: 147.0, start: 21.0),
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
            Pin(size: 165.0, start: 21.0),
            Pin(size: 46.0, middle: 0.1751),
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
          Align(
            alignment: Alignment(-0.42, -0.65),
            child: SizedBox(
              width: 165.0,
              height: 46.0,
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
          ),
          Align(
            alignment: Alignment(0.614, -0.65),
            child: SizedBox(
              width: 165.0,
              height: 46.0,
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
          ),
          Align(
            alignment: Alignment(0.097, -0.65),
            child: SizedBox(
              width: 165.0,
              height: 46.0,
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
          ),
          Pinned.fromPins(
            Pin(size: 165.0, end: -44.0),
            Pin(size: 46.0, middle: 0.1751),
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
          Pinned.fromPins(
            Pin(size: 92.0, start: 21.0),
            Pin(size: 24.0, middle: 0.2419),
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
          Pinned.fromPins(
            Pin(size: 241.0, start: 21.0),
            Pin(size: 211.0, middle: 0.3245),
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
          Align(
            alignment: Alignment(-0.062, -0.351),
            child: SizedBox(
              width: 241.0,
              height: 211.0,
              child: Stack(
                children: <Widget>[
                  Stack(
                    children: <Widget>[
                      ClipRect(
                        child: BackdropFilter(
                          filter:
                              ui.ImageFilter.blur(sigmaX: 21.0, sigmaY: 21.0),
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
          ),
          Pinned.fromPins(
            Pin(size: 241.0, end: 58.0),
            Pin(size: 211.0, middle: 0.3245),
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
          Align(
            alignment: Alignment(-0.062, 0.103),
            child: SizedBox(
              width: 241.0,
              height: 211.0,
              child: Stack(
                children: <Widget>[
                  Stack(
                    children: <Widget>[
                      ClipRect(
                        child: BackdropFilter(
                          filter:
                              ui.ImageFilter.blur(sigmaX: 21.0, sigmaY: 21.0),
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
          ),
          Pinned.fromPins(
            Pin(size: 24.0, end: 14.0),
            Pin(size: 24.0, start: 35.0),
            child: Stack(
              children: <Widget>[
                Container(),
                Container(),
              ],
            ),
          ),
          Container(),
          Pinned.fromPins(
            Pin(size: 241.0, end: 58.0),
            Pin(size: 211.0, middle: 0.5514),
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
          Pinned.fromPins(
            Pin(size: 241.0, start: 21.0),
            Pin(size: 211.0, middle: 0.5514),
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
        ],
      ),
    );
  }
}
