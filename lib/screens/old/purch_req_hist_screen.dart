import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rnd_mobile/api/purchase_req_api.dart';
import 'package:rnd_mobile/models/purchase_req_model.dart';
import 'package:rnd_mobile/providers/purchase_request/purch_req_filter_provider.dart';
import 'package:rnd_mobile/providers/purchase_request/purchase_req_provider.dart';
import 'package:rnd_mobile/providers/user_provider.dart';
import 'package:rnd_mobile/screens/old/purch_req_screen.dart';
import 'package:rnd_mobile/utilities/session_handler.dart';
import 'package:rnd_mobile/widgets/mobile/mob_purch_req_dialog.dart';
import 'package:rnd_mobile/utilities/sliver_delegate.dart';

class PurchReqHistoryScreen extends StatefulWidget {
  const PurchReqHistoryScreen({super.key});

  @override
  State<PurchReqHistoryScreen> createState() => _PurchReqHistoryScreenState();
}

class _PurchReqHistoryScreenState extends State<PurchReqHistoryScreen> {
  late final UserProvider userProvider;
  bool confCanc = false;
  ApprovalStatus? status;
  int _loadedItemsCount = 15;
  bool isLoadingMore = false;
  bool hasMore = true;
  void _loadMore() async {
    late List<PurchaseRequest> newPurchaseRequests;
    if (Provider.of<PurchReqFilterProvider>(context, listen: false).status ==
        ReqStatus.pending) {
      final data = await PurchReqService.getPurchReqView(
        sessionId: userProvider.user!.sessionId,
        recordOffset: _loadedItemsCount,
        forPending: true,
      );
      if (mounted) {
        bool purchReqFlag = handleSessionExpiredException(data, context);

        if (!purchReqFlag) {
          newPurchaseRequests = data['purchaseRequests'];
          hasMore = data['hasMore'];
        }
      }
    } else {
      final data = await PurchReqService.getPurchReqView(
        sessionId: userProvider.user!.sessionId,
        recordOffset: _loadedItemsCount,
        forAll: true,
      );
      if (mounted) {
        bool purchReqFlag = handleSessionExpiredException(data, context);

        if (!purchReqFlag) {
          newPurchaseRequests = data['purchaseRequests'];
          hasMore = data['hasMore'];
        }
      }
    }
    setState(() {
      isLoadingMore = false;
      _loadedItemsCount += newPurchaseRequests.length;
      Provider.of<PurchReqProvider>(context, listen: false)
          .addItems(purchReqs: newPurchaseRequests);
    });
  }

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProvider>(context, listen: false);
  }

  void sortPurchaseRequests(List<PurchaseRequest> purchaseRequests,
      ReqDataType dataType, ReqSort sort,
      {DateTime? startDate,
      DateTime? endDate,
      String? otherDropdown,
      String? otherValue}) {
    if (dataType == ReqDataType.other) {
      if (otherValue != '' && otherValue != null) {
        switch (otherDropdown) {
          case 'Reference':
            purchaseRequests.retainWhere(
                (request) => request.reference.trim() == otherValue.trim());
            break;
          case 'Warehouse':
            purchaseRequests.retainWhere((request) =>
                request.warehouseDescription.trim() == otherValue.trim());
            break;
          case 'Cost Center':
            purchaseRequests.retainWhere((request) =>
                request.costCenterDescription.trim() == otherValue.trim());
            break;
          case 'Requested By':
            purchaseRequests.retainWhere(
                (request) => request.requestedBy.trim() == otherValue.trim());
            break;
          case 'Username':
            purchaseRequests.retainWhere(
                (request) => request.userName.trim() == otherValue.trim());
            break;
          default:
            break;
        }
      }
    } else {
      switch (dataType) {
        case ReqDataType.reqDate:
          if (startDate != null || endDate != null) {
            purchaseRequests.retainWhere((request) {
              if (startDate != null &&
                  request.requestDate.isBefore(startDate)) {
                return false;
              }
              if (endDate != null && request.requestDate.isAfter(endDate)) {
                return false;
              }
              return true;
            });
          }
          purchaseRequests.sort((a, b) => sort == ReqSort.asc
              ? a.requestDate.compareTo(b.requestDate)
              : b.requestDate.compareTo(a.requestDate));
          break;
        case ReqDataType.purchReqNum:
          purchaseRequests.sort((a, b) => sort == ReqSort.asc
              ? a.preqNum.compareTo(b.preqNum)
              : b.preqNum.compareTo(a.preqNum));
          break;
        case ReqDataType.neededDate:
          if (startDate != null || endDate != null) {
            purchaseRequests.retainWhere((request) {
              if (startDate != null && request.neededDate.isBefore(startDate)) {
                return false;
              }
              if (endDate != null && request.neededDate.isAfter(endDate)) {
                return false;
              }
              return true;
            });
          }
          purchaseRequests.sort((a, b) => sort == ReqSort.asc
              ? a.neededDate.compareTo(b.neededDate)
              : b.neededDate.compareTo(a.neededDate));
          break;
        default:
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PurchReqProvider>(
        builder: (context, purchaseRequestsProvider, _) {
      final purchaseListPending = purchaseRequestsProvider.purchaseRequestList;

      return Consumer<PurchReqFilterProvider>(
          builder: (context, filterProvider, _) {
        List<PurchaseRequest> purchaseRequests = [];
        if (purchaseListPending.isNotEmpty) {
          if (filterProvider.status == ReqStatus.approved) {
            purchaseRequests = purchaseListPending.where((item) {
              return item.isFinal == true;
            }).toList();
          } else if (filterProvider.status == ReqStatus.denied) {
            purchaseRequests = purchaseListPending.where((item) {
              return item.isCancelled == true;
            }).toList();
          } else if (filterProvider.status == ReqStatus.pending) {
            purchaseRequests = purchaseListPending.where((item) {
              return item.isCancelled == false && item.isFinal == false;
            }).toList();
          } else {
            purchaseRequests = purchaseListPending;
          }
          sortPurchaseRequests(
              purchaseRequests, filterProvider.dataType!, filterProvider.sort!,
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
              desiredItemHeight: 320,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                var request = purchaseRequests[index];
                var requestDate =
                    DateFormat.yMMMd().format(request.requestDate);
                var neededDate = DateFormat.yMMMd().format(request.neededDate);

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
                                  purchReqShowDialog(
                                      context: context, request: request);
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
                                                      'Request Number: ',
                                                      textAlign: TextAlign.left,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      request.preqNum
                                                          .toString(),
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
                                                      'Request Date: ',
                                                      textAlign: TextAlign.left,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      requestDate,
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
                                                      request.reference.trim(),
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
                                                      request
                                                          .warehouseDescription
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
                                                      'Requested By: ',
                                                      textAlign: TextAlign.left,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      request.requestedBy
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
                                                      'Reason: ',
                                                      textAlign: TextAlign.left,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      request.reason.trim(),
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
                                                  request.isFinal
                                                      ? 'Approved'
                                                      : request.isCancelled
                                                          ? 'Denied'
                                                          : 'Pending',
                                                  style: TextStyle(
                                                    color: request.isFinal
                                                        ? Colors.green
                                                        : request.isCancelled
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
              childCount: purchaseRequests.length,
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
