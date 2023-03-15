import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geo_monitor/library/cache_manager.dart';
import 'package:geo_monitor/library/users/full_user_photo.dart';
import 'package:page_transition/page_transition.dart';
import 'package:uuid/uuid.dart';

import '../../../l10n/translation_handler.dart';
import '../../api/data_api.dart';
import '../../api/prefs_og.dart';
import '../../bloc/admin_bloc.dart';
import '../../bloc/organization_bloc.dart';
import '../../data/country.dart';
import '../../data/user.dart' as ar;
import '../../data/user.dart';
import '../../functions.dart';
import '../../generic_functions.dart';
import '../avatar_editor.dart';
import 'country_chooser.dart';

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


  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _setup();
    _getAdministrator();
  }

  void _getAdministrator() async {
    admin = await prefsOGx.getUser();
    var sett = await prefsOGx.getSettings();
    if (sett != null) {
      hint = await mTx.translate('pleaseSelectCountry', sett.locale!);
      title = await mTx.translate('members', sett.locale!);
      newMember = await mTx.translate('newMember', sett.locale!);
      editMember = await mTx.translate('editMember', sett.locale!);
      name = await mTx.translate('name', sett.locale!);
    }
    setState(() {});
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
    return SafeArea(
      child: Scaffold(
        key: _key,
        appBar: AppBar(
          title:  Text(title == null?
            'User Editor': title!,
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Column(
              children: [
                Text(
                  widget.user == null
                      ? newMember == null?'New Member': newMember!
                      : editMember == null? 'Edit Member': editMember!,
                  style: myTextStyleSmall(context),
                ),
                admin == null
                    ? Container()
                    : const SizedBox(
                        height: 8,
                      ),
                Text(
                  admin == null ? '' : admin!.organizationName!,
                  style: myTextStyleLarge(context),
                ),
                const SizedBox(
                  height: 20,
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
                  padding: const EdgeInsets.all(12.0),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 16,
                          ),
                          Row(
                            children: [
                              CountryChooser(onSelected: (c) {
                                setState(() {
                                  country = c;
                                });
                              }, hint: hint == null? 'Please select country': hint!,),
                              const SizedBox(
                                width: 12,
                              ),
                              country == null
                                  ? const SizedBox()
                                  : Text(
                                      '${country!.name}',
                                      style: myTextStyleMedium(context),
                                    ),
                            ],
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          TextFormField(
                            controller: nameController,
                            keyboardType: TextInputType.text,
                            style: myTextStyleSmall(context),
                            decoration: InputDecoration(
                                icon: Icon(
                                  Icons.person,
                                  size: 18,
                                  color: Theme.of(context).primaryColor,
                                ),
                                labelText: name == null? 'Name': name!,
                                hintStyle: myTextStyleSmall(context),
                                hintText: 'Enter Full Name'),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Please enter full name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: myTextStyleSmall(context),
                            decoration: InputDecoration(
                                icon: Icon(
                                  Icons.email_outlined,
                                  size: 18,
                                  color: Theme.of(context).primaryColor,
                                ),
                                labelText: 'Email Address',
                                hintStyle: myTextStyleSmall(context),
                                hintText: 'Enter Email Address'),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Please enter email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          TextFormField(
                            controller: cellphoneController,
                            keyboardType: TextInputType.phone,
                            style: myTextStyleSmall(context),
                            decoration: InputDecoration(
                                icon: Icon(
                                  Icons.phone,
                                  size: 18,
                                  color: Theme.of(context).primaryColor,
                                ),
                                labelText: 'Cellphone',
                                hintStyle: myTextStyleSmall(context),
                                hintText: 'Cellphone'),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Please enter cellphone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Radio(
                                value: 0,
                                groupValue: genderType,
                                onChanged: _handleGenderValueChange,
                              ),
                              Text(
                                'Male',
                                style: myTextStyleSmall(context),
                              ),
                              Radio(
                                value: 1,
                                groupValue: genderType,
                                onChanged: _handleGenderValueChange,
                              ),
                              Text('Female', style: myTextStyleSmall(context)),
                            ],
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          Row(
                            children: <Widget>[
                              Radio(
                                value: 0,
                                groupValue: userType,
                                onChanged: _handleRadioValueChange,
                              ),
                              Text(
                                'Monitor',
                                style: myTextStyleSmall(context),
                              ),
                              Radio(
                                value: 1,
                                groupValue: userType,
                                onChanged: _handleRadioValueChange,
                              ),
                              Text('Admin', style: myTextStyleSmall(context)),
                              Radio(
                                value: 2,
                                groupValue: userType,
                                onChanged: _handleRadioValueChange,
                              ),
                              Text(
                                'Exec',
                                style: myTextStyleSmall(context),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          isBusy
                              ? const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 8,
                                    backgroundColor: Colors.black,
                                  ),
                                )
                              : SizedBox(
                                  width: 200,
                                  child: ElevatedButton(
                                    onPressed: _submit,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Text(
                                        'Submit User',
                                        style: myTextStyleSmall(context),
                                      ),
                                    ),
                                  ),
                                ),
                          const SizedBox(
                            height: 24,
                          ),
                          SizedBox(
                            width: 200,
                            child: ElevatedButton(
                              onPressed: _navigateToAvatarBuilder,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  'Create Avatar',
                                  style: myTextStyleSmall(context),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 40,
                          ),
                        ],
                      ),
                    ),
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
                    right: 2,
                    top: 0,
                    child: GestureDetector(
                      onTap: _navigateToFullPhoto,
                      child: CircleAvatar(
                        radius: 40,
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
