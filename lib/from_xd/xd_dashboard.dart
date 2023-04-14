import 'package:flutter/material.dart';
import 'package:geo_monitor/from_xd/my_badge.dart';
import 'package:geo_monitor/from_xd/project_list.dart';
import 'package:geo_monitor/from_xd/recent_event_list.dart';
import 'package:geo_monitor/from_xd/xd_header.dart';
import 'package:geo_monitor/library/functions.dart';

import 'member_list.dart';

class XdDashboard extends StatelessWidget {
  const XdDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFf4f3ee),
        centerTitle: true,
        title: Row(mainAxisAlignment: MainAxisAlignment.start,

          children: const [
            XdHeader(),
          ],
        ),
        actions: [
          IconButton(onPressed: (){}, icon: const Icon(Icons.search, color: Colors.black,)),
          IconButton(onPressed: (){}, icon: const Icon(Icons.refresh,color: Colors.black,)),
          IconButton(onPressed: (){}, icon: const Icon(Icons.settings, color: Colors.black,)),

        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: myTextStyleHeader(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Events',
                        style: myTextStyleSubtitle(context),
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      const MyBadge(number: 33, width: 48),

                      IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.blue,
                          ))
                    ],
                  ),
                  const SizedBox(height: 12),
                  const RecentEventList(),
                  const SizedBox(
                    height: 36,
                  ),
                  GestureDetector(
                    onTap: () {
                      pp('projects tapped ... navigate to ');
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Projects',
                          style: myTextStyleSubtitle(context),
                        ),
                        const SizedBox(
                          width: 16,
                        ),
                        const MyBadge(number: 33, width: 48),
                        // const SizedBox(width: 0,),
                        IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.blue,
                            ))
                      ],
                    ),
                  ),
                  const SizedBox(height: 12,),
                  const ProjectList(),
                  const SizedBox(height: 36),
                  GestureDetector(
                    onTap: () {
                      pp('users tapped ... navigate to ');
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Members',
                          style: myTextStyleSubtitle(context),
                        ),
                        const SizedBox(
                          width: 16,
                        ),
                        const MyBadge(number: 33, width: 48, color: Colors.red,),
                        // const SizedBox(width: 0,),
                        IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.blue,
                            ))
                      ],
                    ),
                  ),
                  const SizedBox(height: 12,),
                  const UserList(),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }
}
