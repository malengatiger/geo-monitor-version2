import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/bloc/zip_bloc.dart';
import 'package:geo_monitor/library/data/settings_model.dart';
import 'package:geo_monitor/library/hive_util.dart';
import 'package:geo_monitor/library/users/avatar_editor.dart';
import 'package:page_transition/page_transition.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:uuid/uuid.dart';

import '../../library/api/data_api.dart';
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
  final mm = '🥬🥬🥬🥬🥬🥬 AuthMobile: ';
  String? phoneVerificationId;
  String? code;
  final phoneController = TextEditingController(text: "+27659990000");
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

  @override
  void initState() {
    _animationController = AnimationController(
        value: 0.0,
        duration: const Duration(milliseconds: 2000),
        reverseDuration: const Duration(milliseconds: 2000),
        vsync: this);
    super.initState();
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
          message: 'Please put in the code that was sent to you',
          context: context);
      setState(() {
        busy = false;
      });
      return;
    }
    UserCredential? userCred;
    try {
      pp('$mm .... start getting auth artifacts ...');

      PhoneAuthCredential authCredential = PhoneAuthProvider.credential(
          verificationId: phoneVerificationId!, smsCode: code!);
      userCred = await firebaseAuth.signInWithCredential(authCredential);
      pp('$mm firebase user credential obtained:  🍎 $userCred 🍎');

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
        ;
        var list = await DataAPI.getOrganizationSettings(user!.organizationId!);
        for (var settings in list) {
          if (settings.projectId == null) {
            await prefsOGx.saveSettings(settings);
            break;
          }
        }
        if (list.isEmpty) {
          await prefsOGx.saveSettings(SettingsModel(
              distanceFromProject: 100,
              photoSize: 0,
              maxVideoLengthInMinutes: 3,
              maxAudioLengthInMinutes: 10,
              themeIndex: 0,
              settingsId: const Uuid().v4(),
              created: DateTime.now().toUtc().toIso8601String(),
              organizationId: user!.organizationId,
              projectId: null,
              activityStreamHours: 12));
        }
        setState(() {
          busy = false;
        });
        if (mounted) {
          showToast(
              toastGravity: ToastGravity.TOP,
              backgroundColor: Theme.of(context).primaryColor,
              textStyle: myTextStyleSmall(context),
              message: '${user!.name} has been signed in',
              context: context);
        }
        pp('$mm getting GeoMonitor org data from the db using zip file:  🍎🍎');
        zipBloc.getOrganizationDataZippedFile(user!.organizationId!);
        _navigateToAvatarBuilder();
        return;
      }
    } catch (e) {
      pp('\n\n\n $e \n\n\n');
      String msg = '$e';
      if (msg.contains('dup key')) {
        msg = 'Duplicate organization name';
      }
      if (msg.contains('not found')) {
        msg = 'User not found';
      }
      if (msg.contains('Bad response format')) {
        msg = 'This user does not exist in the database';
      }
      if (msg.contains('server cannot be reached')) {
        msg = 'server cannot be reached';
      }
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
          'Phone Login',
          style: myTextStyleSmall(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: getRoundedBorder(radius: 16),
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
                    Text(
                      'Phone Authentication',
                      style: myTextStyleLarge(context),
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
                                decoration: const InputDecoration(
                                    hintText: 'Enter Phone Number',
                                    label: Text('Phone Number')),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter Phone Number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(
                                height: 32,
                              ),
                              _codeHasBeenSent
                                  ? const SizedBox()
                                  : ElevatedButton(
                                      onPressed: () {
                                        if (_formKey.currentState!.validate()) {
                                          _start();
                                        }
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(4.0),
                                        child: Text('Verify Phone Number'),
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
                                            'Enter SMS pin code sent to ${phoneController.text}',
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
                                                  child: const Padding(
                                                    padding:
                                                        EdgeInsets.all(4.0),
                                                    child: Text('Send Code'),
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
          )
        ],
      ),
    ));
  }
}
