 import 'package:oktoast/oktoast.dart';
import 'package:rnd_mobile/providers/notifications_provider.dart';
import 'package:rnd_mobile/providers/purchase_order/purch_order_filter_provider.dart';
import 'package:rnd_mobile/providers/purchase_request/purch_req_hist_filter_provider.dart';
import 'package:rnd_mobile/providers/purchase_order/purchase_order_provider.dart';
import 'package:rnd_mobile/providers/purchase_request/purchase_req_provider.dart';
import 'package:rnd_mobile/providers/refresh_icon_indicator_provider.dart';
import 'package:rnd_mobile/providers/sales_order/sales_order_hist_filter.provider.dart';
import 'package:rnd_mobile/providers/sales_order/sales_order_provider.dart';
import 'package:rnd_mobile/providers/items/items_provider.dart';
import 'package:rnd_mobile/screens/admin/web/web_admin_main.dart';
import 'package:rnd_mobile/utilities/shared_pref.dart';
import 'package:universal_io/io.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rnd_mobile/models/user_model.dart';
import 'package:rnd_mobile/providers/purchase_request/purch_req_filter_provider.dart';
import 'providers/purchase_order/puch_order_hist_filter_provider.dart';
import 'package:rnd_mobile/providers/user_provider.dart';
import 'package:rnd_mobile/screens/login_screen.dart';
import 'package:firedart/firedart.dart';
import 'package:flutter/foundation.dart';
import 'package:rnd_mobile/firebase/firestore.dart';

//--------------------WEB------------------------------
import 'dart:html' as web;

//--------------------DESKTOP--------------------------
// import 'package:local_notifier/local_notifier.dart';
// import 'package:window_size/window_size.dart';

//--------------------DESKTOP & WEB--------------------
import 'package:rnd_mobile/screens/web/web_home.dart';

//--------------------MOBILE---------------------------
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:rnd_mobile/firebase_options.dart';
// import 'package:rnd_mobile/widgets/toast.dart';

//--------------------WEB & MOBILE--------------------
import 'package:rnd_mobile/screens/mobile/mobile_home.dart';
import 'package:firebase_core/firebase_core.dart';

// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   //while app is in the background
//   String type = message.data['type'];

//   SharedPreferencesService().setRequest(
//       type: type,
//       requestNumber: type == 'PR'
//           ? int.parse(message.data['preqNum'])
//           : int.parse(message.data['poNum']));
//   // AudioCache().play('audio/notif_sound2.mp3');
//   // print('_firebaseMessagingBackgroundHandler!!!!!!!!!');
//   // SharedPreferencesService().getRequest().then((value) {
//   //   showToast('SharedPreferencesService111: $value');
//   // });
//   // showToast('END OF _firebaseMessagingBackgroundHandler');
// }

void main() async {
  //OTHER MOBILES NEED THIS
  //HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  String? token;

  //--------------------WEB---------------------
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAqX9tCKb9Ce2rb5d_rShSNEjDjXoIADSc",
        authDomain: "prime-software-62e3a.firebaseapp.com",
        projectId: "prime-software-62e3a",
        storageBucket: "prime-software-62e3a.appspot.com",
        messagingSenderId: "431428997513",
        appId: "1:431428997513:web:beb46636c4b5b39bf59158",
      ),
    );
    if (web.Notification.permission != 'granted') {
      web.Notification.requestPermission();
    }
  }

  //--------------------MOBILE---------------------

  // if (Platform.isAndroid || Platform.isIOS) {
  //   await Firebase.initializeApp(options: DefaultFirebaseOptions.android);

  //   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  //   FirebaseMessaging messaging = FirebaseMessaging.instance;

  //   if (!await SharedPreferencesService().tokenExists()) {
  //     token = await messaging.getToken(
  //         vapidKey:
  //             'BHMhBBrV_WTKZwItCmH1IJ9vo1i3ZKNBZ-FrviLLdFinU1dRaLQJNspQz_2zZSv-Nbp7iC5fqYExa4MGT4P87hQ');
  //     print('Device token: $token');
  //   }

  //   final NotificationSettings settings = await messaging.requestPermission();
  // }

  //--------------------DESKTOP------------- --------

  // const projectId = 'prime-software-62e3a';
  // Firestore.initialize(projectId);
  // await localNotifier.setup(
  //   appName: 'RnD_Mobile',
  //   // The parameter shortcutPolicy only works on Windows
  //   shortcutPolicy: ShortcutPolicy.requireCreate,
  // );
  // setWindowMinSize(const Size(700, 600));

  // runApp(WebAdmin());
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        //Purchase Request
        ChangeNotifierProvider(create: (_) => PurchReqProvider()),
        ChangeNotifierProvider(create: (_) => PurchReqFilterProvider()),
        ChangeNotifierProvider(create: (_) => PurchReqHistFilterProvider()),
        //Purchase Order
        ChangeNotifierProvider(create: (_) => PurchOrderProvider()),
        ChangeNotifierProvider(create: (_) => PurchOrderFilterProvider()),
        ChangeNotifierProvider(create: (_) => PurchOrderHistFilterProvider()),
        //Sales Order
        ChangeNotifierProvider(create: (_) => SalesOrderProvider()),
        ChangeNotifierProvider(create: (_) => SalesOrderHistFilterProvider()),
        ChangeNotifierProvider(create: (_) => ItemsProvider()),
        //Refresh Icon Indicator
        ChangeNotifierProvider(create: (_) => RefreshIconIndicatorProvider()),
        //Notifications
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MyApp(
        token: token,
      ),
    ),
  );
}

