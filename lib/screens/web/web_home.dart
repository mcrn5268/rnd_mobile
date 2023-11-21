import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firedart/firedart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import 'package:rnd_mobile/providers/refresh_icon_indicator_provider.dart';
import 'package:rnd_mobile/providers/sales_order/sales_order_provider.dart';
import 'package:rnd_mobile/providers/items/items_provider.dart';
import 'package:rnd_mobile/providers/user_provider.dart';
import 'package:rnd_mobile/screens/admin/web/web_admin_main.dart';
import 'package:rnd_mobile/screens/web/items/web_items_main.dart';
import 'package:rnd_mobile/screens/web/purchase_order/web_purch_order_main.dart';
import 'package:rnd_mobile/screens/web/purchase_request/web_purch_req_main.dart';
import 'package:rnd_mobile/screens/web/sales_order/web_sales_order_main.dart';
import 'package:rnd_mobile/utilities/clear_data.dart';
import 'package:rnd_mobile/utilities/session_handler.dart';
import 'package:rnd_mobile/utilities/timestamp_formatter.dart';
import 'package:rnd_mobile/widgets/alert_dialog.dart';
import 'package:rnd_mobile/widgets/lazy_indexedstack.dart';
import 'package:rnd_mobile/widgets/windows_custom_toast.dart';
import 'package:rnd_mobile/widgets/greetings.dart';
import 'package:rnd_mobile/widgets/show_dialog.dart';
import 'package:rnd_mobile/widgets/toast.dart';
import 'package:rnd_mobile/widgets/web/web_app_bar.dart';

//enable ONLY for web
import 'dart:html' as web;
import 'dart:js' as js;

//enable ONLY for desktop
// import 'package:firedart/firedart.dart';
// import 'package:local_notifier/local_notifier.dart';

class WebHome extends StatefulWidget {
  const WebHome({super.key});

  @override
  State<WebHome> createState() => _WebHomeState();
}

class _WebHomeState extends State<WebHome> with AutomaticKeepAliveClientMixin {
  late final UserProvider userProvider;
  late final PurchReqProvider purchReqProvider;
  late final PurchOrderProvider purchOrderProvider;
  late final SalesOrderProvider salesOrderProvider;
  late final ItemsProvider salesOrderItemsProvider;
  late final RefreshIconIndicatorProvider refreshIconIndicatorProvider;
  late final NotificationProvider notifProvider;
  late List<Future<dynamic>> futures;
  late int selectedIndex;
  bool greetings = true;
  bool _isLoading = false;
  bool refresh = false;
  late ValueNotifier<int> indexNotifier;
  final player = AudioCache();
  StreamSubscription<DocumentSnapshot>? _subscription;

  @override
  bool get wantKeepAlive => true;
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
    if (purchReqProvider.purchaseRequestList.isEmpty ||
        purchOrderProvider.purchaseOrderList.isEmpty ||
        salesOrderProvider.salesOrderList.isEmpty ||
        salesOrderItemsProvider.items.isEmpty) {
      //initial load
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
      selectedIndex = 4;
    }
    indexNotifier = ValueNotifier(selectedIndex);

    //web
    webNotificationStream();

