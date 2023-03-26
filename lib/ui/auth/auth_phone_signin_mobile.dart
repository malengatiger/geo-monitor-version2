import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/bloc/zip_bloc.dart';
import 'package:geo_monitor/library/cache_manager.dart';
import 'package:geo_monitor/library/data/settings_model.dart';
import 'package:geo_monitor/library/users/avatar_editor.dart';
import 'package:page_transition/page_transition.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:uuid/uuid.dart';

import '../../l10n/translation_handler.dart';
import '../../library/api/data_api.dart';
import '../../library/bloc/theme_bloc.dart';
import '../../library/data/user.dart' as ur;
import '../../library/functions.dart';
import '../../library/generic_functions.dart';

class AuthPhoneSignInMobile extends StatefulWidget {
  const AuthPhoneSignInMobile({Key? key}) : super(key: key);

  @override
  AuthPhoneSignInMobileState createState() => AuthPhoneSignInMobileState();
}

class AuthPhoneSignInMobileState extends State<AuthPhoneSignInMobile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _codeHasBeenSent = false;
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final mm = '🥬🥬🥬🥬🥬🥬 AuthPhoneSignInMobile: ';
  String? phoneVerificationId;
  String? code;
  final phoneController = TextEditingController(text: "+19985550000");
  final codeController = TextEditingController(text: '123456');
  final orgNameController = TextEditingController();
  final adminController = TextEditingController();
  final errorController = StreamController<ErrorAnimationType>();
  String? currentText;
  bool verificationFailed = false;
  bool verificationCompleted = false;
  bool busy = false;
  final _formKey = GlobalKey<FormState>();
  ur.User? user;
  SignInStrings? signInStrings;
  @override
  void initState() {
    _animationController = AnimationController(
        value: 0.0,
        duration: const Duration(milliseconds: 2000),
        reverseDuration: const Duration(milliseconds: 2000),
        vsync: this);
    super.initState();
    setDotEnv();
    _setTexts();
  }

  Future _setTexts() async {
    signInStrings = await SignInStrings.getTranslated();
    setState(() {});
  }

  void setDotEnv() async {
    await dotenv.load(fileName: ".env");
  }

  void _start() async {
    pp('$mm _start: ....... Verifying phone number ...');
    setState(() {
      busy = true;
    });

    await firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneController.value.text,
        timeout: const Duration(seconds: 90),
        verificationCompleted: (PhoneAuthCredential phoneAuthCredential) {
          pp('$mm verificationCompleted: $phoneAuthCredential');
          var message = phoneAuthCredential.smsCode ?? "";
          if (message.isNotEmpty) {
            codeController.text = message;
          }
          if (mounted) {
            setState(() {
              verificationCompleted = true;
              busy = false;
            });
            showToast(
                backgroundColor: Theme.of(context).colorScheme.background,
                textStyle: myTextStyleMedium(context),
                message: 'Verification completed. Thank you!',
                context: context);
          }
        },
        verificationFailed: (FirebaseAuthException error) {
          pp('\n$mm verificationFailed : $error \n');
          if (mounted) {
            setState(() {
              verificationFailed = true;
              busy = false;
            });
            showToast(
                backgroundColor: Theme.of(context).colorScheme.background,
                textStyle: myTextStyleMedium(context),
                message: 'Verification failed. Please try later',
                context: context);
          }
        },
        codeSent: (String verificationId, int? forceResendingToken) {
          pp('$mm onCodeSent: 🔵 verificationId: $verificationId 🔵 will set state ...');
          phoneVerificationId = verificationId;
          if (mounted) {
            pp('$mm setting state  _codeHasBeenSent to true');
            setState(() {
              _codeHasBeenSent = true;
              busy = false;
            });
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          pp('$mm codeAutoRetrievalTimeout verificationId: $verificationId');
          if (mounted) {
            setState(() {
              busy = false;
              _codeHasBeenSent = false;
            });
            showToast(
                message: 'Code retrieval failed, please try again',
                context: context);
            Navigator.of(context).pop();
          }
        });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _processSignIn() async {
    pp('\n\n$mm _processSignIn ... sign in the user using code: ${codeController.value.text}');
    setState(() {
      busy = true;
    });
    code = codeController.value.text;

    if (code == null || code!.isEmpty) {
      showToast(
          duration: const Duration(seconds: 2),
          backgroundColor: Theme.of(context).colorScheme.error,
          textStyle: const TextStyle(color: Colors.white),
          toastGravity: ToastGravity.CENTER,
          message: signInStrings == null
              ? 'Please put in the code that was sent to you'
              : signInStrings!.putInCode,
          context: context);
      setState(() {
        busy = false;
      });
      return;
    }
    UserCredential? userCred;
    try {
      PhoneAuthCredential authCredential = PhoneAuthProvider.credential(
          verificationId: phoneVerificationId!, smsCode: code!);
      userCred = await firebaseAuth.signInWithCredential(authCredential);

      if (userCred.user?.metadata != null) {
        var createDate = userCred.user?.metadata.creationTime;
        var now = DateTime.now().toUtc();
        var diffMs =
            now.millisecondsSinceEpoch - createDate!.millisecondsSinceEpoch;
        var seconds = Duration(milliseconds: diffMs).inSeconds;
        if (seconds < 120) {
          pp('$mm this is a new user - 🍎🍎🍎 they should not be here; 🍎 seconds: $seconds');
          return;
        } else {
          pp('$mm this is an existing user - 🌀🌀🌀 they should here, maybe because of a '
              'new phone but same number; 🍎 seconds: $seconds}');
        }
      }

      pp('\n$mm seeking to acquire this user from the Geo database by their id:- 🌀🌀🌀...');
      user = await DataAPI.getUserById(userId: userCred.user!.uid);
      if (user != null) {
        pp('$mm GeoMonitor user found on db:  🍎 ${user!.name!} 🍎');
        await prefsOGx.saveUser(user!);
        await cacheManager.addUser(user: user!);
        var settings =
            await DataAPI.getOrganizationSettings(user!.organizationId!);
        settings.sort((a, b) => b.created!.compareTo(a.created!));
        await themeBloc.changeToTheme(settings.first.themeIndex!);
        if (settings.isEmpty) {
          await prefsOGx.saveSettings(SettingsModel(
              distanceFromProject: 500,
              photoSize: 0,
              locale: 'en',
              maxVideoLengthInSeconds: 20,
              maxAudioLengthInMinutes: 30,
              themeIndex: 0,
              settingsId: const Uuid().v4(),
              created: DateTime.now().toUtc().toIso8601String(),
              organizationId: user!.organizationId,
              projectId: null,
              numberOfDays: 7,
              activityStreamHours: 12));
          await themeBloc.changeToTheme(0);
        } else {
          await prefsOGx.saveSettings(settings.first);
          await themeBloc.changeToTheme(settings.first.themeIndex!);
        }
        setState(() {
          busy = false;
        });
        if (mounted) {
          showToast(
              toastGravity: ToastGravity.TOP,
              backgroundColor: Theme.of(context).primaryColor,
              textStyle: myTextStyleSmall(context),
              message: signInStrings == null
                  ? '${user!.name} has been signed in'
                  : signInStrings!.memberSignedIn,
              context: context);
        }
        var map = await getStartEndDates();
        final startDate = map['startDate'];
        final endDate = map['endDate'];
        zipBloc.getOrganizationDataZippedFile(
            user!.organizationId!, startDate!, endDate!);
        _navigateToAvatarBuilder();
        return;
      }
    } catch (e) {
      pp('\n\n\n .... $e \n\n\n');
      String msg = '$e';
      if (msg.contains('dup key')) {
        msg = signInStrings == null
            ? 'Duplicate organization name'
            : signInStrings!.duplicateOrg;
      }
      if (msg.contains('not found')) {
        msg = signInStrings == null
            ? 'User not found'
            : signInStrings!.memberNotExist;
      }
      if (msg.contains('Bad response format')) {
        msg = signInStrings == null
            ? 'User not found'
            : signInStrings!.memberNotExist;
      }
      if (msg.contains('server cannot be reached')) {
        msg = signInStrings == null
            ? 'Server cannot be reached'
            : signInStrings!.serverUnreachable;
      }
      pp(msg);
      if (mounted) {
        showToast(
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.pink.shade700,
            textStyle: myTextStyleMedium(context),
            padding: 20.0,
            toastGravity: ToastGravity.CENTER,
            message: msg,
            context: context);
        setState(() {
          busy = false;
        });
      }
      return;
    }
  }

  void _navigateToAvatarBuilder() async {
    Navigator.of(context).pop(user!);
    pp('$mm _navigateToAvatarBuilder .... after popping current page  🍎🍎');
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: AvatarEditor(
              user: user!,
              goToDashboardWhenDone: true,
            )));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text(
          signInStrings == null ? 'Phone SignIn' : signInStrings!.phoneSignIn,
          style: myTextStyleMedium(context),
        ),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(100.0), child: Column(
          children: const [
            SizedBox(),
          ],
        )),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: getRoundedBorder(radius: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      busy
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 4,
                                      backgroundColor: Colors.pink,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox(
                              height: 12,
                            ),
                      const SizedBox(
                        height: 24,
                      ),
                      Row(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              signInStrings == null
                                  ? 'Phone Authentication'
                                  : signInStrings!.phoneAuth,
                              style: myTextStyleLarge(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                const SizedBox(
                                  height: 8,
                                ),
                                TextFormField(
                                  controller: phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                      hintText: signInStrings == null
                                          ? 'Enter Phone Number'
                                          : signInStrings!.enterPhone,
                                      label: Text(signInStrings == null
                                          ? 'Phone Number'
                                          : signInStrings!.phoneNumber)),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return signInStrings == null
                                          ? 'Please enter Phone Number'
                                          : signInStrings!.enterPhone;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(
                                  height: 60,
                                ),
                                _codeHasBeenSent
                                    ? const SizedBox()
                                    : ElevatedButton(
                                        onPressed: () {
                                          if (_formKey.currentState!.validate()) {
                                            _start();
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Text(signInStrings == null
                                              ? 'Verify Phone Number'
                                              : signInStrings!.verifyPhone),
                                        )),
                                const SizedBox(
                                  height: 20,
                                ),
                                _codeHasBeenSent
                                    ? SizedBox(
                                        height: 200,
                                        child: Column(
                                          children: [
                                            Text(
                                              signInStrings == null
                                                  ? 'Enter SMS pin code sent'
                                                  : signInStrings!.enterSMS,
                                              style: myTextStyleSmall(context),
                                            ),
                                            const SizedBox(
                                              height: 16,
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(4.0),
                                              child: PinCodeTextField(
                                                length: 6,
                                                obscureText: false,
                                                textStyle:
                                                    myNumberStyleLarge(context),
                                                animationType: AnimationType.fade,
                                                pinTheme: PinTheme(
                                                  shape: PinCodeFieldShape.box,
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                  fieldHeight: 50,
                                                  fieldWidth: 40,
                                                  activeFillColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .background,
                                                ),
                                                animationDuration: const Duration(
                                                    milliseconds: 300),
                                                backgroundColor: Theme.of(context)
                                                    .colorScheme
                                                    .background,
                                                enableActiveFill: true,
                                                errorAnimationController:
                                                    errorController,
                                                controller: codeController,
                                                onCompleted: (v) {
                                                  pp("$mm PinCodeTextField: Completed: $v - should call submit ...");
                                                },
                                                onChanged: (value) {
                                                  pp(value);
                                                  setState(() {
                                                    currentText = value;
                                                  });
                                                },
                                                beforeTextPaste: (text) {
                                                  pp("$mm Allowing to paste $text");
                                                  //if you return true then it will show the paste confirmation dialog. Otherwise if false, then nothing will happen.
                                                  //but you can show anything you want here, like your pop up saying wrong paste format or etc
                                                  return true;
                                                },
                                                appContext: context,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 28,
                                            ),
                                            busy
                                                ? const SizedBox(
                                                    height: 16,
                                                    width: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 4,
                                                      backgroundColor:
                                                          Colors.pink,
                                                    ),
                                                  )
                                                : ElevatedButton(
                                                    onPressed: _processSignIn,
                                                    style: ButtonStyle(
                                                      elevation: MaterialStateProperty.all<double>(8.0),
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              4.0),
                                                      child: Text(
                                                          signInStrings == null
                                                              ? 'Send Code'
                                                              : signInStrings!
                                                                  .sendCode),
                                                    )),
                                          ],
                                        ),
                                      )
                                    : const SizedBox(),
                              ],
                            )),
                      )
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    ));
  }
}

