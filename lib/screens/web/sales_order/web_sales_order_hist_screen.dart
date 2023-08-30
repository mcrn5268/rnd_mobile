import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rnd_mobile/api/sales_order_api.dart';
import 'package:rnd_mobile/models/sales_order_model.dart';
import 'package:rnd_mobile/providers/sales_order/sales_order_hist_filter.provider.dart';
import 'package:rnd_mobile/providers/sales_order/sales_order_provider.dart';
import 'package:rnd_mobile/providers/user_provider.dart';
import 'package:rnd_mobile/screens/web/sales_order/line/web_sales_order_line_screen.dart';
import 'package:rnd_mobile/utilities/session_handler.dart';
import 'package:rnd_mobile/widgets/web/web_reusable_row.dart';

class WebSalesOrderHistScreen extends StatefulWidget {
  const WebSalesOrderHistScreen({super.key});

  @override
  State<WebSalesOrderHistScreen> createState() =>
      _WebSalesOrderHistScreenState();
}

class _WebSalesOrderHistScreenState extends State<WebSalesOrderHistScreen> {
  late final UserProvider userProvider;
  late final SalesOrderHistFilterProvider orderFilterProvider;
  bool confCanc = false;
  int? selectedItem;
  int _loadedItemsCount = 15;
  bool isLoadingMore = false;
  bool hasMore = true;
  bool _showFilter = false;
  OrderDataType _orderDataType = OrderDataType.soDate;
  OrderStatus _orderStatus = OrderStatus.all;
  OrderSort _orderSort = OrderSort.dsc;

  final TextEditingController _orderFromController = TextEditingController();
  final TextEditingController _orderToController = TextEditingController();
  final TextEditingController _orderOtherController = TextEditingController();

