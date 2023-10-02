import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rnd_mobile/api/purchase_order_api.dart';
import 'package:rnd_mobile/models/purchase_order_model.dart';
import 'package:rnd_mobile/providers/purchase_order/puch_order_hist_filter_provider.dart';
import 'package:rnd_mobile/providers/purchase_order/purchase_order_provider.dart';
import 'package:rnd_mobile/providers/user_provider.dart';
import 'package:rnd_mobile/utilities/date_only.dart';
import 'package:rnd_mobile/utilities/date_text_formatter.dart';
import 'package:rnd_mobile/utilities/session_handler.dart';
import 'package:rnd_mobile/widgets/alert_dialog.dart';
import 'package:rnd_mobile/widgets/mobile/mob_purch_order_dialog.dart';
import 'package:rnd_mobile/widgets/mobile/mob_reusable_column.dart';
import 'package:rnd_mobile/widgets/toast.dart';
import 'package:table_calendar/table_calendar.dart';

class MobilePurchOrderHistScreen extends StatefulWidget {
  const MobilePurchOrderHistScreen({super.key});

  @override
  State<MobilePurchOrderHistScreen> createState() =>
      _MobilePurchOrderHistScreenState();
}

class _MobilePurchOrderHistScreenState
    extends State<MobilePurchOrderHistScreen> {
  late final UserProvider userProvider;
  late final PurchOrderHistFilterProvider orderFilterProvider;
  late final PurchOrderProvider purchOrderProvider;
  int? selectedItem;
  int _loadedItemsCount = 15;
  bool isLoadingMore = false;
  bool hasMore = true;
  OrderDataType _orderDataType = OrderDataType.poDate;
  OrderStatus _orderStatus = OrderStatus.all;
  OrderSort _orderSort = OrderSort.asc;
  final TextEditingController _orderFromController = TextEditingController();
  final TextEditingController _orderToController = TextEditingController();
  final TextEditingController _orderOtherController = TextEditingController();
  String? _orderDropdownValue;
  late Brightness brightness;
  late Future purchOrderNonPendingData;
  bool initialLoad = false;

  //Date Picker
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _showFromDate = false;
  bool _showToDate = false;
  DateTime _fromFocusedDay = DateTime.now();
  DateTime _toFocusedDay = DateTime.now();
  DateTime? _orderFromDate;
  DateTime? _orderToDate;

  void sortPurchaseOrders(List<PurchaseOrder> purchaseOrders,
      OrderDataType dataType, OrderSort sort,
      {DateTime? startDate,
      DateTime? endDate,
      String? otherDropdown,
      String? otherValue}) {
    if (dataType == OrderDataType.other) {
      if (otherValue != '' && otherValue != null) {
        switch (otherDropdown) {
          case 'Reference':
            purchaseOrders.retainWhere(
                (order) => order.reference.trim() == otherValue.trim());
            break;
          case 'Warehouse':
            purchaseOrders.retainWhere((order) =>
                order.warehouseDescription.trim() == otherValue.trim());
            break;
          case 'Supplier':
            purchaseOrders.retainWhere(
                (order) => order.supplierName.trim() == otherValue.trim());
            break;
          case 'Address':
            purchaseOrders.retainWhere(
                (order) => order.address.trim() == otherValue.trim());
            break;
          case 'Remarks':
            purchaseOrders.retainWhere(
                (order) => order.remarks.trim() == otherValue.trim());
            break;
          case 'Purpose':
            purchaseOrders.retainWhere(
                (order) => order.purpose.trim() == otherValue.trim());
            break;
          case 'Terms of Payment':
            purchaseOrders.retainWhere(
                (order) => order.topDescription.trim() == otherValue.trim());
            break;
          default:
            break;
        }
      }
    } else {
      switch (dataType) {
        case OrderDataType.poDate:
          if (startDate != null || endDate != null) {
            purchaseOrders.retainWhere((order) {
              if (startDate != null &&
                  dateOnly(order.poDate).isBefore(dateOnly(startDate))) {
                return false;
              }
              if (endDate != null &&
                  dateOnly(order.poDate).isAfter(dateOnly(endDate))) {
                return false;
              }
              return true;
            });
          }
          purchaseOrders.sort((a, b) => sort == OrderSort.asc
              ? a.poDate.compareTo(b.poDate)
              : b.poDate.compareTo(a.poDate));
          break;
        case OrderDataType.poNum:
          purchaseOrders.sort((a, b) => sort == OrderSort.asc
              ? a.poNumber.compareTo(b.poNumber)
              : b.poNumber.compareTo(a.poNumber));
          break;
        case OrderDataType.delvDate:
          if (startDate != null || endDate != null) {
            purchaseOrders.retainWhere((order) {
              if (startDate != null &&
                  dateOnly(order.deliveryDate).isBefore(dateOnly(startDate))) {
                return false;
              }
              if (endDate != null &&
                  dateOnly(order.deliveryDate).isAfter(dateOnly(endDate))) {
                return false;
              }
              return true;
            });
          }
          purchaseOrders.sort((a, b) => sort == OrderSort.asc
              ? a.deliveryDate.compareTo(b.deliveryDate)
              : b.deliveryDate.compareTo(a.deliveryDate));
          break;
        default:
          break;
      }
    }
  }

  void _loadMore() async {
    late List<PurchaseOrder> newPurchaseOrders;
    if (Provider.of<PurchOrderHistFilterProvider>(context, listen: false)
            .status ==
        OrderStatus.pending) {
      final data = await PurchOrderService.getPurchOrderView(
        sessionId: userProvider.user!.sessionId,
        recordOffset: _loadedItemsCount,
        forPending: true,
      );
      if (mounted) {
        bool purchOrderFlag = handleSessionExpiredException(data, context);

        if (!purchOrderFlag) {
          newPurchaseOrders = data['purchaseOrders'];
          hasMore = data['hasMore'];
        }
      }
    } else {
      final data = await PurchOrderService.getPurchOrderView(
        sessionId: userProvider.user!.sessionId,
        recordOffset: _loadedItemsCount,
        forAll: true,
      );
      if (mounted) {
        bool purchOrderFlag = handleSessionExpiredException(data, context);

        if (!purchOrderFlag) {
          newPurchaseOrders = data['purchaseOrders'];
          hasMore = data['hasMore'];
        }
      }
    }
    setState(() {
      isLoadingMore = false;
      _loadedItemsCount += newPurchaseOrders.length;
      Provider.of<PurchOrderProvider>(context, listen: false)
          .addItems(purchOrders: newPurchaseOrders);
    });
  }

  Future<dynamic> _getPurchOrderData() {
    return PurchOrderService.getPurchOrderView(
        sessionId: userProvider.user!.sessionId,
        recordOffset: 0,
        // forPending: true,
        forAll: true);
  }

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProvider>(context, listen: false);
    purchOrderProvider =
        Provider.of<PurchOrderProvider>(context, listen: false);
    purchOrderNonPendingData = _getPurchOrderData();
    orderFilterProvider =
        Provider.of<PurchOrderHistFilterProvider>(context, listen: false);
    if (orderFilterProvider.dataType == null ||
        orderFilterProvider.status == null ||
        orderFilterProvider.sort == null) {
      orderFilterProvider.setFilter(
          dataType: _orderDataType,
          status: _orderStatus,
          sort: _orderSort,
          notify: false);
    }
    brightness = PlatformDispatcher.instance.platformBrightness;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: purchOrderNonPendingData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          if (!initialLoad) {
            // Purchase Order Non Pending Items
            bool purchOrderFlag =
                handleSessionExpiredException(snapshot.data!, context);
            if (!purchOrderFlag) {
              final List<PurchaseOrder> data = snapshot.data!['purchaseOrders'];
              purchOrderProvider.addItems(purchOrders: data, notify: false);
            }
            initialLoad = true;
          }

          return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      const Spacer(),
                      InkWell(
                        onTap: () {
                          _orderShowDialog();
                        },
                        child: const Row(
                          children: [
                            Text('Sort By',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            Icon(Icons.filter_list_sharp,
                                color: Colors.grey, size: 15)
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Expanded(child: Consumer<PurchOrderProvider>(
                    builder: (context, purchaseOrdersProvider, _) {
                  List<PurchaseOrder> purchaseListPending =
                      purchaseOrdersProvider.purchaseOrderList;
                  String? searchValue = purchaseOrdersProvider.search;
                  if (searchValue != null && searchValue != '') {
                    purchaseListPending =
                        purchaseListPending.where((purchaseRequest) {
                      return purchaseRequest.containsQuery(searchValue);
                    }).toList();
                  }
                  if (purchaseListPending.isNotEmpty) {
                    return Consumer<PurchOrderHistFilterProvider>(
                        builder: (context, filterProvider, _) {
                      List<PurchaseOrder> purchaseOrders = [];
                      if (purchaseListPending.isNotEmpty) {
                        if (filterProvider.status == OrderStatus.approved) {
                          purchaseOrders = purchaseListPending.where((item) {
                            return item.isFinal == true;
                          }).toList();
                        } else if (filterProvider.status ==
                            OrderStatus.denied) {
                          purchaseOrders = purchaseListPending.where((item) {
                            return item.isCancelled == true;
                          }).toList();
                        } else if (filterProvider.status ==
                            OrderStatus.pending) {
                          purchaseOrders = purchaseListPending.where((item) {
                            return item.isCancelled == false &&
                                item.isFinal == false;
                          }).toList();
                        } else {
                          purchaseOrders = [...purchaseListPending];
                        }
                        sortPurchaseOrders(purchaseOrders,
                            filterProvider.dataType!, filterProvider.sort!,
                            startDate: filterProvider.fromDate,
                            endDate: filterProvider.toDate,
                            otherDropdown: filterProvider.otherDropdown,
                            otherValue: filterProvider.otherValue);
                      }
                      double width = MediaQuery.of(context).size.width;
                      int value = (width / 300).floor();
                      if (value == 0) {
                        value = 1;
                      }
                      return CustomScrollView(
                        slivers: <Widget>[
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (BuildContext context, int index) {
                                if (index == purchaseOrders.length) {
                                  return Column(
                                    children: [
                                      const Divider(),
                                      Stack(
                                        children: [
                                          Align(
                                            alignment: Alignment.center,
                                            child: Visibility(
                                              visible: hasMore,
                                              child: ElevatedButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      isLoadingMore = true;
                                                    });
                                                    _loadMore();
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors
                                                                  .transparent,
                                                          elevation: 0),
                                                  child: isLoadingMore
                                                      ? const CircularProgressIndicator()
                                                      : const Text('Load More',
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .grey))),
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.center,
                                            child: Visibility(
                                                visible: !hasMore,
                                                child: const Text(
                                                    'End of Results')),
                                          ),
                                        ],
                                      ),
                                      const Divider(),
                                    ],
                                  );
                                } else {
                                  var order = purchaseOrders[index];
                                  var poDate =
                                      DateFormat.yMMMd().format(order.poDate);
                                  var deliveryDate = DateFormat.yMMMd()
                                      .format(order.deliveryDate);

                                  return StatefulBuilder(builder:
                                      (BuildContext context,
                                          StateSetter setState) {
                                    return InkWell(
                                      onTap: () {
                                        purchOrderShowDialog(
                                            context: context, order: order);
                                      },
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 15),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: order.isFinal
                                                ? Colors.green
                                                : order.isCancelled
                                                    ? Colors.red
                                                    : Colors.grey,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey
                                                    .withOpacity(0.5),
                                                spreadRadius: 1,
                                                blurRadius: 3,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding:
                                                const EdgeInsets.only(left: 3),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                  color: brightness ==
                                                          Brightness.dark
                                                      ? Colors.grey[900]
                                                      : Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                      color: Colors.grey)),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 10),
                                                child: MobileReusableColumn(
                                                  firstRowFirstText:
                                                      order.poNumber.toString(),
                                                  firstRowSecondText:
                                                      order.isFinal
                                                          ? 'Approved'
                                                          : order.isCancelled
                                                              ? 'Denied'
                                                              : 'Pending',
                                                  secondRowFirstText: order
                                                      .purpose
                                                      .toString()
                                                      .trim(),
                                                  thirdRowFirstText: order
                                                      .warehouseDescription
                                                      .toString()
                                                      .trim(),
                                                  thirdRowSecondText: order
                                                      .reference
                                                      .toString()
                                                      .trim(),
                                                  fourthRowFirstText: poDate,
                                                  fourthRowSecondText:
                                                      deliveryDate,
                                                  statusColor: order.isFinal
                                                      ? Colors.green
                                                      : order.isCancelled
                                                          ? Colors.red
                                                          : Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  });
                                }
                              },
                              childCount: purchaseOrders.length + 1,
                            ),
                          ),
                        ],
                      );
                    });
                  } else {
                    String? searchValue =
                        Provider.of<PurchOrderProvider>(context, listen: false)
                            .search;
                    return Center(
                        child: Text(
                            searchValue != null && searchValue != ''
                                ? 'No Matching Purchase Order Found'
                                : '0 Purchase Orders',
                            style: const TextStyle(fontSize: 30)));
                  }
                })),
              ]));
        }
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
                  Column(children: [
                    IntrinsicHeight(
                      child: Row(children: [
                        Expanded(
                            child: Column(
                          children: [
                            const Divider(),
                            const Text('Data Type',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            const Divider(),
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
                                const Text('Order Date',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey))
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
                                const Expanded(
                                    child: Text('Order Number',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey)))
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
                                const Text('Delivery Date',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey))
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
                                const Text('Other',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey))
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
                                    child: Text(value,
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey)),
                                  );
                                }).toList(),
                              ),
                          ],
                        )),
                        const VerticalDivider(),
                        Expanded(
                          child: Column(
                            children: [
                              const Divider(),
                              const Text('Status',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                              const Divider(),
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
                                  const Text('Approved',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey))
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
                                  const Text('Denied',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey))
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
                                  const Text('Pending',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey))
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
                                  const Text('All',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey))
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
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[\d/]')),
                                  DateTextFormatter()
                                ],
                                decoration: InputDecoration(
                                  labelText: 'From: ',
                                  hintText: 'MM/DD/YYYY',
                                  labelStyle: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                  suffixIcon: Visibility(
                                    visible:
                                        _orderFromController.text.isNotEmpty,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, size: 15),
                                      onPressed: () {
                                        if (_orderFromController
                                            .text.isNotEmpty) {
                                          setState(() {
                                            _orderFromController.clear();
                                            _orderFromDate = null;
                                          });
                                          setState(() {
                                            _orderFromController.clear();
                                            _orderToDate = null;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                onChanged: (String value) {
                                  if (value.length == 10) {
                                    final format = DateFormat('MM/dd/yyyy');
                                    try {
                                      final date = format.parseStrict(value);
                                      if (date.year >= 2010 &&
                                          date.year <= 2050) {
                                        _orderFromDate = date;
                                        _fromFocusedDay = date;
                                        _showFromDate = false;
                                      } else {
                                        // The entered date is not within the valid range
                                        _orderFromDate = null;
                                        _fromFocusedDay = DateTime.now();
                                        // showToastMessage(
                                        //     'Entered date is not within the valid range');

                                        if (mounted) {
                                          alertDialog(context,
                                              title: 'Error',
                                              body:
                                                  'Entered date is not within the valid range');
                                        }
                                      }
                                    } catch (e) {
                                      // The entered date is not valid
                                      _orderFromDate = null;
                                      _fromFocusedDay = DateTime.now();
                                      // showToastMessage(
                                      //     'Entered date is not valid');

                                      if (mounted) {
                                        alertDialog(context,
                                            title: 'Error',
                                            body: 'Entered date is not valid');
                                      }
                                    }
                                    setState(() {});
                                  }
                                },
                                onTap: () {
                                  setState(() {
                                    _showFromDate = true;
                                  });
                                },
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: TextField(
                                controller: _orderToController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[\d/]')),
                                  DateTextFormatter()
                                ],
                                decoration: InputDecoration(
                                  labelText: 'To: ',
                                  hintText: 'MM/DD/YYYY',
                                  labelStyle: const TextStyle(
                                    fontSize: 12,
                                  ),
                                  suffixIcon: Visibility(
                                    visible: _orderToController.text.isNotEmpty,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, size: 15),
                                      color: Colors.grey,
                                      onPressed: () {
                                        if (_orderToController
                                            .text.isNotEmpty) {
                                          setState(() {
                                            _orderToController.clear();
                                            _orderToDate = null;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                onChanged: (String value) {
                                  if (value.length == 10) {
                                    final format = DateFormat('MM/dd/yyyy');
                                    try {
                                      final date = format.parseStrict(value);
                                      if (date.year >= 2010 &&
                                          date.year <= 2050) {
                                        _orderToDate = date;
                                        _toFocusedDay = date;
                                        _showToDate = false;
                                      } else {
                                        // The entered date is not within the valid range
                                        _orderToDate = null;
                                        _toFocusedDay = DateTime.now();

                                        if (mounted) {
                                          alertDialog(context,
                                              title: 'Error',
                                              body:
                                                  'Entered date is not within the valid range');
                                        }
                                        // showToastMessage(
                                        //     'Entered date is not within the valid range');
                                      }
                                    } catch (e) {
                                      // The entered date is not valid
                                      _orderToDate = null;
                                      _toFocusedDay = DateTime.now();
                                      if (mounted) {
                                        alertDialog(context,
                                            title: 'Error',
                                            body: 'Entered date is not valid\n$e');
                                      }
                                      // showToastMessage(
                                      //     'Entered date is not valid');
                                    }
                                    setState(() {});
                                  }
                                },
                                onTap: () {
                                  setState(() {
                                    _showToDate = true;
                                  });
                                },
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Stack(
                      children: [
                        if (_showFromDate) ...[
                          Container(
                            color: Colors.black,
                            height: 425,
                            width: 275,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  height: 5,
                                ),
                                Row(
                                  children: [
                                    const Text('From Date'),
                                    const Spacer(),
                                    InkWell(
                                        onTap: () {
                                          setState(() {
                                            _showFromDate = false;
                                          });
                                        },
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.red,
                                        ))
                                  ],
                                ),
                                TableCalendar(
                                  firstDay: DateTime.utc(2010, 10, 16),
                                  lastDay: DateTime.utc(2050, 3, 14),
                                  focusedDay: _fromFocusedDay,
                                  calendarFormat: _calendarFormat,
                                  availableCalendarFormats: const {
                                    CalendarFormat.month: 'Month',
                                  },
                                  selectedDayPredicate: (day) =>
                                      isSameDay(_orderFromDate, day),
                                  onDaySelected: (selectedDay, focusedDay) {
                                    setState(() {
                                      _orderFromDate = selectedDay;
                                      _fromFocusedDay = focusedDay;
                                      _orderFromController.text =
                                          DateFormat('MM/dd/yyyy')
                                              .format(_orderFromDate!);
                                      _showFromDate = false;
                                    });
                                  },
                                  onPageChanged: (focusedDay) {
                                    _fromFocusedDay = focusedDay;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_showToDate) ...[
                          Container(
                            color: Colors.black,
                            height: 425,
                            width: 275,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  height: 5,
                                ),
                                Row(
                                  children: [
                                    const Text('To Date'),
                                    const Spacer(),
                                    InkWell(
                                        onTap: () {
                                          setState(() {
                                            _showToDate = false;
                                          });
                                        },
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.red,
                                        ))
                                  ],
                                ),
                                TableCalendar(
                                  firstDay: DateTime.utc(2010, 10, 16),
                                  lastDay: DateTime.utc(2050, 3, 14),
                                  focusedDay: _toFocusedDay,
                                  calendarFormat: _calendarFormat,
                                  availableCalendarFormats: const {
                                    CalendarFormat.month: 'Month',
                                  },
                                  selectedDayPredicate: (day) =>
                                      isSameDay(_orderToDate, day),
                                  onDaySelected: (selectedDay, focusedDay) {
                                    setState(() {
                                      _orderToDate = selectedDay;
                                      _toFocusedDay = focusedDay;
                                      _orderToController.text =
                                          DateFormat('MM/dd/yyyy')
                                              .format(_orderToDate!);
                                      _showToDate = false;
                                    });
                                  },
                                  onPageChanged: (focusedDay) {
                                    _toFocusedDay = focusedDay;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Divider(),
                    Visibility(
                      visible: _orderDataType != OrderDataType.other,
                      child: Column(
                        children: [
                          const Text('Sort by',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
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
                                  const Text('Ascending',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey))
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
                                  const Text('Descending',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey))
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
                            style: const TextStyle(fontSize: 12),
                            decoration: const InputDecoration(
                              // contentPadding: EdgeInsets.zero,
                              hintText: 'Enter text here',
                              hintStyle:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          )),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              orderFilterProvider.setFilter(
                                  dataType: _orderDataType,
                                  status: _orderStatus,
                                  sort: _orderSort,
                                  fromDate: _orderFromDate,
                                  toDate: _orderToDate,
                                  otherDropdown: _orderDropdownValue,
                                  otherValue: _orderOtherController.text);
                            },
                            child: Container(
                              height: 40,
                              decoration: const BoxDecoration(
                                  // color: Color(0xFF795FCD),
                                  color: Colors.blueGrey,
                                  border: Border.symmetric(
                                      horizontal:
                                          BorderSide(color: Colors.white))),
                              child: const Center(
                                  child: Text('Apply Filters',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.white))),
                            ),
                          ),
                        )
                      ],
                    ),
                  ])
                ]);
          });
        });
  }
}
