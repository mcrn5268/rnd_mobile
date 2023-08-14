import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rnd_mobile/api/purchase_order_api.dart';
import 'package:rnd_mobile/models/purchase_order_model.dart';
import 'package:rnd_mobile/providers/purchase_order/purch_order_filter_provider.dart';
import 'package:rnd_mobile/providers/purchase_order/purchase_order_provider.dart';
import 'package:rnd_mobile/providers/refresh_icon_indicator_provider.dart';
import 'package:rnd_mobile/providers/user_provider.dart';
import 'package:rnd_mobile/utilities/clear_data.dart';
import 'package:rnd_mobile/utilities/session_handler.dart';
import 'package:rnd_mobile/widgets/mobile/mob_purch_order_dialog.dart';
import 'package:rnd_mobile/widgets/mobile/mob_reusable_column.dart';
import 'package:rnd_mobile/widgets/toast.dart';

enum ApprovalStatus {
  approve,
  deny,
}

class MobilePurchOrderScreen extends StatefulWidget {
  const MobilePurchOrderScreen({super.key});

  @override
  State<MobilePurchOrderScreen> createState() => _MobilePurchOrderScreenState();
}

class _MobilePurchOrderScreenState extends State<MobilePurchOrderScreen> {
  late final UserProvider userProvider;
  late final PurchOrderFilterProvider purchOrderFilterProvider;
  late final PurchOrderProvider purchOrderProvider;
  ApprovalStatus? status;
  late bool confCanc;
  int? selectedItem;
  int _loadedItemsCount = 15;
  bool isLoadingMore = false;
  bool hasMore = true;
  OrderDataType _orderDataType = OrderDataType.poDate;
  final OrderStatus _orderStatus = OrderStatus.pending;
  OrderSort _orderSort = OrderSort.asc;

  final TextEditingController _orderFromController = TextEditingController();
  final TextEditingController _orderToController = TextEditingController();
  final TextEditingController _orderOtherController = TextEditingController();