class SignInStrings {
  late String signIn,
      memberSignedIn,
      putInCode,
      duplicateOrg,
      enterPhone,
      serverUnreachable,
      phoneSignIn,
      phoneAuth,
      phoneNumber,
      verifyPhone,
      enterSMS,
      sendCode,
      verifyComplete,
      verifyFailed,
      enterOrg,
      orgName,
      enterAdmin,
      adminName,
      enterEmail,
      pleaseSelectCountry,
      memberNotExist,
      registerOrganization,
      emailAddress;

  SignInStrings(
      {required this.signIn,
      required this.memberSignedIn,
      required this.putInCode,
      required this.duplicateOrg,
      required this.enterPhone,
      required this.serverUnreachable,
      required this.phoneSignIn,
      required this.phoneAuth,
      required this.phoneNumber,
      required this.verifyPhone,
      required this.enterSMS,
      required this.sendCode,
        required this.registerOrganization,
      required this.verifyComplete,
      required this.verifyFailed,
      required this.enterOrg,
      required this.orgName,
      required this.enterAdmin,
      required this.adminName,
      required this.memberNotExist,
      required this.enterEmail,
        required this.pleaseSelectCountry,
      required this.emailAddress});

  static Future<SignInStrings> getTranslated() async {
    final sett = await prefsOGx.getSettings();

    var signIn = await mTx.translate('signIn', sett!.locale!);
    var memberNotExist = await mTx.translate('memberNotExist', sett.locale!);
    var memberSignedIn = await mTx.translate('memberSignedIn', sett.locale!);
    var putInCode = await mTx.translate('putInCode', sett.locale!);
    var duplicateOrg = await mTx.translate('duplicateOrg', sett.locale!);
    var pleaseSelectCountry = await mTx.translate('pleaseSelectCountry', sett.locale!);

    var registerOrganization = await mTx.translate('registerOrganization', sett.locale!);

    var enterPhone = await mTx.translate('enterPhone', sett.locale!);
    var serverUnreachable =
        await mTx.translate('serverUnreachable', sett.locale!);
    var phoneSignIn = await mTx.translate('phoneSignIn', sett.locale!);
    var phoneAuth = await mTx.translate('phoneAuth', sett.locale!);
    var phoneNumber = await mTx.translate('phoneNumber', sett.locale!);
    var verifyPhone = await mTx.translate('verifyPhone', sett.locale!);
    var enterSMS = await mTx.translate('enterSMS', sett.locale!);
    var sendCode = await mTx.translate('sendCode', sett.locale!);
    var verifyComplete = await mTx.translate('verifyComplete', sett.locale!);
    var verifyFailed = await mTx.translate('verifyFailed', sett.locale!);
    var enterOrg = await mTx.translate('enterOrg', sett.locale!);
    var orgName = await mTx.translate('orgName', sett.locale!);
    var enterAdmin = await mTx.translate('enterAdmin', sett.locale!);
    var adminName = await mTx.translate('adminName', sett.locale!);
    var enterEmail = await mTx.translate('enterEmail', sett.locale!);
    var emailAddress = await mTx.translate('emailAddress', sett.locale!);

    final m = SignInStrings(
        signIn: signIn,
        memberSignedIn: memberSignedIn,
        putInCode: putInCode,
        duplicateOrg: duplicateOrg,
        enterPhone: enterPhone,
        serverUnreachable: serverUnreachable,
        phoneSignIn: phoneSignIn,
        phoneAuth: phoneAuth,
        pleaseSelectCountry: pleaseSelectCountry,
        phoneNumber: phoneNumber,
        verifyPhone: verifyPhone,
        enterSMS: enterSMS,
        sendCode: sendCode,
        registerOrganization: registerOrganization,
        verifyComplete: verifyComplete,
        verifyFailed: verifyFailed,
        enterOrg: enterOrg,
        orgName: orgName,
        enterAdmin: enterAdmin,
        adminName: adminName,
        enterEmail: enterEmail,
        memberNotExist: memberNotExist,
        emailAddress: emailAddress);

    return m;
  }
}
