import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rnd_mobile/api/purchase_req_api.dart';
import 'package:rnd_mobile/models/purchase_req_model.dart';
import 'package:rnd_mobile/providers/purchase_request/purch_req_hist_filter_provider.dart';
import 'package:rnd_mobile/providers/purchase_request/purchase_req_provider.dart';
import 'package:rnd_mobile/providers/user_provider.dart';
import 'package:rnd_mobile/screens/web/purchase_request/line/web_purch_req_line_screen.dart';
import 'package:rnd_mobile/utilities/session_handler.dart';
import 'package:rnd_mobile/widgets/web/web_reusable_row.dart';

class WebPurchReqHistScreen extends StatefulWidget {
  const WebPurchReqHistScreen({super.key});

  @override
  State<WebPurchReqHistScreen> createState() => _WebPurchReqHistScreenState();
}

class _WebPurchReqHistScreenState extends State<WebPurchReqHistScreen> {
  late final UserProvider userProvider;
  late final PurchReqHistFilterProvider reqHistFilterProvider;
  bool confCanc = false;
  int _loadedItemsCount = 15;
  bool isLoadingMore = false;
  bool hasMore = true;
  bool _showFilter = false;
  ReqDataType _reqDataType = ReqDataType.reqDate;
  ReqStatus _reqStatus = ReqStatus.all;
  ReqSort _reqSort = ReqSort.asc;

  final TextEditingController _reqFromController = TextEditingController();
  final TextEditingController _reqToController = TextEditingController();
  final TextEditingController _reqOtherController = TextEditingController();

