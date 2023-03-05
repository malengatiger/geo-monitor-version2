import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geo_monitor/library/api/data_api.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/bloc/organization_bloc.dart';
import 'package:geo_monitor/library/bloc/theme_bloc.dart';
import 'package:geo_monitor/library/functions.dart';
import 'package:geo_monitor/ui/intro/intro_page_one.dart';

import '../../library/generic_functions.dart';

class AuthEmailSignInTabletPortrait extends StatefulWidget {
  const AuthEmailSignInTabletPortrait(
      {Key? key,
      required this.showHeader,
      this.externalPadding,
      this.internalPadding})
      : super(key: key);

  final bool showHeader;
  final double? externalPadding;
  final double? internalPadding;
  @override
  State<AuthEmailSignInTabletPortrait> createState() =>
      _AuthEmailSignInTabletPortraitState();
}

class _AuthEmailSignInTabletPortraitState
    extends State<AuthEmailSignInTabletPortrait> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final firebaseAuth = FirebaseAuth.instance;
  bool busy = false;

  @override
  void initState() {
    super.initState();
  }

  void _submitSignIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      busy = true;
    });

    try {
      var email = emailController.value.text;
      var password = passwordController.value.text;

      var userCred = await firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);

      if (userCred.user != null) {
        var user = await DataAPI.getUserById(userId: userCred.user!.uid);
        if (user != null) {
          await prefsOGx.saveUser(user);
          var map = await getStartEndDates();
          final startDate = map['startDate'];
          final endDate = map['endDate'];
          await organizationBloc.getOrganizationData(
              organizationId: user.organizationId!,
              forceRefresh: true,
              startDate: startDate!,
              endDate: endDate!);
          var settings =
              await DataAPI.getOrganizationSettings(user.organizationId!);
          settings.sort((a, b) => b.created!.compareTo(a.created!));
          await prefsOGx.saveSettings(settings.first);
          await themeBloc.changeToTheme(settings.first.themeIndex!);
          if (mounted) {
            showToast(message: 'Member sign in succeeded', context: context);
            Navigator.of(context).pop(user);
          }
        } else {
          if (mounted) {
            showToast(message: 'Member not found', context: context);
          }
        }
      } else {
        if (mounted) {
          showToast(message: 'Member authentication failed', context: context);
        }
      }
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: widget.showHeader
            ? AppBar(
                title: Text(
                  'Geo Sign In',
                  style: myTextStyleMedium(context),
                ),
              )
            : const PreferredSize(
                preferredSize: Size.fromHeight(0.0),
                child: SizedBox(),
              ),
        body: Stack(
          children: [
            SizedBox(
                child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(widget.externalPadding == null
                    ? 64.0
                    : widget.externalPadding!),
                child: Card(
                  elevation: 4,
                  shape: getRoundedBorder(radius: 16),
                  child: Padding(
                    padding: EdgeInsets.all(widget.internalPadding == null
                        ? 100.0
                        : widget.internalPadding!),
                    child: Column(
                      children: [
                        Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                const SizedBox(
                                  height: 48,
                                ),
                                Text(
                                  'Geo Email Authentication',
                                  style: myTextStyleLarge(context),
                                ),
                                const SizedBox(
                                  height: 48,
                                ),
                                TextFormField(
                                  controller: emailController,
                                  keyboardType: TextInputType.text,
                                  decoration: InputDecoration(
                                      hintText: 'Enter Email Address',
                                      hintStyle: myTextStyleSmall(context),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            width: 0.6,
                                            color: Theme.of(context)
                                                .primaryColor), //<-- SEE HERE
                                      ),
                                      label: Text(
                                        'Email Address',
                                        style: myTextStyleSmall(context),
                                      )),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter Email address';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                TextFormField(
                                  controller: passwordController,
                                  keyboardType: TextInputType.visiblePassword,
                                  decoration: InputDecoration(
                                      hintText: 'Enter Password',
                                      hintStyle: myTextStyleSmall(context),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            width: 0.6,
                                            color: Theme.of(context)
                                                .primaryColor), //<-- SEE HERE
                                      ),
                                      label: Text(
                                        'Password',
                                        style: myTextStyleSmall(context),
                                      )),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter password';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(
                                  height: 72,
                                ),
                                busy
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 4,
                                          backgroundColor: Colors.pink,
                                        ),
                                      )
                                    : SizedBox(
                                        width: 200,
                                        child: ElevatedButton(
                                            onPressed: () {
                                              _submitSignIn();
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.all(16.0),
                                              child: Text('Sign In'),
                                            )),
                                      ),
                                const SizedBox(
                                  height: 48,
                                ),
                              ],
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ))
          ],
        ),
      ),
    );
  }
}

class AuthEmailLinkSignInTabletLandscape extends StatelessWidget {
  const AuthEmailLinkSignInTabletLandscape({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text(
          'Geo Email Sign In',
          style: myTextStyleLarge(context),
        ),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          SizedBox(
            width: 500,
            child: AuthEmailSignInTabletPortrait(
              showHeader: false,
              externalPadding: 24,
              internalPadding: 24,
            ),
          ),
          SizedBox(
            width: 500,
            child: IntroPage(
                assetPath: 'assets/intro/pic3.webp',
                title: 'Geo Monitor',
                text: lorem),
          ),
        ],
      ),
    ));
  }
}
