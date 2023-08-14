import 'package:audioplayers/audioplayers.dart';
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
import 'package:rnd_mobile/models/purchase_order_model.dart';
import 'package:rnd_mobile/models/purchase_req_model.dart';
import 'package:rnd_mobile/models/sales_order_model.dart';
import 'package:rnd_mobile/providers/purchase_order/purchase_order_provider.dart';
import 'package:rnd_mobile/providers/purchase_request/purchase_req_provider.dart';
import 'package:rnd_mobile/providers/items/items_provider.dart';
import 'package:rnd_mobile/providers/refresh_icon_indicator_provider.dart';
import 'package:rnd_mobile/providers/sales_order/sales_order_provider.dart';
import 'package:rnd_mobile/providers/user_provider.dart';
import 'package:rnd_mobile/screens/mobile/items/mob_items_main.dart';
import 'package:rnd_mobile/screens/mobile/purchase_order/mob_purch_order_main.dart';
import 'package:rnd_mobile/screens/mobile/purchase_request/mob_purch_req_main.dart';
import 'package:rnd_mobile/screens/mobile/sales_order/mob_sales_order_main.dart';
import 'package:rnd_mobile/utilities/clear_data.dart';
import 'package:rnd_mobile/utilities/session_handler.dart';
import 'package:rnd_mobile/utilities/shared_pref.dart';
import 'package:rnd_mobile/widgets/greetings.dart';
import 'package:rnd_mobile/widgets/show_dialog.dart';
import 'package:rnd_mobile/widgets/toast.dart';

//ONLY ENABLE THIS PACKAGE FOR WEB
import 'dart:js' as js;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

