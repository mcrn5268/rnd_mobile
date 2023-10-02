import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:restart_app/restart_app.dart';
import 'package:rnd_mobile/api/auth_api.dart';
import 'package:rnd_mobile/api/purchase_order_api.dart';
import 'package:rnd_mobile/api/purchase_req_api.dart';
import 'package:rnd_mobile/api/sales_order_api.dart';
import 'package:rnd_mobile/firebase/firestore.dart';
import 'package:rnd_mobile/models/purchase_order_model.dart';
import 'package:rnd_mobile/models/purchase_req_model.dart';
import 'package:rnd_mobile/models/sales_order_model.dart';
import 'package:rnd_mobile/providers/notifications_provider.dart';
import 'package:rnd_mobile/providers/purchase_order/purchase_order_provider.dart';
import 'package:rnd_mobile/providers/purchase_request/purchase_req_provider.dart';
import 'package:rnd_mobile/providers/items/items_provider.dart';
import 'package:rnd_mobile/providers/refresh_icon_indicator_provider.dart';
import 'package:rnd_mobile/providers/sales_order/sales_order_provider.dart';
import 'package:rnd_mobile/providers/user_provider.dart';
import 'package:rnd_mobile/screens/admin/mobile/mob_admin_main.dart';
import 'package:rnd_mobile/screens/mobile/items/mob_items_main.dart';
import 'package:rnd_mobile/screens/mobile/purchase_order/mob_purch_order_main.dart';
import 'package:rnd_mobile/screens/mobile/purchase_request/mob_purch_req_main.dart';
import 'package:rnd_mobile/screens/mobile/sales_order/mob_sales_order_main.dart';
import 'package:rnd_mobile/utilities/clear_data.dart';
import 'package:rnd_mobile/utilities/session_handler.dart';
import 'package:rnd_mobile/utilities/shared_pref.dart';
import 'package:rnd_mobile/utilities/timestamp_formatter.dart';
import 'package:rnd_mobile/widgets/alert_dialog.dart';
import 'package:rnd_mobile/widgets/greetings.dart';
import 'package:rnd_mobile/widgets/lazy_indexedstack.dart';
import 'package:rnd_mobile/widgets/show_dialog.dart';
import 'package:rnd_mobile/widgets/toast.dart';
import 'package:rnd_mobile/widgets/windows_custom_toast.dart';
import 'package:universal_io/io.dart';

//ONLY ENABLE THIS PACKAGE FOR WEB
// import 'dart:js' as js;
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'dart:async';

//ONLY ENABLE THIS PACKAGE FOR MOBILE
import 'package:firebase_messaging/firebase_messaging.dart';

class MobileHome extends StatefulWidget {
  const MobileHome({super.key});

  @override
  State<MobileHome> createState() => _MobileHomeState();
}

