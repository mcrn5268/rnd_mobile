import 'package:flutter/material.dart';

class RefreshIconIndicatorProvider extends ChangeNotifier {
  bool _show = false;

  bool get show => _show;

  void setShow({required bool show}) {
    if (_show != show) {
      _show = show;
      notifyListeners();
    }
  }
}