  DateTime? _reqStartDate;
  DateTime? _reqEndDate;
  String? _reqDropdownValue;
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
      if (controller == _reqFromController) {
        _reqStartDate = picked;
      } else if (controller == _reqToController) {
        _reqEndDate = picked;
      }
      final formattedDate = DateFormat('yyyy/MM/dd').format(picked);
      controller.text = formattedDate;
    }
  }

  void _loadMore() async {
    late List<PurchaseRequest> newPurchaseRequests;
    if (Provider.of<PurchReqHistFilterProvider>(context, listen: false)
            .status ==
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
    reqHistFilterProvider =
        Provider.of<PurchReqHistFilterProvider>(context, listen: false);
    if (reqHistFilterProvider.dataType == null ||
        reqHistFilterProvider.status == null ||
        reqHistFilterProvider.sort == null) {
      reqHistFilterProvider.setFilter(
          dataType: _reqDataType,
          status: _reqStatus,
          sort: _reqSort,
          notify: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PurchReqProvider>(
        builder: (context, purchaseRequestsProvider, _) {
      List<PurchaseRequest> purchaseListPending =
          purchaseRequestsProvider.purchaseRequestList;
      String? searchValue = purchaseRequestsProvider.search;
      if (searchValue != null && searchValue != '') {
        purchaseListPending = purchaseListPending.where((purchaseRequest) {
          return purchaseRequest.containsQuery(searchValue);
        }).toList();
      }
      if (purchaseListPending.isNotEmpty) {
        return Consumer<PurchReqHistFilterProvider>(
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
            sortPurchaseRequests(purchaseRequests, filterProvider.dataType!,
                filterProvider.sort!,
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
                              text: 'Request #',
                            ),
                            const WebReusableRow(
                              flex: 2,
                              text: 'Request Date',
                            ),
                            const WebReusableRow(
                              flex: 1,
                              text: 'Reference',
                            ),
                            const WebReusableRow(
                              flex: 2,
                              text: 'Warehouse',
                            ),
                            const WebReusableRow(
                              flex: 2,
                              text: 'Requested By',
                            ),
                            const WebReusableRow(
                              flex: 2,
                              text: 'Reason',
                            ),
                            Expanded(
                                flex: 3,
                                child: Row(
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
                                  ],
                                )),
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
                              if (index == purchaseRequests.length) {
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
                                final request = purchaseRequests[index];
                                final requestDate = DateFormat.yMMMd()
                                    .format(request.requestDate);
                                // final neededDate = DateFormat.yMMMd()
                                //     .format(request.neededDate);
                                late final BorderRadius borderRadius;
                                if (index == 0) {
                                  borderRadius = const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  );
                                } else if (index ==
                                    purchaseRequests.length - 1) {
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
                                if (request.isCancelled) {
                                  lineColor = Colors.red;
                                } else if (request.isFinal) {
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
                                                      WebPurchReqLineScreen(
                                                          request: request),
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
                                                  text: request.preqNum
                                                      .toString(),
                                                ),
                                                WebReusableRow(
                                                  flex: 2,
                                                  text: requestDate,
                                                ),
                                                WebReusableRow(
                                                  flex: 1,
                                                  text:
                                                      request.reference.trim(),
                                                ),
                                                WebReusableRow(
                                                  flex: 2,
                                                  text: request
                                                      .warehouseDescription
                                                      .trim(),
                                                ),
                                                WebReusableRow(
                                                  flex: 2,
                                                  text: request.requestedBy
                                                      .trim(),
                                                ),
                                                WebReusableRow(
                                                  flex: 2,
                                                  text: request.reason.trim(),
                                                ),
                                                WebReusableRow(
                                                  flex: 3,
                                                  text: request.isFinal
                                                      ? 'Approved'
                                                      : request.isCancelled
                                                          ? 'Denied'
                                                          : 'Pending',
                                                  color: request.isFinal
                                                      ? Colors.green
                                                      : request.isCancelled
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
                            childCount: purchaseRequests.length + 1,
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
                      child: Column(children: [
                        const SizedBox(height: 10),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
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
                                    Radio<ReqDataType>(
                                      value: ReqDataType.reqDate,
                                      groupValue: _reqDataType,
                                      onChanged: (ReqDataType? value) {
                                        setState(() {
                                          _reqDataType = value!;
                                        });
                                      },
                                    ),
                                    const Text('Request Date',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey))
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
                                        child: Text('Request Number',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey)))
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
                                    const Text('Needed Date',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey))
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
                                    const Text('Other',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey))
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
                                      Radio<ReqStatus>(
                                        value: ReqStatus.approved,
                                        groupValue: _reqStatus,
                                        onChanged: (ReqStatus? value) {
                                          setState(() {
                                            _reqStatus = value!;
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
                                      Radio<ReqStatus>(
                                        value: ReqStatus.denied,
                                        groupValue: _reqStatus,
                                        onChanged: (ReqStatus? value) {
                                          setState(() {
                                            _reqStatus = value!;
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
                                      Radio<ReqStatus>(
                                        value: ReqStatus.pending,
                                        groupValue: _reqStatus,
                                        onChanged: (ReqStatus? value) {
                                          setState(() {
                                            _reqStatus = value!;
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
                                      Radio<ReqStatus>(
                                        value: ReqStatus.all,
                                        groupValue: _reqStatus,
                                        onChanged: (ReqStatus? value) {
                                          setState(() {
                                            _reqStatus = value!;
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
                                      labelStyle: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.close, size: 15),
                                        onPressed: () {
                                          if (_reqFromController
                                              .text.isNotEmpty) {
                                            setState(() {
                                              _reqFromController.clear();
                                              _reqStartDate = null;
                                            });
                                            setState(() {
                                              _reqFromController.clear();
                                              _reqStartDate = null;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    readOnly: true,
                                    onTap: () => _selectDate(
                                        context, _reqFromController),
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: TextField(
                                    controller: _reqToController,
                                    decoration: InputDecoration(
                                      labelText: 'To: ',
                                      labelStyle: const TextStyle(
                                        fontSize: 12,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.close, size: 15),
                                        color: Colors.grey,
                                        onPressed: () {
                                          if (_reqToController
                                              .text.isNotEmpty) {
                                            setState(() {
                                              _reqToController.clear();
                                              _reqEndDate = null;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    readOnly: true,
                                    onTap: () =>
                                        _selectDate(context, _reqToController),
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
                          visible: _reqDataType != ReqDataType.other,
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
                                      Radio<ReqSort>(
                                        value: ReqSort.asc,
                                        groupValue: _reqSort,
                                        onChanged: (ReqSort? value) {
                                          setState(() {
                                            _reqSort = value!;
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
                                      Radio<ReqSort>(
                                        value: ReqSort.dsc,
                                        groupValue: _reqSort,
                                        onChanged: (ReqSort? value) {
                                          setState(() {
                                            _reqSort = value!;
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
                          visible: _reqDataType == ReqDataType.other,
                          child: Padding(
                              padding:
                                  const EdgeInsets.only(left: 10, right: 10),
                              child: TextField(
                                controller: _reqOtherController,
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
                                  reqHistFilterProvider.setFilter(
                                      dataType: _reqDataType,
                                      status: _reqStatus,
                                      sort: _reqSort,
                                      fromDate: _reqStartDate,
                                      toDate: _reqEndDate,
                                      otherDropdown: _reqDropdownValue,
                                      otherValue: _reqOtherController.text);
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
                                              fontSize: 12,
                                              color: Colors.white))),
                                ),
                              ),
                            )
                          ],
                        ),
                      ])),
                ),
              )
            ],
          );
        });
      } else {
        String? searchValue =
            Provider.of<PurchReqProvider>(context, listen: false).search;
        return Center(
            child: Text(
                searchValue != null && searchValue != ''
                    ? 'No Matching Purchase Request Found'
                    : '0 Purchase Request',
                style: const TextStyle(fontSize: 30)));
      }
    });
  }
}
