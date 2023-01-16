import 'package:flutter/material.dart';

import '../../api/sharedprefs.dart';
import '../../auth/app_auth.dart';
import '../../bloc/admin_bloc.dart';
import '../../bloc/organization_bloc.dart';
import '../../bloc/user_bloc.dart';
import '../../data/user.dart' as ar;
import '../../data/country.dart';
import '../../data/user.dart';
import '../../functions.dart';
import '../../generic_functions.dart';
import 'user_edit_main.dart';

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

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _setup();
    _getAdministrator();
  }

  void _getAdministrator() async {
    admin = await Prefs.getUser();
    setState(() {});
  }

  void _setup() {
    if (widget.user != null) {
      nameController.text = widget.user!.name!;
      emailController.text = widget.user!.email!;
      cellphoneController.text = widget.user!.cellphone!;
      _setTypeRadio();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      //todo - validate
      if (type == null) {
        showToast(
            context: context,
            message: 'Please select user type',
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
      setState(() {
        isBusy = true;
      });
      if (country == null) {
        showToast(
            context: context,
            message: 'Please select country',
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.pink,
            textStyle: Styles.whiteSmall);
        return;
      }
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
              created: DateTime.now().toUtc().toIso8601String(),
              fcmRegistration: 'tbd',
              userId: 'tbd');
          pp('😡 😡 😡 _submit new user ......... ${user.toJson()}');
          try {
            var mUser = await AppAuth.createUser(
              user: user,
              password: 'pass123',
              isLocalAdmin: admin == null ? true : false,
            );
            pp('🍎 🍎 🍎 🍎 UserEditMobile: 🍎 A user has been created:  🍎 ${mUser.toJson()}');
            gender = null;
            type = null;
            showToast(
                message: 'User created: ${user.name}',
                context: context,
                backgroundColor: Colors.teal,
                textStyle: Styles.whiteSmall,
                duration: const Duration(seconds: 5));

            await organizationBloc.getUsers(
                organizationId: user.organizationId!, forceRefresh: true);
            if (mounted) {
              Navigator.pop(context);
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
          pp('😡 😡 😡 _submit existing user for update, soon! 🌸 ......... ${widget.user!.toJson()}');

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

  int userType = -1;
  int genderType = -1;

  void _setTypeRadio() {
    if (widget.user != null) {
      if (widget.user!.userType == FIELD_MONITOR) {
        type = FIELD_MONITOR;
        userType = 0;
      }
      if (widget.user!.userType == ORG_ADMINISTRATOR) {
        type = ORG_ADMINISTRATOR;
        userType = 1;
      }
      if (widget.user!.userType == ORG_EXECUTIVE) {
        type = ORG_EXECUTIVE;
        userType = 2;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: _key,
        appBar: AppBar(
          title: Text(
            'User Editor',
            style: Styles.whiteSmall,
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Column(
              children: [
                Text(
                  widget.user == null
                      ? 'New Monitor User'
                      : 'Edit Monitor User',
                  style: Styles.blackBoldMedium,
                ),
                admin == null
                    ? Container()
                    : const SizedBox(
                        height: 8,
                      ),
                Text(
                  admin == null ? '' : admin!.organizationName!,
                  style: Styles.whiteSmall,
                ),
                const SizedBox(
                  height: 20,
                )
              ],
            ),
          ),
        ),
        backgroundColor: Colors.brown[100],
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 8,
                      ),
                      TextFormField(
                        controller: nameController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                            icon: Icon(
                              Icons.person,
                              color: Theme.of(context).primaryColor,
                            ),
                            labelText: 'Name',
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
                        decoration: InputDecoration(
                            icon: Icon(
                              Icons.email_outlined,
                              color: Theme.of(context).primaryColor,
                            ),
                            labelText: 'Email Address',
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
                        decoration: InputDecoration(
                            icon: Icon(
                              Icons.phone,
                              color: Theme.of(context).primaryColor,
                            ),
                            labelText: 'Cellphone',
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
                      Container(
                        color: Colors.amber[50],
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Radio(
                              value: 0,
                              groupValue: genderType,
                              onChanged: _handleGenderValueChange,
                            ),
                            Text(
                              'Male',
                              style: Styles.blackTiny,
                            ),
                            Radio(
                              value: 1,
                              groupValue: genderType,
                              onChanged: _handleGenderValueChange,
                            ),
                            Text('Female', style: Styles.blackTiny),
                          ],
                        ),
                      ),
                      // Text(
                      //   gender == null ? '' : gender!,
                      //   style: Styles.greyLabelSmall,
                      // ),
                      const SizedBox(
                        height: 16,
                      ),
                      Container(
                        color: Colors.brown[50],
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Radio(
                              value: 0,
                              groupValue: userType,
                              onChanged: _handleRadioValueChange,
                            ),
                            Text(
                              'Monitor',
                              style: Styles.blackTiny,
                            ),
                            Radio(
                              value: 1,
                              groupValue: userType,
                              onChanged: _handleRadioValueChange,
                            ),
                            Text('Admin', style: Styles.blackTiny),
                            Radio(
                              value: 2,
                              groupValue: userType,
                              onChanged: _handleRadioValueChange,
                            ),
                            Text(
                              'Executive',
                              style: Styles.blackTiny,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 28,
                      ),
                      CountryChooser(onSelected: (c) {
                        setState(() {
                          country = c;
                        });
                      }),
                      const SizedBox(
                        height: 28,
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
                          : ElevatedButton(
                              onPressed: _submit,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  'Submit User',
                                  style: Styles.whiteSmall,
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
      ),
    );
  }

  String? type;
  String? gender;

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
          type = FIELD_MONITOR;
          userType = 0;
          break;
        case 1:
          type = ORG_ADMINISTRATOR;
          userType = 1;
          break;
        case 2:
          type = ORG_EXECUTIVE;
          userType = 2;
          break;
      }
    });
  }
}
