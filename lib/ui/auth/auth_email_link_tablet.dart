import 'package:flutter/material.dart';
import 'package:geo_monitor/library/functions.dart';

class AuthEmailLinkSignInTabletPortrait extends StatefulWidget {
  const AuthEmailLinkSignInTabletPortrait({Key? key}) : super(key: key);

  @override
  State<AuthEmailLinkSignInTabletPortrait> createState() => _AuthEmailLinkSignInTabletPortraitState();
}

class _AuthEmailLinkSignInTabletPortraitState extends State<AuthEmailLinkSignInTabletPortrait> {
  final emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }
  void _startAuthProcess() async {

  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Geo in Portrait',
            style: myTextStyleMedium(context),
          ),
        ),
        body: Stack(
          children: [
            SizedBox(
                child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                      height: 100,
                      child: Container(
                        color: Colors.teal,
                      )),
                  SizedBox(
                      height: 400,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 48.0, vertical: 24),
                        child: Card(
                          elevation: 4,
                          shape: getRoundedBorder(radius: 16),
                          child: Center(
                              child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 100.0),
                            child: Column(
                              children: [
                                const SizedBox(height: 48,),
                                TextField(
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    hintStyle: myTextStyleMedium(context),
                                    hintText: 'Enter your email address',
                                    label: Text(
                                      'Email Address',
                                      style: myTextStyleMedium(context),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 48,),
                                SizedBox(
                                    width: 200,
                                    child: ElevatedButton(onPressed: _startAuthProcess, child: const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text('Start Process'),
                                    ))),
                              ],
                            ),
                          )),
                        ),
                      )),
                  SizedBox(
                      height: 400,
                      child: Container(
                        color: Colors.grey,
                      )),
                ],
              ),
            ))
          ],
        ),
      ),
    );
  }
}

//
//

class AuthEmailLinkSignInTabletLandscape extends StatelessWidget {
  const AuthEmailLinkSignInTabletLandscape({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text(
          'Geo in Landscape',
          style: myTextStyleMedium(context),
        ),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 500,
            child: Container(
              color: Colors.indigo,
            ),
          ),
          SizedBox(
            width: 500,
            child: Container(
              color: Colors.pink,
            ),
          ),
        ],
      ),
    ));
  }
}



