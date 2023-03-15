import 'package:flutter/material.dart';

import '../../api/data_api.dart';
import '../../cache_manager.dart';
import '../../data/country.dart';
import '../../functions.dart';

class CountryChooser extends StatefulWidget {
  const CountryChooser({Key? key, required this.onSelected, required this.hint}) : super(key: key);
  final Function(Country) onSelected;
  final String hint;

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
    countries.sort((a, b) => a.name!.compareTo(b.name!));
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
        child: Text(
          entry.name!,
          style: myTextStyleSmall(context),
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              backgroundColor: Colors.pink,
            ),
          )
        : DropdownButton(
            elevation: 4,
            hint: Text(widget.hint,
              style: myTextStyleMedium(context),
            ),
            items: list,
            onChanged: onChanged);
  }

  void onChanged(value) {
    widget.onSelected(value);
  }
}
