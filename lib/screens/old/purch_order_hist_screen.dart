import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rnd_mobile/api/purchase_order_api.dart';
import 'package:rnd_mobile/models/purchase_order_model.dart';
import 'package:rnd_mobile/providers/purchase_order/purch_order_filter_provider.dart';
import 'package:rnd_mobile/providers/purchase_order/purchase_order_provider.dart';
import 'package:rnd_mobile/providers/user_provider.dart';
import 'package:rnd_mobile/screens/old/purch_req_screen.dart';
import 'package:rnd_mobile/utilities/session_handler.dart';
import 'package:rnd_mobile/widgets/mobile/mob_purch_order_dialog.dart';
import 'package:rnd_mobile/utilities/sliver_delegate.dart';

class PurchOrderHistoryScreen extends StatefulWidget {
  const PurchOrderHistoryScreen({super.key});

  @override
  State<PurchOrderHistoryScreen> createState() =>
      _PurchOrderHistoryScreenState();
}

class _PurchOrderHistoryScreenState extends State<PurchOrderHistoryScreen> {
  late final UserProvider userProvider;
  bool confCanc = false;
  ApprovalStatus? status;
  int _loadedItemsCount = 15;
  bool isLoadingMore = false;
  bool hasMore = true;
  void _loadMore() async {
    late List<PurchaseOrder> newPurchaseOrders;
    if (Provider.of<PurchOrderFilterProvider>(context, listen: false).status ==
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

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProvider>(context, listen: false);
  }

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
                (request) => request.reference.trim() == otherValue.trim());
            break;
          case 'Warehouse':
            purchaseOrders.retainWhere((request) =>
                request.warehouseDescription.trim() == otherValue.trim());
            break;
          case 'Supplier':
            purchaseOrders.retainWhere(
                (request) => request.supplierName.trim() == otherValue.trim());
            break;
          case 'Address':
            purchaseOrders.retainWhere(
                (request) => request.address.trim() == otherValue.trim());
            break;
          case 'Remarks':
            purchaseOrders.retainWhere(
                (request) => request.remarks.trim() == otherValue.trim());
            break;
          case 'Purpose':
            purchaseOrders.retainWhere(
                (request) => request.purpose.trim() == otherValue.trim());
            break;
          case 'Terms of Payment':
            purchaseOrders.retainWhere((request) =>
                request.topDescription.trim() == otherValue.trim());
            break;
          default:
            break;
        }
      }
    } else {
      switch (dataType) {
        case OrderDataType.poDate:
          if (startDate != null || endDate != null) {
            purchaseOrders.retainWhere((request) {
              if (startDate != null && request.poDate.isBefore(startDate)) {
                return false;
              }
              if (endDate != null && request.poDate.isAfter(endDate)) {
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
            purchaseOrders.retainWhere((request) {
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
          purchaseOrders.sort((a, b) => sort == OrderSort.asc
              ? a.deliveryDate.compareTo(b.deliveryDate)
              : b.deliveryDate.compareTo(a.deliveryDate));
          break;
        default:
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PurchOrderProvider>(
        builder: (context, purchaseOrdersProvider, _) {
      final purchaseListPending = purchaseOrdersProvider.purchaseOrderList;

      return Consumer<PurchOrderFilterProvider>(
          builder: (context, filterProvider, _) {
        List<PurchaseOrder> purchaseOrders = [];
        if (purchaseListPending.isNotEmpty) {
          if (filterProvider.status == OrderStatus.approved) {
            purchaseOrders = purchaseListPending.where((item) {
              return item.isFinal == true;
            }).toList();
          } else if (filterProvider.status == OrderStatus.denied) {
            purchaseOrders = purchaseListPending.where((item) {
              return item.isCancelled == true;
            }).toList();
          } else if (filterProvider.status == OrderStatus.pending) {
            purchaseOrders = purchaseListPending.where((item) {
              return item.isCancelled == false && item.isFinal == false;
            }).toList();
          } else {
            purchaseOrders = purchaseListPending;
          }
          sortPurchaseOrders(
              purchaseOrders, filterProvider.dataType!, filterProvider.sort!,
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
        return CustomScrollView(slivers: [
          SliverGrid(
            gridDelegate: MySliverGridDelegate(
              crossAxisCount: value,
              desiredItemWidth: 300,
              desiredItemHeight: 470,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                var order = purchaseOrders[index];
                var poDate = DateFormat.yMMMd().format(order.poDate);
                var deliveryDate =
                    DateFormat.yMMMd().format(order.deliveryDate);

                return AnimationConfiguration.staggeredGrid(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  columnCount: value,
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 3, 10, 3),
                        child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 0.5,
                                  blurRadius: 1,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: InkWell(
                                onTap: () {
                                  purchOrderShowDialog(
                                      context: context, order: order);
                                },
                                child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        15, 10, 15, 10),
                                    child: StatefulBuilder(builder:
                                        (BuildContext context,
                                            StateSetter setState) {
                                      return Column(children: [
                                        Expanded(
                                          flex: 3,
                                          child: Column(
                                            children: [
                                              Row(
                                                children: [
                                                  const Expanded(
                                                    child: Text(
                                                      'Order Number: ',
                                                      textAlign: TextAlign.left,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      order.poNumber.toString(),
                                                      textAlign:
                                                          TextAlign.right,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const Divider(),
                                              Row(
                                                children: [
                                                  const Expanded(
                                                    flex: 1,
                                                    child: Text(
                                                      'Reference: ',
                                                      textAlign: TextAlign.left,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      order.reference.trim(),
                                                      textAlign:
                                                          TextAlign.right,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const Divider(),
                                              Row(
                                                children: [
                                                  const Expanded(
                                                    flex: 1,
                                                    child: Text(
                                                      'Supplier: ',
                                                      textAlign: TextAlign.left,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      order.supplierName.trim(),
                                                      textAlign:
                                                          TextAlign.right,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const Divider(),
                                              Row(
                                                children: [
                                                  const Expanded(
                                                    flex: 1,
                                                    child: Text(
                                                      'Address: ',
                                                      textAlign: TextAlign.left,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      order.address.trim(),
                                                      textAlign:
                                                          TextAlign.right,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const Divider(),
                                              Row(
                                                children: [
                                                  const Expanded(
                                                    flex: 1,
                                                    child: Text(
                                                      'Warehouse: ',
                                                      textAlign: TextAlign.left,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      order.warehouseDescription
                                                          .trim(),
                                                      textAlign:
                                                          TextAlign.right,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const Divider(),
                                              Row(
                                                children: [
                                                  const Expanded(
                                                    flex: 1,
                                                    child: Text(
                                                      'Purpose: ',
                                                      textAlign: TextAlign.left,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      order.purpose.trim(),
                                                      textAlign:
                                                          TextAlign.right,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const Divider(),
                                              Row(
                                                children: [
                                                  const Expanded(
                                                    flex: 1,
                                                    child: Text(
                                                      'Remarks: ',
                                                      textAlign: TextAlign.left,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      order.remarks.trim(),
                                                      textAlign:
                                                          TextAlign.right,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const Divider(),
                                              Row(
                                                children: [
                                                  const Expanded(
                                                    flex: 1,
                                                    child: Text(
                                                      'Order Date: ',
                                                      textAlign: TextAlign.left,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      poDate,
                                                      textAlign:
                                                          TextAlign.right,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const Divider(),
                                              Row(
                                                children: [
                                                  const Expanded(
                                                    flex: 1,
                                                    child: Text(
                                                      'Delivery Date: ',
                                                      textAlign: TextAlign.left,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      deliveryDate,
                                                      textAlign:
                                                          TextAlign.right,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const Divider(),
                                              Row(
                                                children: [
                                                  const Expanded(
                                                    flex: 1,
                                                    child: Text(
                                                      'Terms of Payment: ',
                                                      textAlign: TextAlign.left,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      order.topDescription
                                                          .trim(),
                                                      textAlign:
                                                          TextAlign.right,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const Divider(),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          color: Colors.grey[200],
                                          child: const Padding(
                                            padding: EdgeInsets.only(
                                                top: 10, bottom: 10),
                                            child: IntrinsicHeight(
                                              child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    SizedBox(width: 10),
                                                    Expanded(
                                                        child: Center(
                                                      child: Text('Status',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                    )),
                                                    SizedBox(width: 10),
                                                  ]),
                                            ),
                                          ),
                                        ),
                                        const Divider(),
                                        Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              const SizedBox(width: 10),
                                              Expanded(
                                                  child: Center(
                                                child: Text(
                                                  order.isFinal
                                                      ? 'Approved'
                                                      : order.isCancelled
                                                          ? 'Denied'
                                                          : 'Pending',
                                                  style: TextStyle(
                                                    color: order.isFinal
                                                        ? Colors.green
                                                        : order.isCancelled
                                                            ? Colors.red
                                                            : Colors.black,
                                                  ),
                                                ),
                                              )),
                                              const SizedBox(width: 10),
                                            ]),
                                        const Divider(),
                                      ]);
                                    })))),
                      ),
                    ),
                  ),
                );
              },
              childCount: purchaseOrders.length,
            ),
          ),
          SliverToBoxAdapter(
              child: Column(
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
                              backgroundColor: Colors.transparent,
                              elevation: 0),
                          child: isLoadingMore
                              ? const CircularProgressIndicator()
                              : const Text('Load More',
                                  style: TextStyle(color: Colors.black))),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Visibility(
                        visible: !hasMore, child: const Text('End of Results')),
                  ),
                ],
              ),
            ],
          )),
        ]);
      });
    });
  }
}