class CustomTraversalPolicy extends FocusTraversalPolicy {
  @override
  Iterable<FocusNode> sortDescendants(
      Iterable<FocusNode> descendants, FocusNode currentNode) {
    // Return the descendants unchanged.
    return descendants;
  }

  @override
  FocusNode? findFirstFocusInDirection(
      FocusNode currentNode, TraversalDirection direction) {
    // Return null to use the default behavior.
    return null;
  }

  @override
  bool inDirection(FocusNode currentNode, TraversalDirection direction) {
    // Return false to use the default behavior.
    return false;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({this.token, super.key});
  final String? token;
  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: MaterialApp(
        title: 'RnD',
        theme: ThemeData(
          // primarySwatch: customSwatch,
          primaryColor: Colors.blueGrey,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          canvasColor: Colors.grey[900],
          // primarySwatch: customSwatch,
          primarySwatch: Colors.blueGrey,
          inputDecorationTheme: const InputDecorationTheme(
            hintStyle: TextStyle(color: Colors.grey),
          ),
          appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              toolbarHeight: 66,
              titleTextStyle: TextStyle(fontSize: 20, color: Colors.white)),
          checkboxTheme: CheckboxThemeData(
            fillColor: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
              if (states.contains(MaterialState.disabled)) {
                return null;
              }
              if (states.contains(MaterialState.selected)) {
                return const Color(0xFF795FCD);
              }
              return null;
            }),
          ),
          radioTheme: RadioThemeData(
            fillColor: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
              if (states.contains(MaterialState.disabled)) {
                return null;
              }
              if (states.contains(MaterialState.selected)) {
                return const Color(0xFF795FCD);
              }
              return null;
            }),
          ),
          switchTheme: SwitchThemeData(
            thumbColor: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
              if (states.contains(MaterialState.disabled)) {
                return null;
              }
              if (states.contains(MaterialState.selected)) {
                return const Color(0xFF795FCD);
              }
              return null;
            }),
            trackColor: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
              if (states.contains(MaterialState.disabled)) {
                return null;
              }
              if (states.contains(MaterialState.selected)) {
                return const Color(0xFF795FCD);
              }
              return null;
            }),
          ),
        ),
        home: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            return FutureBuilder<List<dynamic>>(
                future: Future.wait([
                  SharedPreferencesService().getUser(),
                  SharedPreferencesService().nonMobileExists(),
                  SharedPreferencesService().tokenExists()
                ]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else {
                    if (snapshot.hasData) {
                      final data = snapshot.data![0] as Map<String, String>;
                      final nonMobileExists = snapshot.data![1];
                      final tokenExists = snapshot.data![2];
                      if (data['username'] != '' && data['sessionId'] != '') {
                        final user = UserModel(
                            username: data['username']!,
                            sessionId: data['sessionId']!);
                        userProvider.setUser(user, notify: false);
                      }
                      if (userProvider.user == null) {
                        // User is not logged in
                        return const LoginScreen();
                      } else {
                        // User is logged in
                        if (!Platform.isAndroid && !Platform.isIOS) {
                          if (!nonMobileExists) {
                            SharedPreferencesService().saveNonMobile(true);
                            if (kIsWeb) {
                              //web uses firebase firestore
                              FirestoreService().create(
                                  collection: 'tokens',
                                  documentId: userProvider.user!.username,
                                  data: {'nonMobile': true});
                            } else {
                              //desktop uses firedart
                              Firestore.instance
                                  .collection("tokens")
                                  .document(userProvider.user!.username)
                                  .set({'nonMobile': true}, merge: true);
                            }
                          }
                        }
                        //--------------------MOBILE---------------------

                        else {
                          if (!tokenExists) {
                            if (token != null) {
                              SharedPreferencesService().saveToken(token!);
                              FirestoreService().create(
                                  collection: 'tokens',
                                  documentId: userProvider.user!.username,
                                  data: token,
                                  forDeviceToken: true);
                            }
                          }
                        }
                        //web
                        if (MediaQuery.of(context).size.width < 600) {
                          return const MobileHome();
                        } else {
                          return const WebHome();
                        }

                        //mobile
                        // return const MobileHome();

                        //desktop
                        // return const WebHome();
                      }
                    } else {
                      return const Center(child: Text('Something Went Wrong'));
                    }
                  }
                });
          },
        ),
      ),
    );
  }
}

