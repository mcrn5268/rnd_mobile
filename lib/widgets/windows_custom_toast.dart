import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:toastification/toastification.dart';

class CustomToast {
  static void show(
      {required BuildContext context,
      required String message,
      bool fromLogin = false}) {
    if (context.mounted) {
      showToast() {
        Toastification().show(
          context: context,
          title: message,
          autoCloseDuration: const Duration(seconds: 3),
          icon: const Icon(Icons.info),
          backgroundColor: Colors.black,
        );
      }

      if (fromLogin) {
        showToast();
      } else {
        SchedulerBinding.instance.addPostFrameCallback((_) => showToast());
      }
    }
  }
}
