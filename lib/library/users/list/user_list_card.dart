import 'package:badges/badges.dart' as bd;
import 'package:flutter/material.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';

import '../../data/user.dart';
import '../../functions.dart';

class UserListCard extends StatelessWidget {
  const UserListCard(
      {Key? key,
      required this.users,
      required this.deviceUser,
      required this.navigateToPhone,
      required this.navigateToMessaging,
      required this.navigateToUserDashboard,
      required this.navigateToUserEdit,
      required this.navigateToScheduler,
      required this.navigateToKillPage,
      required this.amInLandscape,
      required this.badgeTapped,
      required this.navigateToLocationRequest,
      required this.avatarRadius})
      : super(key: key);

  final List<User> users;
  final User deviceUser;
  final bool amInLandscape;
  final double avatarRadius;

  final Function(User) navigateToPhone;
  final Function(User) navigateToMessaging;
  final Function(User) navigateToUserDashboard;

  final Function(User) navigateToUserEdit;
  final Function(User) navigateToScheduler;
  final Function(User) navigateToKillPage;
  final Function(User) navigateToLocationRequest;
  final Function() badgeTapped;

  List<FocusedMenuItem> _getMenuItems(User someUser, BuildContext context) {
    List<FocusedMenuItem> list = [];

    if (someUser.userId != deviceUser.userId) {
      list.add(FocusedMenuItem(
          title: Text('Call User', style: myTextStyleSmallBlack(context)),
          // backgroundColor: Theme.of(context).primaryColor,
          trailingIcon: Icon(
            Icons.phone,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            navigateToPhone(someUser);
          }));
      list.add(FocusedMenuItem(
          title: Text('Send Message', style: myTextStyleSmallBlack(context)),
          // backgroundColor: Theme.of(context).primaryColor,
          trailingIcon: Icon(
            Icons.send,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            navigateToMessaging(someUser);
          }));
    }

    if (deviceUser.userType == UserType.fieldMonitor) {
      // pp('$mm Field monitor cannot edit any other users');
    } else {
      list.add(FocusedMenuItem(
          title:
              Text('Member Dashboard', style: myTextStyleSmallBlack(context)),
          trailingIcon: Icon(
            Icons.dashboard,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            navigateToUserDashboard(someUser);
          }));
      list.add(FocusedMenuItem(
          title: Text(
            'Edit Member',
            style: myTextStyleSmallBlack(context),
          ),
          trailingIcon: Icon(
            Icons.create,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            navigateToUserEdit(someUser);
          }));
    }

    if (deviceUser.userType == UserType.orgAdministrator ||
        deviceUser.userType == UserType.orgExecutive) {
      list.add(FocusedMenuItem(
          title: Text('Request Member Location',
              style: myTextStyleSmallBlack(context)),
          trailingIcon: Icon(
            Icons.location_on,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            navigateToLocationRequest(someUser);
          }));
      list.add(FocusedMenuItem(
          title: Text('Schedule FieldMonitor',
              style: myTextStyleSmallBlack(context)),
          trailingIcon: Icon(
            Icons.person,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            navigateToScheduler(someUser);
          }));
      list.add(FocusedMenuItem(
          title: Text('Remove User', style: myTextStyleSmallBlack(context)),
          trailingIcon: Icon(
            Icons.cut,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            navigateToKillPage(someUser);
          }));
    }
    // }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: getRoundedBorder(radius: 16),
      child: Padding(
        padding: amInLandscape
            ? const EdgeInsets.symmetric(horizontal: 24.0)
            : const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          children: [
            const SizedBox(
              height: 32,
            ),
            Text(
              deviceUser.organizationName!,
              style: myTextStyleLargePrimaryColor(context),
            ),
            const SizedBox(
              height: 12,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Admins & Field Monitors',
                  style: myTextStyleSmall(context),
                ),
                const SizedBox(
                  width: 8,
                ),
              ],
            ),
            SizedBox(
              height: amInLandscape ? 48 : 60,
            ),
            Expanded(
              child: InkWell(
                onTap: () {
                  badgeTapped();
                },
                child: bd.Badge(
                  badgeContent: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      '${users.length}',
                      style: myTextStyleSmall(context),
                    ),
                  ),
                  badgeStyle: bd.BadgeStyle(
                    badgeColor: Theme.of(context).primaryColor,
                    elevation: 8,
                    padding: const EdgeInsets.all(4),
                  ),
                  position: bd.BadgePosition.topEnd(top: -24, end: 4),
                  child: ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (BuildContext context, int index) {
                      var mUser = users.elementAt(index);
                      var created = DateTime.parse(mUser.created!);
                      var now = DateTime.now();
                      var ms = now.millisecondsSinceEpoch -
                          created.millisecondsSinceEpoch;
                      var deltaHours = Duration(milliseconds: ms).inHours;
                      return FocusedMenuHolder(
                        menuOffset: 20,
                        duration: const Duration(milliseconds: 300),
                        menuItems: _getMenuItems(mUser, context),
                        animateMenuItems: true,
                        openWithTap: true,
                        onPressed: () {
                          pp('💛️💛️💛💛️💛️💛💛️💛️💛️ tapped FocusedMenuHolder ...');
                        },
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0)),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6.0, horizontal: 20),
                                child: Row(
                                  children: [
                                    mUser.thumbnailUrl == null
                                        ? CircleAvatar(
                                            radius: avatarRadius,
                                          )
                                        : CircleAvatar(
                                            radius: avatarRadius,
                                            backgroundImage: NetworkImage(
                                                mUser.thumbnailUrl!),
                                          ),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    Flexible(
                                      child: Row(
                                        children: [
                                          Text(
                                            mUser.name!,
                                            style: myTextStyleSmall(context),
                                          ),
                                          const SizedBox(
                                            width: 8,
                                          ),
                                          deltaHours < 4
                                              ? const SizedBox(
                                                  width: 8,
                                                  height: 8,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 3,
                                                    backgroundColor:
                                                        Colors.pink,
                                                  ),
                                                )
                                              : const SizedBox(),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 0,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