const MaterialColor customSwatch = MaterialColor(
  0xFF795FCD,
  <int, Color>{
    50: Color(0xFF795FCD),
    100: Color(0xFF795FCD),
    200: Color(0xFF795FCD),
    300: Color(0xFF795FCD),
    400: Color(0xFF795FCD),
    500: Color(0xFF795FCD),
    600: Color(0xFF795FCD),
    700: Color(0xFF795FCD),
    800: Color(0xFF795FCD),
    900: Color(0xFF795FCD),
  },
);
// const MaterialColor lightPurpleSwatch = MaterialColor(
//   0xFFB39DDB,
//   <int, Color>{
//     50: Color(0xFFF3E5F5),
//     100: Color(0xFFE1BEE7),
//     200: Color(0xFFCE93D8),
//     300: Color(0xFFBA68C8),
//     400: Color(0xFFAB47BC),
//     500: Color(0xFF9C27B0),
//     600: Color(0xFF8E24AA),
//     700: Color(0xFF7B1FA2),
//     800: Color(0xFF6A1B9A),
//     900: Color(0xFF4A148C),
//   },
// );

//test notif
// curl -X POST -H "Content-Type: application/json" -d "{\"username\":\"admin\",\"preqNum\":\"16\",\"requestDate\":\"16\",\"reference\":\"16\",\"warehouse\":\"16\",\"requestedBy\":\"16\",\"reason\":\"16\"}" http://192.168.254.163:3000/send-push-notification


//PR
// curl -X POST -H "Content-Type: application/json" -d "{\"usernames\":[\"admin\"],\"type\":\"PR\",\"preqNum\":\"25\",\"requestDate\":\"16\",\"reference\":\"16\",\"warehouse\":\"16\",\"requestedBy\":\"16\",\"reason\":\"16\"}" http://192.168.254.163:3000/send-push-notification
//PR only preqNum
// curl -X POST -H "Content-Type: application/json" -d "{\"usernames\":[\"admin\"],\"type\":\"PR\",\"preqNum\":\"44\"}" http://192.168.254.163:3000/send-push-notification

//PO
// curl -X POST -H "Content-Type: application/json" -d "{\"usernames\":[\"admin\"],\"type\":\"PO\",\"poNum\":\"16\",\"poDate\":\"16\",\"delvDate\":\"16\",\"reference\":\"16\",\"warehouse\":\"16\",\"purpose\":\"16\",\"remarks\":\"16\"}" http://192.168.254.163:3000/send-push-notification
//PO only poNum
//curl -X POST -H "Content-Type: application/json" -d "{\"usernames\":[\"admin\"],\"type\":\"PO\",\"poNum\":\"21\"}" http://192.168.254.163:3000/send-push-notification

//group
// curl -X POST -H "Content-Type: application/json" -d "{\"group\":\"groupname\",\"type\":\"group\",\"title\":\"Group Notif Title\",\"body\":\"group notif test\"}" http://192.168.254.163:3000/send-push-notification-group