  DateTime? _orderStartDate;
  DateTime? _orderEndDate;
  String? _orderDropdownValue;
  void sortSalesOrders(
      List<SalesOrder> salesOrders, OrderDataType dataType, OrderSort sort,
      {DateTime? startDate,
      DateTime? endDate,
      String? otherDropdown,
      String? otherValue}) {
    if (dataType == OrderDataType.other) {
      if (otherValue != '' && otherValue != null) {
        switch (otherDropdown) {
          case 'Reference':
            salesOrders.retainWhere(
                (order) => order.reference.trim() == otherValue.trim());
            break;
          case 'Warehouse':
            salesOrders.retainWhere((order) =>
                order.warehouseDescription.trim() == otherValue.trim());
            break;
          case 'Debtor':
            salesOrders.retainWhere(
                (order) => order.debtorName.trim() == otherValue.trim());
            break;
          case 'Address':
            salesOrders.retainWhere(
                (order) => order.address.trim() == otherValue.trim());
            break;
          case 'Particulars':
            salesOrders.retainWhere(
                (order) => order.particulars.trim() == otherValue.trim());
            break;
          case 'Terms of Payment':
            salesOrders.retainWhere(
                (order) => order.topDescription.trim() == otherValue.trim());
            break;
          case 'Username':
            salesOrders.retainWhere(
                (order) => order.userName.trim() == otherValue.trim());
            break;
          default:
            break;
        }
      }
    } else {
      switch (dataType) {
        case OrderDataType.soDate:
          if (startDate != null || endDate != null) {
            salesOrders.retainWhere((request) {
              if (startDate != null && request.soDate.isBefore(startDate)) {
                return false;
              }
              if (endDate != null && request.soDate.isAfter(endDate)) {
                return false;
              }
              return true;
            });
          }
          salesOrders.sort((a, b) => sort == OrderSort.asc
              ? a.soDate.compareTo(b.soDate)
              : b.soDate.compareTo(a.soDate));
          break;
        case OrderDataType.soNum:
          salesOrders.sort((a, b) => sort == OrderSort.asc
              ? a.soNumber.compareTo(b.soNumber)
              : b.soNumber.compareTo(a.soNumber));
          break;
        case OrderDataType.delvDate:
          if (startDate != null || endDate != null) {
            salesOrders.retainWhere((request) {
              if (startDate != null &&
                  request.deliveryDate.isBefore(startDate)) {
                return false;
              }
              if (endDate != null && request.deliveryDate.isAfter(endDate)) {
                return false;
              }
              return true;
            });
          }
          salesOrders.sort((a, b) => sort == OrderSort.asc
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
    );
    if (picked != null) {
      if (controller == _orderFromController) {
        _orderStartDate = picked;
      } else if (controller == _orderToController) {
        _orderEndDate = picked;
      }
      final formattedDate = DateFormat('MM/dd/yyyy').format(picked);
      controller.text = formattedDate;
    }
  }

  void _loadMore() async {
    late List<SalesOrder> newSalesOrders;
    final data = await SalesOrderService.getSalesOrderView(
      sessionId: userProvider.user!.sessionId,
      recordOffset: _loadedItemsCount,
      forPending: true,
      forAll: true,
    );
    if (mounted) {
      bool salesOrderFlag = handleSessionExpiredException(data, context);

      if (!salesOrderFlag) {
        newSalesOrders = data['salesOrders'];
        hasMore = data['hasMore'];
      }
    }
    setState(() {
      isLoadingMore = false;
      _loadedItemsCount += newSalesOrders.length;
      Provider.of<SalesOrderProvider>(context, listen: false)
          .addItems(salesOrders: newSalesOrders);
    });
  }

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProvider>(context, listen: false);
    orderFilterProvider =
        Provider.of<SalesOrderHistFilterProvider>(context, listen: false);

    if (orderFilterProvider.dataType == null ||
        orderFilterProvider.status == null ||
        orderFilterProvider.sort == null) {
      orderFilterProvider.setFilter(
          dataType: _orderDataType,
          status: _orderStatus,
          sort: _orderSort,
          notify: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SalesOrderProvider>(
        builder: (context, salesOrdersProvider, _) {
      List<SalesOrder> purchaseListPending = salesOrdersProvider.salesOrderList;

      String? searchValue = salesOrdersProvider.search;
      if (searchValue != null && searchValue != '') {
        purchaseListPending = purchaseListPending.where((purchaseRequest) {
          return purchaseRequest.containsQuery(searchValue);
        }).toList();
      }
      if (purchaseListPending.isNotEmpty) {
        return Consumer<SalesOrderHistFilterProvider>(
            builder: (context, filterProvider, _) {
          List<SalesOrder> salesOrders = [];
          if (purchaseListPending.isNotEmpty) {
            if (filterProvider.status == OrderStatus.approved) {
              salesOrders = purchaseListPending.where((item) {
                return item.isFinal == true;
              }).toList();
            } else if (filterProvider.status == OrderStatus.denied) {
              salesOrders = purchaseListPending.where((item) {
                return item.isCancelled == true;
              }).toList();
            } else if (filterProvider.status == OrderStatus.pending) {
              salesOrders = purchaseListPending.where((item) {
                return item.isCancelled == false && item.isFinal == false;
              }).toList();
            } else {
              salesOrders = purchaseListPending;
            }
            sortSalesOrders(
                salesOrders, filterProvider.dataType!, filterProvider.sort!,
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
          return Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 100, vertical: 15),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: MediaQuery.of(context).platformBrightness ==
                                Brightness.dark
                            ? Colors.grey[900]
                            : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 0.5,
                            blurRadius: 1,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 3),
                        child: Row(
                          children: [
                            const WebReusableRow(
                              flex: 1,
                              text: 'Order #',
                            ),
                            const WebReusableRow(
                              flex: 2,
                              text: 'Order Date',
                            ),
                            const WebReusableRow(
                              flex: 2,
                              text: 'Delivery Date',
                            ),
                            const WebReusableRow(
                              flex: 2,
                              text: 'Reference',
                            ),
                            const WebReusableRow(
                              flex: 3,
                              text: 'Warehouse',
                            ),
                            const WebReusableRow(
                              flex: 3,
                              text: 'Debtor',
                            ),
                            Expanded(
                                flex: 4,
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      const Expanded(
                                        flex: 7,
                                        child: Center(
                                          child: Padding(
                                            padding: EdgeInsets.only(left: 40),
                                            child: Text('Status',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey)),
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            _showFilter = !_showFilter;
                                          });
                                        },
                                        child: const Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.filter_list_outlined,
                                                  color: Colors.grey),
                                              Text('Filter',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey)),
                                            ]),
                                      )
                                    ])),
                            const SizedBox(
                              width: 15,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: CustomScrollView(
                      slivers: <Widget>[
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (BuildContext context, int index) {
                              if (index == salesOrders.length) {
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
                                                            color:
                                                                Colors.grey))),
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
                                final order = salesOrders[index];
                                final soDate =
                                    DateFormat.yMMMd().format(order.soDate);
                                final deliveryDate = DateFormat.yMMMd()
                                    .format(order.deliveryDate);
                                late final BorderRadius borderRadius;
                                if (index == 0) {
                                  borderRadius = const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  );
                                } else if (index == salesOrders.length - 1) {
                                  borderRadius = const BorderRadius.only(
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  );
                                } else {
                                  borderRadius = BorderRadius.zero;
                                }
                                late final Color backgroundColor;
                                if (MediaQuery.of(context).platformBrightness ==
                                    Brightness.dark) {
                                  backgroundColor = index.isEven
                                      ? Colors.grey[900]!
                                      : Colors.grey[850]!;
                                } else {
                                  backgroundColor = index.isEven
                                      ? Colors.white
                                      : Colors.grey[50]!;
                                }
                                late final Color lineColor;
                                if (order.isCancelled) {
                                  lineColor = Colors.red;
                                } else if (order.isFinal) {
                                  lineColor = Colors.green;
                                } else {
                                  lineColor = Colors.grey;
                                }
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 100),
                                  child: Container(
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: lineColor,
                                      borderRadius: borderRadius,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 3),
                                      child: Container(
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: backgroundColor,
                                          borderRadius: borderRadius,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.5),
                                              spreadRadius: 0.5,
                                              blurRadius: 1,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: InkWell(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                PageRouteBuilder(
                                                  pageBuilder: (_, __, ___) =>
                                                      WebSalesOrderLineScreen(
                                                          order: order),
                                                  transitionsBuilder:
                                                      (_, a, __, c) =>
                                                          FadeTransition(
                                                              opacity: a,
                                                              child: c),
                                                ),
                                              );
                                            },
                                            child: Row(
                                              children: [
                                                WebReusableRow(
                                                  flex: 1,
                                                  text:
                                                      order.soNumber.toString(),
                                                ),
                                                WebReusableRow(
                                                  flex: 2,
                                                  text: soDate,
                                                ),
                                                WebReusableRow(
                                                  flex: 2,
                                                  text: deliveryDate,
                                                ),
                                                WebReusableRow(
                                                  flex: 2,
                                                  text: order.reference.trim(),
                                                ),
                                                WebReusableRow(
                                                  flex: 3,
                                                  text: order
                                                      .warehouseDescription
                                                      .trim(),
                                                ),
                                                WebReusableRow(
                                                  flex: 3,
                                                  text: order.debtorName.trim(),
                                                ),
                                                WebReusableRow(
                                                  flex: 4,
                                                  text: order.isFinal
                                                      ? 'Approved'
                                                      : order.isCancelled
                                                          ? 'Denied'
                                                          : 'Pending',
                                                  color: order.isFinal
                                                      ? Colors.green
                                                      : order.isCancelled
                                                          ? Colors.red
                                                          : Colors.grey,
                                                ),
                                                const SizedBox(
                                                    width: 10,
                                                    child: Icon(Icons
                                                        .arrow_right_outlined)),
                                                const SizedBox(width: 5)
                                              ],
                                            )),
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                            childCount: salesOrders.length + 1,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              Positioned(
                top: 80,
                right: 75,
                child: Visibility(
                  visible: _showFilter,
                  child: Container(
                      width: 300,
                      height: 400,
                      decoration: BoxDecoration(
                        color: MediaQuery.of(context).platformBrightness ==
                                Brightness.dark
                            ? Colors.grey[850]
                            : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: StatefulBuilder(builder:
                          (BuildContext context, StateSetter setState) {
                        return Column(children: [
                          const SizedBox(height: 10),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                InkWell(
                                  onTap: () {
                                    this.setState(() {
                                      _showFilter = false;
                                    });
                                  },
                                  child: const Center(
                                    child: Text('Close',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey)),
                                  ),
                                ),
                                const SizedBox(width: 10)
                              ]),
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
                                        value: OrderDataType.soDate,
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
                                        value: OrderDataType.soNum,
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
                                        'Cost Center',
                                        'Requested By',
                                        'Username'
                                      ].map<DropdownMenuItem<String>>(
                                          (String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey)),
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
                                                fontSize: 12,
                                                color: Colors.grey))
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
                                                fontSize: 12,
                                                color: Colors.grey))
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
                                                fontSize: 12,
                                                color: Colors.grey))
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
                                                fontSize: 12,
                                                color: Colors.grey))
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ]),
                          ),
                          const Divider(),
                          Visibility(
                            visible: _orderDataType == OrderDataType.soDate ||
                                _orderDataType == OrderDataType.delvDate,
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(left: 10, right: 10),
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
                                          icon:
                                              const Icon(Icons.close, size: 15),
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
                                      onTap: () => _selectDate(
                                          context, _orderFromController),
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
                                          icon:
                                              const Icon(Icons.close, size: 15),
                                          color: Colors.grey,
                                          onPressed: () {
                                            if (_orderToController
                                                .text.isNotEmpty) {
                                              setState(() {
                                                _orderToController.clear();
                                                _orderEndDate = null;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                      readOnly: true,
                                      onTap: () => _selectDate(
                                          context, _orderToController),
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
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey)),
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
                                                fontSize: 12,
                                                color: Colors.grey))
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
                                                fontSize: 12,
                                                color: Colors.grey))
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
                                padding:
                                    const EdgeInsets.only(left: 10, right: 10),
                                child: TextField(
                                  controller: _orderOtherController,
                                  style: const TextStyle(fontSize: 12),
                                  decoration: const InputDecoration(
                                    // contentPadding: EdgeInsets.zero,
                                    hintText: 'Enter text here',
                                    hintStyle: TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                )),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _showFilter = false;
                                    });
                                    orderFilterProvider.setFilter(
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
                                        // color: Color(0xFF795FCD),
                                        color: Colors.blueGrey,
                                        border: Border.symmetric(
                                            horizontal: BorderSide(
                                                color: Colors.white))),
                                    child: const Center(
                                        child: Text('Apply Filters',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white))),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ]);
                      })),
                ),
              )
            ],
          );
        });
      } else {
        String? searchValue =
            Provider.of<SalesOrderProvider>(context, listen: false).search;
        return Center(
            child: Text(
                searchValue != null && searchValue != ''
                    ? 'No Matching sales Order Found'
                    : '0 Purchase Orders',
                style: const TextStyle(fontSize: 30)));
      }
    });
  }
}
