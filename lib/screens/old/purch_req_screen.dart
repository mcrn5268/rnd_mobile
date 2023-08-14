import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rnd_mobile/api/purchase_req_api.dart';
import 'package:rnd_mobile/models/purchase_req_model.dart';
import 'package:rnd_mobile/providers/purchase_request/purchase_req_provider.dart';
import 'package:rnd_mobile/providers/user_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:rnd_mobile/utilities/clear_data.dart';
import 'package:rnd_mobile/widgets/mobile/mob_purch_req_dialog.dart';
import 'package:rnd_mobile/utilities/sliver_delegate.dart';
import 'package:rnd_mobile/widgets/toast.dart';

enum ApprovalStatus {
  approve,
  deny,
}

class PurchReqScreen extends StatefulWidget {
  const PurchReqScreen({super.key});

  @override
  State<PurchReqScreen> createState() => _PurchReqScreenState();
}

class _PurchReqScreenState extends State<PurchReqScreen> {
  late final UserProvider userProvider;
  bool confCanc = false;
  ApprovalStatus? status;
  int _loadedItemsCount = 15;
  bool isLoadingMore = false;
  bool hasMore = true;
  void _loadMore() async {
    final data = await PurchReqService.getPurchReqView(
      sessionId: userProvider.user!.sessionId,
      recordOffset: _loadedItemsCount,
      forPending: true,
    );
    final List<PurchaseRequest> newPurchaseRequests = data['purchaseRequests'];
    setState(() {
      hasMore = data['hasMore'];
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

  @override
  Widget build(BuildContext context) {
    return Consumer<PurchReqProvider>(
        builder: (context, purchaseRequestsProvider, _) {
      final purchaseListPending = purchaseRequestsProvider.purchaseRequestList
          .where((purchReq) => !purchReq.isFinal && !purchReq.isCancelled)
          .toList();
      double width = MediaQuery.of(context).size.width;
      int value = (width / 300).floor();
      if (value == 0) {
        value = 1;
      }
      if (purchaseListPending.isNotEmpty) {
        return CustomScrollView(
          slivers: [
            SliverGrid(
              gridDelegate: MySliverGridDelegate(
                crossAxisCount: value,
                desiredItemWidth: 300,
                desiredItemHeight: 280,
              ),
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  var request = purchaseListPending[index];
                  var requestDate =
                      DateFormat.yMMMd().format(request.requestDate);
                  var neededDate =
                      DateFormat.yMMMd().format(request.neededDate);

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
                                  padding:
                                      const EdgeInsets.fromLTRB(15, 10, 15, 10),
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
                                                    request.preqNum.toString(),
                                                    textAlign: TextAlign.right,
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
                                                    textAlign: TextAlign.right,
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
                                                    textAlign: TextAlign.right,
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
                                                    request.warehouseDescription
                                                        .trim(),
                                                    textAlign: TextAlign.right,
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
                                                    request.requestedBy.trim(),
                                                    textAlign: TextAlign.right,
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
                                                    textAlign: TextAlign.right,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Divider(),
                                          ],
                                        ),
                                      ),

                                      //Buttons
                                      Stack(
                                        children: [
                                          Row(children: [
                                            Expanded(
                                              child: Visibility(
                                                  visible: !confCanc,
                                                  child: ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                    child: const Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(Icons.close),
                                                          Text('Deny')
                                                        ]),
                                                    onPressed: () {
                                                      setState(() {
                                                        confCanc = true;
                                                        status =
                                                            ApprovalStatus.deny;
                                                      });
                                                    },
                                                  )),
                                            ),
                                            const SizedBox(width: 15),
                                            Expanded(
                                              child: Visibility(
                                                  visible: !confCanc,
                                                  child: ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.green,
                                                    ),
                                                    child: const Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(Icons.check),
                                                          Text('Approve')
                                                        ]),
                                                    onPressed: () {
                                                      setState(() {
                                                        confCanc = true;
                                                        status = ApprovalStatus
                                                            .approve;
                                                      });
                                                    },
                                                  )),
                                            ),
                                          ]),
                                          Row(children: [
                                            Expanded(
                                              child: Visibility(
                                                  visible: confCanc,
                                                  child: ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                    child: const Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(Icons.close),
                                                          Text('Cancel')
                                                        ]),
                                                    onPressed: () {
                                                      setState(() {
                                                        confCanc = false;
                                                        status = null;
                                                      });
                                                    },
                                                  )),
                                            ),
                                            const SizedBox(width: 15),
                                            Expanded(
                                              child: Visibility(
                                                  visible: confCanc,
                                                  child: ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.green,
                                                    ),
                                                    child: const Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(Icons.check),
                                                          Text('Confirm')
                                                        ]),
                                                    onPressed: () async {
                                                      dynamic response;
                                                      if (status ==
                                                          ApprovalStatus
                                                              .approve) {
                                                        response = await PurchReqService
                                                            .aprvPurchReq(
                                                                sessionId:
                                                                    userProvider
                                                                        .user!
                                                                        .sessionId,
                                                                hdrId:
                                                                    request.id);
                                                      } else {
                                                        response = await PurchReqService
                                                            .dnyPurchReq(
                                                                sessionId:
                                                                    userProvider
                                                                        .user!
                                                                        .sessionId,
                                                                hdrId:
                                                                    request.id);
                                                      }
                                                      String message;
                                                      if (response.statusCode ==
                                                          200) {
                                                        message = status ==
                                                                ApprovalStatus
                                                                    .approve
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
                                                        if (!mounted) return;
                                                        clearData(context);
                                                      }

                                                      setState(() {
                                                        purchaseListPending
                                                            .remove(request);
                                                        purchaseRequestsProvider
                                                            .updateItem(
                                                                purchReq:
                                                                    request,
                                                                status: (status ==
                                                                        ApprovalStatus
                                                                            .approve
                                                                    ? 'Approved'
                                                                    : 'Denied'));
                                                        status = null;
                                                        confCanc = false;
                                                      });
                                                    },
                                                  )),
                                            ),
                                          ]),
                                        ],
                                      ),
                                    ]);
                                  }),
                                )),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: purchaseListPending.length,
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
                          visible: !hasMore,
                          child: const Text('End of Results')),
                    ),
                  ],
                ),
              ],
            )),
          ],
        );
      } else {
        return const Center(
            child: Text('0 Purchase Orders', style: TextStyle(fontSize: 30)));
      }
    });
  }
}