//ONLY ENABLE THIS PACKAGE FOR MOBILE
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:universal_io/io.dart';

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
  late List<Future<dynamic>> futures;
  bool greetings = true;
  bool _isLoading = false;
  bool refresh = false;
  late ValueNotifier<int> indexNotifier;
  late ValueNotifier<String> titleNotifier;
  final player = AudioCache();

  //ONLY FOR WEB
  StreamSubscription<DocumentSnapshot>? _subscription;

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
    if (purchReqProvider.purchaseRequestList.isEmpty ||
        purchOrderProvider.purchaseOrderList.isEmpty ||
        salesOrderProvider.salesOrderList.isEmpty ||
        salesOrderItemsProvider.items.isEmpty) {
      futures = [
        _getPurchReqData(),
        _getPurchOrderData(),
        _getSalesOrderData(),
        _getSalesOrderItemsData()
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
      webNotifStream();
    } else {
      //when user taps notif
    //   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    //     setState(() {
    //       futures = [
    //         _getPurchReqData(button: true),
    //         _getPurchOrderData(button: true),
    //         _getSalesOrderData(button: true),
    //         _getSalesOrderItemsData(button: true),
    //       ];
    //     });
    //     if (message.data['type'] == 'PR') {
    //       String requestNumber = message.data['preqNum'];
    //       purchReqProvider.setReqNumber(
    //           reqNumber: int.parse(requestNumber), notify: true);
    //       indexNotifier = ValueNotifier(0);
    //     }
    //     if (message.data['type'] == 'PO') {
    //       String orderNumber = message.data['poNum'];
    //       purchOrderProvider.setOrderNumber(
    //           orderNumber: int.parse(orderNumber), notify: true);
    //       indexNotifier = ValueNotifier(1);
    //     }
    //   });

    //   //foreground
    //   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    //     player.play('audio/notif_sound2.mp3');
    //     showToast(
    //         message.data['type'] == 'PR'
    //             ? 'New Purchase Request!'
    //             : 'New Purchase Order!',
    //         gravity: ToastGravity.TOP);
    //     //just for the refresh icon to show red indicator
    //     refreshIconIndicatorProvider.setShow(show: true);
    //   });
     }
  }

  @override
  void dispose() {
    indexNotifier.dispose();
    titleNotifier.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  void webNotifStream() {
    bool stream = false;
    final documentRef = FirebaseFirestore.instance
        .collection("notifications")
        .doc(userProvider.user!.username);
    _subscription = documentRef.snapshots().listen(
      (event) {
        if (stream) {
          final data = event.data()!;
          webNotification(data: data);
        }
        stream = true;
      },
      onError: (error) => print("Listen failed: $error"),
    );
  }

  Future<void> webNotification({required Map<String, dynamic> data}) async {
    final notification = js.JsObject(js.context['Notification'], [
      '***New Purchase ${data['type'] == "PR" ? "Request" : "Order"}!***',
      js.JsObject.jsify({
        'body': data['type'] == "PR"
            ? "Request Number: ${data["preqNum"]}"
            : "Order Number: ${data["poNum"]}"
      })
    ]);
    notification.callMethod('addEventListener', [
      'click',
      (event) {
        js.context.callMethod('focus');
        futures = [
          _getPurchReqData(button: true),
          _getPurchOrderData(button: true),
          _getSalesOrderData(button: true),
          _getSalesOrderItemsData(button: true),
        ];

        if (data['type'] == 'PR') {
          Provider.of<PurchReqProvider>(context, listen: false).setReqNumber(
              reqNumber: int.parse(data["preqNum"]), notify: true);
          indexNotifier.value = 0;
          indexNotifier = ValueNotifier(0);
        } else if (data['type'] == 'PO') {
          Provider.of<PurchOrderProvider>(context, listen: false)
              .setOrderNumber(
                  orderNumber: int.parse(data["poNum"]), notify: true);
          indexNotifier.value = 1;
          indexNotifier = ValueNotifier(1);
        }

        setState(() {});
      }
    ]);
  }

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
        forAll: true);
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
        forAll: true);
  }

  Future<dynamic> _getSalesOrderData({bool button = false}) {
    if (button) {
      salesOrderProvider.clearOrderNumber();
      salesOrderProvider.clearList();
    }
    return SalesOrderService.getSalesOrderView(
        sessionId: userProvider.user!.sessionId,
        recordOffset: 0,
        forPending: true,
        forAll: true);
  }

  Future<dynamic> _getSalesOrderItemsData({bool button = false}) {
    if (button) {
      salesOrderItemsProvider.clearItems(notify: false);
    }
    return SalesOrderService.getItemView(
        sessionId: userProvider.user!.sessionId);
  }

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
            Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: () {
                      showToast('Refreshing data...');

                      Provider.of<RefreshIconIndicatorProvider>(context,
                              listen: false)
                          .setShow(show: false);
                      setState(() {
                        refresh = true;
                        //GET new data
                        //it will refresh all the pages
                        //because pages uses FutureBuilder = futures variable
                        futures = [
                          _getPurchReqData(button: true),
                          _getPurchOrderData(button: true),
                          _getSalesOrderData(button: true),
                          _getSalesOrderItemsData(button: true),
                        ];
                      });
                    },
                  ),
                ),
                Positioned(
                    right: 3,
                    top: 4,
                    child: Consumer<RefreshIconIndicatorProvider>(builder:
                        (context, refreshIconIndicatorProvider, child) {
                      return Visibility(
                          visible: refreshIconIndicatorProvider.show,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle, color: Colors.red),
                          ));
                    }))
              ],
            ),
          ],
          elevation: 0,
          centerTitle: true,
          title: ValueListenableBuilder<String>(
              valueListenable: titleNotifier,
              builder: (context, value, _) {
                return Text(value);
              }),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.deepPurple, Colors.deepPurple],
              ),
            ),
          ),
        ),
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
                                ? Colors.deepPurple
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            key: const PageStorageKey('purchase_request'),
                            leading: Icon(Icons.playlist_add_check,
                                color: value == 0
                                    ? Colors.white
                                    : MediaQuery.of(context)
                                                .platformBrightness ==
                                            Brightness.dark
                                        ? Colors.grey
                                        : Colors.black),
                            title: Text('Purchase Request',
                                style: TextStyle(
                                    color: value == 0
                                        ? Colors.white
                                        : MediaQuery.of(context)
                                                    .platformBrightness ==
                                                Brightness.dark
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
                                      final List<PurchaseRequest> data =
                                          snapshot.data['purchaseRequests'] ??
                                              [];
                                      int pending = data
                                          .where((purchReq) =>
                                              !purchReq.isFinal &&
                                              !purchReq.isCancelled)
                                          .length;
                                      return Visibility(
                                        visible: pending != 0,
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.red,
                                          ),
                                          child: Center(
                                            child: Text(
                                              pending.toString(),
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
                                ? Colors.deepPurple
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            key: const PageStorageKey('purchase_order'),
                            leading: Icon(Icons.playlist_add_check,
                                color: value == 1
                                    ? Colors.white
                                    : MediaQuery.of(context)
                                                .platformBrightness ==
                                            Brightness.dark
                                        ? Colors.grey
                                        : Colors.black),
                            title: Text('Purchase Order',
                                style: TextStyle(
                                    color: value == 1
                                        ? Colors.white
                                        : MediaQuery.of(context)
                                                    .platformBrightness ==
                                                Brightness.dark
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
                                      final List<PurchaseOrder> data =
                                          snapshot.data['purchaseOrders'] ?? [];
                                      int pending = data
                                          .where((purchOrder) =>
                                              !purchOrder.isFinal &&
                                              !purchOrder.isCancelled)
                                          .length;
                                      return Visibility(
                                        visible: pending != 0,
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.red,
                                          ),
                                          child: Center(
                                            child: Text(
                                              pending.toString(),
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
                                ? Colors.deepPurple
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            key: const PageStorageKey('sales_order'),
                            leading: Icon(Icons.playlist_add,
                                color: value == 2
                                    ? Colors.white
                                    : MediaQuery.of(context)
                                                .platformBrightness ==
                                            Brightness.dark
                                        ? Colors.grey
                                        : Colors.black),
                            title: Text('Sales Order',
                                style: TextStyle(
                                    color: value == 2
                                        ? Colors.white
                                        : MediaQuery.of(context)
                                                    .platformBrightness ==
                                                Brightness.dark
                                            ? Colors.grey
                                            : Colors.black)),
                            // trailing: SizedBox(
                            //   width: 20,
                            //   height: 20,
                            //   child: FutureBuilder(
                            //       future: futures[2],
                            //       builder: (context, snapshot) {
                            //         if (snapshot.connectionState ==
                            //             ConnectionState.done) {
                            //           final List<SalesOrder> data =
                            //               snapshot.data['salesOrders'] ?? [];
                            //           int pending = data
                            //               .where((salesOrder) =>
                            //                   !salesOrder.isFinal &&
                            //                   !salesOrder.isCancelled)
                            //               .length;
                            //           return Visibility(
                            //             visible: pending != 0,
                            //             child: Container(
                            //               width: 20,
                            //               height: 20,
                            //               decoration: const BoxDecoration(
                            //                 shape: BoxShape.circle,
                            //                 color: Colors.red,
                            //               ),
                            //               child: Center(
                            //                 child: Text(
                            //                   pending.toString(),
                            //                   style: const TextStyle(
                            //                     color: Colors.white,
                            //                     fontSize: 12,
                            //                   ),
                            //                 ),
                            //               ),
                            //             ),
                            //           );
                            //         } else {
                            //           return Container();
                            //         }
                            //       }),
                            // ),
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
                                ? Colors.deepPurple
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            key: const PageStorageKey('items'),
                            leading: Icon(Icons.list,
                                color: value == 3
                                    ? Colors.white
                                    : MediaQuery.of(context)
                                                .platformBrightness ==
                                            Brightness.dark
                                        ? Colors.grey
                                        : Colors.black),
                            title: Text('Items',
                                style: TextStyle(
                                    color: value == 3
                                        ? Colors.white
                                        : MediaQuery.of(context)
                                                    .platformBrightness ==
                                                Brightness.dark
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
                        color: MediaQuery.of(context).platformBrightness ==
                                Brightness.dark
                            ? Colors.grey
                            : Colors.black,
                      ),
                      title: Text(userProvider.user!.username,
                          style: TextStyle(
                              color:
                                  MediaQuery.of(context).platformBrightness ==
                                          Brightness.dark
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
                                if (!mounted) return;
                                clearData(context);
                                showToast('Logging Out Successful!');
                              } catch (e) {
                                showToast('Something Went Wrong!');
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
                    // print('snapshot.data![0]: ${snapshot.data![0]}');
                    final List<PurchaseRequest> data =
                        snapshot.data![0]['purchaseRequests'];
                    if (purchReqProvider.purchaseRequestList.isEmpty) {
                      purchReqProvider.setList(
                          purchaseRequestList: data, notify: false);
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
                      purchOrderProvider.setList(
                          purchaseOrderList: data2, notify: false);
                    }
                  } else {
                    purchOrderProvider
                        .setList(purchaseOrderList: [], notify: false);
                  }

                  // Sales Order
                  bool salesOrderFlag =
                      handleSessionExpiredException(snapshot.data![2], context);
                  if (!salesOrderFlag) {
                    final List<SalesOrder> data3 =
                        snapshot.data![2]['salesOrders'];
                    if (salesOrderProvider.salesOrderList.isEmpty) {
                      salesOrderProvider.setList(
                          salesOrderList: data3, notify: false);
                    }
                  } else {
                    salesOrderProvider
                        .setList(salesOrderList: [], notify: false);
                  }

                  // Sales Order Items
                  bool salesOrderItemsFlag =
                      handleSessionExpiredException(snapshot.data![3], context);
                  if (!salesOrderItemsFlag) {
                    final List<dynamic> data3 = snapshot.data![3]['items'];
                    if (salesOrderItemsProvider.items.isEmpty) {
                      salesOrderItemsProvider.addItems(
                          items: data3, notify: false);
                      salesOrderItemsProvider.setItemsHasMore(
                          hasMore: snapshot.data![3]['hasMore'], notify: false);
                    }
                  } else {
                    salesOrderItemsProvider.addItems(items: [], notify: false);
                  }

                  //todo
                  //put the item from notif in first
                  // if (purchReqProvider.reqNumber != -1) {
                  //   PurchaseRequest item = purchReqProvider.purchaseRequestList
                  //       .firstWhere((item) =>
                  //           item.preqNum == purchReqProvider.reqNumber);
                  //   print('item: ${item.preqNum}');
                  //   purchReqProvider.removeItem(purchReq: item, notify: true);
                  //   purchReqProvider.insertItemtoFirst(
                  //       item: item, notify: true);
                  //   purchReqProvider.setReqNumber(reqNumber: -1);
                  //   refresh = false;
                  // }
                  return ValueListenableBuilder<int>(
                      valueListenable: indexNotifier,
                      builder: (context, value, _) {
                        return IndexedStack(
                          index: value,
                          children: const [
                            MobilePurchReqMain(),
                            MobilePurchOrderMain(),
                            MobileSalersOrderMain(),
                            MobileItemsMain(),
                            GreetingsScreen(),
                          ],
                        );
                      });
                }
              }),
    );
  }
}
