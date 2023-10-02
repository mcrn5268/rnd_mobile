import 'package:flutter/material.dart';

class NotificationProvider extends ChangeNotifier {
  List<dynamic> _notifications = [];
  bool _seen = true;

  List<dynamic> get notifications => _notifications;
  bool get seen => _seen;

  void setNotifications(List<dynamic> notifications, {bool notify = true}) {
    _notifications = notifications;
    _seen = !notifications.any((notif) => notif['seen'] == false);

    if (notify) {
      notifyListeners();
    }
  }

  void addNotification(dynamic notification, {bool notify = true}) {
    _notifications.add(notification);
    _seen = !notifications.any((notif) => notif['seen'] == false);

    if (notify) {
      notifyListeners();
    }
  }

  void clearNotifications({bool notify = true}) {
    _notifications = [];
    if (notify) {
      notifyListeners();
    }
  }

  void setSeen(bool seen, {bool notify = true}) {
    _seen = seen;
    if (notify) {
      notifyListeners();
    }
  }

  void clearSeen({bool notify = true}) {
    _seen = true;
    if (notify) {
      notifyListeners();
    }
  }
}
