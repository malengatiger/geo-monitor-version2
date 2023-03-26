import 'package:badges/badges.dart' as bd;
import 'package:flutter/material.dart';
import 'package:geo_monitor/library/data/audio.dart';
import 'package:geo_monitor/library/data/photo.dart';
import 'package:geo_monitor/library/data/video.dart';
import 'package:geo_monitor/library/users/edit/user_form.dart';
import 'package:geo_monitor/ui/activity/geo_activity.dart';
import 'package:geo_monitor/ui/activity/user_profile_card.dart';
import 'package:page_transition/page_transition.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../../../l10n/translation_handler.dart';
import '../../api/prefs_og.dart';
import '../../data/country.dart';
import '../../data/location_response.dart';
import '../../data/user.dart' as ar;
import '../../functions.dart';
import '../../ui/maps/location_response_map.dart';

class UserEditTablet extends StatefulWidget {
  final ar.User? user;

  const UserEditTablet({super.key, this.user});

  @override
  UserEditTabletState createState() => UserEditTabletState();
}

class UserEditTabletState extends State<UserEditTablet>
    with SingleTickerProviderStateMixin {

  ar.User? admin;
  final _key = GlobalKey<ScaffoldState>();
  var isBusy = false;
  Country? country;
  String? title, subTitle;

  @override
  void initState() {
    super.initState();
    _getAdministrator();
  }

  void _getAdministrator() async {
    admin = await prefsOGx.getUser();
    var sett = await prefsOGx.getSettings();
    if (sett != null) {
      title = await mTx.translate('editMember', sett.locale!);
    }

    setState(() {});
  }

  void _navigateToLocationResponseMap(LocationResponse locationResponse) async {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: LocationResponseMap(
              locationResponse: locationResponse,
            )));
  }

  showPhoto(Photo p1) {}

  showVideo(Video p1) {}

  showAudio(Audio p1) {}

  @override
  Widget build(BuildContext context) {
    final ori = MediaQuery.of(context).orientation;
    if (ori.name == 'portrait') {
    } else {
    }
    final width = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        key: _key,
        appBar: AppBar(
          title: Text(
            title == null ? 'Geo Member Editor' : title!,
            style: myTextStyleLarge(context),
          ),
        ),
        body: OrientationLayoutBuilder(
          portrait: (ctx) {
            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      SizedBox(width: (width / 2) - 24,
                        child: widget.user == null? UserForm(
                          width: width / 2,
                          internalPadding: 24,
                          user: widget.user,
                        ): bd.Badge(
                          child: bd.Badge(
                            position:
                                bd.BadgePosition.topStart(top: -12, start: -12),
                            badgeStyle: bd.BadgeStyle(
                                badgeColor: Theme.of(context).primaryColor,
                                shape: bd.BadgeShape.square,
                                elevation: 16),
                            badgeContent: widget.user == null
                                ? const SizedBox()
                                : UserProfileCard(
                                    userName: widget.user!.name!,
                                    userThumbUrl: widget.user!.thumbnailUrl,
                                    namePictureHorizontal: true,
                                    elevation: 8,
                                    textStyle: myTextStyleMediumBoldPrimaryColor(
                                        context),
                                  ),
                            child: UserForm(
                              width: width / 2,
                              internalPadding: 24,
                              user: widget.user,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      GeoActivity(
                          width: (width / 2) - 40,
                          thinMode: true,
                          showPhoto: showPhoto,
                          showVideo: showVideo,
                          showAudio: showAudio,
                          showUser: (user) {},
                          showLocationRequest: (req) {},
                          showLocationResponse: (resp) {
                            _navigateToLocationResponseMap(resp);
                          },
                          showGeofenceEvent: (event) {},
                          showProjectPolygon: (polygon) {},
                          showProjectPosition: (position) {},
                          showOrgMessage: (message) {},
                          forceRefresh: false)
                    ],
                  ),
                ),
                // widget.user?.thumbnailUrl == null
                //     ? const Positioned(
                //         left: 24,
                //         top: 48,
                //         child: CircleAvatar(
                //           radius: 24,
                //         ))
                //     : Positioned(
                //         left: 24,
                //         top: 24,
                //         child: GestureDetector(
                //           onTap: _navigateToFullPhoto,
                //           child: CircleAvatar(
                //             radius: 24,
                //             backgroundImage:
                //                 NetworkImage(widget.user!.thumbnailUrl!),
                //           ),
                //         )),
              ],
            );
          },
          landscape: (ctx) {
            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(48.0),
                  child: Row(
                    children: [
                      bd.Badge(
                        position:
                        bd.BadgePosition.topStart(top: -28, start: -28),
                        badgeStyle: bd.BadgeStyle(
                            badgeColor: Theme.of(context).primaryColor,
                            shape: bd.BadgeShape.square,
                            elevation: 16),
                        badgeContent: widget.user == null
                            ? const SizedBox()
                            : UserProfileCard(
                          userName: widget.user!.name!,
                          userThumbUrl: widget.user!.thumbnailUrl,
                          namePictureHorizontal: true,
                          elevation: 8,
                          textStyle: myTextStyleMediumPrimaryColor(
                              context),
                        ),
                        child: UserForm(
                          width: width / 2,
                          internalPadding: 36,
                          user: widget.user,
                        ),
                      ),
                      GeoActivity(
                          width: (width / 2) - 100,
                          thinMode: true,
                          showPhoto: showPhoto,
                          showVideo: showVideo,
                          showAudio: showAudio,
                          showUser: (user) {},
                          showLocationRequest: (req) {},
                          showLocationResponse: (resp) {
                            _navigateToLocationResponseMap(resp);
                          },
                          showGeofenceEvent: (event) {},
                          showProjectPolygon: (polygon) {},
                          showProjectPosition: (position) {},
                          showOrgMessage: (message) {},
                          forceRefresh: false)
                    ],
                  ),
                ),
                // widget.user?.thumbnailUrl == null
                //     ? const Positioned(
                //         left: 48,
                //         top: 0,
                //         child: CircleAvatar(
                //           radius: 16,
                //           backgroundColor: Colors.teal,
                //         ))
                //     : Positioned(
                //         left: 20,
                //         top: 0,
                //         child: GestureDetector(
                //           onTap: _navigateToFullPhoto,
                //           child: CircleAvatar(
                //             radius: 48,
                //             backgroundImage:
                //                 NetworkImage(widget.user!.thumbnailUrl!),
                //           ),
                //         )),
              ],
            );
          },
        ),
      ),
    );
  }
}
