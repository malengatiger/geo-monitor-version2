import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geo_monitor/library/cache_manager.dart';
import 'package:geo_monitor/library/users/edit/user_form.dart';
import 'package:geo_monitor/library/users/full_user_photo.dart';
import 'package:page_transition/page_transition.dart';
import 'package:uuid/uuid.dart';

import '../../../l10n/translation_handler.dart';
import '../../api/data_api.dart';
import '../../api/prefs_og.dart';
import '../../bloc/admin_bloc.dart';
import '../../bloc/fcm_bloc.dart';
import '../../bloc/organization_bloc.dart';
import '../../data/country.dart';
import '../../data/settings_model.dart';
import '../../data/user.dart' as ar;
import '../../data/user.dart';
import '../../functions.dart';
import '../../generic_functions.dart';
import '../avatar_editor.dart';

class UserEditMobile extends StatefulWidget {
  final ar.User? user;
  const UserEditMobile(this.user, {super.key});

  @override
  UserEditMobileState createState() => UserEditMobileState();
}

class UserEditMobileState extends State<UserEditMobile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  var nameController = TextEditingController();
  var emailController = TextEditingController();
  var passwordController = TextEditingController();
  var cellphoneController = TextEditingController();
  ar.User? admin;
  final _formKey = GlobalKey<FormState>();
  final _key = GlobalKey<ScaffoldState>();
  var isBusy = false;
  Country? country;
  int userType = -1;
  int genderType = -1;
  String? type;
  String? gender;
  String? name, hint, title, newMember, editMember;
  String? countryName,
      userName,
      cellphone,
      male,
      female,
      monitor,
      executive,
      administrator;

  UserFormStrings? userFormStrings;
  late StreamSubscription<SettingsModel> settingsSubscription;


  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _listen();
    _setTexts();
    _setup();
    _getAdministrator();
  }

  void _getAdministrator() async {
    admin = await prefsOGx.getUser();
    setState(() {});
  }

  void _setTexts() async {
    var sett = await prefsOGx.getSettings();
    if (sett != null) {
      userFormStrings = await UserFormStrings.getTranslated();
      hint = await mTx.translate('pleaseSelectCountry', sett.locale!);
      title = await mTx.translate('members', sett.locale!);
      newMember = await mTx.translate('newMember', sett.locale!);
      editMember = await mTx.translate('editMember', sett.locale!);
      name = await mTx.translate('name', sett.locale!);
    }
    setState(() {});
  }
  void _listen() async {
    settingsSubscription = fcmBloc.settingsStream.listen((event) async {
      if (country != null) {
        countryName = await mTx.translate(country!.name!, event.locale!);
      }
      if (mounted) {
        _setTexts();
      }
    });
  }


  Future<void> _setup() async {
    if (widget.user != null) {
      nameController.text = widget.user!.name!;
      emailController.text = widget.user!.email!;
      cellphoneController.text = widget.user!.cellphone!;
      _setTypeRadio();
      _setGenderRadio();
      await _setCountry();
    }
  }

  _setCountry() async {
    if (widget.user != null) {
      if (widget.user!.countryId != null) {
        var countries = await cacheManager.getCountries();
        for (var value in countries) {
          if (widget.user!.countryId == value.countryId) {
            country = value;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() async {
    if (country == null) {
      setState(() {
        busy = false;
      });
      showToast(
          context: context,
          message: 'Please select country',
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.pink,
          textStyle: Styles.whiteSmall);

      return;
    }
    if (gender == null) {
      showToast(
          context: context,
          message: 'Please select user gender',
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.pink,
          textStyle: Styles.whiteSmall);
      return;
    }
    if (type == null) {
      showToast(
          context: context,
          message: 'Please select user type',
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.pink,
          textStyle: Styles.whiteSmall);
      return;
    }
    if (_formKey.currentState!.validate()) {
      //todo - validate
      pp('🔵🔵 ....... Submitting user data to create a new User!');

      setState(() {
        isBusy = true;
      });

      try {
        if (widget.user == null) {
          var user = ar.User(
              name: nameController.text,
              email: emailController.text,
              cellphone: cellphoneController.text,
              organizationId: admin!.organizationId!,
              organizationName: admin!.organizationName,
              countryId: country!.countryId,
              userType: type,
              gender: gender,
              active: 0,
              created: DateTime.now().toUtc().toIso8601String(),
              fcmRegistration: 'tbd',
              password: const Uuid().v4(),
              userId: 'tbd');
          pp('\n\n\n😡😡😡 _submit new user ......... ${user.toJson()}');
          try {
            var mUser = await DataAPI.createUser(user);
            pp('\n🍎🍎🍎🍎 UserEditMobile: 🍎 A user has been created:  🍎 '
                '${mUser.toJson()}\b');
            gender = null;
            type = null;
            if (mounted) {
              showToast(
                  message: 'User created: ${user.name}',
                  context: context,
                  backgroundColor: Colors.teal,
                  textStyle: Styles.whiteSmall,
                  toastGravity: ToastGravity.TOP,
                  duration: const Duration(seconds: 5));
            }

            await organizationBloc.getUsers(
                organizationId: user.organizationId!, forceRefresh: true);
            if (mounted) {
              Navigator.of(context).pop(mUser);
            }
          } catch (e) {
            pp(e);
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('User Create failed: $e')));
          }
        } else {
          widget.user!.name = nameController.text;
          widget.user!.email = emailController.text;
          widget.user!.cellphone = cellphoneController.text;
          widget.user!.userType = type;
          widget.user!.countryId = country!.countryId!;
          widget.user!.gender = gender;

          pp('\n\n😡😡😡 _submit existing user for update, check countryId 🌸 ......... '
              '${widget.user!.toJson()} \n');

          try {
            await adminBloc.updateUser(widget.user!);
            var list = await organizationBloc.getUsers(
                organizationId: widget.user!.organizationId!,
                forceRefresh: true);
            if (mounted) {
              Navigator.pop(context, list);
            }
          } catch (e) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Update failed: $e')));
          }
        }
      } catch (e) {
        pp(e);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
      setState(() {
        isBusy = false;
      });
    }
  }

  void _setTypeRadio() {
    if (widget.user != null) {
      if (widget.user!.userType == UserType.fieldMonitor) {
        type = UserType.fieldMonitor;
        userType = 0;
      }
      if (widget.user!.userType == UserType.orgAdministrator) {
        type = UserType.orgAdministrator;
        userType = 1;
      }
      if (widget.user!.userType == UserType.orgExecutive) {
        type = UserType.orgExecutive;
        userType = 2;
      }
    }
  }

  void _setGenderRadio() {
    if (widget.user != null) {
      if (widget.user!.gender != null) {
        gender = widget.user!.gender!;
        switch (widget.user!.gender) {
          case 'Male':
            genderType = 0;
            break;
          case 'Female':
            genderType = 1;
            break;
        }
      }
    }
  }

  void _navigateToAvatarBuilder() async {
    //Navigator.of(context).pop();
    var user = await Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 2),
            child: AvatarEditor(
              user: widget.user!,
              goToDashboardWhenDone: false,
            )));
    if (user is User) {
      if (widget.user != null) {
        widget.user!.imageUrl = user.imageUrl;
        widget.user!.thumbnailUrl = user.thumbnailUrl;
        setState(() {});
      }
    }
  }

  void _navigateToFullPhoto() async {
    Navigator.of(context).pop();
    await Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 2),
            child: FullUserPhoto(
              user: widget.user!,
            )));
  }

  void _handleGenderValueChange(Object? value) {
    pp('🌸 🌸 🌸 🌸 🌸 _handleGenderValueChange: 🌸 $value');
    setState(() {
      switch (value) {
        case 0:
          gender = 'Male';
          genderType = 0;
          break;
        case 1:
          gender = 'Female';
          genderType = 1;
          break;
        case 2:
          gender = 'Other';
          genderType = 2;
          break;
      }
    });
  }

  void _handleRadioValueChange(Object? value) {
    pp('🌸 🌸 🌸 🌸 🌸 _handleRadioValueChange: 🌸 $value');
    setState(() {
      switch (value) {
        case 0:
          type = UserType.fieldMonitor;
          userType = 0;
          break;
        case 1:
          type = UserType.orgAdministrator;
          userType = 1;
          break;
        case 2:
          type = UserType.orgExecutive;
          userType = 2;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var deviceType = getThisDeviceType();
    return SafeArea(
      child: Scaffold(
        key: _key,
        appBar: AppBar(
          title: Text(
            title == null ? 'User Editor' : title!,
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(40),
            child: Column(
              children: [
                Text(
                  widget.user == null
                      ? newMember == null
                          ? 'New Member'
                          : newMember!
                      : editMember == null
                          ? 'Edit Member'
                          : editMember!,
                  style: myTextStyleSmall(context),
                ),
                admin == null
                    ? Container()
                    : const SizedBox(
                        height: 8,
                      ),
                Text(
                  admin == null ? '' : admin!.organizationName!,
                  style: myTextStyleMediumBold(context),
                ),
                const SizedBox(
                  height: 8,
                )
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                elevation: 4,
                shape: getRoundedBorder(radius: 16),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    child: UserForm(
                        user: widget.user,
                        width: width,
                        internalPadding: 8.0),
                  ),
                ),
              ),
            ),
            widget.user?.thumbnailUrl == null
                ? const Positioned(
                    right: 2,
                    top: 0,
                    child: CircleAvatar(
                      radius: 24,
                    ))
                : Positioned(
                    right: 20,
                    top: 0,
                    child: GestureDetector(
                      onTap: _navigateToFullPhoto,
                      child: CircleAvatar(
                        radius: deviceType == 'phone'?24:40,
                        backgroundImage:
                            NetworkImage(widget.user!.thumbnailUrl!),
                      ),
                    )),
          ],
        ),
      ),
    );
  }
}

