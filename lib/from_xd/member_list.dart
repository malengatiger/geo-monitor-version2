import 'package:flutter/material.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/bloc/organization_bloc.dart';

import '../library/data/user.dart';
import '../library/functions.dart';
import '../library/generic_functions.dart';

class UserList extends StatefulWidget {
  const UserList({Key? key}) : super(key: key);

  @override
  UserListState createState() => UserListState();
}

class UserListState extends State<UserList>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool busy = false;
  var users = <User>[];

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getData();
  }

  void _getData() async {
    setState(() {
      busy = true;
    });
    try {
      var user = await prefsOGx.getUser();
      pp('${user!.toJson()}');
      users = await organizationBloc.getUsers(
          organizationId: user.organizationId!, forceRefresh: true);
      pp('users found: ${users.length}');
    } catch (e) {
      pp(e);
      if (mounted) {
        showToast(message: '$e', context: context);
      }
    }

    setState(() {
      busy = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
          itemCount: users.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            final user = users.elementAt(index);
            return UserView(user: user, height: 212, width: 242);
          }),
    );
  }
}

class UserView extends StatelessWidget {
  const UserView(
      {Key? key, required this.user, required this.height, required this.width})
      : super(key: key);
  final User user;
  final double height, width;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: Card(
        shape: getRoundedBorder(radius: 10),
        elevation: 4,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_2_outlined,
                    color: Colors.black,
                    size: 24,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Flexible(
                    child: Text(
                      '${user.name}',
                      overflow: TextOverflow.ellipsis,
                      style: myTextStyleSmall(context),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            user.thumbnailUrl == null
                ? const CircleAvatar(
              radius: 64,
                    child: Icon(Icons.person, size: 60,),
                  )
                : CircleAvatar(
              radius: 64,
              backgroundImage: NetworkImage(user.thumbnailUrl!,),
            )
          ],
        ),
      ),
    );
  }
}
