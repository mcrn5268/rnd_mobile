import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:proste_bezier_curve/proste_bezier_curve.dart';
import 'package:provider/provider.dart';
import 'package:rnd_mobile/api/auth_api.dart';
import 'package:rnd_mobile/models/user_model.dart';
import 'package:rnd_mobile/providers/user_provider.dart';
import 'package:rnd_mobile/utilities/shared_pref.dart';
import 'package:rnd_mobile/widgets/windows_custom_toast.dart';
import 'package:rnd_mobile/widgets/toast.dart';
import 'package:universal_io/io.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameLogin = TextEditingController();
  final _passLogin = TextEditingController();
  late final UserProvider userProvider;
  bool logInHasError = false;
  bool _isLoading = false;
  String? _loginUsernameErrorText;
  String? _loginPasswordErrorText;
  bool _passwordVisible = true;

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProvider>(context, listen: false);
    _usernameLogin.text = 'admin';
    _passLogin.text = '';
  }

  @override
  void dispose() {
    _usernameLogin.dispose();
    _passLogin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget notLoggedIn = SingleChildScrollView(
      child: Stack(
        children: [
          Column(
            children: [
              Stack(
                children: [
                  Column(
                    children: [
                      ClipPath(
                        clipper: ProsteThirdOrderBezierCurve(
                          position: ClipPosition.bottom,
                          list: [
                            ThirdOrderBezierCurveSection(
                              p1: const Offset(0, 300),
                              p2: const Offset(0, 120),
                              p3: Offset(
                                  MediaQuery.of(context).size.width, 300),
                              p4: Offset(
                                  MediaQuery.of(context).size.width, 120),
                            ),
                          ],
                        ),
                        child: Container(
                          height: 300,
                          decoration: const BoxDecoration(
                              image: DecorationImage(
                                  image: AssetImage(
                                      'assets/images/desk-image2.jpg'),
                                  fit: BoxFit.cover)),
                        ),
                      ),
                      const SizedBox(height: 75),
                      Center(
                        child: Container(
                          height: logInHasError ? 133 : 112,
                          width: Platform.isAndroid
                              ? MediaQuery.of(context).size.width - 50
                              : 400,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey[350],
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10, right: 10),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _usernameLogin,
                                  style: const TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(
                                      Icons.person_outline,
                                      color: Colors.black,
                                    ),
                                    hintText: 'Username',
                                    border: InputBorder.none,
                                    errorText: _loginUsernameErrorText,
                                    errorStyle: const TextStyle(
                                      color: Colors.red,
                                    ),
                                  ),
                                  onChanged: (textt) {
                                    setState(() {
                                      _loginUsernameErrorText = null;
                                    });
                                  },
                                ),
                                const Divider(
                                  color: Colors.grey,
                                ),
                                TextFormField(
                                  obscureText: _passwordVisible,
                                  style: const TextStyle(color: Colors.black),
                                  controller: _passLogin,
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: Colors.black,
                                    ),
                                    suffixIcon: Visibility(
                                      visible: _passLogin.text.isNotEmpty,
                                      child: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _passwordVisible =
                                                !_passwordVisible;
                                          });
                                        },
                                        //have no right eye icon, I have to import a package that has it
                                        //for now temporarily I'll use check and close
                                        icon: FaIcon(
                                          _passwordVisible
                                              ? FontAwesomeIcons.eye
                                              : FontAwesomeIcons.eyeSlash,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    hintText: 'Password',
                                    border: InputBorder.none,
                                    errorText: _loginPasswordErrorText,
                                  ),
                                  onChanged: (textt) {
                                    setState(() {
                                      _loginPasswordErrorText = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),

                  //Log in button
                  Padding(
                    padding: const EdgeInsets.only(top: 510),
                    child: Column(
                      children: [
                        Center(
                          child: Container(
                              height: 40,
                              width: Platform.isAndroid
                                  ? MediaQuery.of(context).size.width - 50
                                  : 400,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.grey[350],
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                  onPressed: () async {
                                    setState(() {
                                      _isLoading = true;
                                    });
                                    final response = await AuthAPIService.login(
                                        password: _passLogin.text,
                                        username: _usernameLogin.text);

                                    if (response.body.isNotEmpty) {
                                      try {
                                        final responseData =
                                            json.decode(response.body);
                                        if (responseData
                                            .containsKey('result')) {
                                          final sessionId =
                                              responseData['result']
                                                  ['SessionID'];
                                          if (sessionId != null) {
                                            const message =
                                                'Success!';
                                            if (kIsWeb || Platform.isAndroid) {
                                              showToast(message);
                                            } else {
                                              if (mounted) {
                                                CustomToast.show(
                                                    context: context,
                                                    message: message,
                                                    fromLogin: true);
                                              }
                                            }
                                            SharedPreferencesService().saveUser(
                                                username: _usernameLogin.text,
                                                sessionId: sessionId);
                                          } else {
                                            if (kIsWeb) {
                                              showToast('Session ID is null');
                                            } else {
                                              if (mounted) {
                                                CustomToast.show(
                                                    context: context,
                                                    message:
                                                        'Session ID is null');
                                              }
                                            }
                                          }

                                          if (kDebugMode) {
                                            print('sessionId: $sessionId');
                                          }
                                          final user = UserModel(
                                              username: _usernameLogin.text,
                                              sessionId: sessionId);
                                          userProvider.setUser(user);
                                        } else if (responseData
                                            .containsKey('error')) {
                                          final errorMsg =
                                              responseData['error']['msg'];
                                          if (kIsWeb) {
                                            showToast('Error: $errorMsg');
                                          } else {
                                            if (mounted) {
                                              CustomToast.show(
                                                  context: context,
                                                  message: 'Error: $errorMsg');
                                            }
                                          }
                                        } else {
                                          if (kIsWeb) {
                                            showToast(
                                                'Unexpected response format');
                                          } else {
                                            if (mounted) {
                                              CustomToast.show(
                                                  context: context,
                                                  message:
                                                      'Unexpected response format');
                                            }
                                          }
                                        }
                                      } catch (e) {
                                        if (kDebugMode) {
                                          print('Error decoding JSON: $e');
                                        }
                                      }
                                    } else {
                                      if (kDebugMode) {
                                        print('response body is null');
                                      }
                                    }
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      elevation: 0),
                                  child: _isLoading
                                      ? const CircularProgressIndicator()
                                      : const Text(
                                          'Log in',
                                          style: TextStyle(color: Colors.black),
                                        ))),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ],
          ),
          Positioned(
            top: 0,
            width: MediaQuery.of(context).size.width,
            child: const Padding(
              padding: EdgeInsets.only(top: 270),
              child: Column(
                children: [
                  Text(
                    'Good day!',
                    style: TextStyle(
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
    return Scaffold(body: notLoggedIn);
  }
}
