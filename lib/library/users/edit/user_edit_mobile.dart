import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';

import '../../api/data_api.dart';
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
      pp('🔵🔵 ....... Submitting user data to create a new User!');
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
              fcmRegistration: 'tbd', password: const Uuid().v4(),
              userId: 'tbd');
          pp('\n\n\n😡😡😡 _submit new user ......... ${user.toJson()}');
          try {
            var mUser = await DataAPI.registerUser(user);
            pp('\n🍎🍎🍎🍎 UserEditMobile: 🍎 A user has been created:  🍎 ${mUser.toJson()}\b');
            gender = null;
            type = null;
            showToast(
                message: 'User created: ${user.name}',
                context: context,
                backgroundColor: Colors.teal,
                textStyle: Styles.whiteSmall,
                toastGravity: ToastGravity.TOP,
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
            style: myTextStyleSmall(context),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Column(
              children: [
                Text(
                  widget.user == null
                      ? 'New Monitor User'
                      : 'Edit Monitor User',
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
        body: Padding(
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
                        height: 8,
                      ),
                      Row(
                        children: [
                          CountryChooser(onSelected: (c) {
                            setState(() {
                              country = c;
                            });
                          }),
                          const SizedBox(width: 12,),
                          country == null? const SizedBox(): Text('${country!.name}', style: myTextStyleMedium(context),),
                        ],
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      TextFormField(
                        controller: nameController,
                        keyboardType: TextInputType.text,
                        style: myTextStyleSmall(context),
                        decoration: InputDecoration(
                            icon: Icon(
                              Icons.person, size: 18,
                              color: Theme.of(context).primaryColor,
                            ),
                            labelText: 'Name', hintStyle: myTextStyleSmall(context),
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
                              Icons.email_outlined, size: 18,
                              color: Theme.of(context).primaryColor,
                            ),
                            labelText: 'Email Address', hintStyle: myTextStyleSmall(context),
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
                              Icons.phone, size: 18,
                              color: Theme.of(context).primaryColor,
                            ),
                            labelText: 'Cellphone', hintStyle: myTextStyleSmall(context),
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
