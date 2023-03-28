import 'package:flutter/material.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/functions.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../../l10n/translation_handler.dart';
import '../../library/data/user.dart' as ur;
import 'auth_email_signin.dart';
import 'auth_phone_signin.dart';

class AuthTabletSignIn extends StatefulWidget {
  const AuthTabletSignIn({Key? key}) : super(key: key);

  @override
  State<AuthTabletSignIn> createState() => _AuthTabletSignInState();
}

class _AuthTabletSignInState extends State<AuthTabletSignIn> {
  final subText = 'Please sign in using the appropriate method. '
      'It is recommended to use phone authentication if your device can accept SMS messages. '
      'If not, please use email authentication';

  String? title, subTitle;
  @override
  void initState() {
    super.initState();
    _setTexts();
  }
  Future _setTexts() async {
    final sett = await prefsOGx.getSettings();
    if (sett != null) {
      title = await mTx.translate('signIn', sett!.locale!);
      subTitle = await mTx.translate('signInInstruction', sett!.locale!);
    }
    setState(() {

    });
  }
  void _onSignedIn(ur.User user) async {}

  void _onError(String message) async {}

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text(title == null?'Sign In':title!),
        bottom: PreferredSize(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48.0),
                    child: Text(subTitle == null?
                      subText: subTitle!,
                      style: myTextStyleSmall(context),
                    ),
                  ),
                  const SizedBox(
                    height: 48,
                  ),
                ],
              ),
            ),
            preferredSize: Size.fromHeight(120)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: OrientationLayoutBuilder(
          portrait: (context) {
            return Row(
              children: [
                SizedBox(
                  width: (width / 2) - 80,
                  height: 600,
                  child: AuthPhoneSignIn(
                    onSignedIn: _onSignedIn,
                    onError: _onError,
                  ),
                ),
                const SizedBox(width: 48,),
                SizedBox(
                  width: (width / 2),
                  height: 600,
                  child: AuthEmailSignIn(
                    showHeader: false,
                    externalPadding: 12,
                    internalPadding: 12,
                    onSignedIn: _onSignedIn,
                    onError: _onError,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ));
  }
}
