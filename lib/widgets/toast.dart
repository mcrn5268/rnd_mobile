import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
import 'package:oktoast/oktoast.dart';

void showToastMessage(String message, {bool errorToast = false}) {
  showToastWidget(
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: Colors.black,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon(Icons.check, color: Colors.green),
          // SizedBox(width: 12.0),
          Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          if (errorToast) ...[
            const SizedBox(width: 12.0),
            GestureDetector(
              onTap: () {
                dismissAllToast();
              },
              child: const Icon(Icons.close, color: Colors.red),
            ),
          ]
        ],
      ),
    ),
    position: ToastPosition.bottom,
    duration:
        errorToast ? const Duration(minutes: 1) : const Duration(seconds: 5),
    handleTouch: true,
  );
}


// void showToast(String message,
//     {ToastGravity gravity = ToastGravity.BOTTOM, int timeInSecForWeb = 2}) {
//   Fluttertoast.showToast(
//       msg: message,
//       toastLength: Toast.LENGTH_LONG,
//       gravity: gravity,
//       timeInSecForIosWeb: timeInSecForWeb,
//       textColor: Colors.white,
//       fontSize: 16.0,
//       webBgColor: "#333333",
//       webPosition: "center");
// }
