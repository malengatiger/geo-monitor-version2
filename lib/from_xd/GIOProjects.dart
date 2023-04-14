import 'dart:ui' as ui;

import 'package:adobe_xd/pinned.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GIOProjects extends StatelessWidget {
  GIOProjects({
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffffffff),
      body: Stack(
        children: <Widget>[
          Pinned.fromPins(
            Pin(start: 0.0, end: 0.0),
            Pin(size: 995.0, start: 102.0),
            child: ClipRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xffffffff),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x26ffffff),
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
            Pin(size: 130.0, start: 16.0),
            Pin(size: 40.0, start: 132.0),
            child: Text(
              'Projects',
              style: TextStyle(
                fontFamily: 'SF Pro',
                fontSize: 34,
                color: const Color(0xff424343),
                fontWeight: FontWeight.w700,
              ),
              softWrap: false,
            ),
          ),
          Pinned.fromPins(
            Pin(size: 71.0, end: 16.0),
            Pin(size: 24.0, start: 195.0),
            child: Stack(
              children: <Widget>[
                Pinned.fromPins(
                  Pin(startFraction: 0.0, endFraction: 0.3521),
                  Pin(size: 24.0, middle: 0.5),
                  child: Text(
                    'Filter',
                    style: TextStyle(
                      fontFamily: 'SF Pro',
                      fontSize: 20,
                      color: const Color(0xff00a6ed),
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    textHeightBehavior:
                        TextHeightBehavior(applyHeightToFirstAscent: false),
                    textAlign: TextAlign.right,
                    softWrap: false,
                  ),
                ),
                Pinned.fromPins(
                  Pin(size: 13.0, start: 54.0),
                  Pin(size: 21.0, middle: 0.6667),
                  child: Transform.rotate(
                    angle: 4.7124,
                    child: Text(
                      '􀆉',
                      style: TextStyle(
                        fontFamily: 'SF Pro',
                        fontSize: 18,
                        color: const Color(0x4c00a6ed),
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
            Pin(start: 17.8, end: 17.8),
            Pin(size: 895.0, middle: 0.3642),
            child: SingleChildScrollView(
              primary: false,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 20,
                runSpacing: 16,
                children: [{}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}]
                    .map((itemData) {
                  return SizedBox(
                    width: 358.0,
                    height: 59.0,
                    child: Stack(
                      children: <Widget>[
                        Pinned.fromPins(
                          Pin(startFraction: 0.1776, endFraction: 0.4196),
                          Pin(size: 19.0, middle: 0.0759),
                          child: Text(
                            'SkyScraper Repair',
                            style: TextStyle(
                              fontFamily: 'SF Pro',
                              fontSize: 16,
                              color: const Color(0xff424343),
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                            textHeightBehavior: TextHeightBehavior(
                                applyHeightToFirstAscent: false),
                            softWrap: false,
                          ),
                        ),
                        Pinned.fromPins(
                          Pin(startFraction: 0.1776, endFraction: 0.2769),
                          Pin(size: 14.0, middle: 0.8539),
                          child: Text(
                            'March 2, 2023 - October 30, 2024',
                            style: TextStyle(
                              fontFamily: 'SF Pro',
                              fontSize: 12,
                              color: const Color(0xff424343),
                              height: 1.3333333333333333,
                            ),
                            textHeightBehavior: TextHeightBehavior(
                                applyHeightToFirstAscent: false),
                            softWrap: false,
                          ),
                        ),
                        Pinned.fromPins(
                          Pin(startFraction: 0.1776, endFraction: 0.4923),
                          Pin(size: 14.0, middle: 0.4944),
                          child: Text(
                            'BuildBetter Partners',
                            style: TextStyle(
                              fontFamily: 'SF Pro',
                              fontSize: 12,
                              color: const Color(0x64424343),
                              fontWeight: FontWeight.w500,
                              height: 1.3333333333333333,
                            ),
                            textHeightBehavior: TextHeightBehavior(
                                applyHeightToFirstAscent: false),
                            softWrap: false,
                          ),
                        ),
                        Pinned.fromPins(
                          Pin(size: 55.5, start: 0.8),
                          Pin(start: 0.8, end: 2.3),
                          child: Stack(
                            children: <Widget>[
                              Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: const AssetImage(''),
                                    fit: BoxFit.cover,
                                  ),
                                  border: Border.all(
                                      width: 1.0,
                                      color: const Color(0xff000000)),
                                ),
                                margin: EdgeInsets.fromLTRB(
                                    -22.8, -8.0, -28.7, -8.5),
                              ),
                              ClipOval(
                                child: BackdropFilter(
                                  filter: ui.ImageFilter.blur(
                                      sigmaX: 21.0, sigmaY: 21.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.all(
                                          Radius.elliptical(9999.0, 9999.0)),
                                      border: Border.all(
                                          width: 2.0,
                                          color: const Color(0xff000000)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Pinned.fromPins(
                          Pin(size: 57.0, start: 0.0),
                          Pin(start: 0.0, end: 1.5),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(
                                  Radius.elliptical(9999.0, 9999.0)),
                            ),
                          ),
                        ),
                        Pinned.fromPins(
                          Pin(size: 13.0, start: 344.5),
                          Pin(size: 21.0, middle: 0.4533),
                          child: Transform.rotate(
                            angle: 3.1416,
                            child: Text(
                              '􀆉',
                              style: TextStyle(
                                fontFamily: 'SF Pro',
                                fontSize: 18,
                                color: const Color(0x4c424343),
                                fontWeight: FontWeight.w500,
                                height: 1,
                              ),
                              textHeightBehavior: TextHeightBehavior(
                                  applyHeightToFirstAscent: false),
                              softWrap: false,
                            ),
                          ),
                        ),
                        Pinned.fromPins(
                          Pin(size: 297.0, end: 0.5),
                          Pin(size: 1.0, end: -1.0),
                          child: SvgPicture.string(
                            _svg_zhuzx9,
                            allowDrawingOutsideViewBox: true,
                            fit: BoxFit.fill,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Pinned.fromPins(
            Pin(start: 0.0, end: 0.0),
            Pin(size: 76.0, middle: 0.5105),
            child: Stack(
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xfef4f3ee),
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(10.0),
                          bottomLeft: Radius.circular(10.0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x4d000000),
                            offset: Offset(0, 0.33000001311302185),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                    ),
                    Pinned.fromPins(
                      Pin(size: 48.0, start: 18.0),
                      Pin(size: 50.0, start: 0.0),
                      child: Container(),
                    ),
                    Pinned.fromPins(
                      Pin(size: 48.0, start: 18.0),
                      Pin(size: 12.0, middle: 0.5313),
                      child: Text(
                        'Home',
                        style: TextStyle(
                          fontFamily: 'SF Pro',
                          fontSize: 10,
                          color: const Color(0xfe00a6ed),
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                        textHeightBehavior:
                            TextHeightBehavior(applyHeightToFirstAscent: false),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Container(),
                    Pinned.fromPins(
                      Pin(size: 48.0, start: 18.0),
                      Pin(size: 50.0, start: 0.0),
                      child: Container(),
                    ),
                    Align(
                      alignment: Alignment(0.003, 0.063),
                      child: SizedBox(
                        width: 48.0,
                        height: 12.0,
                        child: Text(
                          'Projects',
                          style: TextStyle(
                            fontFamily: 'SF Pro',
                            fontSize: 10,
                            color: const Color(0xfe424343),
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                          textHeightBehavior: TextHeightBehavior(
                              applyHeightToFirstAscent: false),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Container(),
                    Pinned.fromPins(
                      Pin(size: 48.0, end: 17.0),
                      Pin(size: 12.0, middle: 0.5313),
                      child: Text(
                        'Teams',
                        style: TextStyle(
                          fontFamily: 'SF Pro',
                          fontSize: 10,
                          color: const Color(0xfe424343),
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                        textHeightBehavior:
                            TextHeightBehavior(applyHeightToFirstAscent: false),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Container(),
                  ],
                ),
              ],
            ),
          ),
          Pinned.fromPins(
            Pin(start: 0.0, end: 0.0),
            Pin(size: 102.0, start: 0.0),
            child: Stack(
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xfff4f3ee),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10.0),
                      topRight: Radius.circular(10.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x29000000),
                        offset: Offset(0, 3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                Pinned.fromPins(
                  Pin(size: 44.0, middle: 0.5014),
                  Pin(size: 44.0, end: 5.0),
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: const AssetImage(''),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),
                Container(),
                Pinned.fromPins(
                  Pin(size: 24.0, end: 16.0),
                  Pin(size: 24.0, end: 14.0),
                  child: Stack(
                    children: <Widget>[
                      Container(),
                      Container(),
                    ],
                  ),
                ),
                Container(),
                Container(),
                Container(),
              ],
            ),
          ),
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
        ],
      ),
    );
  }
}

const String _svg_zhuzx9 =
    '<svg viewBox="76.0 314.5 297.0 1.0" ><path transform="translate(76.0, 314.5)" d="M 0 0 L 297 0" fill="none" stroke="#424343" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /></svg>';
