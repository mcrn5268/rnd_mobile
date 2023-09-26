import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:provider/provider.dart';
import 'package:rnd_mobile/api/sales_order_api.dart';
import 'package:rnd_mobile/models/debtor_model.dart';
import 'package:rnd_mobile/models/salesrep_model.dart';
import 'package:rnd_mobile/models/top_model.dart';
import 'package:rnd_mobile/models/warehouse_model.dart';
import 'package:rnd_mobile/providers/items/items_provider.dart';
import 'package:rnd_mobile/providers/user_provider.dart';
import 'package:rnd_mobile/utilities/date_text_formatter.dart';
import 'package:rnd_mobile/utilities/session_handler.dart';
import 'package:rnd_mobile/widgets/mobile/mob_sales_order_items.dart';
import 'package:rnd_mobile/widgets/toast.dart';
import 'package:rnd_mobile/widgets/windows_custom_toast.dart';
import 'package:table_calendar/table_calendar.dart';

class MobileSalesCreateOrderScreen extends StatefulWidget {
  const MobileSalesCreateOrderScreen({super.key});

  @override
  State<MobileSalesCreateOrderScreen> createState() =>
      _MobileSalesCreateOrderScreenState();
}

class _MobileSalesCreateOrderScreenState
    extends State<MobileSalesCreateOrderScreen> {
  late final UserProvider userProvider;
  final TextEditingController _salesOrderDateController =
      TextEditingController();
  final TextEditingController _deliveryDateController = TextEditingController();
  bool _debtorClear = false;
  bool _warehouseClear = false;
  bool _topClear = false;
  bool _salesRepClear = false;
  // final TextEditingController _debtorController = TextEditingController();
  // final TextEditingController _warehouseController = TextEditingController();
  // final TextEditingController _topController = TextEditingController();
  // final TextEditingController _salesRepController = TextEditingController();
  // final TextEditingController _itemController = TextEditingController();
  // final TextEditingController _itemUnitController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _particularsController = TextEditingController();
  // final TextEditingController _lineNumberController = TextEditingController();
  // final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _conversionFactorController =
      TextEditingController();
  // final TextEditingController _sellingPriceController = TextEditingController();
  List<Debtor> _debtors = [];
  List<Warehouse> _warehouse = [];
  List<TermsOfPayment> _tops = [];
  List<SalesRep> _salesReps = [];
  int _loadedDebtors = 15;
  int _loadedWarehouse = 15;
  int _loadedTops = 15;
  int _loadedSalesReps = 15;
  bool _debtorsHasMore = true;
  bool _warehouseHasMore = true;
  bool _topsHasMore = true;
  bool _salesRepsHasMore = true;
  Debtor? _selectedDebtor;
  Warehouse? _selectedWarehouse;
  TermsOfPayment? _selectedTOP;
  SalesRep? _selectedSalesRep;
  List<dynamic> _selectedItem = [];
  Map<String, dynamic> _prevSearchResult = {};
  final ValueNotifier<bool> _debtorIsLoadingMore = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _warehouseIsLoadingMore =
      ValueNotifier<bool>(false);
  final ValueNotifier<bool> _topIsLoadingMore = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _salesRepIsLoadingMore = ValueNotifier<bool>(false);
  bool _isCreating = false;
  late final ItemsProvider salesOrderItemsProvider;
  bool isLoadingMore = false;
  late List<dynamic> items;
  late bool itemsHasMore;
  List<bool> _itemIsActive = [];
  // List<Widget> _itemsRowList = [];
  List<String?> _itemsErrorText = [];
  List<String?> _itemQtyErrorText = [];
  List<String?> _itemBaseSellingPriceErrorText = [];
  List<TextEditingController> _itemsLineNumberControllerList = [];
  List<TextEditingController> _itemsControllerList = [];
  List<TextEditingController> _itemsUnitControllerList = [];
  List<TextEditingController> _itemsQuantityControllerList = [];
  // List<TextEditingController> _itemsConversionControllerList = [];
  List<TextEditingController> _itemsPriceControllerList = [];
  List<dynamic> removedIndex = [];
  final ScrollController _scrollController = ScrollController();
  double scrollAmount = 200.0;
  final _salesOrderDateFocusNode = FocusNode();
  final _deliveryDateFocusNode = FocusNode();
  final _itemFocusNode = FocusNode();
  final ScrollController debtorScrollController = ScrollController();
  final ScrollController whsScrollController = ScrollController();
  final ScrollController topScrollController = ScrollController();
  final ScrollController salesRepScrollController = ScrollController();
  int _debtorLoadMoreCounter = 0;
  int _whsLoadMoreCounter = 0;
  int _topLoadMoreCounter = 0;
  int _salesRepLoadMoreCounter = 0;
  bool _debtorJumpLoadMore = false;
  bool _whsJumpLoadMore = false;
  bool _topJumpLoadMore = false;
  bool _salesRepJumpLoadMore = false;
  String? _salesOrderDateErrorText;
  String? _salesOrderDelvDateErrorText;
  String? _debtorErrorText;
  String? _warehouseErrorText;
  String? _topErrorText;
  String? _salesRepErrorText;
  bool _salesOrderDateNotValid = false;
  bool _salesOrderDelvDateNotValid = false;
  late Brightness brightness;

  //for date picker
  CalendarFormat _calendarFormat = CalendarFormat.month;

  //sales order date
  final LayerLink _layerLinkSalesOrderDate = LayerLink();
  bool _showOverlaySalesOrderDate = false;
  DateTime _salesOrderfocusedDay = DateTime.now();
  DateTime? _salesOrderDate;

  //sales order deliveryd ate
  final LayerLink _layerLinkSalesOrderDelvDate = LayerLink();
  bool _showOverlaySalesOrderDelvDate = false;
  DateTime _salesOrderDelvfocusedDay = DateTime.now();
  DateTime? _salesOrderDelvDate;

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProvider>(context, listen: false);
    _conversionFactorController.text = '1';
    salesOrderItemsProvider =
        Provider.of<ItemsProvider>(context, listen: false);
    items = salesOrderItemsProvider.items;
    itemsHasMore = salesOrderItemsProvider.hasMore;
    _itemIsActive.add(true);
    addItem();
    brightness = PlatformDispatcher.instance.platformBrightness;
  }

  @override
  void dispose() {
    _salesOrderDateController.dispose();
    _deliveryDateController.dispose();
    // _debtorController.dispose();
    // _warehouseController.dispose();
    // _topController.dispose();
    // _salesRepController.dispose();
    _referenceController.dispose();
    _particularsController.dispose();
    _conversionFactorController.dispose();
    for (var controller in _itemsLineNumberControllerList) {
      controller.dispose();
    }
    for (var controller in _itemsControllerList) {
      controller.dispose();
    }
    for (var controller in _itemsUnitControllerList) {
      controller.dispose();
    }
    for (var controller in _itemsQuantityControllerList) {
      controller.dispose();
    }
    for (var controller in _itemsPriceControllerList) {
      controller.dispose();
    }
    super.dispose();
  }

  void addItem() {
    _itemsErrorText.add(null);
    _itemQtyErrorText.add(null);
    _itemBaseSellingPriceErrorText.add(null);
    TextEditingController itemLineNumberController = TextEditingController();
    _itemsLineNumberControllerList.add(itemLineNumberController);
    TextEditingController itemController = TextEditingController();
    _itemsControllerList.add(itemController);
    TextEditingController itemUnitController = TextEditingController();
    _itemsUnitControllerList.add(itemUnitController);
    TextEditingController itemQuantityController = TextEditingController();
    _itemsQuantityControllerList.add(itemQuantityController);
    TextEditingController itemPriceController = TextEditingController();
    _itemsPriceControllerList.add(itemPriceController);
    int itemIndex = _itemIsActive.length - 1;
    _itemsLineNumberControllerList[itemIndex].text =
        _itemsLineNumberControllerList.length.toString();
    _selectedItem.insert(itemIndex, [null]);
  }

  void addDebtorsToList(List<Debtor> newDebtorList) {
    for (Debtor newDebtorData in newDebtorList) {
      bool exists = _debtors.any((existingDebtor) =>
          existingDebtor.debtorId == newDebtorData.debtorId &&
          existingDebtor.debtorName == newDebtorData.debtorName &&
          existingDebtor.debtorCode == newDebtorData.debtorCode);
      if (!exists) {
        _debtors.add(newDebtorData);
      }
    }
  }

  void addWarehouseToList(List<Warehouse> newWarehouseList) {
    for (Warehouse newWarehouseData in newWarehouseList) {
      bool exists = _warehouse.any((existingWarehouse) =>
          existingWarehouse.whsId == newWarehouseData.whsId &&
          existingWarehouse.whsDesc == newWarehouseData.whsDesc &&
          existingWarehouse.whsCode == newWarehouseData.whsCode);
      if (!exists) {
        _warehouse.add(newWarehouseData);
      }
    }
  }

  void addTOPsToList(List<TermsOfPayment> newTOPsList) {
    for (TermsOfPayment newTOPData in newTOPsList) {
      bool exists = _tops.any((existingTOP) =>
          existingTOP.topId == newTOPData.topId &&
          existingTOP.topDesc == newTOPData.topDesc &&
          existingTOP.topCode == newTOPData.topCode);
      if (!exists) {
        _tops.add(newTOPData);
      }
    }
  }

  void addSalesRepsToList(List<SalesRep> newSalesRepList) {
    for (SalesRep newSalesRepData in newSalesRepList) {
      bool exists = _salesReps.any((existingSalesRep) =>
          existingSalesRep.salesRepId == newSalesRepData.salesRepId &&
          existingSalesRep.salesRepName == newSalesRepData.salesRepName &&
          existingSalesRep.salesRepCode == newSalesRepData.salesRepCode);
      if (!exists) {
        _salesReps.add(newSalesRepData);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget referenceWidget = Expanded(
      child: TextField(
        controller: _referenceController,
        decoration: InputDecoration(
          labelText: 'Reference',
          labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.grey),
            borderRadius: BorderRadius.circular(10.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.grey),
            borderRadius: BorderRadius.circular(10.0),
          ),
          filled: true,
          fillColor:
              brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
          suffixIcon: Visibility(
            visible: _referenceController.text.isNotEmpty,
            child: IconButton(
              icon: const Icon(Icons.close, size: 25),
              onPressed: () {
                setState(() {
                  _referenceController.clear();
                });
              },
            ),
          ),
        ),
        onChanged: (text) {
          setState(() {});
        },
      ),
    );

    Widget salesOrderDateWidget = Expanded(
      child: CompositedTransformTarget(
        link: _layerLinkSalesOrderDate,
        child: TextField(
          focusNode: _salesOrderDateFocusNode,
          controller: _salesOrderDateController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d/]')),
            DateTextFormatter()
          ],
          decoration: InputDecoration(
            labelText: 'Sales Order Date',
            hintText: 'MM/DD/YYYY',
            labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.grey),
              borderRadius: BorderRadius.circular(10.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color:
                    _salesOrderDateErrorText != null ? Colors.red : Colors.grey,
              ),
              borderRadius: BorderRadius.circular(10.0),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Colors.red,
              ),
              borderRadius: BorderRadius.circular(10.0),
            ),
            errorText: _salesOrderDateErrorText,
            filled: true,
            fillColor:
                brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
            suffixIcon: Visibility(
              visible: _salesOrderDateController.text.isNotEmpty,
              child: IconButton(
                focusNode: FocusNode(skipTraversal: true),
                icon: const Icon(Icons.close, size: 25),
                onPressed: () {
                  setState(() {
                    _salesOrderDateController.clear();
                    _salesOrderDate = null;
                    _salesOrderfocusedDay = DateTime.now();
                  });
                },
              ),
            ),
          ),
          onChanged: (String value) {
            if (value.length == 10) {
              final format = DateFormat('MM/dd/yyyy');
              try {
                print('value: $value');
                final date = format.parseStrict(value);
                if (date.year >= 2010 && date.year <= 2050) {
                  print('date: $date');
                  _salesOrderDate = date;
                  _salesOrderfocusedDay = date;
                  _showOverlaySalesOrderDate = false;
                  _salesOrderDateNotValid = false;
                } else {
                  // The entered date is not within the valid range
                  _salesOrderDate = null;
                  _salesOrderfocusedDay = DateTime.now();
                  _salesOrderDateNotValid = true;
                }
              } catch (e) {
                // The entered date is not valid
                _salesOrderDate = null;
                _salesOrderfocusedDay = DateTime.now();
                _salesOrderDateNotValid = true;
              }
              setState(() {});
            }
          },
          onTap: () {
            setState(() {
              _salesOrderDateErrorText = null;
              _showOverlaySalesOrderDate = true;
            });
          },
        ),
      ),
    );

    Widget salesOrderDelvDateWidget = Expanded(
      child: CompositedTransformTarget(
        link: _layerLinkSalesOrderDelvDate,
        child: TextField(
          focusNode: _deliveryDateFocusNode,
          controller: _deliveryDateController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d/]')),
            DateTextFormatter()
          ],
          decoration: InputDecoration(
            labelText: 'Delivery Date',
            hintText: 'MM/DD/YYYY',
            labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.grey),
              borderRadius: BorderRadius.circular(10.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: _salesOrderDelvDateErrorText != null
                      ? Colors.red
                      : Colors.grey),
              borderRadius: BorderRadius.circular(10.0),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Colors.red,
              ),
              borderRadius: BorderRadius.circular(10.0),
            ),
            errorText: _salesOrderDelvDateErrorText,
            filled: true,
            fillColor:
                brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
            suffixIcon: Visibility(
              visible: _deliveryDateController.text.isNotEmpty,
              child: IconButton(
                focusNode: FocusNode(skipTraversal: true),
                icon: const Icon(Icons.close, size: 25),
                onPressed: () {
                  setState(() {
                    _deliveryDateController.clear();
                    _salesOrderDelvDate = null;
                    _salesOrderDelvfocusedDay = DateTime.now();
                  });
                },
              ),
            ),
          ),
          onChanged: (String value) {
            if (value.length == 10) {
              final format = DateFormat('MM/dd/yyyy');
              try {
                final date = format.parseStrict(value);
                if (date.year >= 2010 && date.year <= 2050) {
                  _salesOrderDelvDate = date;
                  _salesOrderDelvfocusedDay = date;
                  _showOverlaySalesOrderDelvDate = false;
                  _salesOrderDelvDateNotValid = false;
                } else {
                  // The entered date is not within the valid range
                  _salesOrderDelvDate = null;
                  _salesOrderDelvfocusedDay = DateTime.now();
                  _salesOrderDelvDateNotValid = true;
                }
              } catch (e) {
                print('catch e: $e');
                // The entered date is not valid
                _salesOrderDelvDate = null;
                _salesOrderDelvfocusedDay = DateTime.now();
                _salesOrderDelvDateNotValid = true;
              }
              setState(() {});
            }
          },
          onTap: () {
            setState(() {
              _salesOrderDelvDateErrorText = null;
              _showOverlaySalesOrderDelvDate = true;
            });
          },
        ),
      ),
    );

    Widget particularsWidget = Expanded(
      child: TextField(
        controller: _particularsController,
        decoration: InputDecoration(
          labelText: 'Particulars',
          labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.grey),
            borderRadius: BorderRadius.circular(10.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.grey),
            borderRadius: BorderRadius.circular(10.0),
          ),
          filled: true,
          fillColor:
              brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
          suffixIcon: Visibility(
            visible: _particularsController.text.isNotEmpty,
            child: IconButton(
              icon: const Icon(Icons.close, size: 25),
              onPressed: () {
                setState(() {
                  _particularsController.clear();
                });
              },
            ),
          ),
        ),
        onChanged: (text) {
          setState(() {});
        },
      ),
    );

    Widget debtorWidget = Expanded(
      child: Autocomplete<Debtor>(
          displayStringForOption: (Debtor option) => option.debtorName,
          optionsBuilder: (TextEditingValue textEditingValue) async {
            bool salesOrderFlag = false;
            //first time loading data
            if (_debtors.isEmpty) {
              final result = await SalesOrderService.getDebtorView(
                  sessionId: userProvider.user!.sessionId);
              List<dynamic> resultDebtors = result['debtors'];
              _debtors = resultDebtors
                  .map((debtorList) => Debtor(
                        debtorId: debtorList[0],
                        debtorCode: debtorList[1].toString(),
                        debtorName: debtorList[2].toString(),
                      ))
                  .toList();

              _debtorsHasMore = result['hasMore'];
              //for checking if session is still valid
              if (context.mounted) {
                salesOrderFlag =
                    handleSessionExpiredException(_debtors[0], context);
              }
            }
            //if session is still valid
            if (!salesOrderFlag) {
              if (textEditingValue.text.length < 2) {
                //use main list for search if  input character <2
                return _debtors
                    .where((debtor) =>
                        debtor.contains(textEditingValue.text.toLowerCase()))
                    .toList();
              } else {
                //uses simple_search_value filter
                late final Map<String, dynamic> search;

                if (_prevSearchResult.containsKey('debtor') &&
                    _prevSearchResult['debtor']
                        .containsKey(textEditingValue.text)) {
                  //if input is already stored in previous search result
                  //then reuse that list
                  return _prevSearchResult['debtor'][textEditingValue.text];
                } else {
                  //else then get a new list from API
                  search = await SalesOrderService.getDebtorView(
                      sessionId: userProvider.user!.sessionId,
                      search: textEditingValue.text);
                  List<dynamic> resultDebtors = search['debtors'];
                  List<Debtor> searchResult = resultDebtors
                      .map((debtorList) => Debtor(
                            debtorId: debtorList[0],
                            debtorCode: debtorList[1].toString(),
                            debtorName: debtorList[2].toString(),
                          ))
                      .toList();

                  searchResult = searchResult
                      .where((debtor) =>
                          debtor.contains(textEditingValue.text.toLowerCase()))
                      .toList();
                  addDebtorsToList(searchResult);

                  //create the previous search result
                  if (!_prevSearchResult.containsKey('debtor')) {
                    _prevSearchResult['debtor'] = {};
                  }
                  _prevSearchResult['debtor'][textEditingValue.text] =
                      searchResult;
                  return searchResult;
                }
              }
            } else {
              return [];
            }
          },
          fieldViewBuilder: (BuildContext context,
              TextEditingController fieldTextEditingController,
              FocusNode fieldFocusNode,
              VoidCallback onFieldSubmitted) {
            if (_debtorClear) {
              fieldTextEditingController.clear();
              _debtorClear = false;
            }
            return TextField(
                controller: fieldTextEditingController,
                focusNode: fieldFocusNode,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'Debtor',
                  labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: _debtorErrorText != null
                            ? Colors.red
                            : Colors.grey),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.red, // Red border color for errors
                    ),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  errorText: _debtorErrorText,
                  filled: true,
                  fillColor: brightness == Brightness.dark
                      ? Colors.grey[900]
                      : Colors.white,
                  suffixIcon: Visibility(
                    visible: fieldTextEditingController.text.isNotEmpty,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 25),
                      onPressed: () {
                        setState(() {
                          fieldTextEditingController.clear();
                          _selectedDebtor = null;
                        });
                      },
                    ),
                  ),
                ),
                onSubmitted: (value) {
                  onFieldSubmitted();
                  setState(() {
                    _selectedDebtor = _debtors.firstWhere(
                        (debtor) => debtor.containsStringValue(value) != null);
                  });
                },
                onTap: () {
                  setState(() {
                    _debtorErrorText = null;
                  });
                });
          },
          optionsViewBuilder: (BuildContext context,
              AutocompleteOnSelected<Debtor> onSelected,
              Iterable<Debtor> options) {
            if (_debtorJumpLoadMore) {
              options = _debtors;
            }
            return Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 200.0,
                height: MediaQuery.of(context).size.height / 2,
                child: Material(
                  elevation: 4.0,
                  child: ListView.builder(
                    controller: debtorScrollController,
                    itemCount: options.length + 1,
                    itemBuilder: (BuildContext context, int index) {
                      if (index == options.length) {
                        return Stack(
                          children: [
                            Align(
                                alignment: Alignment.center,
                                child: Visibility(
                                  visible: _debtorsHasMore,
                                  child: ValueListenableBuilder<bool>(
                                    valueListenable: _debtorIsLoadingMore,
                                    builder: (BuildContext context,
                                        bool debtorIsLoadingMore,
                                        Widget? child) {
                                      return ElevatedButton(
                                          onPressed: () async {
                                            setState(() {
                                              _debtorIsLoadingMore.value = true;
                                            });
                                            final result =
                                                await SalesOrderService
                                                    .getDebtorView(
                                                        sessionId: userProvider
                                                            .user!.sessionId,
                                                        recordOffset:
                                                            _loadedDebtors);
                                            List<dynamic> resultDebtors =
                                                result['debtors'];
                                            List<Debtor> searchResult =
                                                resultDebtors
                                                    .map((debtorList) => Debtor(
                                                          debtorId:
                                                              debtorList[0],
                                                          debtorCode:
                                                              debtorList[1]
                                                                  .toString(),
                                                          debtorName:
                                                              debtorList[2]
                                                                  .toString(),
                                                        ))
                                                    .toList();
                                            setState(() {
                                              // _debtors.addAll(
                                              //     searchResult);
                                              addDebtorsToList(searchResult);
                                              _debtorsHasMore =
                                                  result['hasMore'];
                                              _loadedDebtors += _debtors.length;
                                              _debtorIsLoadingMore.value =
                                                  false;
                                              _debtorClear = true;
                                              _debtorLoadMoreCounter++;
                                              _debtorJumpLoadMore = true;
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              elevation: 0),
                                          child: debtorIsLoadingMore
                                              ? const CircularProgressIndicator()
                                              : const Text('Load More',
                                                  style: TextStyle(
                                                      color: Colors.grey)));
                                    },
                                  ),
                                )),
                            Align(
                              alignment: Alignment.center,
                              child: Visibility(
                                  visible: !_debtorsHasMore,
                                  child: const Text('End of Results')),
                            ),
                          ],
                        );
                      } else {
                        final Debtor option = options.elementAt(index);
                        final bool highlight =
                            AutocompleteHighlightedOption.of(context) == index;
                        if (highlight && debtorScrollController.hasClients) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_debtorJumpLoadMore) {
                              debtorScrollController
                                  .jumpTo((_debtorLoadMoreCounter * 15) * 56.0);
                              _debtorJumpLoadMore = false;
                            } else {
                              debtorScrollController.animateTo(
                                index * 56.0,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                              );
                            }
                          });
                        }

                        return InkWell(
                          onTap: () {
                            onSelected(option);
                            setState(() {
                              _selectedDebtor = option;
                            });
                          },
                          child: ListTile(
                            tileColor: highlight
                                ? Theme.of(context).focusColor.withOpacity(0.1)
                                : null,
                            title: Text(option.debtorName,
                                style: const TextStyle(fontSize: 12)),
                            subtitle: Text(option.debtorCode,
                                style: const TextStyle(fontSize: 12)),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            );
          }),
    );

    Widget warehouseWidget = Expanded(
      child: Autocomplete<Warehouse>(
          displayStringForOption: (Warehouse option) => option.whsDesc,
          optionsBuilder: (TextEditingValue textEditingValue) async {
            bool salesOrderFlag = false;
            //first time loading data
            if (_warehouse.isEmpty) {
              final result = await SalesOrderService.getWarehouseView(
                  sessionId: userProvider.user!.sessionId);
              List<dynamic> resultWarehouse = result['warehouse'];
              _warehouse = resultWarehouse
                  .map((warehouseList) => Warehouse(
                        whsId: warehouseList[0],
                        whsCode: warehouseList[1].toString(),
                        whsDesc: warehouseList[2].toString(),
                      ))
                  .toList();

              _warehouseHasMore = result['hasMore'];
              //for checking if session is still valid
              if (context.mounted) {
                salesOrderFlag =
                    handleSessionExpiredException(_warehouse[0], context);
              }
            }
            //if session is still valid
            if (!salesOrderFlag) {
              if (textEditingValue.text.length < 2) {
                //use main list for search if  input character <2
                return _warehouse
                    .where((warehouse) =>
                        warehouse.contains(textEditingValue.text.toLowerCase()))
                    .toList();
              } else {
                //uses simple_search_value filter
                late final Map<String, dynamic> search;

                if (_prevSearchResult.containsKey('warehouse') &&
                    _prevSearchResult['warehouse']
                        .containsKey(textEditingValue.text)) {
                  //if input is already stored in previous search result
                  //then reuse that list
                  return _prevSearchResult['warehouse'][textEditingValue.text];
                } else {
                  //else then get a new list from API
                  search = await SalesOrderService.getWarehouseView(
                      sessionId: userProvider.user!.sessionId,
                      search: textEditingValue.text);
                  List<dynamic> resultWarehouse = search['warehouse'];
                  List<Warehouse> searchResult = resultWarehouse
                      .map((warehouseList) => Warehouse(
                            whsId: warehouseList[0],
                            whsCode: warehouseList[1].toString(),
                            whsDesc: warehouseList[2].toString(),
                          ))
                      .toList();

                  searchResult = searchResult
                      .where((warehouse) => warehouse
                          .contains(textEditingValue.text.toLowerCase()))
                      .toList();
                  addWarehouseToList(searchResult);

                  //create the previous search result
                  if (!_prevSearchResult.containsKey('warehouse')) {
                    _prevSearchResult['warehouse'] = {};
                  }
                  _prevSearchResult['warehouse'][textEditingValue.text] =
                      searchResult;
                  return searchResult;
                }
              }
            } else {
              return [];
            }
          },
          fieldViewBuilder: (BuildContext context,
              TextEditingController fieldTextEditingController,
              FocusNode fieldFocusNode,
              VoidCallback onFieldSubmitted) {
            if (_warehouseClear) {
              fieldTextEditingController.clear();
              _warehouseClear = false;
            }
            return TextField(
                controller: fieldTextEditingController,
                focusNode: fieldFocusNode,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'Warehouse',
                  labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: _warehouseErrorText != null
                            ? Colors.red
                            : Colors.grey),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.red,
                    ),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  errorText: _warehouseErrorText,
                  filled: true,
                  fillColor: brightness == Brightness.dark
                      ? Colors.grey[900]
                      : Colors.white,
                  suffixIcon: Visibility(
                    visible: fieldTextEditingController.text.isNotEmpty,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 25),
                      onPressed: () {
                        setState(() {
                          fieldTextEditingController.clear();
                          _selectedWarehouse = null;
                        });
                      },
                    ),
                  ),
                ),
                onSubmitted: (value) {
                  onFieldSubmitted();
                  setState(() {
                    _selectedWarehouse = _warehouse.firstWhere((warehouse) =>
                        warehouse.containsStringValue(value) != null);
                  });
                },
                onTap: () {
                  setState(() {
                    _warehouseErrorText = null;
                  });
                });
          },
          optionsViewBuilder: (BuildContext context,
              AutocompleteOnSelected<Warehouse> onSelected,
              Iterable<Warehouse> options) {
            if (_whsJumpLoadMore) {
              options = _warehouse;
            }
            return Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 200.0,
                height: MediaQuery.of(context).size.height / 2,
                child: Material(
                  elevation: 4.0,
                  child: ListView.builder(
                    controller: whsScrollController,
                    itemCount: options.length + 1,
                    itemBuilder: (BuildContext context, int index) {
                      if (index == options.length) {
                        return Stack(
                          children: [
                            Align(
                                alignment: Alignment.center,
                                child: Visibility(
                                  visible: _warehouseHasMore,
                                  child: ValueListenableBuilder<bool>(
                                    valueListenable: _warehouseIsLoadingMore,
                                    builder: (BuildContext context,
                                        bool warehouseIsLoadingMore,
                                        Widget? child) {
                                      return ElevatedButton(
                                          onPressed: () async {
                                            setState(() {
                                              _warehouseIsLoadingMore.value =
                                                  true;
                                            });
                                            final result =
                                                await SalesOrderService
                                                    .getWarehouseView(
                                                        sessionId: userProvider
                                                            .user!.sessionId,
                                                        recordOffset:
                                                            _loadedWarehouse);
                                            List<dynamic> resultWarehouse =
                                                result['warehouse'];
                                            List<Warehouse> searchResult =
                                                resultWarehouse
                                                    .map((warehouseList) =>
                                                        Warehouse(
                                                          whsId:
                                                              warehouseList[0],
                                                          whsCode:
                                                              warehouseList[1]
                                                                  .toString(),
                                                          whsDesc:
                                                              warehouseList[2]
                                                                  .toString(),
                                                        ))
                                                    .toList();
                                            setState(() {
                                              // _warehouse.addAll(
                                              //     searchResult);
                                              addWarehouseToList(searchResult);
                                              _warehouseHasMore =
                                                  result['hasMore'];
                                              _loadedWarehouse +=
                                                  _warehouse.length;
                                              _warehouseIsLoadingMore.value =
                                                  false;
                                              _warehouseClear = true;
                                              _whsLoadMoreCounter++;
                                              _whsJumpLoadMore = true;
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              elevation: 0),
                                          child: warehouseIsLoadingMore
                                              ? const CircularProgressIndicator()
                                              : const Text('Load More',
                                                  style: TextStyle(
                                                      color: Colors.grey)));
                                    },
                                  ),
                                )),
                            Align(
                              alignment: Alignment.center,
                              child: Visibility(
                                  visible: !_warehouseHasMore,
                                  child: const Text('End of Results')),
                            ),
                          ],
                        );
                      } else {
                        final Warehouse option = options.elementAt(index);
                        final bool highlight =
                            AutocompleteHighlightedOption.of(context) == index;
                        if (highlight && whsScrollController.hasClients) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_whsJumpLoadMore) {
                              whsScrollController
                                  .jumpTo((_whsLoadMoreCounter * 15) * 56.0);
                              _whsJumpLoadMore = false;
                            } else {
                              whsScrollController.animateTo(
                                index * 56.0,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                              );
                            }
                          });
                        }

                        return InkWell(
                          onTap: () {
                            onSelected(option);
                            setState(() {
                              _selectedWarehouse = option;
                            });
                          },
                          child: ListTile(
                            tileColor: highlight
                                ? Theme.of(context).focusColor.withOpacity(0.1)
                                : null,
                            title: Text(option.whsDesc,
                                style: const TextStyle(fontSize: 12)),
                            subtitle: Text(option.whsCode,
                                style: const TextStyle(fontSize: 12)),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            );
          }),
    );

    Widget topWidget = Expanded(
      child: Autocomplete<TermsOfPayment>(
          displayStringForOption: (TermsOfPayment option) => option.topDesc,
          optionsBuilder: (TextEditingValue textEditingValue) async {
            bool salesOrderFlag = false;
            //first time loading data
            if (_tops.isEmpty) {
              final result = await SalesOrderService.getTOPView(
                  sessionId: userProvider.user!.sessionId);
              List<dynamic> resultTOP = result['tops'];
              _tops = resultTOP
                  .map((topList) => TermsOfPayment(
                        topId: topList[0],
                        topCode: topList[1].toString(),
                        topDesc: topList[2].toString(),
                      ))
                  .toList();

              _topsHasMore = result['hasMore'];
              //for checking if session is still valid
              if (context.mounted) {
                salesOrderFlag =
                    handleSessionExpiredException(_tops[0], context);
              }
            }
            //if session is still valid
            if (!salesOrderFlag) {
              if (textEditingValue.text.length < 2) {
                //use main list for search if  input character <2
                return _tops
                    .where((top) =>
                        top.contains(textEditingValue.text.toLowerCase()))
                    .toList();
              } else {
                //uses simple_search_value filter
                late final Map<String, dynamic> search;

                if (_prevSearchResult.containsKey('tops') &&
                    _prevSearchResult['tops']
                        .containsKey(textEditingValue.text)) {
                  //if input is already stored in previous search result
                  //then reuse that list
                  return _prevSearchResult['tops'][textEditingValue.text];
                } else {
                  //else then get a new list from API
                  search = await SalesOrderService.getTOPView(
                      sessionId: userProvider.user!.sessionId,
                      search: textEditingValue.text);
                  List<dynamic> resultTOP = search['tops'];
                  List<TermsOfPayment> searchResult = resultTOP
                      .map((topsList) => TermsOfPayment(
                            topId: topsList[0],
                            topCode: topsList[1].toString(),
                            topDesc: topsList[2].toString(),
                          ))
                      .toList();

                  searchResult = searchResult
                      .where((top) =>
                          top.contains(textEditingValue.text.toLowerCase()))
                      .toList();
                  addTOPsToList(searchResult);

                  //create the previous search result
                  if (!_prevSearchResult.containsKey('top')) {
                    _prevSearchResult['tops'] = {};
                  }
                  _prevSearchResult['tops'][textEditingValue.text] =
                      searchResult;
                  return searchResult;
                }
              }
            } else {
              return [];
            }
          },
          fieldViewBuilder: (BuildContext context,
              TextEditingController fieldTextEditingController,
              FocusNode fieldFocusNode,
              VoidCallback onFieldSubmitted) {
            if (_topClear) {
              fieldTextEditingController.clear();
              _topClear = false;
            }
            return TextField(
                controller: fieldTextEditingController,
                focusNode: fieldFocusNode,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'Terms Of Payment',
                  labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color:
                            _topErrorText != null ? Colors.red : Colors.grey),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.red,
                    ),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  errorText: _topErrorText,
                  filled: true,
                  fillColor: brightness == Brightness.dark
                      ? Colors.grey[900]
                      : Colors.white,
                  suffixIcon: Visibility(
                    visible: fieldTextEditingController.text.isNotEmpty,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 25),
                      onPressed: () {
                        setState(() {
                          fieldTextEditingController.clear();
                          _selectedTOP = null;
                        });
                      },
                    ),
                  ),
                ),
                onSubmitted: (value) {
                  onFieldSubmitted();
                  setState(() {
                    _selectedTOP = _tops.firstWhere(
                        (top) => top.containsStringValue(value) != null);
                  });
                },
                onTap: () {
                  setState(() {
                    _topErrorText = null;
                  });
                });
          },
          optionsViewBuilder: (BuildContext context,
              AutocompleteOnSelected<TermsOfPayment> onSelected,
              Iterable<TermsOfPayment> options) {
            if (_topJumpLoadMore) {
              options = _tops;
            }
            return Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 200.0,
                height: MediaQuery.of(context).size.height / 2,
                child: Material(
                  elevation: 4.0,
                  child: ListView.builder(
                    controller: topScrollController,
                    itemCount: options.length + 1,
                    itemBuilder: (BuildContext context, int index) {
                      if (index == options.length) {
                        return Stack(
                          children: [
                            Align(
                                alignment: Alignment.center,
                                child: Visibility(
                                  visible: _topsHasMore,
                                  child: ValueListenableBuilder<bool>(
                                    valueListenable: _topIsLoadingMore,
                                    builder: (BuildContext context,
                                        bool topIsLoadingMore, Widget? child) {
                                      return ElevatedButton(
                                          onPressed: () async {
                                            setState(() {
                                              _topIsLoadingMore.value = true;
                                            });
                                            final result =
                                                await SalesOrderService
                                                    .getTOPView(
                                                        sessionId: userProvider
                                                            .user!.sessionId,
                                                        recordOffset:
                                                            _loadedTops);
                                            List<dynamic> resultTOP =
                                                result['tops'];
                                            List<TermsOfPayment> searchResult =
                                                resultTOP
                                                    .map((topsList) =>
                                                        TermsOfPayment(
                                                          topId: topsList[0],
                                                          topCode: topsList[1]
                                                              .toString(),
                                                          topDesc: topsList[2]
                                                              .toString(),
                                                        ))
                                                    .toList();
                                            setState(() {
                                              // _tops.addAll(
                                              //     searchResult);
                                              addTOPsToList(searchResult);
                                              _topsHasMore = result['hasMore'];
                                              _loadedTops += _tops.length;
                                              _topIsLoadingMore.value = false;
                                              _topClear = true;
                                              _topLoadMoreCounter++;
                                              _topJumpLoadMore = true;
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              elevation: 0),
                                          child: topIsLoadingMore
                                              ? const CircularProgressIndicator()
                                              : const Text('Load More',
                                                  style: TextStyle(
                                                      color: Colors.grey)));
                                    },
                                  ),
                                )),
                            Align(
                              alignment: Alignment.center,
                              child: Visibility(
                                  visible: !_topsHasMore,
                                  child: const Text('End of Results')),
                            ),
                          ],
                        );
                      } else {
                        final TermsOfPayment option = options.elementAt(index);
                        final bool highlight =
                            AutocompleteHighlightedOption.of(context) == index;
                        if (highlight && topScrollController.hasClients) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_topJumpLoadMore) {
                              topScrollController
                                  .jumpTo((_topLoadMoreCounter * 15) * 56.0);
                              _topJumpLoadMore = false;
                            } else {
                              topScrollController.animateTo(
                                index * 56.0,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                              );
                            }
                          });
                        }

                        return InkWell(
                          onTap: () {
                            onSelected(option);
                            setState(() {
                              _selectedTOP = option;
                            });
                          },
                          child: ListTile(
                            tileColor: highlight
                                ? Theme.of(context).focusColor.withOpacity(0.1)
                                : null,
                            title: Text(option.topDesc,
                                style: const TextStyle(fontSize: 12)),
                            subtitle: Text(option.topCode,
                                style: const TextStyle(fontSize: 12)),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            );
          }),
    );

    Widget salesRepWidget = Expanded(
      child: Autocomplete<SalesRep>(
          displayStringForOption: (SalesRep option) => option.salesRepName,
          optionsBuilder: (TextEditingValue textEditingValue) async {
            bool salesOrderFlag = false;
            //first time loading data
            if (_salesReps.isEmpty) {
              final result = await SalesOrderService.getSalesRepView(
                  sessionId: userProvider.user!.sessionId);
              List<dynamic> resultSalesRep = result['salesReps'];
              _salesReps = resultSalesRep
                  .map((salesRepsList) => SalesRep(
                        salesRepId: salesRepsList[0],
                        salesRepCode: salesRepsList[1].toString(),
                        salesRepName: salesRepsList[2].toString(),
                      ))
                  .toList();

              _salesRepsHasMore = result['hasMore'];
              //for checking if session is still valid
              if (context.mounted) {
                salesOrderFlag =
                    handleSessionExpiredException(_salesReps[0], context);
              }
            }
            //if session is still valid
            if (!salesOrderFlag) {
              if (textEditingValue.text.length < 2) {
                //use main list for search if  input character <2
                return _salesReps
                    .where((salesRep) =>
                        salesRep.contains(textEditingValue.text.toLowerCase()))
                    .toList();
              } else {
                //uses simple_search_value filter
                late final Map<String, dynamic> search;

                if (_prevSearchResult.containsKey('salesReps') &&
                    _prevSearchResult['salesReps']
                        .containsKey(textEditingValue.text)) {
                  //if input is already stored in previous search result
                  //then reuse that list
                  return _prevSearchResult['salesReps'][textEditingValue.text];
                } else {
                  //else then get a new list from API
                  search = await SalesOrderService.getSalesRepView(
                      sessionId: userProvider.user!.sessionId,
                      search: textEditingValue.text);
                  List<dynamic> resultSalesRep = search['salesReps'];
                  print('resultSalesRep: $resultSalesRep');
                  List<SalesRep> searchResult = resultSalesRep
                      .map((salesRepsList) => SalesRep(
                            salesRepId: salesRepsList[0],
                            salesRepCode: salesRepsList[1].toString(),
                            salesRepName: salesRepsList[2].toString(),
                          ))
                      .toList();

                  searchResult = searchResult
                      .where((salesRep) => salesRep
                          .contains(textEditingValue.text.toLowerCase()))
                      .toList();
                  addSalesRepsToList(searchResult);

                  //create the previous search result
                  if (!_prevSearchResult.containsKey('salesRep')) {
                    _prevSearchResult['salesReps'] = {};
                  }
                  _prevSearchResult['salesReps'][textEditingValue.text] =
                      searchResult;
                  return searchResult;
                }
              }
            } else {
              return [];
            }
          },
          fieldViewBuilder: (BuildContext context,
              TextEditingController fieldTextEditingController,
              FocusNode fieldFocusNode,
              VoidCallback onFieldSubmitted) {
            if (_salesRepClear) {
              fieldTextEditingController.clear();
              _salesRepClear = false;
            }
            return TextField(
                controller: fieldTextEditingController,
                focusNode: fieldFocusNode,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'Sales Representative',
                  labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: _salesRepErrorText != null
                            ? Colors.red
                            : Colors.grey),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.red,
                    ),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  errorText: _salesRepErrorText,
                  filled: true,
                  fillColor: brightness == Brightness.dark
                      ? Colors.grey[900]
                      : Colors.white,
                  suffixIcon: Visibility(
                    visible: fieldTextEditingController.text.isNotEmpty,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 25),
                      onPressed: () {
                        setState(() {
                          fieldTextEditingController.clear();
                          _selectedSalesRep = null;
                        });
                      },
                    ),
                  ),
                ),
                onSubmitted: (value) {
                  onFieldSubmitted();
                  setState(() {
                    _selectedSalesRep = _salesReps.firstWhere((salesRep) =>
                        salesRep.containsStringValue(value) != null);
                  });
                },
                onTap: () {
                  setState(() {
                    _salesRepErrorText = null;
                  });
                });
          },
          optionsViewBuilder: (BuildContext context,
              AutocompleteOnSelected<SalesRep> onSelected,
              Iterable<SalesRep> options) {
            if (_salesRepJumpLoadMore) {
              options = _salesReps;
            }
            return Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 200.0,
                height: MediaQuery.of(context).size.height / 2,
                child: Material(
                  elevation: 4.0,
                  child: ListView.builder(
                    controller: salesRepScrollController,
                    itemCount: options.length + 1,
                    itemBuilder: (BuildContext context, int index) {
                      if (index == options.length) {
                        return Stack(
                          children: [
                            Align(
                                alignment: Alignment.center,
                                child: Visibility(
                                  visible: _salesRepsHasMore,
                                  child: ValueListenableBuilder<bool>(
                                    valueListenable: _salesRepIsLoadingMore,
                                    builder: (BuildContext context,
                                        bool salesRepIsLoadingMore,
                                        Widget? child) {
                                      return ElevatedButton(
                                          onPressed: () async {
                                            setState(() {
                                              _salesRepIsLoadingMore.value =
                                                  true;
                                            });
                                            final result =
                                                await SalesOrderService
                                                    .getSalesRepView(
                                                        sessionId: userProvider
                                                            .user!.sessionId,
                                                        recordOffset:
                                                            _loadedSalesReps);
                                            List<dynamic> resultSalesRep =
                                                result['salesReps'];
                                            List<SalesRep> searchResult =
                                                resultSalesRep
                                                    .map((salesRepsList) =>
                                                        SalesRep(
                                                          salesRepId:
                                                              salesRepsList[0],
                                                          salesRepCode:
                                                              salesRepsList[1]
                                                                  .toString(),
                                                          salesRepName:
                                                              salesRepsList[2]
                                                                  .toString(),
                                                        ))
                                                    .toList();
                                            setState(() {
                                              // _salesReps.addAll(
                                              //     searchResult);
                                              addSalesRepsToList(searchResult);
                                              _salesRepsHasMore =
                                                  result['hasMore'];
                                              _loadedSalesReps +=
                                                  _salesReps.length;
                                              _salesRepIsLoadingMore.value =
                                                  false;
                                              _salesRepClear = true;
                                              _salesRepLoadMoreCounter++;
                                              _salesRepJumpLoadMore = true;
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              elevation: 0),
                                          child: salesRepIsLoadingMore
                                              ? const CircularProgressIndicator()
                                              : const Text('Load More',
                                                  style: TextStyle(
                                                      color: Colors.grey)));
                                    },
                                  ),
                                )),
                            Align(
                              alignment: Alignment.center,
                              child: Visibility(
                                  visible: !_salesRepsHasMore,
                                  child: const Text('End of Results')),
                            ),
                          ],
                        );
                      } else {
                        final SalesRep option = options.elementAt(index);
                        final bool highlight =
                            AutocompleteHighlightedOption.of(context) == index;
                        if (highlight && salesRepScrollController.hasClients) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_salesRepJumpLoadMore) {
                              salesRepScrollController.jumpTo(
                                  (_salesRepLoadMoreCounter * 15) * 56.0);
                              _debtorJumpLoadMore = false;
                            } else {
                              salesRepScrollController.animateTo(
                                index * 56.0,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                              );
                            }

                            salesRepScrollController.animateTo(
                              index * 56.0,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                            );
                          });
                        }

                        return InkWell(
                          onTap: () {
                            onSelected(option);
                            setState(() {
                              _selectedSalesRep = option;
                            });
                          },
                          child: ListTile(
                            tileColor: highlight
                                ? Theme.of(context).focusColor.withOpacity(0.1)
                                : null,
                            title: Text(option.salesRepName,
                                style: const TextStyle(fontSize: 12)),
                            subtitle: Text(option.salesRepCode,
                                style: const TextStyle(fontSize: 12)),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            );
          }),
    );

    Widget itemsRowWidget(int index) {
      return Column(
        children: [
          const Divider(),
          Row(
            children: [
              Text('${index + 1}.',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(
                width: 5,
              ),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _itemsLineNumberControllerList[index],
                            enabled: false,
                            decoration: InputDecoration(
                              disabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: MediaQuery.of(context)
                                                .platformBrightness ==
                                            Brightness.dark
                                        ? Colors.black
                                        : Colors.transparent),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              labelText: 'Line Number',
                              labelStyle: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              filled: true,
                              fillColor: brightness == Brightness.dark
                                  ? Colors.grey[900]
                                  : Colors.white,
                              suffixIcon: Visibility(
                                visible: _itemsLineNumberControllerList[index]
                                    .text
                                    .isNotEmpty,
                                child: IconButton(
                                  focusNode: FocusNode(skipTraversal: true),
                                  icon: const Icon(Icons.close, size: 25),
                                  onPressed: () {
                                    setState(() {
                                      _itemsLineNumberControllerList[index]
                                          .clear();
                                    });
                                  },
                                ),
                              ),
                            ),
                            onChanged: (text) {
                              setState(() {});
                            },
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: false),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                          ),
                        ),
                        const SizedBox(
                          width: 15,
                        ),

                        //Item Dropdown
                        Expanded(
                          child: Stack(children: [
                            TextField(
                              enabled: false,
                              focusNode: _itemFocusNode,
                              controller: _itemsControllerList[index],
                              style: TextStyle(
                                  fontSize: 12,
                                  color: MediaQuery.of(context)
                                              .platformBrightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black),
                              decoration: InputDecoration(
                                disabledBorder: OutlineInputBorder(
                                  borderSide:
                                      const BorderSide(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                labelText: 'Item (Click to choose)',
                                labelStyle: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                                enabledBorder: OutlineInputBorder(
                                  borderSide:
                                      const BorderSide(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: _itemsErrorText[index] != null
                                          ? Colors.red
                                          : Colors.grey),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                  ),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                errorText: _itemsErrorText[index],
                                errorStyle: const TextStyle(color: Colors.red),
                                filled: true,
                                fillColor: brightness == Brightness.dark
                                    ? Colors.grey[900]
                                    : Colors.white,
                              ),
                            ),
                            StatefulBuilder(builder:
                                (BuildContext context, StateSetter setState) {
                              return Row(children: [
                                Expanded(
                                    child: InkWell(
                                        onTap: () async {
                                          this.setState(() {
                                            _itemsErrorText[index] = null;
                                          });
                                          final item = await showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                List<dynamic> mainList =
                                                    salesOrderItemsProvider
                                                        .items;
                                                List<dynamic> subList =
                                                    mainList;
                                                return StatefulBuilder(builder:
                                                    (BuildContext context,
                                                        StateSetter setState) {
                                                  return SimpleDialog(
                                                    title: SizedBox(
                                                        height: 30,
                                                        width: 200,
                                                        child: TextField(
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 12),
                                                          decoration:
                                                              const InputDecoration(
                                                            contentPadding:
                                                                EdgeInsets.zero,
                                                            hintText: 'Search',
                                                            hintStyle:
                                                                TextStyle(
                                                                    fontSize:
                                                                        12),
                                                            prefixIcon: Icon(
                                                                Icons.search),
                                                            border:
                                                                OutlineInputBorder(
                                                              borderRadius: BorderRadius
                                                                  .all(Radius
                                                                      .circular(
                                                                          30.0)),
                                                            ),
                                                          ),
                                                          onChanged: (text) {
                                                            setState(() {
                                                              final searchText =
                                                                  text.toLowerCase();
                                                              subList = mainList
                                                                  .where(
                                                                      (item) {
                                                                return item.any((value) => value
                                                                    .toString()
                                                                    .toLowerCase()
                                                                    .contains(
                                                                        searchText));
                                                              }).toList();
                                                            });
                                                          },
                                                        )),
                                                    children: [
                                                      const Divider(),
                                                      SizedBox(
                                                        height: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .height -
                                                            200,
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width -
                                                            100,
                                                        child: Column(
                                                          children: [
                                                            Expanded(
                                                              child:
                                                                  mobileSalesOrderItems(
                                                                items: subList,
                                                                clickable: true,
                                                              ),
                                                            ),
                                                            const Divider(),
                                                            Stack(
                                                              children: [
                                                                Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  child:
                                                                      Visibility(
                                                                    visible:
                                                                        itemsHasMore,
                                                                    child: ElevatedButton(
                                                                        onPressed: () async {
                                                                          setState(
                                                                              () {
                                                                            isLoadingMore =
                                                                                true;
                                                                          });
                                                                          final data = await SalesOrderService.getItemView(
                                                                              sessionId: userProvider.user!.sessionId,
                                                                              recordOffset: salesOrderItemsProvider.loadedItems);
                                                                          if (mounted) {
                                                                            bool
                                                                                salesOrderFlag =
                                                                                handleSessionExpiredException(data, context);
                                                                            if (!salesOrderFlag) {
                                                                              final List<dynamic> newSalesOrderItems = data['items'];
                                                                              salesOrderItemsProvider.setItemsHasMore(hasMore: data['hasMore']);
                                                                              salesOrderItemsProvider.incLoadedItems(resultLength: newSalesOrderItems.length);
                                                                              salesOrderItemsProvider.addItems(items: newSalesOrderItems);
                                                                              setState(() {
                                                                                items = salesOrderItemsProvider.items;
                                                                                isLoadingMore = false;
                                                                                itemsHasMore = salesOrderItemsProvider.hasMore;
                                                                              });
                                                                            }
                                                                          }
                                                                        },
                                                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, elevation: 0),
                                                                        child: isLoadingMore ? const CircularProgressIndicator() : const Text('Load More', style: TextStyle(color: Colors.grey))),
                                                                  ),
                                                                ),
                                                                Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  child: Visibility(
                                                                      visible:
                                                                          !itemsHasMore,
                                                                      child: const Text(
                                                                          'End of Results')),
                                                                ),
                                                              ],
                                                            ),
                                                            const Divider(),
                                                          ],
                                                        ),
                                                      )
                                                    ],
                                                  );
                                                });
                                              });
                                          if (item != null) {
                                            setState(() {
                                              _selectedItem[index] = item;
                                              _itemsUnitControllerList[index]
                                                  .text = item[5];
                                              _itemsControllerList[index].text =
                                                  item[2];
                                            });
                                          }
                                        },
                                        child: const SizedBox(height: 51))),
                                Visibility(
                                  visible: _itemsControllerList[index]
                                      .text
                                      .isNotEmpty,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, size: 25),
                                    onPressed: () {
                                      setState(() {
                                        _selectedItem[index] = [null];
                                        _itemsUnitControllerList[index].clear();
                                        _itemsControllerList[index].clear();
                                      });
                                    },
                                  ),
                                ),
                              ]);
                            }),
                          ]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            enabled: false,
                            controller: _itemsUnitControllerList[index],
                            decoration: InputDecoration(
                              labelText: 'Unit',
                              labelStyle: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: MediaQuery.of(context)
                                                .platformBrightness ==
                                            Brightness.dark
                                        ? Colors.black
                                        : Colors.transparent),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              filled: true,
                              fillColor: brightness == Brightness.dark
                                  ? Colors.grey[900]
                                  : Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 15,
                        ),
                        Expanded(
                          child: StatefulBuilder(builder:
                              (BuildContext context, StateSetter setState) {
                            return TextField(
                              controller: _itemsQuantityControllerList[index],
                              decoration: InputDecoration(
                                labelText: 'Quantity',
                                labelStyle: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                                enabledBorder: OutlineInputBorder(
                                  borderSide:
                                      const BorderSide(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: _itemQtyErrorText[index] != null
                                          ? Colors.red
                                          : Colors.grey),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                  ),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                errorText: _itemQtyErrorText[index],
                                errorStyle: const TextStyle(color: Colors.red),
                                filled: true,
                                fillColor: brightness == Brightness.dark
                                    ? Colors.grey[900]
                                    : Colors.white,
                                suffixIcon: Visibility(
                                  visible: _itemsQuantityControllerList[index]
                                      .text
                                      .isNotEmpty,
                                  child: IconButton(
                                    focusNode: FocusNode(skipTraversal: true),
                                    icon: const Icon(Icons.close, size: 25),
                                    onPressed: () {
                                      setState(() {
                                        _itemsQuantityControllerList[index]
                                            .clear();
                                      });
                                    },
                                  ),
                                ),
                              ),
                              onChanged: (text) {
                                setState(() {});
                              },
                              onTap: () {
                                this.setState(() {
                                  _itemQtyErrorText[index] = null;
                                });
                              },
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: false),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: StatefulBuilder(builder:
                              (BuildContext context, StateSetter setState) {
                            return TextField(
                              enabled: false,
                              controller: _conversionFactorController,
                              decoration: InputDecoration(
                                labelText: 'Conversion Factor',
                                labelStyle: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                                enabledBorder: OutlineInputBorder(
                                  borderSide:
                                      const BorderSide(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: MediaQuery.of(context)
                                                  .platformBrightness ==
                                              Brightness.dark
                                          ? Colors.black
                                          : Colors.transparent),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide:
                                      const BorderSide(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                filled: true,
                                fillColor: brightness == Brightness.dark
                                    ? Colors.grey[900]
                                    : Colors.white,
                                suffixIcon: Visibility(
                                  visible: _conversionFactorController
                                      .text.isNotEmpty,
                                  child: IconButton(
                                    focusNode: FocusNode(skipTraversal: true),
                                    icon: const Icon(Icons.close, size: 25),
                                    onPressed: () {
                                      setState(() {
                                        _conversionFactorController.clear();
                                      });
                                    },
                                  ),
                                ),
                              ),
                              onChanged: (text) {
                                setState(() {});
                              },
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                            );
                          }),
                        ),
                        const SizedBox(
                          width: 15,
                        ),
                        Expanded(
                          flex: 1,
                          child: StatefulBuilder(builder:
                              (BuildContext context, StateSetter setState) {
                            return TextField(
                              controller: _itemsPriceControllerList[index],
                              decoration: InputDecoration(
                                labelText: 'Base Selling Price',
                                labelStyle: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                                enabledBorder: OutlineInputBorder(
                                  borderSide:
                                      const BorderSide(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: _itemBaseSellingPriceErrorText[
                                                  index] !=
                                              null
                                          ? Colors.red
                                          : Colors.grey),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                  ),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                errorText:
                                    _itemBaseSellingPriceErrorText[index],
                                errorStyle: const TextStyle(color: Colors.red),
                                filled: true,
                                fillColor: brightness == Brightness.dark
                                    ? Colors.grey[900]
                                    : Colors.white,
                                suffixIcon: Visibility(
                                  visible: _itemsPriceControllerList[index]
                                      .text
                                      .isNotEmpty,
                                  child: IconButton(
                                    focusNode: FocusNode(skipTraversal: true),
                                    icon: const Icon(Icons.close, size: 25),
                                    onPressed: () {
                                      setState(() {
                                        _itemsPriceControllerList[index]
                                            .clear();
                                      });
                                    },
                                  ),
                                ),
                              ),
                              onChanged: (text) {
                                setState(() {});
                              },
                              onTap: () {
                                this.setState(() {
                                  _itemBaseSellingPriceErrorText[index] = null;
                                });
                              },
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Visibility(
              visible: index != 0,
              child: InkWell(
                onTap: () {
                  setState(() {
                    removedIndex.add(index);
                    _itemIsActive[index] = false;
                    _itemsControllerList[index].clear();
                    _itemsUnitControllerList[index].clear();
                    _itemsQuantityControllerList[index].clear();
                    _itemsPriceControllerList[index].clear();
                  });
                },
                child: const Text('Remove',
                    style: TextStyle(fontSize: 12, color: Colors.red)),
              ),
            ),
          ),
        ],
      );
    }

    Widget addItemButtonWidget = InkWell(
      onTap: () {
        setState(() {
          _itemIsActive.add(true);
          addItem();
        });
      },
      child: Column(
        children: [
          Text(
            'Add Item',
            style: TextStyle(
                color: brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black),
          ),
          const SizedBox(height: 0.3),
          Container(
            height: 1,
            width: 70,
            color: brightness == Brightness.dark ? Colors.white : Colors.black,
          ),
        ],
      ),
    );

    Widget createButtonWidget = Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          // backgroundColor: const Color(0xFF795FCD),
          backgroundColor: Colors.blueGrey,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () async {
          setState(() {
            _isCreating = true;
          });
          bool proceed = true;
          String? reference = _referenceController.text.isNotEmpty
              ? _referenceController.text
              : null;

          String? soDate = _salesOrderDate?.toLocal().toIso8601String();
          if (soDate == null) {
            // showToast('Sales Order Date is empty');
            proceed = false;
            _salesOrderDateErrorText = _salesOrderDateNotValid
                ? 'Sales Order Date is not valid'
                : 'Sales Order Date is empty';
          }

          String? deliveryDate = _salesOrderDelvDate?.toLocal().toIso8601String();
          if (deliveryDate == null) {
            // showToast('Delivery Date is empty');
            proceed = false;
            _salesOrderDelvDateErrorText = _salesOrderDelvDateNotValid
                ? 'Delivery Date is not valid'
                : 'Delivery Date is empty';
          }
          // final debtorID = double.parse(_selectedDebtor[0].toString());
          // final whsID = double.parse(_selectedWarehouse[0].toString());
          // final topID = double.parse(_selectedTOP[0].toString());
          // final salesrepID =
          //     double.parse(_selectedSalesRep[0].toString());

          // final debtorID = _selectedDebtor[0].toDouble();
          // final whsID = _selectedWarehouse[0].toDouble();
          // final topID = _selectedTOP[0].toDouble();
          // final salesrepID = _selectedSalesRep[0].toDouble();

          double? debtorID =
              _selectedDebtor != null ? _selectedDebtor!.debtorId : null;
          if (debtorID == null) {
            // showToast('Debtor is empty');
            proceed = false;
            _debtorErrorText = 'Debtor is empty';
          }

          double? whsID =
              _selectedWarehouse != null ? _selectedWarehouse!.whsId : null;
          if (whsID == null) {
            // showToast('Warehouse is empty');
            proceed = false;
            _warehouseErrorText = 'Warehouse is empty';
          }

          double? topID = _selectedTOP != null ? _selectedTOP!.topId : null;
          if (topID == null) {
            // showToast('Terms of Payment is empty');
            proceed = false;
            _topErrorText = 'Terms of Payment is empty';
          }

          double? salesrepID =
              _selectedSalesRep != null ? _selectedSalesRep!.salesRepId : null;
          if (salesrepID == null) {
            // showToast('Sales Representative is empty');
            proceed = false;
            _salesRepErrorText = 'Sales Representative is empty';
          }

          // final itemID = _selectedItem[0];

          String? particulars = _particularsController.text.isNotEmpty
              ? _particularsController.text
              : null;
          // CHECK THE removedIndex LIST
          List<dynamic> lines = [];

          for (int index = 0; index < _itemIsActive.length; index++) {
            if (!removedIndex.contains(index + 1)) {
              int? lnNum =
                  int.tryParse(_itemsLineNumberControllerList[index].text);
              int? itemID = _selectedItem.length > index
                  ? int.tryParse(_selectedItem[index][0].toString())
                  : null;
              String? soUnit = _itemsUnitControllerList[index].text;
              int? qty = int.tryParse(_itemsQuantityControllerList[index].text);
              int? conversionFactor =
                  int.tryParse(_conversionFactorController.text);
              double? baseSellingPrice =
                  double.tryParse(_itemsPriceControllerList[index].text);

              if (itemID == null) {
                setState(() {
                  _itemsErrorText[index] = 'Item is empty';
                });
                proceed = false;
                // break;
              }
              if (qty == null) {
                setState(() {
                  _itemQtyErrorText[index] = 'Quantity is empty';
                });

                proceed = false;
                // break;
              }
              if (baseSellingPrice == null) {
                setState(() {
                  _itemBaseSellingPriceErrorText[index] = 'Price is empty';
                });
                proceed = false;
                // break;
              }

              lines.add({
                'lnNum': lnNum,
                'itemID': itemID,
                'soUnit': soUnit,
                'qty': qty,
                'conversionFactor': conversionFactor,
                'baseSellingPrice': baseSellingPrice,
              });
            }
          }
          if (proceed) {
            await SalesOrderService.createSalesOrder(
              sessionId: userProvider.user!.sessionId,
              reference: reference,
              soDate: soDate,
              deliveryDate: deliveryDate,
              debtorID: debtorID,
              whsID: whsID,
              topID: topID,
              salesrepID: salesrepID,
              particulars: particulars,
              lines: lines,
            ).then((response) {
              if (response.statusCode == 200) {
                // showToast('Sales Order Created!', timeInSecForWeb: 5);
                showToastMessage('Sales Order Created!');
                try {
                  setState(() {
                    _referenceController.clear();
                    _salesOrderDate = null;
                    _salesOrderDateController.clear();
                    _salesOrderDelvDate = null;
                    _deliveryDateController.clear();
                    _debtorClear = true;
                    _warehouseClear = true;
                    _topClear = true;
                    _salesRepClear = true;
                    _particularsController.clear();
                    _conversionFactorController.clear();
                    _selectedDebtor = null;
                    _selectedWarehouse = null;
                    _selectedTOP = null;
                    _selectedSalesRep = null;
                    for (var controller in _itemsControllerList) {
                      controller.clear();
                    }
                    for (var controller in _itemsLineNumberControllerList) {
                      controller.clear();
                    }
                    _itemsLineNumberControllerList.clear();
                    for (var controller in _itemsUnitControllerList) {
                      controller.clear();
                    }
                    _itemsUnitControllerList.clear();
                    for (var controller in _itemsQuantityControllerList) {
                      controller.clear();
                    }
                    _itemsQuantityControllerList.clear();
                    for (var controller in _itemsPriceControllerList) {
                      controller.clear();
                    }
                    _itemsPriceControllerList.clear();
                    // _itemsRowList.clear();
                    // _addNewWidget();
                    addItem();
                    _itemIsActive.clear();
                    _itemIsActive.add(true);
                  });
                } catch (e) {
                  print('something errorrrrr: $e');
                }
              } else {
                showToastMessage(
                    'An Error Has Occured!\nstatus code: ${response.statusCode}\nbody: ${response.body}',
                    errorToast: true);
                if (kDebugMode) {
                  print(
                      'status code: ${response.statusCode}\nbody: ${response.body}');
                }
              }
            }).catchError((error) {
              showToastMessage('An Error Has Occured!: $error',
                  errorToast: true);
            });
          }
          setState(() {
            _isCreating = false;
          });
        },
        child: SizedBox(
          height: 51,
          child: Center(
            child: _isCreating
                ? const CircularProgressIndicator()
                : const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );

    Widget salesOrderDateCalendarWidget = Positioned(
      width: 300,
      child: CompositedTransformFollower(
        link: _layerLinkSalesOrderDate,
        showWhenUnlinked: false,
        offset: const Offset(-130.0, 60.0),
        child: Container(
          decoration: BoxDecoration(
            color: brightness == Brightness.dark ? Colors.black : Colors.white,
            border: Border.all(
              color:
                  brightness == Brightness.dark ? Colors.white : Colors.black,
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2010, 10, 16),
                lastDay: DateTime.utc(2050, 3, 14),
                focusedDay: _salesOrderfocusedDay,
                calendarFormat: _calendarFormat,
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Month',
                },
                selectedDayPredicate: (day) => isSameDay(_salesOrderDate, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _salesOrderDate = selectedDay;
                    _salesOrderfocusedDay = focusedDay;
                    _salesOrderDateController.text =
                        DateFormat('MM/dd/yyyy').format(_salesOrderDate!);
                    _showOverlaySalesOrderDate = false;
                  });
                },
                onPageChanged: (focusedDay) {
                  _salesOrderfocusedDay = focusedDay;
                },
              ),
              Align(
                  alignment: Alignment.topRight,
                  child: InkWell(
                      onTap: () {
                        setState(() {
                          _showOverlaySalesOrderDate = false;
                        });
                      },
                      child: const Icon(Icons.close)))
            ],
          ),
        ),
      ),
    );

    Widget salesOrderDelvDateCalendarWidget = Positioned(
      width: 300,
      child: CompositedTransformFollower(
        link: _layerLinkSalesOrderDelvDate,
        showWhenUnlinked: false,
        offset: const Offset(0.0, 60.0),
        child: Container(
          decoration: BoxDecoration(
            color: brightness == Brightness.dark ? Colors.black : Colors.white,
            border: Border.all(
              color:
                  brightness == Brightness.dark ? Colors.white : Colors.black,
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2010, 10, 16),
                lastDay: DateTime.utc(2050, 3, 14),
                focusedDay: _salesOrderDelvfocusedDay,
                calendarFormat: _calendarFormat,
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Month',
                },
                selectedDayPredicate: (day) =>
                    isSameDay(_salesOrderDelvDate, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _salesOrderDelvDate = selectedDay;
                    _salesOrderDelvfocusedDay = focusedDay;
                    _deliveryDateController.text =
                        DateFormat('MM/dd/yyyy').format(_salesOrderDelvDate!);
                    _showOverlaySalesOrderDelvDate = false;
                  });
                },
                onPageChanged: (focusedDay) {
                  _salesOrderDelvfocusedDay = focusedDay;
                },
              ),
              Align(
                  alignment: Alignment.topRight,
                  child: InkWell(
                      onTap: () {
                        setState(() {
                          _showOverlaySalesOrderDelvDate = false;
                        });
                      },
                      child: const Icon(Icons.close)))
            ],
          ),
        ),
      ),
    );

    return FocusScope(
      onKey: (node, event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.tab) {
            if (event.isShiftPressed) {
              node.previousFocus();
            } else {
              node.nextFocus();
            }
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      referenceWidget,
                      const SizedBox(
                        width: 15,
                      ),
                      salesOrderDateWidget
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      salesOrderDelvDateWidget,
                      const SizedBox(
                        width: 15,
                      ),
                      particularsWidget
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      //Debtor dropdown
                      debtorWidget,
                      const SizedBox(
                        width: 15,
                      ),
                      // Warehouse Dropdown
                      warehouseWidget
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Terms of Payment Dropdown
                      topWidget,
                      const SizedBox(
                        width: 15,
                      ),
                      // Sales Representative Dropdown
                      salesRepWidget
                    ],
                  ),
                  const SizedBox(height: 20),
                  //Items Row
                  Column(
                    children: List.generate(_itemIsActive.length, (index) {
                      if (_itemIsActive[index]) {
                        return itemsRowWidget(index);
                      } else {
                        return Container();
                      }
                    }),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  Row(children: [const Spacer(), addItemButtonWidget]),
                  const SizedBox(height: 20),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [createButtonWidget]),
                  const Divider(),
                ],
              ),
              if (_showOverlaySalesOrderDate) ...[salesOrderDateCalendarWidget],
              if (_showOverlaySalesOrderDelvDate) ...[
                salesOrderDelvDateCalendarWidget
              ]
            ],
          ),
        ),
      ),
    );
  }
}
