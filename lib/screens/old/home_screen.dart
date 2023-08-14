import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firedart/firestore/firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:provider/provider.dart';
import 'package:restart_app/restart_app.dart';
import 'package:rnd_mobile/api/auth_api.dart';
import 'package:rnd_mobile/api/purchase_order_api.dart';
import 'package:rnd_mobile/api/purchase_req_api.dart';
import 'package:rnd_mobile/api/sales_order_api.dart';
import 'package:rnd_mobile/main.dart';
import 'package:rnd_mobile/models/purchase_order_model.dart';
import 'package:rnd_mobile/models/purchase_req_model.dart';
import 'package:rnd_mobile/providers/purchase_order/purch_order_filter_provider.dart';
import 'package:rnd_mobile/providers/purchase_request/purch_req_filter_provider.dart';
import 'package:rnd_mobile/providers/purchase_order/purchase_order_provider.dart';
import 'package:rnd_mobile/providers/purchase_request/purchase_req_provider.dart';
import 'package:rnd_mobile/providers/user_provider.dart';
import 'package:rnd_mobile/screens/old/purch_order_hist_screen.dart';
import 'package:rnd_mobile/screens/old/purch_order_screen.dart';
import 'package:rnd_mobile/screens/old/purch_req_hist_screen.dart';
import 'package:rnd_mobile/screens/old/purch_req_screen.dart';
import 'package:rnd_mobile/utilities/clear_data.dart';
import 'package:rnd_mobile/utilities/session_handler.dart';
import 'package:rnd_mobile/widgets/show_dialog.dart';
import 'package:rnd_mobile/widgets/toast.dart';
import 'package:universal_io/io.dart';
import 'package:audioplayers/audioplayers.dart';