class UserFormStrings {
  late String emailAddress,
      selectCountry,
      userName,
      cellphone,
      male,
      female,
      fieldMonitor,
      executive,
      administrator,
      submitMember,
      enterFullName,
      enterEmail,
      enterCell,
      profilePhoto;

  UserFormStrings(
      {required this.userName,
      required this.cellphone,
      required this.male,
      required this.selectCountry,
      required this.emailAddress,
      required this.female,
      required this.fieldMonitor,
      required this.executive,
      required this.administrator,
      required this.enterCell,
      required this.enterEmail,
      required this.enterFullName,
      required this.submitMember,
      required this.profilePhoto});

  static Future<UserFormStrings?> getTranslated() async {
    var sett = await prefsOGx.getSettings();
    if (sett != null) {
      var userName = await mTx.translate('name', sett.locale!);
      var cellphone = await mTx.translate('cellphone', sett.locale!);
      var male = await mTx.translate('male', sett.locale!);
      var female = await mTx.translate('female', sett.locale!);
      var fieldMonitor = await mTx.translate('fieldMonitor', sett.locale!);
      var executive = await mTx.translate('executive', sett.locale!);
      var administrator = await mTx.translate('administrator', sett.locale!);
      var submitUser = await mTx.translate('submitMember', sett.locale!);
      var profilePhoto = await mTx.translate('profilePhoto', sett.locale!);
      var enterCell = await mTx.translate('enterCell', sett.locale!);
      var enterEmail = await mTx.translate('enterEmail', sett.locale!);
      var enterFullName = await mTx.translate('enterFullName', sett.locale!);
      var selectCountry = await mTx.translate('pleaseSelectCountry', sett.locale!);
      var emailAddress = await mTx.translate('emailAddress', sett.locale!);

      var m = UserFormStrings(
          selectCountry: selectCountry,
          emailAddress: emailAddress,
          enterCell: enterCell,
          enterEmail: enterEmail,
          enterFullName: enterFullName,
          userName: userName,
          cellphone: cellphone,
          male: male,
          female: female,
          fieldMonitor: fieldMonitor,
          executive: executive,
          administrator: administrator,
          submitMember: submitUser,
          profilePhoto: profilePhoto);
      return m;
    }
    return null;
  }
}
