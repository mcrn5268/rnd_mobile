import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void showToast(String message,
    {ToastGravity gravity = ToastGravity.BOTTOM, int timeInSecForWeb = 2}) {
  Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: gravity,
      timeInSecForIosWeb: timeInSecForWeb,
      textColor: Colors.white,
      fontSize: 16.0,
      webBgColor: "#333333",
      webPosition: "center");
}