//enable ONLY for web
import 'dart:html' as web;
import 'dart:js' as js;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PurchReqFilterProvider reqFilterProvider;
  late final PurchOrderFilterProvider orderFilterProvider;
  late final UserProvider userProvider;
  late final PurchReqProvider purchReqProvider;
  late final PurchOrderProvider purchOrderProvider;
  int _currentIndex = 0;
  String appBarTitle = 'Purchase Request';
  late final List<Widget> _children;
  int tempIndex = 0;
  late List<Future<dynamic>> futures;
  bool stream = false;
  bool refresh = false;
  bool _isLoading = false;
  final player = AudioCache();

  ReqDataType _reqDataType = ReqDataType.reqDate;
  ReqStatus _reqStatus = ReqStatus.approved;
  ReqSort _reqSort = ReqSort.asc;

  OrderDataType _orderDataType = OrderDataType.poNum;
  OrderStatus _orderStatus = OrderStatus.approved;
  OrderSort _orderSort = OrderSort.asc;

  final TextEditingController _reqFromController = TextEditingController();
  final TextEditingController _reqToController = TextEditingController();
  final TextEditingController _reqOtherController = TextEditingController();

  final TextEditingController _orderFromController = TextEditingController();
  final TextEditingController _orderToController = TextEditingController();
  final TextEditingController _orderOtherController = TextEditingController();

  DateTime? _reqStartDate;
  DateTime? _reqEndDate;
  String? _reqDropdownValue;

  DateTime? _orderStartDate;
  DateTime? _orderEndDate;
  String? _orderDropdownValue;

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015, 8),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      if (controller == _reqFromController) {
        _reqStartDate = picked;
      } else if (controller == _reqToController) {
        _reqEndDate = picked;
      }
      final formattedDate = DateFormat('MM/dd/yyyy').format(picked);
      controller.text = formattedDate;
    }
  }

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProvider>(context, listen: false);
    purchReqProvider = Provider.of<PurchReqProvider>(context, listen: false);
    purchOrderProvider =
        Provider.of<PurchOrderProvider>(context, listen: false);
    reqFilterProvider =
        Provider.of<PurchReqFilterProvider>(context, listen: false);
    reqFilterProvider.setFilter(
        dataType: _reqDataType,
        status: _reqStatus,
        sort: _reqSort,
        notify: false);
    orderFilterProvider =
        Provider.of<PurchOrderFilterProvider>(context, listen: false);
    orderFilterProvider.setFilter(
        dataType: _orderDataType,
        status: _orderStatus,
        sort: _orderSort,
        notify: false);

    futures = [_getPurchReqData(), _getPurchOrderData(), _getSalesOrderData()];
    _children = [
      const PurchReqScreen(),
      const PurchReqHistoryScreen(),
      const PurchOrderScreen(),
      const PurchOrderHistoryScreen(),
    ];
    if (kIsWeb) {
      webNotif();
    } else {
      if (Platform.isAndroid || Platform.isIOS) {
        mobileNotif();
      } else {
        desktopNotif();
      }
    }
  }

  Future<void> webNotification({required String message}) async {
    var permission = web.Notification.permission;
    if (permission == 'granted') {
      player.play('audio/notif_sound2.mp3');
      var notification = web.Notification(message);

      //not working

      // web.window.onFocus.listen((event) {
      //   // Perform the desired action here
      //   print('Notification clicked!');
      // });
      // notification.onClick.listen((event) {
      //   print('web notif click');
      //   js.context.callMethod('focus');
      //   setState(() {
      //     _currentIndex = 0;
      //     future = _getData();
      //   });
      // });
    }
  }

  void mobileNotif() {
    // // //when user taps notif
    // FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    //   print('FirebaseMessaging.onMessageOpenedApp');
    //   if (message.data['type'] == 'PR') {
    //     String requestNumber = message.data['preqNum'];
    //     // use the data to navigate to the appropriate screen
    //     // ...
    //     print('requestNumber onMessageOpenedApp: $requestNumber');
    //     Provider.of<PurchReqProvider>(context, listen: false)
    //         .setReqNumber(reqNumber: int.parse(requestNumber), notify: true);
    //     _currentIndex = 0;
    //   }
    //   if (message.data['type'] == 'PO') {
    //     String requestNumber = message.data['poNum'];
    //     // use the data to navigate to the appropriate screen
    //     // ...
    //     print('requestNumber onMessageOpenedApp: $requestNumber');
    //     Provider.of<PurchOrderProvider>(context, listen: false).setOrderNumber(
    //         orderNumber: int.parse(requestNumber), notify: true);
    //     _currentIndex = 2;
    //   }

    //   setState(() {
    //     futures = [_getPurchReqData(), _getPurchOrderData()];
    //   });
    // });

    // //foreground
    // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    //   print('FirebaseMessaging.onMessage');
    //   player.play('audio/notif_sound2.mp3');
    //   showToast('New Purchase Request!', gravity: ToastGravity.TOP);
    // });
  }

  void webNotif() {
    bool stream = false;
    final documentRef = FirebaseFirestore.instance
        .collection("notifications")
        .doc(userProvider.user!.username);
    documentRef.snapshots().listen(
      (event) {
        if (stream) {
          final data = event.data()!;
          DateTime dateTime = data["requestDate"].toDate();
          String message =
              "***New Purchase Request!***\nRequest Number: ${data["preqNum"]}\nRequest Date: $dateTime\nReference: ${data["reference"]}\nWarehouse: ${data["warehouseDescription"]}\nRequested By: ${data["requestedBy"]}\nReason: ${data["reason"]}";
          webNotification(message: message);
          Provider.of<PurchReqProvider>(context, listen: false).setReqNumber(
              reqNumber: int.parse(data["preqNum"]), notify: true);
        }
        stream = true;
      },
      onError: (error) => print("Listen failed: $error"),
    );
  }

  void desktopNotif() {
    // final documentRef = Firestore.instance
    //     .collection('notifications')
    //     .document(userProvider.user!.username);
    // // Listen to changes in the document
    // documentRef.stream.listen(
    //   (document) {
    //     // Handle the updated document data
    //     if (stream) {
    //       final Map<String, dynamic> data = document!.map;
    //       String message =
    //           "***New Purchase Request!***\nRequest Number: ${data["preqNum"]}\nRequest Date: ${data["requestDate"]}\nReference: ${data["reference"]}\nWarehouse: ${data["warehouseDescription"]}\nRequested By: ${data["requestedBy"]}\nReason: ${data["reason"]}";

    //       Provider.of<PurchReqProvider>(context, listen: false).setReqNumber(
    //           reqNumber: int.parse(data["preqNum"]), notify: true);
    //       LocalNotification notification = LocalNotification(
    //         title: "Request Number: ${data["preqNum"]}",
    //         body: message,
    //       );
    //       notification.onShow = () {
    //         print('onShow ${notification.identifier}');
    //       };
    //       notification.onClose = (closeReason) {
    //         // Only supported on windows, other platforms closeReason is always unknown.
    //         switch (closeReason) {
    //           case LocalNotificationCloseReason.userCanceled:
    //             // do something
    //             break;
    //           case LocalNotificationCloseReason.timedOut:
    //             // do something
    //             break;
    //           default:
    //         }
    //         print('onClose  - $closeReason');
    //       };
    //       notification.onClick = () {
    //         print('onClick ${notification.identifier}');
    //       };
    //       notification.onClickAction = (actionIndex) {
    //         print('onClickAction ${notification.identifier} - $actionIndex');
    //       };

    //       player.play('audio/notif_sound2.mp3');
    //       notification.show();
    //     }
    //     stream = true;
    //   },
    //   onError: (error) {
    //     // Handle errors
    //     print('Error: $error');
    //   },
    // );
  }

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
      // purchOrderProvider.clearOrderNumber();
      // purchOrderProvider.clearList();
    }
    return SalesOrderService.getSalesOrderView(
        sessionId: userProvider.user!.sessionId,
        recordOffset: 0,
        forPending: true,
        forAll: true);
  }

  Future<void> _reqShowDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return SimpleDialog(
              title: const Center(
                  child: Column(
                children: [Text('Filter'), Divider()],
              )),
              children: [
                IntrinsicHeight(
                  child: Row(children: [
                    Expanded(
                        child: Column(
                      children: [
                        const Text('Data Type'),
                        Row(
                          children: [
                            Radio<ReqDataType>(
                              value: ReqDataType.reqDate,
                              groupValue: _reqDataType,
                              onChanged: (ReqDataType? value) {
                                setState(() {
                                  _reqDataType = value!;
                                });
                              },
                            ),
                            const Text('Request Date')
                          ],
                        ),
                        Row(
                          children: [
                            Radio<ReqDataType>(
                              value: ReqDataType.purchReqNum,
                              groupValue: _reqDataType,
                              onChanged: (ReqDataType? value) {
                                setState(() {
                                  _reqDataType = value!;
                                });
                              },
                            ),
                            const Expanded(
                                child: Text('Purchase Request Number'))
                          ],
                        ),
                        Row(
                          children: [
                            Radio<ReqDataType>(
                              value: ReqDataType.neededDate,
                              groupValue: _reqDataType,
                              onChanged: (ReqDataType? value) {
                                setState(() {
                                  _reqDataType = value!;
                                });
                              },
                            ),
                            const Text('Needed Date')
                          ],
                        ),
                        Row(
                          children: [
                            Radio<ReqDataType>(
                              value: ReqDataType.other,
                              groupValue: _reqDataType,
                              onChanged: (ReqDataType? value) {
                                setState(() {
                                  _reqDataType = value!;
                                });
                              },
                            ),
                            const Text('Other')
                          ],
                        ),
                        if (_reqDataType == ReqDataType.other)
                          DropdownButton<String>(
                            value: _reqDropdownValue,
                            onChanged: (String? newValue) {
                              setState(() {
                                _reqDropdownValue = newValue;
                              });
                            },
                            items: <String>[
                              'Reference',
                              'Warehouse',
                              'Cost Center',
                              'Requested By',
                              'Username'
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                      ],
                    )),
                    const VerticalDivider(),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Status'),
                          Row(
                            children: [
                              Radio<ReqStatus>(
                                value: ReqStatus.approved,
                                groupValue: _reqStatus,
                                onChanged: (ReqStatus? value) {
                                  setState(() {
                                    _reqStatus = value!;
                                  });
                                },
                              ),
                              const Text('Approved')
                            ],
                          ),
                          Row(
                            children: [
                              Radio<ReqStatus>(
                                value: ReqStatus.denied,
                                groupValue: _reqStatus,
                                onChanged: (ReqStatus? value) {
                                  setState(() {
                                    _reqStatus = value!;
                                  });
                                },
                              ),
                              const Text('Denied')
                            ],
                          ),
                          Row(
                            children: [
                              Radio<ReqStatus>(
                                value: ReqStatus.pending,
                                groupValue: _reqStatus,
                                onChanged: (ReqStatus? value) {
                                  setState(() {
                                    _reqStatus = value!;
                                  });
                                },
                              ),
                              const Text('Pending')
                            ],
                          ),
                          Row(
                            children: [
                              Radio<ReqStatus>(
                                value: ReqStatus.all,
                                groupValue: _reqStatus,
                                onChanged: (ReqStatus? value) {
                                  setState(() {
                                    _reqStatus = value!;
                                  });
                                },
                              ),
                              const Text('All')
                            ],
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
                const Divider(),
                Visibility(
                  visible: _reqDataType == ReqDataType.reqDate ||
                      _reqDataType == ReqDataType.neededDate,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _reqFromController,
                            decoration: InputDecoration(
                              labelText: 'From: ',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.close),
                                color: Colors.grey,
                                onPressed: () {
                                  if (_reqFromController.text.isNotEmpty) {
                                    setState(() {
                                      _reqFromController.clear();
                                      _reqStartDate = null;
                                    });
                                    this.setState(() {
                                      _reqFromController.clear();
                                      _reqStartDate = null;
                                    });
                                  }
                                },
                              ),
                            ),
                            readOnly: true,
                            onTap: () =>
                                _selectDate(context, _reqFromController),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: TextField(
                            controller: _reqToController,
                            decoration: InputDecoration(
                              labelText: 'To: ',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.close),
                                color: Colors.grey,
                                onPressed: () {
                                  if (_reqToController.text.isNotEmpty) {
                                    setState(() {
                                      _reqToController.clear();
                                      _reqEndDate = null;
                                    });
                                  }
                                },
                              ),
                            ),
                            readOnly: true,
                            onTap: () => _selectDate(context, _reqToController),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Visibility(
                  visible: _reqDataType != ReqDataType.other,
                  child: Column(
                    children: [
                      const Text('Sort by'),
                      Center(
                          child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Radio<ReqSort>(
                                value: ReqSort.asc,
                                groupValue: _reqSort,
                                onChanged: (ReqSort? value) {
                                  setState(() {
                                    _reqSort = value!;
                                  });
                                },
                              ),
                              const Text('Ascending')
                            ],
                          ),
                          Row(
                            children: [
                              Radio<ReqSort>(
                                value: ReqSort.dsc,
                                groupValue: _reqSort,
                                onChanged: (ReqSort? value) {
                                  setState(() {
                                    _reqSort = value!;
                                  });
                                },
                              ),
                              const Text('Descending')
                            ],
                          ),
                        ],
                      )),
                    ],
                  ),
                ),
                Visibility(
                  visible: _reqDataType == ReqDataType.other,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    child: TextField(
                      controller: _reqOtherController,
                      decoration: const InputDecoration(
                        hintText: 'Enter text here',
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    reqFilterProvider.setFilter(
                        dataType: _reqDataType,
                        status: _reqStatus,
                        sort: _reqSort,
                        fromDate: _reqStartDate,
                        toDate: _reqEndDate,
                        otherDropdown: _reqDropdownValue,
                        otherValue: _reqOtherController.text);
                  },
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      const RoundedRectangleBorder(
                        //borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey),
                      ),
                    ),
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.white),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                //end
              ]);
        });
      },
    );
  }

  Future<void> _orderShowDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return SimpleDialog(
              title: const Center(
                  child: Column(
                children: [Text('Filter'), Divider()],
              )),
              children: [
                IntrinsicHeight(
                  child: Row(children: [
                    Expanded(
                        child: Column(
                      children: [
                        const Text('Data Type'),
                        Row(
                          children: [
                            Radio<OrderDataType>(
                              value: OrderDataType.poDate,
                              groupValue: _orderDataType,
                              onChanged: (OrderDataType? value) {
                                setState(() {
                                  _orderDataType = value!;
                                });
                              },
                            ),
                            const Expanded(child: Text('Purchase Order Date'))
                          ],
                        ),
                        Row(
                          children: [
                            Radio<OrderDataType>(
                              value: OrderDataType.poNum,
                              groupValue: _orderDataType,
                              onChanged: (OrderDataType? value) {
                                setState(() {
                                  _orderDataType = value!;
                                });
                              },
                            ),
                            const Expanded(child: Text('Purchase Order Number'))
                          ],
                        ),
                        Row(
                          children: [
                            Radio<OrderDataType>(
                              value: OrderDataType.delvDate,
                              groupValue: _orderDataType,
                              onChanged: (OrderDataType? value) {
                                setState(() {
                                  _orderDataType = value!;
                                });
                              },
                            ),
                            const Text('Delivery Date Date')
                          ],
                        ),
                        Row(
                          children: [
                            Radio<OrderDataType>(
                              value: OrderDataType.other,
                              groupValue: _orderDataType,
                              onChanged: (OrderDataType? value) {
                                setState(() {
                                  _orderDataType = value!;
                                });
                              },
                            ),
                            const Text('Other')
                          ],
                        ),
                        if (_orderDataType == OrderDataType.other)
                          DropdownButton<String>(
                            value: _orderDropdownValue,
                            onChanged: (String? newValue) {
                              setState(() {
                                _orderDropdownValue = newValue;
                              });
                            },
                            items: <String>[
                              'Reference',
                              'Warehouse',
                              'Supplier',
                              'Address',
                              'Remarks',
                              'Purpose',
                              'Terms of Payment',
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                      ],
                    )),
                    const VerticalDivider(),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Status'),
                          Row(
                            children: [
                              Radio<OrderStatus>(
                                value: OrderStatus.approved,
                                groupValue: _orderStatus,
                                onChanged: (OrderStatus? value) {
                                  setState(() {
                                    _orderStatus = value!;
                                  });
                                },
                              ),
                              const Text('Approved')
                            ],
                          ),
                          Row(
                            children: [
                              Radio<OrderStatus>(
                                value: OrderStatus.denied,
                                groupValue: _orderStatus,
                                onChanged: (OrderStatus? value) {
                                  setState(() {
                                    _orderStatus = value!;
                                  });
                                },
                              ),
                              const Text('Denied')
                            ],
                          ),
                          Row(
                            children: [
                              Radio<OrderStatus>(
                                value: OrderStatus.pending,
                                groupValue: _orderStatus,
                                onChanged: (OrderStatus? value) {
                                  setState(() {
                                    _orderStatus = value!;
                                  });
                                },
                              ),
                              const Text('Pending')
                            ],
                          ),
                          Row(
                            children: [
                              Radio<OrderStatus>(
                                value: OrderStatus.all,
                                groupValue: _orderStatus,
                                onChanged: (OrderStatus? value) {
                                  setState(() {
                                    _orderStatus = value!;
                                  });
                                },
                              ),
                              const Text('All')
                            ],
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
                const Divider(),
                Visibility(
                  visible: _orderDataType == OrderDataType.poDate ||
                      _orderDataType == OrderDataType.delvDate,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _orderFromController,
                            decoration: InputDecoration(
                              labelText: 'From: ',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.close),
                                color: Colors.grey,
                                onPressed: () {
                                  if (_orderFromController.text.isNotEmpty) {
                                    _orderFromController.clear();
                                    _orderStartDate = null;
                                  }
                                },
                              ),
                            ),
                            readOnly: true,
                            onTap: () =>
                                _selectDate(context, _orderFromController),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: TextField(
                            controller: _orderToController,
                            decoration: InputDecoration(
                              labelText: 'To: ',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.close),
                                color: Colors.grey,
                                onPressed: () {
                                  if (_orderToController.text.isNotEmpty) {
                                    _orderToController.clear();
                                    _orderEndDate = null;
                                  }
                                },
                              ),
                            ),
                            readOnly: true,
                            onTap: () =>
                                _selectDate(context, _orderToController),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Visibility(
                  visible: _orderDataType != OrderDataType.other,
                  child: Column(
                    children: [
                      const Text('Sort by'),
                      Center(
                          child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Radio<OrderSort>(
                                value: OrderSort.asc,
                                groupValue: _orderSort,
                                onChanged: (OrderSort? value) {
                                  setState(() {
                                    _orderSort = value!;
                                  });
                                },
                              ),
                              const Text('Ascending')
                            ],
                          ),
                          Row(
                            children: [
                              Radio<OrderSort>(
                                value: OrderSort.dsc,
                                groupValue: _orderSort,
                                onChanged: (OrderSort? value) {
                                  setState(() {
                                    _orderSort = value!;
                                  });
                                },
                              ),
                              const Text('Descending')
                            ],
                          ),
                        ],
                      )),
                    ],
                  ),
                ),
                Visibility(
                  visible: _orderDataType == OrderDataType.other,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    child: TextField(
                      controller: _orderOtherController,
                      decoration: const InputDecoration(
                        hintText: 'Enter text here',
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    orderFilterProvider.setFilter(
                        dataType: _orderDataType,
                        status: _orderStatus,
                        sort: _orderSort,
                        fromDate: _orderStartDate,
                        toDate: _orderEndDate,
                        otherDropdown: _orderDropdownValue,
                        otherValue: _orderOtherController.text);
                  },
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      const RoundedRectangleBorder(
                        //borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey),
                      ),
                    ),
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.white),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                //end
              ]);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text(appBarTitle),
            backgroundColor: const Color(0xFF000000),
            flexibleSpace: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: kToolbarHeight,
                child: Stack(
                  children: [
                    //Refresh button
                    Align(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Stack(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: () {
                                  showToast('Refreshing data...');
                                  setState(() {
                                    refresh = true;
                                    futures = [
                                      _getPurchReqData(button: true),
                                      _getPurchOrderData(button: true)
                                    ];
                                  });
                                },
                                color: Colors.white,
                                splashColor: Colors.transparent,
                              ),
                              Positioned(
                                right: 1,
                                top: 3,
                                child: Selector<PurchReqProvider, int>(
                                    //todo
                                    selector: (context, purchReqProvider) =>
                                        purchReqProvider.reqNumber,
                                    builder: (context, reqNumber, child) {
                                      return Visibility(
                                          visible: reqNumber != -1,
                                          child: Container(
                                            width: 10,
                                            height: 10,
                                            decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.red),
                                          ));
                                    }),
                              )
                            ],
                          ),
                          Visibility(
                            visible: _currentIndex == 1 || _currentIndex == 3,
                            child: Stack(
                              children: [
                                Visibility(
                                  visible: _currentIndex == 1,
                                  child: IconButton(
                                    icon:
                                        const Icon(Icons.filter_list_outlined),
                                    onPressed: () {
                                      _reqShowDialog();
                                    },
                                    color: Colors.white,
                                    splashColor: Colors.transparent,
                                  ),
                                ),
                                Visibility(
                                  visible: _currentIndex == 3,
                                  child: IconButton(
                                    icon:
                                        const Icon(Icons.filter_list_outlined),
                                    onPressed: () {
                                      _orderShowDialog();
                                    },
                                    color: Colors.white,
                                    splashColor: Colors.transparent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 37,
                      bottom: 35,
                      child: SizedBox(
                        width: 10,
                        height: 10,
                        child: FutureBuilder(
                            future: Future.wait(futures),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.done) {
                                final List<PurchaseRequest> data =
                                    snapshot.data![0]['purchaseRequests'] ?? [];
                                int pending = data
                                    .where((purchReq) =>
                                        !purchReq.isFinal &&
                                        !purchReq.isCancelled)
                                    .length;

                                final List<PurchaseOrder> data2 =
                                    snapshot.data![1]['purchaseOrders'] ?? [];
                                int pending2 = data2
                                    .where((purchOrder) =>
                                        !purchOrder.isFinal &&
                                        !purchOrder.isCancelled)
                                    .length;
                                return Visibility(
                                    visible: pending != 0 || pending2 != 0,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.red),
                                    ));
                              } else {
                                return Container();
                              }
                            }),
                      ),
                    ),
                  ],
                ),
              ),
            )),
        drawer: Drawer(
          child: Stack(
            children: [
              ListView(
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
                  Container(
                    color: _currentIndex == 0
                        ? const Color.fromARGB(255, 226, 226, 226)
                        : Colors.transparent,
                    child: ListTile(
                      key: const PageStorageKey('purchase_request'),
                      leading: Icon(Icons.receipt,
                          color:
                              _currentIndex == 0 ? Colors.black : Colors.grey),
                      title: Text('Purchase Request',
                          style: TextStyle(
                              color: _currentIndex == 0
                                  ? Colors.black
                                  : Colors.grey)),
                      trailing: SizedBox(
                        width: 20,
                        height: 20,
                        child: FutureBuilder(
                            future: futures[0],
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.done) {
                                final List<PurchaseRequest> data =
                                    snapshot.data['purchaseRequests'] ?? [];
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
                      selected: _currentIndex == 0,
                      onTap: () {
                        setState(() {
                          _currentIndex = 0;
                          appBarTitle = 'Purchase Request';
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  //Purchase Request History
                  Container(
                    color: _currentIndex == 1
                        ? const Color.fromARGB(255, 226, 226, 226)
                        : Colors.transparent,
                    child: ListTile(
                      key: const PageStorageKey('purchase_request_history'),
                      leading: Icon(Icons.history,
                          color:
                              _currentIndex == 1 ? Colors.black : Colors.grey),
                      title: Text('Purchase Request History',
                          style: TextStyle(
                              color: _currentIndex == 1
                                  ? Colors.black
                                  : Colors.grey)),
                      selected: _currentIndex == 1,
                      onTap: () {
                        setState(() {
                          _currentIndex = 1;
                          appBarTitle = 'Purchase Request History';
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  //Purchase Order
                  Container(
                    color: _currentIndex == 2
                        ? const Color.fromARGB(255, 226, 226, 226)
                        : Colors.transparent,
                    child: ListTile(
                      key: const PageStorageKey('purchase_order'),
                      leading: Icon(Icons.receipt,
                          color:
                              _currentIndex == 2 ? Colors.black : Colors.grey),
                      title: Text('Purchase Order',
                          style: TextStyle(
                              color: _currentIndex == 2
                                  ? Colors.black
                                  : Colors.grey)),
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
                      selected: _currentIndex == 2,
                      onTap: () {
                        setState(() {
                          _currentIndex = 2;
                          appBarTitle = 'Purchase Order';
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ), //Purchase Order History
                  Container(
                    color: _currentIndex == 3
                        ? const Color.fromARGB(255, 226, 226, 226)
                        : Colors.transparent,
                    child: ListTile(
                      key: const PageStorageKey('purchase_Order_history'),
                      leading: Icon(Icons.history,
                          color:
                              _currentIndex == 3 ? Colors.black : Colors.grey),
                      title: Text('Purchase Order History',
                          style: TextStyle(
                              color: _currentIndex == 3
                                  ? Colors.black
                                  : Colors.grey)),
                      selected: _currentIndex == 3,
                      onTap: () {
                        setState(() {
                          _currentIndex = 3;
                          appBarTitle = 'Purchase Order History';
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
              Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(userProvider.user!.username),
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
                    // Display a loading indicator or a progress bar
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    // Handle the error
                    return Text('Error: ${snapshot.error}');
                  } else {
                    // Purchase Request
                    bool purchReqFlag = handleSessionExpiredException(
                        snapshot.data![0], context);
                    if (!purchReqFlag) {
                      final List<PurchaseRequest> data =
                          snapshot.data![0]['purchaseRequests'];
                      if (purchReqProvider.purchaseRequestList.isEmpty) {
                        purchReqProvider.setList(
                            purchaseRequestList: data, notify: false);
                      }
                    } else {
                      purchReqProvider.setList(purchaseRequestList: [], notify: false);
                    }

                    // Purchase Order
                    bool purchOrderFlag = handleSessionExpiredException(
                        snapshot.data![1], context);
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

                    //put the item from notif in first
                    if (purchReqProvider.reqNumber != -1 && refresh) {
                      PurchaseRequest item = purchReqProvider.purchaseRequestList
                          .firstWhere((item) =>
                              item.preqNum == purchReqProvider.reqNumber);
                      purchReqProvider.removeItem(
                          purchReq: item, notify: false);
                      purchReqProvider.insertItemtoFirst(
                          item: item, notify: false);
                      purchReqProvider.setReqNumber(reqNumber: -1);
                      refresh = false;
                    }
                    return IndexedStack(
                      index: _currentIndex,
                      children: _children,
                    );
                  }
                }));
  }
}
