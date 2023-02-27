import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geo_monitor/library/cache_manager.dart';
import 'package:geo_monitor/library/data/audio.dart';
import 'package:geo_monitor/library/data/photo.dart';
import 'package:geo_monitor/library/data/video.dart';
import 'package:geo_monitor/library/users/edit/user_form.dart';
import 'package:geo_monitor/library/users/full_user_photo.dart';
import 'package:geo_monitor/ui/activity/geo_activity.dart';
import 'package:page_transition/page_transition.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:uuid/uuid.dart';

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

class UserEditTablet extends StatefulWidget {
  final ar.User? user;

  const UserEditTablet({super.key, this.user});

  @override
  UserEditTabletState createState() => UserEditTabletState();
}

class UserEditTabletState extends State<UserEditTablet>
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
    admin = await prefsOGx.getUser();
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

  Future _setCountry() async {
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
            pp('\n🍎🍎🍎🍎 UserEditTabletPortrait: 🍎 A user has been created:  🍎 '
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

  int userType = -1;
  int genderType = -1;

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

  @override
  Widget build(BuildContext context) {
    var topPadding = 0.0;
    final ori = MediaQuery.of(context).orientation;
    if (ori.name == 'portrait') {
      topPadding = 80;
    } else {
      topPadding = 48;
    }
    final width = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        key: _key,
        appBar: AppBar(
          title: Text(
            'Geo Member Editor',
            style: myTextStyleLarge(context),
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(topPadding),
            child: Column(
              children: [
                Text(
                  widget.user == null
                      ? 'New Monitor User'
                      : 'Edit Monitor User',
                  style: myTextStyleMedium(context),
                ),

                const SizedBox(
                  height: 12,
                )
              ],
            ),
          ),
        ),
        body: OrientationLayoutBuilder(
          portrait: (ctx) {
            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(48.0),
                  child: Row(
                    children: [
                      UserForm(
                        width: width / 2,
                        internalPadding: 32,
                        user: widget.user,
                      ),
                      GeoActivity(
                          width: (width / 2) - 100,
                          thinMode: true,
                          showPhoto: showPhoto,
                          showVideo: showVideo,
                          showAudio: showAudio,
                          forceRefresh: false)
                    ],
                  ),
                ),
                widget.user?.thumbnailUrl == null
                    ?  Positioned(
                        right:  (width / 2) - 60,
                        top: 16,
                        child: const CircleAvatar(
                          radius: 24,
                        ))
                    : Positioned(
                        right: (width / 2) - 60,
                        top: 16,
                        child: GestureDetector(
                          onTap: _navigateToFullPhoto,
                          child: CircleAvatar(
                            radius: 48,
                            backgroundImage:
                                NetworkImage(widget.user!.thumbnailUrl!),
                          ),
                        )),
              ],
            );
          },
          landscape: (ctx) {
            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(48.0),
                  child: Row(
                    children: [
                      UserForm(
                        width: width / 2,
                        internalPadding: 36,
                        user: widget.user,
                      ),
                      GeoActivity(
                          width: (width / 2) - 100,
                          thinMode: true,
                          showPhoto: showPhoto,
                          showVideo: showVideo,
                          showAudio: showAudio,
                          forceRefresh: false)
                    ],
                  ),
                ),
                widget.user?.thumbnailUrl == null
                    ? const Positioned(
                        right: 36,
                        top: 36,
                        child: CircleAvatar(
                          radius: 48,
                        ))
                    : Positioned(
                        right: 36,
                        top: 16,
                        child: GestureDetector(
                          onTap: _navigateToFullPhoto,
                          child: CircleAvatar(
                            radius: 86,
                            backgroundImage:
                                NetworkImage(widget.user!.thumbnailUrl!),
                          ),
                        )),
              ],
            );
          },
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

  showPhoto(Photo p1) {}

  showVideo(Video p1) {}

  showAudio(Audio p1) {}
}
