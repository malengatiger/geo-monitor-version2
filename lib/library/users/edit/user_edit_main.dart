import 'package:flutter/material.dart';

import 'package:responsive_builder/responsive_builder.dart';

import '../../api/data_api.dart';
import '../../data/country.dart';
import '../../data/user.dart';
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
  State<CountryChooser> createState() => _CountryChooserState();
}

class _CountryChooserState extends State<CountryChooser> {
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
    countries = await DataAPI.getCountries();
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
        child: Text(entry.name!),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {

    return  DropdownButton(items: list, onChanged: onChanged);
  }

  void onChanged(value) {
    widget.onSelected(value);
  }
}

