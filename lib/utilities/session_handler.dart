import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rnd_mobile/utilities/clear_data.dart';
import 'package:rnd_mobile/widgets/alert_dialog.dart';
import 'package:rnd_mobile/widgets/toast.dart';
import 'package:rnd_mobile/widgets/windows_custom_toast.dart';
import 'package:universal_io/io.dart';

bool alreadyShowedDialog = false;
bool handleSessionExpiredException(dynamic data, BuildContext context) {
  if (data is Map &&
      data['error'] != null &&
      data['error']['class'] == 'ESessionExpiredException') {
    if (!alreadyShowedDialog) {
      if (context.mounted) {
        Future.delayed(Duration.zero, () {
          alertDialog(context,
              title: 'Session Expired', body: 'Please Login Again.');
        });
      }

      // if (kIsWeb || Platform.isAndroid) {
      //   showToastMessage('Session Expired. Please Login Again.',
      //       errorToast: true);
      // } else {
      //   CustomToast.show(
      //       context: context, message: 'Session Expired. Please Login Again.');
      // }
      alreadyShowedDialog = true;
    }

    clearData(context);
    return true;
  } else {
    return false;
  }
}
