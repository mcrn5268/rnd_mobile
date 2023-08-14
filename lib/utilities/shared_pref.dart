import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  //for device token
  final String _tokenKey = 'token_device';

  Future<void> saveToken(String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<bool> tokenExists() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey);
  }

//for session handling
  final String _usernameKey = 'username';
  final String _sIDKey = 'sID';
  Future<void> saveUser(
      {required String username, required String sessionId}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_sIDKey, sessionId);
  }

  Future<Map<String, String>> getUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? username = prefs.getString(_usernameKey);
    final String? sessionId = prefs.getString(_sIDKey);
    return {
      'username': username ?? '',
      'sessionId': sessionId ?? '',
    };
  }

  Future<void> removeUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usernameKey);
    await prefs.remove(_sIDKey);
  }

  Future<bool> userExists() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (kDebugMode) {
      print(
          'exist?: ${prefs.containsKey(_usernameKey) && prefs.containsKey(_sIDKey)}');
    }
    return prefs.containsKey(_usernameKey) && prefs.containsKey(_sIDKey);
  }

  //for FCM background handler
  final String _type = 'request_type';
  final String _requestNumber = 'request_number';
  Future<void> setRequest(
      {required String type, required int requestNumber}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_type, type);
    await prefs.setInt(_requestNumber, requestNumber);
  }

  Future<Map<String, dynamic>> getRequest() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? type = prefs.getString(_type);
    final int? requestNumber = prefs.getInt(_requestNumber);
    return {'type': type ?? '', 'requestNumber': requestNumber ?? -1};
  }
}