    //desktop
    // desktopNotificationStream();
  }

  @override
  void dispose() {
    indexNotifier.dispose();
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
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

  void webNotificationStream() {
    bool stream = false;
    final documentRef = FirebaseFirestore.instance
        .collection("notifications")
        .doc(userProvider.user!.username);
    _subscription = documentRef.snapshots().listen(
      (event) {
        if (stream) {
          final data = event.data()!;
          if (data['notifications'] != null) {
            if (data['triggerStream'] == true) {
              webNotification(data: data);
              player.play('audio/notif_sound2.mp3',
                  isNotification: true, volume: 0.5);
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              notifProvider.setNotifications(data['notifications']);
              notifProvider.setSeen(!notifProvider.notifications
                  .any((notif) => notif['seen'] == false));
            });
          }
        }
        stream = true;
      },
      onError: (error) => print("Listen failed: $error"),
    );
  }

  js.JsObject createNotification(String title, String body) {
    showToastMessage(title);
    return js.JsObject(js.context['Notification'], [
      title,
      js.JsObject.jsify({'body': body})
    ]);
  }

  Future<void> webNotification({required Map<String, dynamic> data}) async {
    final notifications = data['notifications'];
    final lastNotification = notifications.last;
    final type = lastNotification['type'];

    if (type != "group") {
      refreshIconIndicatorProvider.setShow(show: true);
    }

    final notificationTitle = type == "group"
        ? 'New Notification!'
        : 'New Purchase ${type == "PR" ? "Request" : "Order"}!';

    final notificationBody = type == "group"
        ? lastNotification['body']
        : type == "PR"
            ? "Request Number: ${lastNotification['preqNum']}"
            : "Order Number: ${lastNotification['poNum']}";

    final notification =
        createNotification(notificationTitle, notificationBody);

    notification.callMethod('addEventListener', [
      'click',
      (event) {
        js.context.callMethod('focus');

        if (type != "group") {
          futures = [
            _getPurchReqData(button: true),
            _getPurchOrderData(button: true),
          ];
        }

        first = true;

        if (type == 'PR') {
          purchReqProvider.setReqNumber(
              reqNumber: int.parse(lastNotification["preqNum"]), notify: true);
          updateSelectedIndex(0);
        } else if (type == 'PO') {
          purchOrderProvider.setOrderNumber(
              orderNumber: int.parse(lastNotification["poNum"]), notify: true);
          updateSelectedIndex(1);
        }

        setState(() {});
      }
    ]);
  }

  void updateSelectedIndex(int newIndex) {
    setState(() {
      indexNotifier.value = newIndex;
      selectedIndex = newIndex;
      indexNotifier = ValueNotifier(newIndex);
    });
  }

  // void desktopNotificationStream() {
  //   bool stream = false;
  //   final documentRef = Firestore.instance
  //       .collection('notifications')
  //       .document(userProvider.user!.username);
  //   // Listen to changes in the document
  //   documentRef.stream.listen(
  //     (document) {
  //       if (stream) {
  //         final Map<String, dynamic> data = document!.map;
  //         refreshIconIndicatorProvider.setShow(show: true);
  //         desktopNotification(data: data);
  //       }
  //       stream = true;
  //     },
  //     onError: (error) {
  //       // Handle errors
  //       if (kDebugMode) {
  //         print('Error: $error');
  //       }
  //     },
  //   );
  // }

  // void desktopNotification({required Map<String, dynamic> data}) {
  //   LocalNotification notification = LocalNotification(
  //     title:
  //         '***New Purchase ${data['type'] == "PR" ? "Request" : "Order"}!***',
  //     body: data['type'] == "PR"
  //         ? '"Request Number: ${data["preqNum"]}'
  //         : '"Order Number: ${data["poNum"]}',
  //   );
  //   notification.onShow = () {
  //     if (kDebugMode) {
  //       print('onShow ${notification.identifier}');
  //     }
  //   };
  //   notification.onClose = (closeReason) {
  //     // Only supported on windows, other platforms closeReason is always unknown.
  //     switch (closeReason) {
  //       case LocalNotificationCloseReason.userCanceled:
  //         // do something
  //         break;
  //       case LocalNotificationCloseReason.timedOut:
  //         // do something
  //         break;
  //       default:
  //     }
  //     if (kDebugMode) {
  //       print('onClose ${notification.identifier} - $closeReason');
  //     }
  //   };
  //   notification.onClick = () {
  //     if (kDebugMode) {
  //       print('onClick ${notification.identifier}');
  //     }
  //     futures = [
  //       _getPurchReqData(button: true),
  //       _getPurchOrderData(button: true),
  //       _getSalesOrderData(button: true),
  //       _getSalesOrderItemsData(button: true),
  //     ];
  //     //first for selected item in menu to update
  //     first = true;
  //     if (data['type'] == 'PR') {
  //       purchReqProvider.setReqNumber(
  //           reqNumber: int.parse(data["preqNum"]), notify: true);
  //       indexNotifier.value = 0;
  //       selectedIndex = 0;
  //       indexNotifier = ValueNotifier(0);
  //     } else if (data['type'] == 'PO') {
  //       purchOrderProvider.setOrderNumber(
  //           orderNumber: int.parse(data["poNum"]), notify: true);
  //       indexNotifier.value = 1;
  //       selectedIndex = 1;
  //       indexNotifier = ValueNotifier(1);
  //     }
  //     setState(() {});
  //   };
  //   notification.onClickAction = (actionIndex) {
  //     if (kDebugMode) {
  //       print('onClickAction ${notification.identifier} - $actionIndex');
  //     }
  //   };

  //   notification.show();
  // }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        appBar: WebCustomAppBar(
          menuItems: [
            'Purchase Request',
            'Purchase Order',
            'Sales Order',
            'Items',
            '(Hidden)',
            if (userProvider.user!.username == 'admin') ' groups\n(hidden)'
          ],
          onMenuItemSelected: (index) {
            indexNotifier.value = index;
          },
          selectedIndex: selectedIndex,
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
                                                        : notif['type'] == 'PO'
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
                      icon:
                          const Icon(Icons.notifications, color: Colors.white),
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
                      // updateSelectedIndex(0);
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
                        salesOrderProvider.clearOrderNumber();
                        salesOrderProvider.clearList();
                        salesOrderItemsProvider.clearItems(notify: false);
                        salesOrderItemsProvider.resetDidLoadDataAlready();
                      });
                    },
                  ),
                ),
                Positioned(
                  right: 5,
                  top: 10,
                  child: Visibility(
                    visible: Provider.of<RefreshIconIndicatorProvider>(context,
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
            Row(
              children: [
                const SizedBox(width: 10),
                // Container(
                //   margin: const EdgeInsets.all(8),
                //   width: 50,
                //   height: 50,
                //   decoration: const BoxDecoration(
                //     shape: BoxShape.circle,
                //     image: DecorationImage(
                //       image: AssetImage('assets/images/person-placeholder.png'),
                //       fit: BoxFit.cover,
                //     ),
                //   ),
                // ),
                // Text(userProvider.user!.username,
                //     style: const TextStyle(fontSize: 12, color: Colors.white)),
                // const SizedBox(width: 10),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                  ),
                  onSelected: (String value) async {
                    final response = await dialogBuilder(
                      context: context,
                      title: 'Log out',
                      message: 'Are you sure you want to log out?',
                    );
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

                          if (kIsWeb) {
                            showToastMessage('Logging Out Successful!');
                          } else {
                            if (mounted) {
                              CustomToast.show(
                                  context: context,
                                  message: 'Logging Out Successful!');
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            alertDialog(context,
                                title: 'Error',
                                body: 'Something Went Wrong! $e');
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
                  itemBuilder: (BuildContext context) {
                    return ['Log out'].map((String choice) {
                      return PopupMenuItem<String>(
                        value: choice,
                        child: Text(
                          choice,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      );
                    }).toList();
                  },
                ),
                // ElevatedButton(
                //   onPressed: () async {
                //     final response = await dialogBuilder(
                //       context: context,
                //       title: 'Log out',
                //       message: 'Are you sure you want to log out?',
                //     );
                //     if (response != null) {
                //       if (response) {
                //         setState(() {
                //           _isLoading = true;
                //         });
                //         try {
                //           await AuthAPIService.logout(
                //               sessionId: userProvider.user!.sessionId);
                //           if (!mounted) return;
                //           clearData(context);
                //           showToast('Logging Out Successful!');
                //         } catch (e) {
                //           showToast('Something Went Wrong!');
                //           if (kDebugMode) {
                //             print('Error Logout: $e');
                //           }
                //           Restart.restartApp();
                //         }
                //         setState(() {
                //           _isLoading = false;
                //         });
                //       }
                //     }
                //   },
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.red[100],
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(30),
                //     ),
                //   ),
                //   child: const Text('Log out',
                //       style: TextStyle(fontSize: 12, color: Colors.red)),
                // ),
              ],
            ),
          ],
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
                    // Purchase Request
                    bool purchReqFlag = handleSessionExpiredException(
                        snapshot.data![0], context);
                    if (!purchReqFlag) {
                      final List<PurchaseRequest> data =
                          snapshot.data![0]['purchaseRequests'];
                      if (purchReqProvider.purchaseRequestList.isEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          purchReqProvider.setList(
                              purchaseRequestList: data, notify: true);
                          purchReqProvider.setItemsHasMore(
                              hasMore: snapshot.data![0]['hasMore']);
                        });
                      }
                    } else {
                      purchReqProvider
                          .setList(purchaseRequestList: [], notify: false);
                    }

                    // Purchase Order
                    bool purchOrderFlag = handleSessionExpiredException(
                        snapshot.data![1], context);
                    if (!purchOrderFlag) {
                      final List<PurchaseOrder> data2 =
                          snapshot.data![1]['purchaseOrders'];
                      if (purchOrderProvider.purchaseOrderList.isEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          purchOrderProvider.setList(
                              purchaseOrderList: data2, notify: true);
                          purchOrderProvider.setItemsHasMore(
                              hasMore: snapshot.data![1]['hasMore']);
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
                        // if (greetings) {
                        //   greetings = false;
                        //   return Center(
                        //     child: Column(
                        //       mainAxisAlignment: MainAxisAlignment.center,
                        //       children: [
                        //         Image.asset('assets/images/PrimeLogo.png'),
                        //         const SizedBox(height: 25),
                        //         const Text('Welcome!',
                        //             style: TextStyle(fontSize: 30)),
                        //       ],
                        //     ),
                        //   );
                        // } else {
                        return LazyIndexedStack(
                          index: value,
                          children: [
                            const WebPurchReqMain(),
                            const WebPurchOrderMain(),
                            const WebSalesOrderMain(),
                            const WebItemsMain(),
                            const GreetingsScreen(),
                            userProvider.user!.username == 'admin'
                                ? const WebAdmin()
                                : const SizedBox.shrink()
                          ],
                        );

                        // }
                      },
                    );
                  }
                }));
  }
}