  DateTime? _orderStartDate;
  DateTime? _orderEndDate;
  String? _orderDropdownValue;
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
              if (startDate != null && order.poDate.isBefore(startDate)) {
                return false;
              }
              if (endDate != null && order.poDate.isAfter(endDate)) {
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
              if (startDate != null && order.deliveryDate.isBefore(startDate)) {
                return false;
              }
              if (endDate != null && order.deliveryDate.isAfter(endDate)) {
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

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015, 8),
      lastDate: DateTime(2101),
      initialEntryMode: DatePickerEntryMode.input,
    );
    if (picked != null) {
      if (controller == _orderFromController) {
        _orderStartDate = picked;
      } else if (controller == _orderToController) {
        _orderEndDate = picked;
      }
      final formattedDate = DateFormat('yyyy/MM/dd').format(picked);
      controller.text = formattedDate;
    }
  }

  void _loadMore() async {
    final data = await PurchOrderService.getPurchOrderView(
      sessionId: userProvider.user!.sessionId,
      recordOffset: _loadedItemsCount,
      forPending: true,
    );
    if (mounted) {
      bool purchOrderFlag = handleSessionExpiredException(data, context);
      if (!purchOrderFlag) {
        final List<PurchaseOrder> newPurchaseOrders = data['purchaseOrders'];
        setState(() {
          hasMore = data['hasMore'];
          isLoadingMore = false;
          _loadedItemsCount += newPurchaseOrders.length;
          Provider.of<PurchOrderProvider>(context, listen: false)
              .addItems(purchOrders: newPurchaseOrders);
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProvider>(context, listen: false);
    purchOrderFilterProvider =
        Provider.of<PurchOrderFilterProvider>(context, listen: false);
    purchOrderProvider =
        Provider.of<PurchOrderProvider>(context, listen: false);
    if (purchOrderFilterProvider.dataType == null ||
        purchOrderFilterProvider.status == null ||
        purchOrderFilterProvider.sort == null) {
      purchOrderFilterProvider.setFilter(
          dataType: _orderDataType,
          status: _orderStatus,
          sort: _orderSort,
          notify: false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Icon(Icons.filter_list_sharp,
                          color: Colors.grey, size: 15)
                    ],
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: Consumer<PurchOrderProvider>(
                builder: (context, purchaseOrdersProvider, _) {
              List<PurchaseOrder> purchaseListPending = purchaseOrdersProvider
                  .purchaseOrderList
                  .where((purchOrder) =>
                      !purchOrder.isFinal && !purchOrder.isCancelled)
                  .toList();
              String? searchValue = purchaseOrdersProvider.search;
              if (searchValue != null && searchValue != '') {
                purchaseListPending =
                    purchaseListPending.where((purchaseorder) {
                  return purchaseorder.containsQuery(searchValue);
                }).toList();
              }
              if (purchaseListPending.isNotEmpty) {
                return Consumer<PurchOrderFilterProvider>(
                    builder: (context, filterProvider, _) {
                  List<PurchaseOrder> purchaseOrders = [];
                  if (purchaseListPending.isNotEmpty) {
                    purchaseOrders = purchaseListPending;
                    sortPurchaseOrders(purchaseOrders, filterProvider.dataType!,
                        filterProvider.sort!,
                        startDate: filterProvider.fromDate,
                        endDate: filterProvider.toDate,
                        otherDropdown: filterProvider.otherDropdown,
                        otherValue: filterProvider.otherValue);

                    if (purchOrderProvider.orderNumber != -1) {
                      PurchaseOrder? newItem =
                          purchOrderProvider.purchaseOrderList.firstWhereOrNull(
                        (item) =>
                            item.poNumber == purchOrderProvider.orderNumber,
                      );

                      if (newItem != null) {
                        purchaseOrders.removeWhere(
                            (item) => item.poNumber == newItem.poNumber);
                        purchaseOrders.insert(0, newItem);
                        purchOrderProvider.setOrderNumber(orderNumber: -1);
                      }
                      SchedulerBinding.instance.addPostFrameCallback((_) =>
                          Provider.of<RefreshIconIndicatorProvider>(context,
                                  listen: false)
                              .setShow(show: false));
                    }
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
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  elevation: 0),
                                              child: isLoadingMore
                                                  ? const CircularProgressIndicator()
                                                  : const Text('Load More',
                                                      style: TextStyle(
                                                          color: Colors.grey))),
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.center,
                                        child: Visibility(
                                            visible: !hasMore,
                                            child:
                                                const Text('End of Results')),
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
                              var deliveryDate =
                                  DateFormat.yMMMd().format(order.deliveryDate);
                              selectedItem = null;
                              confCanc = false;
                              status = null;
                              return StatefulBuilder(builder:
                                  (BuildContext context, StateSetter setState) {
                                Color leadingColor;
                                if (status == ApprovalStatus.deny) {
                                  leadingColor = Colors.red;
                                } else if (status == ApprovalStatus.approve) {
                                  leadingColor = Colors.green;
                                } else {
                                  leadingColor = Colors.grey;
                                }

                                return InkWell(
                                  onTap: () {
                                    purchOrderShowDialog(
                                        context: context, order: order);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 15),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: leadingColor,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.5),
                                            spreadRadius: 1,
                                            blurRadius: 3,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 3),
                                        child: Container(
                                          decoration: BoxDecoration(
                                              color: MediaQuery.of(context)
                                                          .platformBrightness ==
                                                      Brightness.dark
                                                  ? Colors.grey[900]
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                  color: leadingColor)),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 10),
                                            child: MobileReusableColumn(
                                              firstRowFirstText:
                                                  order.poNumber.toString(),
                                              firstRowSecondText: 'Pending',
                                              secondRowFirstText: order.purpose
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
                                              fourthRowSecondText: deliveryDate,
                                              confCanc: confCanc,
                                              statusColor: Colors.grey,
                                              onDenyPressed: () {
                                                setState(() {
                                                  selectedItem = index;
                                                  confCanc = true;
                                                  status = ApprovalStatus.deny;
                                                });
                                              },
                                              onApprovePressed: () {
                                                setState(() {
                                                  selectedItem = index;
                                                  confCanc = true;
                                                  status =
                                                      ApprovalStatus.approve;
                                                });
                                              },
                                              onCancelPressed: () {
                                                setState(() {
                                                  selectedItem = null;
                                                  confCanc = false;
                                                  status = null;
                                                });
                                              },
                                              onConfirmPressed: () async {
                                                dynamic response;
                                                if (status ==
                                                    ApprovalStatus.approve) {
                                                  response =
                                                      await PurchOrderService
                                                          .aprvPurchOrder(
                                                              sessionId:
                                                                  userProvider
                                                                      .user!
                                                                      .sessionId,
                                                              poId: order.id);
                                                } else {
                                                  response =
                                                      await PurchOrderService
                                                          .dnyPurchOrder(
                                                              sessionId:
                                                                  userProvider
                                                                      .user!
                                                                      .sessionId,
                                                              poId: order.id);
                                                }
                                                String message;
                                                if (response.statusCode ==
                                                    200) {
                                                  message = status ==
                                                          ApprovalStatus.approve
                                                      ? 'Approved'
                                                      : 'Denied';
                                                } else if (response
                                                        .statusCode ==
                                                    401) {
                                                  message =
                                                      'Session Expired. Please Login Again.';
                                                } else {
                                                  message =
                                                      'Error! Something Went Wrong!';
                                                }
                                                showToast(message);

                                                if (response.statusCode ==
                                                    401) {
                                                  if (mounted) {
                                                    clearData(context);
                                                  }
                                                }

                                                setState(() {
                                                  purchaseOrders.remove(order);
                                                  purchaseOrdersProvider
                                                      .updateItem(
                                                          purchOrder: order,
                                                          status: (status ==
                                                                  ApprovalStatus
                                                                      .approve
                                                              ? 'Approved'
                                                              : 'Denied'));

                                                  selectedItem = null;
                                                  status = null;
                                                  confCanc = false;
                                                });
                                              },
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
            }),
          ),
        ]));
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
                    Row(children: [
                      Expanded(
                          child: Column(
                        children: [
                          const Divider(),
                          const Text('Data Type',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                          const Divider(),
                          Row(children: [
                            Expanded(
                              child: Column(children: [
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
                                                fontSize: 12,
                                                color: Colors.grey)))
                                  ],
                                ),
                              ]),
                            ),
                            Expanded(
                              child: Column(children: [
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
                              ]),
                            ),
                          ]),
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
                    ]),
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
                                  labelStyle: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.close, size: 15),
                                    onPressed: () {
                                      if (_orderFromController
                                          .text.isNotEmpty) {
                                        setState(() {
                                          _orderFromController.clear();
                                          _orderStartDate = null;
                                        });
                                        this.setState(() {
                                          _orderFromController.clear();
                                          _orderStartDate = null;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                readOnly: true,
                                onTap: () =>
                                    _selectDate(context, _orderFromController),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: TextField(
                                controller: _orderToController,
                                decoration: InputDecoration(
                                  labelText: 'To: ',
                                  labelStyle: const TextStyle(
                                    fontSize: 12,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.close, size: 15),
                                    color: Colors.grey,
                                    onPressed: () {
                                      if (_orderToController.text.isNotEmpty) {
                                        setState(() {
                                          _orderToController.clear();
                                          _orderEndDate = null;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                readOnly: true,
                                onTap: () =>
                                    _selectDate(context, _orderToController),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
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
                              purchOrderFilterProvider.setFilter(
                                  dataType: _orderDataType,
                                  status: _orderStatus,
                                  sort: _orderSort,
                                  fromDate: _orderStartDate,
                                  toDate: _orderEndDate,
                                  otherDropdown: _orderDropdownValue,
                                  otherValue: _orderOtherController.text);
                            },
                            child: Container(
                              height: 40,
                              decoration: const BoxDecoration(
                                  color: Color(0xFF795FCD),
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
