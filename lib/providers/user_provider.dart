import 'package:flutter/material.dart';
import 'package:rnd_mobile/models/user_model.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;

  UserModel? get user => _user;

  void setUser(UserModel user, {bool notify = true}) {
    _user = user;
    if (notify) {
      notifyListeners();
    }
  }

  void clearUser({bool notify = true}) {
    _user = null;
    if (notify) {
      notifyListeners();
    }
  }

  void updateUser({String? username, String? sessionId}) {
    if (_user != null) {
      _user = UserModel(
        username: username ?? _user!.username,
        sessionId: sessionId ?? _user!.sessionId,
      );

      notifyListeners();
    }
  }
}
