import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rnd_mobile/api/purchase_req_api.dart';
import 'package:rnd_mobile/models/purchase_req_model.dart';
import 'package:rnd_mobile/providers/purchase_request/purch_req_filter_provider.dart';
import 'package:rnd_mobile/providers/purchase_request/purchase_req_provider.dart';
import 'package:rnd_mobile/providers/refresh_icon_indicator_provider.dart';
import 'package:rnd_mobile/providers/user_provider.dart';
import 'package:rnd_mobile/utilities/clear_data.dart';
import 'package:rnd_mobile/utilities/date_only.dart';
import 'package:rnd_mobile/utilities/date_text_formatter.dart';
import 'package:rnd_mobile/utilities/session_handler.dart';
import 'package:rnd_mobile/widgets/alert_dialog.dart';
import 'package:rnd_mobile/widgets/mobile/mob_purch_req_dialog.dart';
import 'package:rnd_mobile/widgets/mobile/mob_reusable_column.dart';
import 'package:rnd_mobile/widgets/toast.dart';
import 'package:rnd_mobile/widgets/windows_custom_toast.dart';
import 'package:table_calendar/table_calendar.dart';

enum ApprovalStatus {
  approve,
  deny,
}

class MobilePurchReqScreen extends StatefulWidget {
  const MobilePurchReqScreen({super.key});

  @override
  State<MobilePurchReqScreen> createState() => _MobilePurchReqScreenState();
}

class _MobilePurchReqScreenState extends State<MobilePurchReqScreen> {
  late final UserProvider userProvider;
  late final PurchReqFilterProvider reqFilterProvider;
  late final PurchReqProvider purchReqProvider;
  ApprovalStatus? status;
  late bool confCanc;
  int? selectedItem;
  int _loadedItemsCount = 15;
  bool isLoadingMore = false;
  late bool hasMore;
  ReqDataType _reqDataType = ReqDataType.reqDate;
  final ReqStatus _reqStatus = ReqStatus.pending;
  ReqSort _reqSort = ReqSort.asc;
  final TextEditingController _reqFromController = TextEditingController();
  final TextEditingController _reqToController = TextEditingController();
  final TextEditingController _reqOtherController = TextEditingController();
  String? _reqDropdownValue;
  late Brightness brightness;

