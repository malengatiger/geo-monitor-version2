import 'package:flutter/material.dart';
import 'package:geo_monitor/library/functions.dart';

import 'package:responsive_builder/responsive_builder.dart';

import '../../api/data_api.dart';
import '../../data/country.dart';
import '../../data/user.dart';
import '../../hive_util.dart';
import 'user_edit_desktop.dart';
import 'user_edit_mobile.dart';
import 'user_edit_tablet.dart';

class UserEditMain extends StatelessWidget {
  final User? user;

  const UserEditMain(this.user, {super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout(
      mobile: UserEditMobile(user),
      tablet: UserEditTablet(user),
      desktop: UserEditDesktop(user),
    );
  }
}


class CountryChooser extends StatefulWidget {
  const CountryChooser({Key? key, required this.onSelected}) : super(key: key);
  final Function(Country) onSelected;

  @override
  State<CountryChooser> createState() => CountryChooserState();
}

class CountryChooserState extends State<CountryChooser> {
  List<Country> countries = <Country>[];
  bool loading = false;
  @override
  void initState() {
    super.initState();
    _getData();
  }
  void _getData() async {
    setState(() {
      loading = true;
    });
    countries = await cacheManager.getCountries();
    if (countries.isEmpty) {
      countries = await DataAPI.getCountries();
    }
    countries.sort((a,b) => a.name!.compareTo(b.name!));
    _buildDropDown();
    setState(() {
      loading = false;
    });
  }
  var list = <DropdownMenuItem>[];
  void _buildDropDown() {
    for (var entry in countries) {
      list.add(DropdownMenuItem<Country>(
        value: entry,
        child: Text(entry.name!, style: myTextStyleSmall(context),),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {

    return  loading? const SizedBox(height: 20, width: 20,
    child: CircularProgressIndicator(
      strokeWidth: 4, backgroundColor: Colors.pink,
    ),) : DropdownButton(
        elevation: 4, hint:  Text('Countries', style: myTextStyleSmall(context),),

        items: list, onChanged: onChanged);
  }

  void onChanged(value) {
    widget.onSelected(value);
  }
}

