import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geo_monitor/library/api/sharedprefs.dart';
import 'package:geo_monitor/library/data/country.dart';
import 'package:geo_monitor/library/data/organization.dart';
import 'package:geo_monitor/library/data/organization_registration_bag.dart';
import 'package:geo_monitor/library/location/loc_bloc.dart';
import 'package:geo_monitor/library/users/edit/user_edit_main.dart';
import 'package:geo_monitor/ui/dashboard/dashboard_mobile.dart';
import 'package:page_transition/page_transition.dart';
import 'package:uuid/uuid.dart';

import '../api/data_api.dart';
import '../data/user.dart' as ur;
import '../functions.dart';
import '../generic_functions.dart';

class OrgRegistrationPage extends StatefulWidget {
  const OrgRegistrationPage({Key? key}) : super(key: key);

  @override
  OrgRegistrationPageState createState() => OrgRegistrationPageState();
}

class OrgRegistrationPageState extends State<OrgRegistrationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _codeHasBeenSent = false;
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final mm = '🥬🥬🥬🥬🥬🥬 CustomPhoneAuth: ';
  String? phoneVerificationId;
  String? code;
  final phoneController = TextEditingController(text: "+27659990000");
  final codeController = TextEditingController();
  final orgNameController = TextEditingController();
  final adminController = TextEditingController();
  bool verificationFailed = false;
  bool busy = false;
  final _formKey = GlobalKey<FormState>();
  ur.User? user;
  Country? country;

  @override
  void initState() {
    _animationController = AnimationController(
        value: 0.0,
        duration: const Duration(milliseconds: 2000),
        reverseDuration: const Duration(milliseconds: 2000),
        vsync: this);
    super.initState();
    //_start();
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
    if (country == null) {
      showToast(
          duration: const Duration(seconds: 2),
          backgroundColor: Theme.of(context).errorColor,
          message: 'Please select country',
          context: context);
      setState(() {
        busy = false;
      });
      return;
    }
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
      pp('$mm .... start building registration artifacts ...');
      PhoneAuthCredential authCredential = PhoneAuthProvider.credential(
          verificationId: phoneVerificationId!, smsCode: code!);
      await firebaseAuth.signOut();
      var userCred = await firebaseAuth.signInWithCredential(authCredential);
      pp('$mm firebase user credential obtained:  🍎 $userCred');

      var org = Organization(
          name: orgNameController.value.text,
          countryId: country!.countryId,
          email: '',
          created: DateTime.now().toUtc().toIso8601String(),
          countryName: country!.name,
          organizationId: const Uuid().v4());

      var loc = await locationBloc.getLocation();

      var bag = OrganizationRegistrationBag(
          organization: org,
          sampleProjectPosition: null,
          sampleUsers: [],
          sampleProject: null,
          date: DateTime.now().toUtc().toIso8601String(),
          latitude: loc.latitude,
          longitude: loc.longitude);

      var result = await DataAPI.registerOrganization(bag);
      user = ur.User(
          name: adminController.value.text,
          email: '',
          userId: userCred.user!.uid,
          cellphone: phoneController.value.text,
          created: DateTime.now().toUtc().toIso8601String(),
          userType: ur.UserType.orgAdministrator,
          gender: '',
          organizationName: orgNameController.value.text,
          organizationId: org.organizationId,
          countryId: country!.countryId,
          password: const Uuid().v4());
      var m = await DataAPI.addUser(user!);
      await Prefs.saveUser(m);

      pp('\n\n$mm Organization registered:  🍎 ${result.toJson()} \n\n');
    } catch (e) {
      pp(e);
      String msg = e.toString();
      if (msg.contains('dup key')) {
        msg = 'Duplicate organization name';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(duration: const Duration(seconds: 5), content: Text(msg)));
        setState(() {
          busy = false;
        });
      }
      return;
    }
    setState(() {
      busy = false;
    });
    _popOut();
  }

  void _popOut() {
    if (user == null) return;
    if (mounted) {
      Navigator.of(context).pop(user);
    }
  }

  _onCountrySelected(Country p1) {
    if (mounted) {
      setState(() {
        country = p1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text(
          'Organization Registration',
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
                      height: 8,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0),
                      child: Row(
                        children: [
                          CountryChooser(onSelected: _onCountrySelected),
                          country == null
                              ? const SizedBox()
                              : Text(
                                  '${country!.name}',
                                  style: myTextStyleSmall(context),
                                ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: orgNameController,
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(
                                    hintText: 'Enter Organization Name',
                                    hintStyle: myTextStyleSmall(context),
                                    label: Text(
                                      'Organization Name',
                                      style: myTextStyleSmall(context),
                                    )),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter Organization Name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              TextFormField(
                                controller: adminController,
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(
                                    hintText: 'Enter Administrator Name',
                                    hintStyle: myTextStyleSmall(context),
                                    label: Text(
                                      'Administrator Name',
                                      style: myTextStyleSmall(context),
                                    )),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter Administrator Name';
                                  }
                                  return null;
                                },
                              ),
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
                                height: 20,
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
                                        padding: EdgeInsets.all(12.0),
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
                                            decoration: InputDecoration(
                                                hintText: 'Enter Code',
                                                hintStyle:
                                                    myTextStyleSmall(context),
                                                label: Text(
                                                  'Code',
                                                  style:
                                                      myTextStyleSmall(context),
                                                )),
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
                                                  onPressed:
                                                      _processRegistration,
                                                  child: const Padding(
                                                    padding:
                                                        EdgeInsets.all(12.0),
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