  //Date Picker
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _showFromDate = false;
  bool _showToDate = false;
  DateTime _fromFocusedDay = DateTime.now();
  DateTime _toFocusedDay = DateTime.now();
  DateTime? _reqFromDate;
  DateTime? _reqToDate;

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
                  dateOnly(request.requestDate).isBefore(dateOnly(startDate))) {
                return false;
              }
              if (endDate != null &&
                  dateOnly(request.requestDate).isAfter(dateOnly(endDate))) {
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
              if (startDate != null &&
                  dateOnly(request.neededDate).isBefore(dateOnly(startDate))) {
                return false;
              }
              if (endDate != null &&
                  dateOnly(request.neededDate).isAfter(dateOnly(endDate))) {
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

  // Future<void> _selectDate(
  //     BuildContext context, TextEditingController controller) async {
  //   final DateTime? picked = await showDatePicker(
  //     context: context,
  //     initialDate: DateTime.now(),
  //     firstDate: DateTime(2015, 8),
  //     lastDate: DateTime(2101),
  //     initialEntryMode: DatePickerEntryMode.input,
  //   );
  //   if (picked != null) {
  //     if (controller == _reqFromController) {
  //       _reqFromDate = picked;
  //     } else if (controller == _reqToController) {
  //       _reqToDate = picked;
  //     }
  //     final formattedDate = DateFormat('yyyy/MM/dd').format(picked);
  //     controller.text = formattedDate;
  //   }
  // }

  void _loadMore() async {
    final data = await PurchReqService.getPurchReqView(
      sessionId: userProvider.user!.sessionId,
      recordOffset: _loadedItemsCount,
      forPending: true,
    );
    if (mounted) {
      bool purchReqFlag = handleSessionExpiredException(data, context);
      if (!purchReqFlag) {
        final List<PurchaseRequest> newPurchaseRequests =
            data['purchaseRequests'];
        setState(() {
          hasMore = data['hasMore'];
          isLoadingMore = false;
          _loadedItemsCount += newPurchaseRequests.length;
          Provider.of<PurchReqProvider>(context, listen: false)
              .addItems(purchReqs: newPurchaseRequests);
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProvider>(context, listen: false);
    reqFilterProvider =
        Provider.of<PurchReqFilterProvider>(context, listen: false);
    purchReqProvider = Provider.of<PurchReqProvider>(context, listen: false);
    if (reqFilterProvider.dataType == null ||
        reqFilterProvider.status == null ||
        reqFilterProvider.sort == null) {
      reqFilterProvider.setFilter(
          dataType: _reqDataType,
          status: _reqStatus,
          sort: _reqSort,
          notify: false);
    }
    brightness = PlatformDispatcher.instance.platformBrightness;
    hasMore = purchReqProvider.hasMore;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                const Spacer(),
                InkWell(
                  onTap: () {
                    _reqShowDialog();
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
            child: Consumer<PurchReqProvider>(
                builder: (context, purchaseRequestsProvider, _) {
              List<PurchaseRequest> purchaseListPending =
                  purchaseRequestsProvider.purchaseRequestList
                      .where((purchReq) =>
                          !purchReq.isFinal && !purchReq.isCancelled)
                      .toList();
              String? searchValue = purchaseRequestsProvider.search;
              if (searchValue != null && searchValue != '') {
                purchaseListPending =
                    purchaseListPending.where((purchaseRequest) {
                  return purchaseRequest.containsQuery(searchValue);
                }).toList();
              }

              if (purchaseListPending.isNotEmpty) {
                return Consumer<PurchReqFilterProvider>(
                    builder: (context, filterProvider, _) {
                  List<PurchaseRequest> purchaseRequests = [];
                  if (purchaseListPending.isNotEmpty) {
                    purchaseRequests = [...purchaseListPending];
                    sortPurchaseRequests(purchaseRequests,
                        filterProvider.dataType!, filterProvider.sort!,
                        startDate: filterProvider.fromDate,
                        endDate: filterProvider.toDate,
                        otherDropdown: filterProvider.otherDropdown,
                        otherValue: filterProvider.otherValue);
                    if (purchReqProvider.reqNumber != -1) {
                      PurchaseRequest? newItem = purchReqProvider
                          .purchaseRequestList
                          .firstWhereOrNull((item) =>
                              item.preqNum == purchReqProvider.reqNumber);

                      if (newItem != null) {
                        purchaseRequests.removeWhere(
                            (item) => item.preqNum == newItem.preqNum);
                        purchaseRequests.insert(0, newItem);
                        purchReqProvider.setReqNumber(reqNumber: -1);
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
                              var request = purchaseRequests[index];
                              var requestDate = DateFormat.yMMMd()
                                  .format(request.requestDate);
                              var neededDate =
                                  DateFormat.yMMMd().format(request.neededDate);
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
                                    purchReqShowDialog(
                                        context: context, request: request);
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
                                              color:
                                                  brightness == Brightness.dark
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
                                                  request.preqNum.toString(),
                                              firstRowSecondText: 'Pending',
                                              secondRowFirstText: request.reason
                                                  .toString()
                                                  .trim(),
                                              thirdRowFirstText: request
                                                  .warehouseDescription
                                                  .toString()
                                                  .trim(),
                                              thirdRowSecondText: request
                                                  .reference
                                                  .toString()
                                                  .trim(),
                                              fourthRowFirstText: requestDate,
                                              fourthRowSecondText: neededDate,
                                              statusColor: Colors.grey,
                                              confCanc: confCanc,
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
                                                      await PurchReqService
                                                          .aprvPurchReq(
                                                              sessionId:
                                                                  userProvider
                                                                      .user!
                                                                      .sessionId,
                                                              hdrId:
                                                                  request.id);
                                                } else {
                                                  response =
                                                      await PurchReqService
                                                          .dnyPurchReq(
                                                              sessionId:
                                                                  userProvider
                                                                      .user!
                                                                      .sessionId,
                                                              hdrId:
                                                                  request.id);
                                                }
                                                bool messageIsError = false;
                                                String message;
                                                if (response.statusCode ==
                                                    200) {
                                                  message = status ==
                                                          ApprovalStatus.approve
                                                      ? 'PR #${request.preqNum} Approved'
                                                      : 'PR #${request.preqNum} Denied';
                                                } else if (response
                                                        .statusCode ==
                                                    401) {
                                                  messageIsError = true;
                                                  message =
                                                      'Session Expired. Please Login Again.';
                                                } else {
                                                  messageIsError = true;
                                                  message =
                                                      'Error! Something Went Wrong!\n${response.body}';
                                                }
                                                if (messageIsError) {
                                                  if (mounted) {
                                                    alertDialog(context,
                                                        title: 'Error',
                                                        body: message);
                                                  }
                                                } else {
                                                  showToastMessage(message,
                                                      errorToast:
                                                          messageIsError);
                                                }
                                                if (response.statusCode ==
                                                    401) {
                                                  if (mounted) {
                                                    clearData(context);
                                                  }
                                                }

                                                setState(() {
                                                  purchaseRequests
                                                      .remove(request);
                                                  purchaseRequestsProvider
                                                      .updateItem(
                                                          purchReq: request,
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
                          childCount: purchaseRequests.length + 1,
                        ),
                      ),
                    ],
                  );
                });
              } else {
                String? searchValue = purchReqProvider.search;
                return Center(
                    child: Text(
                        searchValue != null && searchValue != ''
                            ? 'No Matching Purchase Request Found'
                            : '0 Purchase Request',
                        style: const TextStyle(fontSize: 30)));
              }
            }),
          )
        ],
      ),
    );
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
                                            fontSize: 12, color: Colors.grey)),
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
                              ]),
                            ),
                            Expanded(
                              child: Column(children: [
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
                              ]),
                            ),
                          ]),
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
                                    visible: _reqFromController.text.isNotEmpty,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, size: 15),
                                      onPressed: () {
                                        if (_reqFromController
                                            .text.isNotEmpty) {
                                          setState(() {
                                            _reqFromController.clear();
                                            _reqFromDate = null;
                                          });
                                          setState(() {
                                            _reqFromController.clear();
                                            _reqFromDate = null;
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
                                        _reqFromDate = date;
                                        _fromFocusedDay = date;
                                        _showFromDate = false;
                                      } else {
                                        // The entered date is not within the valid range
                                        _reqFromDate = null;
                                        _fromFocusedDay = DateTime.now();
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
                                      _reqFromDate = null;
                                      _fromFocusedDay = DateTime.now();
                                      if (mounted) {
                                        alertDialog(context,
                                            title: 'Error',
                                            body: 'Entered date is not valid');
                                      }
                                      // showToastMessage(
                                      //     'Entered date is not valid');
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
                                controller: _reqToController,
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
                                    visible: _reqToController.text.isNotEmpty,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, size: 15),
                                      color: Colors.grey,
                                      onPressed: () {
                                        if (_reqToController.text.isNotEmpty) {
                                          setState(() {
                                            _reqToController.clear();
                                            _reqToDate = null;
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
                                        _reqToDate = date;
                                        _toFocusedDay = date;
                                        _showToDate = false;
                                      } else {
                                        // The entered date is not within the valid range
                                        _reqToDate = null;
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
                                      _reqToDate = null;
                                      _toFocusedDay = DateTime.now();
                                      if (mounted) {
                                        alertDialog(context,
                                            title: 'Error',
                                            body: 'Entered date is not valid');
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
                                      isSameDay(_reqFromDate, day),
                                  onDaySelected: (selectedDay, focusedDay) {
                                    final dateWithoutOffset =
                                        selectedDay.toLocal();
                                    setState(() {
                                      _reqFromDate = dateWithoutOffset;
                                      _fromFocusedDay = focusedDay;
                                      _reqFromController.text =
                                          DateFormat('MM/dd/yyyy')
                                              .format(_reqFromDate!);
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
                                      isSameDay(_reqToDate, day),
                                  onDaySelected: (selectedDay, focusedDay) {
                                    setState(() {
                                      _reqToDate = selectedDay;
                                      _toFocusedDay = focusedDay;
                                      _reqToController.text =
                                          DateFormat('MM/dd/yyyy')
                                              .format(_reqToDate!);
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
                      visible: _reqDataType != ReqDataType.other,
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
                          padding: const EdgeInsets.only(left: 10, right: 10),
                          child: TextField(
                            controller: _reqOtherController,
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
                              reqFilterProvider.setFilter(
                                  dataType: _reqDataType,
                                  status: _reqStatus,
                                  sort: _reqSort,
                                  fromDate: _reqFromDate,
                                  toDate: _reqToDate,
                                  otherDropdown: _reqDropdownValue,
                                  otherValue: _reqOtherController.text);
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
                  ]),
                ]);
          });
        });
  }
}