class _MobileHomeState extends State<MobileHome>
    with AutomaticKeepAliveClientMixin {
  late final UserProvider userProvider;
  late final PurchReqProvider purchReqProvider;
  late final PurchOrderProvider purchOrderProvider;
  late final SalesOrderProvider salesOrderProvider;
  late final ItemsProvider salesOrderItemsProvider;
  late final RefreshIconIndicatorProvider refreshIconIndicatorProvider;
  late final NotificationProvider notifProvider;
  late List<Future<dynamic>> futures;
  bool greetings = true;
  bool _isLoading = false;
  bool refresh = false;
  late ValueNotifier<int> indexNotifier;
  late ValueNotifier<String> titleNotifier;
  final player = AudioCache();
  late Brightness brightness;

  //ONLY FOR WEB
  // StreamSubscription<DocumentSnapshot>? _subscription;

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProvider>(context, listen: false);
    purchReqProvider = Provider.of<PurchReqProvider>(context, listen: false);
    purchOrderProvider =
        Provider.of<PurchOrderProvider>(context, listen: false);
    salesOrderProvider =
        Provider.of<SalesOrderProvider>(context, listen: false);
    salesOrderItemsProvider =
        Provider.of<ItemsProvider>(context, listen: false);
    refreshIconIndicatorProvider =
        Provider.of<RefreshIconIndicatorProvider>(context, listen: false);
    notifProvider = Provider.of<NotificationProvider>(context, listen: false);
    brightness = PlatformDispatcher.instance.platformBrightness;
    if (purchReqProvider.purchaseRequestList.isEmpty ||
        purchOrderProvider.purchaseOrderList.isEmpty ||
        salesOrderProvider.salesOrderList.isEmpty ||
        salesOrderItemsProvider.items.isEmpty) {
      futures = [
        _getPurchReqData(),
        _getPurchOrderData(),
        // _getSalesOrderData(),
        // _getSalesOrderItemsData(),
        FirestoreService().read(
            collection: 'notifications',
            documentId: userProvider.user!.username)
      ];
    } else {
      futures = _getLoadedData();
    }
    // greetings is for showing page not in nav menu/bar
    if (greetings) {
      indexNotifier = ValueNotifier(4);
      titleNotifier = ValueNotifier('');
    }
    if (kIsWeb) {
      // webNotificationStream();
    } else {
      // when user taps notif
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        setState(() {
          futures = [
            _getPurchReqData(button: true),
            _getPurchOrderData(button: true),
            // _getSalesOrderData(button: true),
            // _getSalesOrderItemsData(button: true),
          ];
        });
        if (message.data['type'] == 'PR') {
          String requestNumber = message.data['preqNum'];
          purchReqProvider.setReqNumber(
              reqNumber: int.parse(requestNumber), notify: true);
          indexNotifier = ValueNotifier(0);
        }
        if (message.data['type'] == 'PO') {
          String orderNumber = message.data['poNum'];
          purchOrderProvider.setOrderNumber(
              orderNumber: int.parse(orderNumber), notify: true);
          indexNotifier = ValueNotifier(1);
        }
      });

      //foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final type = message.data['type'];
        print('foreground: $type');
        player.play('audio/notif_sound2.mp3');
        showToastMessage(
            type == 'PR' ? 'New Purchase Request!' : 'New Purchase Order!');
        refreshIconIndicatorProvider.setShow(show: true);
        notifProvider.addNotification({
          'type': type,
          'timestamp': Timestamp.now().millisecondsSinceEpoch,
          'seen': false,
          if (type == 'group') 'group': message.data['group'],
          if (type == 'PR') 'preqNum': message.data['preqNum'],
          if (type == 'PO') 'poNum': message.data['poNum'],
        });
      });
    }
  }

  @override
  void dispose() {
    indexNotifier.dispose();
    titleNotifier.dispose();
    // _subscription?.cancel();
    super.dispose();
  }

  // void webNotificationStream() {
  //   bool stream = false;
  //   final documentRef = FirebaseFirestore.instance
  //       .collection("notifications")
  //       .doc(userProvider.user!.username);
  //   _subscription = documentRef.snapshots().listen(
  //     (event) {
  //       if (stream) {
  //         final data = event.data()!;
  //         if (data['notifications'] != null) {
  //           if (data['triggerStream'] == true) {
  //             webNotification(data: data);
  //             player.play('audio/notif_sound2.mp3',
  //                 isNotification: true, volume: 0.5);
  //           }
  //           WidgetsBinding.instance.addPostFrameCallback((_) {
  //             notifProvider.setNotifications(data['notifications']);
  //             notifProvider.setSeen(!notifProvider.notifications
  //                 .any((notif) => notif['seen'] == false));
  //           });
  //         }
  //       }
  //       stream = true;
  //     },
  //     onError: (error) => print("Listen failed: $error"),
  //   );
  // }

  // js.JsObject createNotification(String title, String body) {
  //   showToastMessage(title);
  //   return js.JsObject(js.context['Notification'], [
  //     title,
  //     js.JsObject.jsify({'body': body})
  //   ]);
  // }

  // Future<void> webNotification({required Map<String, dynamic> data}) async {
  //   final notifications = data['notifications'];
  //   final lastNotification = notifications.last;
  //   final type = lastNotification['type'];

  //   if (type != "group") {
  //     refreshIconIndicatorProvider.setShow(show: true);
  //   }

  //   final notificationTitle = type == "group"
  //       ? 'New Notification!'
  //       : 'New Purchase ${type == "PR" ? "Request" : "Order"}!';

  //   final notificationBody = type == "group"
  //       ? lastNotification['body']
  //       : type == "PR"
  //           ? "Request Number: ${lastNotification['preqNum']}"
  //           : "Order Number: ${lastNotification['poNum']}";

  //   final notification =
  //       createNotification(notificationTitle, notificationBody);
  //   notification.callMethod('addEventListener', [
  //     'click',
  //     (event) {
  //       js.context.callMethod('focus');
  //       if (type != "group") {
  //         futures = [
  //           _getPurchReqData(button: true),
  //           _getPurchOrderData(button: true),
  //           // _getSalesOrderData(button: true),
  //           // _getSalesOrderItemsData(button: true),
  //         ];
  //       }
  //       if (data['type'] == 'PR') {
  //         purchReqProvider.setReqNumber(
  //             reqNumber: int.parse(data["preqNum"]), notify: true);
  //         indexNotifier.value = 0;
  //         indexNotifier = ValueNotifier(0);
  //       } else if (data['type'] == 'PO') {
  //         purchOrderProvider.setOrderNumber(
  //             orderNumber: int.parse(data["poNum"]), notify: true);
  //         indexNotifier.value = 1;
  //         indexNotifier = ValueNotifier(1);
  //       }
  //       setState(() {});
  //     }
  //   ]);
  // }

  List<Future<Map<String, dynamic>>> _getLoadedData() {
    return [
      Future.value({'purchaseRequests': purchReqProvider.purchaseRequestList}),
      Future.value({'purchaseOrders': purchOrderProvider.purchaseOrderList}),
      Future.value({'salesOrders': salesOrderProvider.salesOrderList}),
      Future.value({'items': salesOrderItemsProvider.items}),
    ];
  }

  // GET data
  Future<dynamic> _getPurchReqData({bool button = false}) {
    if (button) {
      purchReqProvider.clearReqNumber();
      purchReqProvider.clearList();
    }
    return PurchReqService.getPurchReqView(
      sessionId: userProvider.user!.sessionId,
      recordOffset: 0,
      forPending: true,
      // forAll: true
    );
  }

  Future<dynamic> _getPurchOrderData({bool button = false}) {
    if (button) {
      purchOrderProvider.clearOrderNumber();
      purchOrderProvider.clearList();
    }
    return PurchOrderService.getPurchOrderView(
      sessionId: userProvider.user!.sessionId,
      recordOffset: 0,
      forPending: true,
      // forAll: true
    );
  }

  // Future<dynamic> _getSalesOrderData({bool button = false}) {
  //   if (button) {
  //     salesOrderProvider.clearOrderNumber();
  //     salesOrderProvider.clearList();
  //   }
  //   return SalesOrderService.getSalesOrderView(
  //       sessionId: userProvider.user!.sessionId,
  //       recordOffset: 0,
  //       forPending: true,
  //       forAll: true);
  // }

  // Future<dynamic> _getSalesOrderItemsData({bool button = false}) {
  //   if (button) {
  //     salesOrderItemsProvider.clearItems(notify: false);
  //   }
  //   return SalesOrderService.getItemView(
  //       sessionId: userProvider.user!.sessionId);
  // }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
            actions: [
              Consumer<NotificationProvider>(
                builder: (context, consumerNotifProvider, child) {
                  return Stack(
                    children: [
                      const SizedBox(
                        width: 55,
                        height: kToolbarHeight,
                      ),
                      Positioned.fill(
                          child: PopupMenuButton(
                        tooltip: "Open Notifications",
                        onCanceled: () async {
                          if (!notifProvider.seen) {
                            consumerNotifProvider.setSeen(true);
                            for (final notification
                                in consumerNotifProvider.notifications) {
                              notification['seen'] = true;
                            }
                            await FirestoreService().create(
                                collection: 'notifications',
                                documentId: userProvider.user!.username,
                                data: {
                                  'notifications':
                                      consumerNotifProvider.notifications,
                                  'triggerStream': false
                                });
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          final ScrollController scrollController =
                              ScrollController();
                          if (consumerNotifProvider.notifications.isEmpty) {
                            return [
                              PopupMenuItem(
                                enabled: false,
                                child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxHeight: 200),
                                    child: const Center(
                                      child: Text('Empty'),
                                    )),
                              )
                            ];
                          } else {
                            return [
                              PopupMenuItem(
                                enabled: false,
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxHeight: 200),
                                  child: Scrollbar(
                                    controller: scrollController,
                                    thumbVisibility: true,
                                    child: SingleChildScrollView(
                                      controller: scrollController,
                                      child: Column(
                                        children: List.generate(
                                          consumerNotifProvider
                                              .notifications.length,
                                          (index) {
                                            final notif = consumerNotifProvider
                                                .notifications[index];
                                            return Column(
                                              children: [
                                                ListTile(
                                                  title: Text(
                                                      notif['type'] == 'PR'
                                                          ? 'New Purchase Request #${notif['preqNum']}'
                                                          : notif['type'] ==
                                                                  'PO'
                                                              ? 'New Purchase Order #${notif['poNum']}'
                                                              : notif['body'],
                                                      style: const TextStyle(
                                                          fontSize: 13)),
                                                  subtitle: Text(
                                                      formatTimestampMillis(
                                                          notif['timestamp']),
                                                      style: const TextStyle(
                                                          fontSize: 10)),
                                                  trailing: Text(
                                                    notif['seen'] == true
                                                        ? '    '
                                                        : 'New!',
                                                    style: const TextStyle(
                                                        color: Colors.red,
                                                        fontSize: 10),
                                                  ),
                                                ),
                                                const Divider(),
                                              ],
                                            );
                                          },
                                        ).reversed.toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ];
                          }
                        },
                        icon: const Icon(Icons.notifications),
                        offset: const Offset(0, 50),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      )),
                      Positioned(
                        right: 5,
                        top: 10,
                        child: Visibility(
                          visible: !consumerNotifProvider.seen,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle, color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              Stack(
                children: [
                  const SizedBox(
                    width: 55,
                    height: kToolbarHeight,
                  ),
                  Positioned.fill(
                    child: IconButton(
                      tooltip: "Refresh",
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: () {
                        showToastMessage('Refreshing data...');

                        refreshIconIndicatorProvider.setShow(show: false);
                        setState(() {
                          refresh = true;
                          //GET new data
                          //it will refresh all the pages
                          //because pages uses FutureBuilder = futures variable
                          futures = [
                            _getPurchReqData(button: true),
                            _getPurchOrderData(button: true),
                            // _getSalesOrderData(button: true),
                            // _getSalesOrderItemsData(button: true),
                          ];
                        });
                      },
                    ),
                  ),
                  Positioned(
                    right: 5,
                    top: 10,
                    child: Visibility(
                      visible: Provider.of<RefreshIconIndicatorProvider>(
                              context,
                              listen: true)
                          .show,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            // backgroundColor: Colors.deepPurple,
            backgroundColor: Colors.blueGrey,
            shadowColor: Colors.transparent,
            elevation: 0.0,
            centerTitle: true,
            title: ValueListenableBuilder<String>(
                valueListenable: titleNotifier,
                builder: (context, value, _) {
                  return Text(value);
                }),
            // flexibleSpace: Container(
            //   decoration: const BoxDecoration(
            //     gradient: LinearGradient(
            //       begin: Alignment.topCenter,
            //       end: Alignment.bottomCenter,
            //       colors: [Colors.blueGrey, Colors.blueGrey],
            //       // colors: [Colors.deepPurple, Colors.deepPurple],
            //     ),
            //   ),
            // ),
            flexibleSpace: Consumer2<PurchReqProvider, PurchOrderProvider>(
                builder:
                    (context, purchReqProvider, purchOrderProvider, child) {
              return Row(
                children: [
                  Stack(
                    children: [
                      const SizedBox(
                        width: 55,
                        height: kToolbarHeight,
                      ),
                      Visibility(
                        visible: purchReqProvider.purchReqPending != 0 ||
                            purchOrderProvider.purchOrderPending != 0,
                        child: Positioned(
                          right: 5,
                          top: 10,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle, color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            })),
      ),
      drawer: Drawer(
        child: Stack(
          children: [
            ValueListenableBuilder<int>(
                valueListenable: indexNotifier,
                builder: (context, value, _) {
                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      const DrawerHeader(
                        decoration: BoxDecoration(
                          color: Colors.white,
                        ),
                        child: Image(
                          image: AssetImage('assets/images/PrimeLogo.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                      //Purchase Request
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: value == 0
                                // ? const Colors.deepPurple
                                ? Colors.blueGrey
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            key: const PageStorageKey('purchase_request'),
                            leading: Icon(Icons.playlist_add_check,
                                color: value == 0
                                    ? Colors.white
                                    : brightness == Brightness.dark
                                        ? Colors.grey
                                        : Colors.black),
                            title: Text('Purchase Request',
                                style: TextStyle(
                                    color: value == 0
                                        ? Colors.white
                                        : brightness == Brightness.dark
                                            ? Colors.grey
                                            : Colors.black)),
                            trailing: SizedBox(
                              width: 20,
                              height: 20,
                              child: FutureBuilder(
                                  future: futures[0],
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.done) {
                                      return Visibility(
                                        visible:
                                            purchReqProvider.purchReqPending !=
                                                0,
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.red,
                                          ),
                                          child: Center(
                                            child: Text(
                                              purchReqProvider.purchReqPending
                                                  .toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    } else {
                                      return Container();
                                    }
                                  }),
                            ),
                            selected: value == 0,
                            onTap: () {
                              indexNotifier.value = 0;
                              titleNotifier.value = 'Purchase Request';
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ),
                      //Purchase Order
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: value == 1
                                // ? const Colors.deepPurple
                                ? Colors.blueGrey
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            key: const PageStorageKey('purchase_order'),
                            leading: Icon(Icons.playlist_add_check,
                                color: value == 1
                                    ? Colors.white
                                    : brightness == Brightness.dark
                                        ? Colors.grey
                                        : Colors.black),
                            title: Text('Purchase Order',
                                style: TextStyle(
                                    color: value == 1
                                        ? Colors.white
                                        : brightness == Brightness.dark
                                            ? Colors.grey
                                            : Colors.black)),
                            trailing: SizedBox(
                              width: 20,
                              height: 20,
                              child: FutureBuilder(
                                  future: futures[1],
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.done) {
                                      return Visibility(
                                        visible: purchOrderProvider
                                                .purchOrderPending !=
                                            0,
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.red,
                                          ),
                                          child: Center(
                                            child: Text(
                                              purchOrderProvider
                                                  .purchOrderPending
                                                  .toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    } else {
                                      return Container();
                                    }
                                  }),
                            ),
                            selected: value == 1,
                            onTap: () {
                              indexNotifier.value = 1;
                              titleNotifier.value = 'Purchase Order';
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ),
                      //Sales Order
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: value == 2
                                // ? const Colors.deepPurple
                                ? Colors.blueGrey
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            key: const PageStorageKey('sales_order'),
                            leading: Icon(Icons.playlist_add,
                                color: value == 2
                                    ? Colors.white
                                    : brightness == Brightness.dark
                                        ? Colors.grey
                                        : Colors.black),
                            title: Text('Sales Order',
                                style: TextStyle(
                                    color: value == 2
                                        ? Colors.white
                                        : brightness == Brightness.dark
                                            ? Colors.grey
                                            : Colors.black)),
                            selected: value == 2,
                            onTap: () {
                              indexNotifier.value = 2;
                              titleNotifier.value = 'Sales Order';
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ),
                      //Items
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: value == 3
                                // ? const Colors.deepPurple
                                ? Colors.blueGrey
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            key: const PageStorageKey('items'),
                            leading: Icon(Icons.list,
                                color: value == 3
                                    ? Colors.white
                                    : brightness == Brightness.dark
                                        ? Colors.grey
                                        : Colors.black),
                            title: Text('Items',
                                style: TextStyle(
                                    color: value == 3
                                        ? Colors.white
                                        : brightness == Brightness.dark
                                            ? Colors.grey
                                            : Colors.black)),
                            selected: value == 3,
                            onTap: () {
                              indexNotifier.value = 3;
                              titleNotifier.value = 'Items';
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ),
                      //Admin
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: value == 5
                                // ? const Colors.deepPurple
                                ? Colors.blueGrey
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            key: const PageStorageKey('admin'),
                            leading: Icon(Icons.lock,
                                color: value == 5
                                    ? Colors.white
                                    : brightness == Brightness.dark
                                        ? Colors.grey
                                        : Colors.black),
                            title: Text(' groups\n(hidden)',
                                style: TextStyle(
                                    color: value == 5
                                        ? Colors.white
                                        : brightness == Brightness.dark
                                            ? Colors.grey
                                            : Colors.black)),
                            selected: value == 5,
                            onTap: () {
                              indexNotifier.value = 5;
                              titleNotifier.value = 'groups(hidden)';
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                }),
            Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        Icons.person,
                        color: brightness == Brightness.dark
                            ? Colors.grey
                            : Colors.black,
                      ),
                      title: Text(userProvider.user!.username,
                          style: TextStyle(
                              color: brightness == Brightness.dark
                                  ? Colors.grey
                                  : Colors.black)),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          final response = await dialogBuilder(
                              context: context,
                              title: 'Log out',
                              message: 'Are you sure you want to log out?');
                          if (response != null) {
                            if (response) {
                              setState(() {
                                _isLoading = true;
                              });
                              try {
                                await AuthAPIService.logout(
                                    sessionId: userProvider.user!.sessionId);
                                if (mounted) {
                                  clearData(context);
                                }
                                showToastMessage('Logging Out Successful!');
                              } catch (e) {
                                if (mounted) {
                                  alertDialog(context,
                                      title: 'Error', body: '$e');
                                }

                                if (kDebugMode) {
                                  print('Error Logout: $e');
                                }
                                Restart.restartApp();
                              }
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Text('Log out'),
                      ),
                    ),
                  ],
                ))
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder(
              future: Future.wait(futures),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  if (Platform.isAndroid) {
                    SharedPreferencesService().getRequest().then((value) {
                      // print('SharedPreferencesService222: $value');
                      // showToast('SharedPreferencesService222: $value');
                      if (value['type'] != '' || value['requestNumber'] != -1) {
                        SchedulerBinding.instance.addPostFrameCallback((_) {
                          if (value['type'] == 'PR') {
                            int requestNumber = value['requestNumber'];
                            purchReqProvider.setReqNumber(
                                reqNumber: requestNumber, notify: true);
                            setState(() {
                              // indexNotifier = ValueNotifier(0);
                              indexNotifier.value = 0;
                              titleNotifier.value = 'Purchase Request';
                            });
                          }
                          if (value['type'] == 'PO') {
                            int orderNumber = value['requestNumber'];
                            purchOrderProvider.setOrderNumber(
                                orderNumber: orderNumber, notify: true);
                            setState(() {
                              // indexNotifier = ValueNotifier(1);
                              indexNotifier.value = 1;
                              titleNotifier.value = 'Purchase Order';
                            });
                          }
                          SharedPreferencesService()
                              .setRequest(type: '', requestNumber: -1);
                        });
                      }
                    });
                  }

                  // Purchase Request
                  bool purchReqFlag =
                      handleSessionExpiredException(snapshot.data![0], context);
                  if (!purchReqFlag) {
                    final List<PurchaseRequest> data =
                        snapshot.data![0]['purchaseRequests'];
                    if (purchReqProvider.purchaseRequestList.isEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        purchReqProvider.setList(
                            purchaseRequestList: data, notify: true);
                      });
                    }
                  } else {
                    purchReqProvider
                        .setList(purchaseRequestList: [], notify: false);
                  }

                  // Purchase Order
                  bool purchOrderFlag =
                      handleSessionExpiredException(snapshot.data![1], context);
                  if (!purchOrderFlag) {
                    final List<PurchaseOrder> data2 =
                        snapshot.data![1]['purchaseOrders'];
                    if (purchOrderProvider.purchaseOrderList.isEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        purchOrderProvider.setList(
                            purchaseOrderList: data2, notify: true);
                      });
                    }
                  } else {
                    purchOrderProvider
                        .setList(purchaseOrderList: [], notify: false);
                  }

                  // Sales Order
                  // bool salesOrderFlag = handleSessionExpiredException(
                  //     snapshot.data![2], context);
                  // if (!salesOrderFlag) {
                  //   final List<SalesOrder> data3 =
                  //       snapshot.data![2]['salesOrders'];
                  //   if (salesOrderProvider.salesOrderList.isEmpty) {
                  //     salesOrderProvider.setList(
                  //         salesOrderList: data3, notify: false);
                  //   }
                  // } else {
                  //   salesOrderProvider
                  //       .setList(salesOrderList: [], notify: false);
                  // }

                  // // Sales Order Items
                  // bool salesOrderItemsFlag = handleSessionExpiredException(
                  //     snapshot.data![3], context);
                  // if (!salesOrderItemsFlag) {
                  //   final List<dynamic> data3 = snapshot.data![3]['items'];
                  //   if (salesOrderItemsProvider.items.isEmpty) {
                  //     salesOrderItemsProvider.addItems(
                  //         items: data3, notify: false);
                  //     salesOrderItemsProvider.setItemsHasMore(
                  //         hasMore: snapshot.data![3]['hasMore'],
                  //         notify: false);
                  //   }
                  // } else {
                  //   salesOrderItemsProvider
                  //       .addItems(items: [], notify: false);
                  // }

                  //Notifications
                  if (notifProvider.notifications.isEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      notifProvider.setNotifications(
                          snapshot.data![2]['notifications'],
                          notify: true);
                    });
                  }
                  return ValueListenableBuilder<int>(
                      valueListenable: indexNotifier,
                      builder: (context, value, _) {
                        return LazyIndexedStack(
                          index: value,
                          children: [
                            const MobilePurchReqMain(),
                            const MobilePurchOrderMain(),
                            const MobileSalersOrderMain(),
                            const MobileItemsMain(),
                            const GreetingsScreen(),
                            userProvider.user == null
                                ? const SizedBox.shrink()
                                : userProvider.user!.username == 'admin'
                                    ? const MobileAdmin()
                                    : const SizedBox.shrink()
                          ],
                        );
                      });
                }
              }),
    );
  }
}
