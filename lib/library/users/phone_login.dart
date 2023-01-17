import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geo_monitor/library/api/sharedprefs.dart';
import 'package:geo_monitor/library/data/country.dart';
import 'package:geo_monitor/library/data/organization.dart';
import 'package:geo_monitor/library/data/organization_registration_bag.dart';
import 'package:geo_monitor/library/hive_util.dart';
import 'package:geo_monitor/library/location/loc_bloc.dart';
import 'package:geo_monitor/library/users/edit/user_edit_main.dart';
import 'package:geo_monitor/ui/dashboard/dashboard_mobile.dart';
import 'package:page_transition/page_transition.dart';
import 'package:uuid/uuid.dart';

import '../api/data_api.dart';
import '../data/data_bag.dart';
import '../data/user.dart' as ur;
import '../functions.dart';
import '../generic_functions.dart';

class PhoneLogin extends StatefulWidget {
  const PhoneLogin({Key? key}) : super(key: key);

  @override
  PhoneLoginState createState() => PhoneLoginState();
}

class PhoneLoginState extends State<PhoneLogin>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _codeHasBeenSent = false;
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final mm = '🥬🥬🥬🥬🥬🥬 PhoneLogin: ';
  String? phoneVerificationId;
  String? code;
  final phoneController = TextEditingController(text: "+27659990000");
  final codeController = TextEditingController(text:'123456');
  final orgNameController = TextEditingController();
  final adminController = TextEditingController();
  bool verificationFailed = false;
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
    firebaseAuth.authStateChanges().listen((user) {
      pp('$mm firebaseAuth.authStateChanges: 🍎 $user');
    });
  }

  void _start() async {
    pp('$mm _start: ....... Verifying phone number ...');
    // ui.AuthProvider<ui.AuthListener, AuthCredential>  provider =
    // ui.PhoneAuthProvider();
    setState(() {
      busy = true;
    });

    await firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneController.value.text,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential phoneAuthCredential) {
          pp('$mm verificationCompleted: $phoneAuthCredential');
        },
        verificationFailed: (FirebaseAuthException error) {
          pp('\n$mm verificationFailed : $error \n');
          if (mounted) {
            setState(() {
              verificationFailed = true;
              busy = false;
            });
            showToast(
                backgroundColor: Theme.of(context).errorColor,
                textStyle: const TextStyle(color: Colors.white),
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
        });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _processRegistration() async {
    pp('$mm process code sent and register organization, code: ${codeController.value.text}');
    setState(() {
      busy = true;
    });
    code = codeController.value.text;

    if (code == null || code!.isEmpty) {
      showToast(
          duration: const Duration(seconds: 2),
          backgroundColor: Theme.of(context).errorColor,
          textStyle: const TextStyle(color: Colors.white),
          toastGravity: ToastGravity.CENTER,
          message: 'Please put in the code that was sent to you',
          context: context);
      setState(() {
        busy = false;
      });
      return;
    }

    try {
        pp('$mm .... start getting auth artifacts ...');
        PhoneAuthCredential authCredential = PhoneAuthProvider.credential(
            verificationId: phoneVerificationId!, smsCode: code!);
        var userCred = await firebaseAuth.signInWithCredential(authCredential);
        pp('$mm firebase user credential obtained:  🍎 $userCred 🍎');
        if (userCred.user?.metadata != null ) {
          var createDate = userCred.user?.metadata.creationTime;
          var now = DateTime.now().toUtc();
          var diffMs = now.millisecondsSinceEpoch - createDate!.millisecondsSinceEpoch;
          var seconds = Duration(milliseconds: diffMs).inSeconds;
          if (seconds < 120) {
            pp('$mm this is a new user - 🍎🍎🍎 they should not be here; 🍎 seconds: $seconds');
            return;
          } else {
            pp('$mm this is an existing user - 🌀🌀🌀 they should here, maybe because of a '
                'new phone but same number; 🍎 seconds: $seconds}');
          }
        }
        user = await DataAPI.getUser(userId: userCred.user!.uid);
        if (user != null) {
          await Prefs.saveUser(user!);
          await hiveUtil.addUser(user: user!);
          setState(() {
            busy = false;
          });
          if (mounted) {
            showToast(
                toastGravity: ToastGravity.TOP,
                backgroundColor: Theme.of(context).primaryColor,
                textStyle: myTextStyleSmall(context),
                message: '${user!.name} has been signed in', context: context);
          }
          _navigateToDashboard();
          return;
        }

    } catch (e) {
      pp(e);
      String msg = e.toString();
      if (msg.contains('dup key')) {
        msg = 'Duplicate organization name';
      }
      if (msg.contains('Bad response format')) {
        msg = 'This user does not exist in the database';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Theme.of(context).errorColor,
            duration: const Duration(seconds: 5), content: Text(msg)));
        setState(() {
          busy = false;
        });
      }
      return;
    }

    _navigateToDashboard();
  }

  void _navigateToDashboard() {
    if (user == null) return;
    if (mounted) {
      Navigator.of(context).pop(user);
    }
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
                      height: 28,
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
                                height: 48,
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
                                          TextFormField(
                                            controller: codeController,
                                            keyboardType: TextInputType.number,
                                            decoration:  InputDecoration(
                                                hintText: 'Enter Code', hintStyle: myTextStyleSmall(context),
                                                label:  Text('Code', style: myTextStyleSmall(context),)),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter SMS code received';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(
                                            height: 28,
                                          ),
                                          busy? const SizedBox(height: 16, width: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 4, backgroundColor: Colors.pink,
                                          ),): ElevatedButton(
                                              onPressed: _processRegistration,
                                              child: const Padding(
                                                padding: EdgeInsets.all(4.0),
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
