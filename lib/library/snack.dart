import 'package:flutter/material.dart';


///Utility class to provide snackbars
class AppSnackbar {
  static showSnackbar(
      {required GlobalKey<ScaffoldState> scaffoldKey,
        required String message,
        required Color textColor,
        required Color backgroundColor}) {

  }

  static showSnackbarWithProgressIndicator(
      {required GlobalKey<ScaffoldState> scaffoldKey,
        required String message,
        required Color textColor,
        required Color backgroundColor}) {

  }

  static showSnackbarWithAction(
      {required GlobalKey<ScaffoldState> scaffoldKey,
        required String message,
        required Color textColor,
        required Color backgroundColor,
        String? actionLabel,
        SnackBarListener? listener,
        IconData? icon,
        int? durationMinutes,
        int? action}) {

  }


  static showErrorSnackbar(
      {required GlobalKey<ScaffoldState> scaffoldKey,
        required String message,
        SnackBarListener? listener,
        String? actionLabel = ''}) {

  }

}

abstract class SnackBarListener {
  onActionPressed(int action);
}