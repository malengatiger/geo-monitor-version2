import 'package:adobe_xd/pinned.dart';
import 'package:flutter/material.dart';

class ICONS1 extends StatelessWidget {
  ICONS1({
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffffffff),
      body: Stack(
        children: <Widget>[
          Container(),
          Container(),
          Container(),
          Container(),
          Container(),
          Container(),
          Container(),
          Container(),
          Container(),
          Container(),
          Container(),
          Pinned.fromPins(
            Pin(size: 24.0, middle: 0.2141),
            Pin(size: 24.0, start: 108.0),
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
          Container(),
          Container(),
          Container(),
          Pinned.fromPins(
            Pin(startFraction: 0.3592, endFraction: 0.5942),
            Pin(size: 34.0, middle: 0.9092),
            child: Text(
              'Title1',
              style: TextStyle(
                fontFamily: 'SF Pro',
                fontSize: 28,
                color: const Color(0xffffffff),
                fontWeight: FontWeight.w700,
              ),
              softWrap: false,
            ),
          ),
          Pinned.fromPins(
            Pin(size: 16.0, start: 618.0),
            Pin(size: 26.0, middle: 0.9055),
            child: Transform.rotate(
              angle: 3.1416,
              child: Text(
                '􀆉',
                style: TextStyle(
                  fontFamily: 'SF Pro',
                  fontSize: 22,
                  color: const Color(0xff007aff),
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
                textHeightBehavior:
                    TextHeightBehavior(applyHeightToFirstAscent: false),
                softWrap: false,
              ),
            ),
          ),
          Container(),
        ],
      ),
    );
  }
}
