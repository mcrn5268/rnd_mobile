import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:provider/provider.dart';
import 'package:rnd_mobile/api/sales_order_api.dart';
import 'package:rnd_mobile/providers/items/items_provider.dart';
import 'package:rnd_mobile/providers/user_provider.dart';
import 'package:rnd_mobile/utilities/session_handler.dart';
import 'package:rnd_mobile/widgets/mobile/mob_sales_order_items.dart';
import 'package:rnd_mobile/widgets/toast.dart';

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
  final TextEditingController _debtorController = TextEditingController();
  final TextEditingController _warehouseController = TextEditingController();
  final TextEditingController _topController = TextEditingController();
  final TextEditingController _salesRepController = TextEditingController();
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _itemUnitController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _particularsController = TextEditingController();
  final TextEditingController _lineNumberController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _conversionFactorController =
      TextEditingController();
  final TextEditingController _sellingPriceController = TextEditingController();
  List<dynamic> _debtors = [];
  List<dynamic> _warehouse = [];
  List<dynamic> _tops = [];
  List<dynamic> _salesReps = [];
  int _loadedDebtors = 15;
  int _loadedWarehouse = 15;
  int _loadedTops = 15;
  int _loadedSalesReps = 15;
  bool _debtorsHasMore = true;
  bool _warehouseHasMore = true;
  bool _topsHasMore = true;
  bool _salesRepsHasMore = true;
  List<dynamic> _selectedDebtor = [];
  List<dynamic> _selectedWarehouse = [];
  List<dynamic> _selectedTOP = [];
  List<dynamic> _selectedSalesRep = [];
  List<dynamic> _selectedItem = [];
  final Map<String, dynamic> _prevSearchResult = {};
  final ValueNotifier<bool> _debtorIsLoadingMore = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _warehouseIsLoadingMore =
      ValueNotifier<bool>(false);
  final ValueNotifier<bool> _topIsLoadingMore = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _salesRepIsLoadingMore = ValueNotifier<bool>(false);
  DateTime? _salesOrderDate;
  DateTime? _salesOrderDelvDate;
  bool _isCreating = false;
  late final ItemsProvider salesOrderItemsProvider;
  bool isLoadingMore = false;
  late List<dynamic> items;
  late bool itemsHasMore;
  List<Widget> _itemsRowList = [];
  List<TextEditingController> _itemsLineNumberControllerList = [];
  List<TextEditingController> _itemsControllerList = [];
  List<TextEditingController> _itemsUnitControllerList = [];
  List<TextEditingController> _itemsQuantityControllerList = [];
  // List<TextEditingController> _itemsConversionControllerList = [];
  List<TextEditingController> _itemsPriceControllerList = [];
  List<dynamic> removedIndex = [];
  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProvider>(context, listen: false);
    _conversionFactorController.text = '1';
    salesOrderItemsProvider =
        Provider.of<ItemsProvider>(context, listen: false);
    items = salesOrderItemsProvider.items;
    itemsHasMore = salesOrderItemsProvider.hasMore;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addNewWidget();
    });
  }

  @override
  void dispose() {
    _salesOrderDateController.dispose();
    _deliveryDateController.dispose();
    _debtorController.dispose();
    _warehouseController.dispose();
    _topController.dispose();
    _salesRepController.dispose();
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
      if (controller == _salesOrderDateController) {
        _salesOrderDate = picked;
      } else if (controller == _deliveryDateController) {
        _salesOrderDelvDate = picked;
      }
      final formattedDate = DateFormat('yyyy/MM/dd').format(picked);
      setState(() {
        controller.text = formattedDate;
      });
    }
  }

  void _addNewWidget() {
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
    int itemIndex = _itemsRowList.length;
    _itemsLineNumberControllerList[itemIndex].text =
        _itemsLineNumberControllerList.length.toString();
    _selectedItem.insert(itemIndex, [null]);
    setState(() {
      _itemsRowList.add(
        Column(
          children: [
            const Divider(),
            Row(
              children: [
                Text('${itemIndex + 1}.',
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
                              controller:
                                  _itemsLineNumberControllerList[itemIndex],
                              enabled: false,
                              decoration: InputDecoration(
                                disabledBorder: OutlineInputBorder(
                                  borderSide:
                                      const BorderSide(color: Colors.black),
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
                                fillColor:
                                    MediaQuery.of(context).platformBrightness ==
                                            Brightness.dark
                                        ? Colors.grey[900]
                                        : Colors.white,
                                suffixIcon: Visibility(
                                  visible:
                                      _itemsLineNumberControllerList[itemIndex]
                                          .text
                                          .isNotEmpty,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, size: 25),
                                    onPressed: () {
                                      setState(() {
                                        _itemsLineNumberControllerList[
                                                itemIndex]
                                            .clear();
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
                                controller: _itemsControllerList[itemIndex],
                                style: const TextStyle(fontSize: 12),
                                decoration: InputDecoration(
                                  labelText: 'Item',
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
                                  fillColor: MediaQuery.of(context)
                                              .platformBrightness ==
                                          Brightness.dark
                                      ? Colors.grey[900]
                                      : Colors.white,
                                ),
                                // onChanged: (text) {
                                //   setState(() {});
                                // },
                              ),
                              StatefulBuilder(builder:
                                  (BuildContext context, StateSetter setState) {
                                return Row(children: [
                                  Expanded(
                                      child: InkWell(
                                          onTap: () async {
                                            final item = await showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  List<dynamic> mainList =
                                                      salesOrderItemsProvider
                                                          .items;
                                                  List<dynamic> subList =
                                                      mainList;
                                                  return StatefulBuilder(
                                                      builder:
                                                          (BuildContext context,
                                                              StateSetter
                                                                  setState) {
                                                    return SimpleDialog(
                                                      title: SizedBox(
                                                          height: 30,
                                                          width: 200,
                                                          child: TextField(
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        12),
                                                            decoration:
                                                                const InputDecoration(
                                                              contentPadding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              hintText:
                                                                  'Search',
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
                                                                  items:
                                                                      subList,
                                                                  clickable:
                                                                      true,
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
                                                                            setState(() {
                                                                              isLoadingMore = true;
                                                                            });
                                                                            final data =
                                                                                await SalesOrderService.getItemView(sessionId: userProvider.user!.sessionId, recordOffset: salesOrderItemsProvider.loadedItems);
                                                                            if (mounted) {
                                                                              bool salesOrderFlag = handleSessionExpiredException(data, context);
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
                                                _selectedItem[itemIndex] = item;
                                                _itemsUnitControllerList[
                                                        itemIndex]
                                                    .text = item[5];
                                                _itemsControllerList[itemIndex]
                                                    .text = item[2];
                                              });
                                            }
                                          },
                                          child: const SizedBox(height: 51))),
                                  Visibility(
                                    visible: _itemsControllerList[itemIndex]
                                        .text
                                        .isNotEmpty,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, size: 25),
                                      onPressed: () {
                                        setState(() {
                                          _selectedItem[itemIndex] = [null];
                                          _itemsUnitControllerList[itemIndex]
                                              .clear();
                                          _itemsControllerList[itemIndex]
                                              .clear();
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
                              controller: _itemsUnitControllerList[itemIndex],
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
                                  borderSide:
                                      const BorderSide(color: Colors.black),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide:
                                      const BorderSide(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                filled: true,
                                fillColor:
                                    MediaQuery.of(context).platformBrightness ==
                                            Brightness.dark
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
                                controller:
                                    _itemsQuantityControllerList[itemIndex],
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
                                    borderSide:
                                        const BorderSide(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  filled: true,
                                  fillColor: MediaQuery.of(context)
                                              .platformBrightness ==
                                          Brightness.dark
                                      ? Colors.grey[900]
                                      : Colors.white,
                                  suffixIcon: Visibility(
                                    visible:
                                        _itemsQuantityControllerList[itemIndex]
                                            .text
                                            .isNotEmpty,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, size: 25),
                                      onPressed: () {
                                        setState(() {
                                          _itemsQuantityControllerList[
                                                  itemIndex]
                                              .clear();
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
                                    borderSide:
                                        const BorderSide(color: Colors.black),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide:
                                        const BorderSide(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  filled: true,
                                  fillColor: MediaQuery.of(context)
                                              .platformBrightness ==
                                          Brightness.dark
                                      ? Colors.grey[900]
                                      : Colors.white,
                                  suffixIcon: Visibility(
                                    visible: _conversionFactorController
                                        .text.isNotEmpty,
                                    child: IconButton(
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
                                controller:
                                    _itemsPriceControllerList[itemIndex],
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
                                    borderSide:
                                        const BorderSide(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  filled: true,
                                  fillColor: MediaQuery.of(context)
                                              .platformBrightness ==
                                          Brightness.dark
                                      ? Colors.grey[900]
                                      : Colors.white,
                                  suffixIcon: Visibility(
                                    visible:
                                        _itemsPriceControllerList[itemIndex]
                                            .text
                                            .isNotEmpty,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, size: 25),
                                      onPressed: () {
                                        setState(() {
                                          _itemsPriceControllerList[itemIndex]
                                              .clear();
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
                visible: itemIndex != 0,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      removedIndex.add(itemIndex);
                      _itemsRowList[itemIndex] = Container();
                      _itemsControllerList[itemIndex].clear();
                      _itemsUnitControllerList[itemIndex].clear();
                      _itemsQuantityControllerList[itemIndex].clear();
                      _itemsPriceControllerList[itemIndex].clear();
                    });
                  },
                  child: const Text('Remove',
                      style: TextStyle(fontSize: 12, color: Colors.red)),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _referenceController,
                    decoration: InputDecoration(
                      labelText: 'Reference',
                      labelStyle:
                          const TextStyle(fontSize: 12, color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      filled: true,
                      fillColor: MediaQuery.of(context).platformBrightness ==
                              Brightness.dark
                          ? Colors.grey[900]
                          : Colors.white,
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
                ),
                const SizedBox(
                  width: 15,
                ),
                Expanded(
                  child: TextField(
                    controller: _salesOrderDateController,
                    decoration: InputDecoration(
                      labelText: 'Sales Order Date',
                      labelStyle:
                          const TextStyle(fontSize: 12, color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      filled: true,
                      fillColor: MediaQuery.of(context).platformBrightness ==
                              Brightness.dark
                          ? Colors.grey[900]
                          : Colors.white,
                      suffixIcon: Visibility(
                        visible: _salesOrderDateController.text.isNotEmpty,
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 25),
                          onPressed: () {
                            setState(() {
                              _salesOrderDateController.clear();
                            });
                          },
                        ),
                      ),
                    ),
                    readOnly: true,
                    onTap: () =>
                        _selectDate(context, _salesOrderDateController),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _deliveryDateController,
                    decoration: InputDecoration(
                      labelText: 'Delivery Date',
                      labelStyle:
                          const TextStyle(fontSize: 12, color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      filled: true,
                      fillColor: MediaQuery.of(context).platformBrightness ==
                              Brightness.dark
                          ? Colors.grey[900]
                          : Colors.white,
                      suffixIcon: Visibility(
                        visible: _deliveryDateController.text.isNotEmpty,
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 25),
                          onPressed: () {
                            setState(() {
                              _deliveryDateController.clear();
                            });
                          },
                        ),
                      ),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context, _deliveryDateController),
                  ),
                ),
                const SizedBox(
                  width: 15,
                ),
                Expanded(
                  child: TextField(
                    controller: _particularsController,
                    decoration: InputDecoration(
                      labelText: 'Particulars',
                      labelStyle:
                          const TextStyle(fontSize: 12, color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      filled: true,
                      fillColor: MediaQuery.of(context).platformBrightness ==
                              Brightness.dark
                          ? Colors.grey[900]
                          : Colors.white,
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
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                //Debtor dropdown
                Expanded(
                  child: TypeAheadFormField<dynamic>(
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: _debtorController,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        labelText: 'Debtor',
                        labelStyle:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        filled: true,
                        fillColor: MediaQuery.of(context).platformBrightness ==
                                Brightness.dark
                            ? Colors.grey[900]
                            : Colors.white,
                        suffixIcon: Visibility(
                          visible: _debtorController.text.isNotEmpty,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 25),
                            onPressed: () {
                              setState(() {
                                _debtorController.clear();
                              });
                            },
                          ),
                        ),
                      ),
                      onSubmitted: (value) async {
                        bool salesOrderFlag = false;
                        if (_debtors.isEmpty) {
                          final result = await SalesOrderService.getDebtorView(
                              sessionId: userProvider.user!.sessionId);

                          _debtors = result['debtors'];
                          _debtorsHasMore = result['hasMore'];
                          //for checking if session is still valid
                          if (context.mounted) {
                            salesOrderFlag = handleSessionExpiredException(
                                _debtors[0], context);
                          }
                        }
                        //if session is still valid
                        if (!salesOrderFlag) {
                          late final dynamic closestMatch;
                          //if input already exists from previous search result
                          //if yes then use the list to get the item/option
                          if (_prevSearchResult.containsKey('debtor') &&
                              _prevSearchResult['debtor'].containsKey(value)) {
                            closestMatch = _prevSearchResult['debtor'][value]
                                .firstWhere(
                                    (debtor) => debtor
                                        .toString()
                                        .toLowerCase()
                                        .contains(value.toLowerCase()),
                                    orElse: () => null);

                            _prevSearchResult['debtor']
                                [closestMatch[2]] = _prevSearchResult['debtor']
                                    [value]
                                .where((string) => string
                                    .toString()
                                    .toLowerCase()
                                    .contains(closestMatch[2].toLowerCase()))
                                .toList();
                          } else {
                            //else then use the main list
                            closestMatch = _debtors.firstWhere(
                                (debtor) => debtor
                                    .toString()
                                    .toLowerCase()
                                    .contains(value.toLowerCase()),
                                orElse: () => null);
                          }

                          _selectedDebtor = closestMatch;
                          if (closestMatch != null) {
                            setState(() {
                              _debtorController.text =
                                  closestMatch[2].toString();
                            });
                          }
                        }
                      },
                    ),
                    suggestionsCallback: (pattern) async {
                      bool salesOrderFlag = false;
                      //first time loading data
                      if (_debtors.isEmpty) {
                        final result = await SalesOrderService.getDebtorView(
                            sessionId: userProvider.user!.sessionId);

                        _debtors = result['debtors'];
                        _debtorsHasMore = result['hasMore'];
                        //for checking if session is still valid
                        if (context.mounted) {
                          salesOrderFlag = handleSessionExpiredException(
                              _debtors[0], context);
                        }
                      }
                      //if session is still valid
                      if (!salesOrderFlag) {
                        if (_debtorController.text.isEmpty) {
                          //this is to add 1 more item at the end of the list
                          //the last item will be used for Load More button
                          List<dynamic> list = [];
                          list = _debtors
                              .where((debtor) => debtor
                                  .toString()
                                  .toLowerCase()
                                  .contains(pattern.toLowerCase()))
                              .toList();
                          list.add([]);
                          return list;
                        } else if (_debtorController.text.length < 2) {
                          //use main list for search if  input character <2
                          return _debtors
                              .where((debtor) => debtor
                                  .toString()
                                  .toLowerCase()
                                  .contains(pattern.toLowerCase()))
                              .toList();
                        } else {
                          //uses simple_search_value filter
                          late final Map<String, dynamic> search;

                          if (_prevSearchResult.containsKey('debtor') &&
                              _prevSearchResult['debtor']
                                  .containsKey(pattern)) {
                            //if input is already stored in previous search result
                            //then reuse that list
                            return _prevSearchResult['debtor'][pattern];
                          } else {
                            //else then get a new list from API
                            search = await SalesOrderService.getDebtorView(
                                sessionId: userProvider.user!.sessionId,
                                search: pattern);

                            List<dynamic> searchResult = search['debtors']
                                .where((debtor) => debtor
                                    .toString()
                                    .toLowerCase()
                                    .contains(pattern.toLowerCase()))
                                .toList();

                            //create the previous search result
                            if (!_prevSearchResult.containsKey('debtor')) {
                              _prevSearchResult['debtor'] = {};
                            }
                            _prevSearchResult['debtor'][pattern] = searchResult;
                            return searchResult;
                          }
                        }
                      } else {
                        return [];
                      }
                    },
                    itemBuilder: (BuildContext context, suggestion) {
                      if (suggestion.isEmpty) {
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
                                            setState(() {
                                              _debtors
                                                  .addAll(result['debtors']);
                                              _debtorsHasMore =
                                                  result['hasMore'];
                                              _loadedDebtors += _debtors.length;
                                              _debtorIsLoadingMore.value =
                                                  false;
                                              _debtorController.text = ' ';
                                              _debtorController.clear();
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
                        return ListTile(
                          title: Text(suggestion[2].toString(),
                              style: const TextStyle(fontSize: 12)),
                          subtitle: Text(suggestion[1].toString(),
                              style: const TextStyle(fontSize: 12)),
                        );
                      }
                    },
                    loadMore: _debtorIsLoadingMore.value,
                    noItemsFoundBuilder: (value) {
                      return const Center(child: Text('No Items'));
                    },
                    onSuggestionSelected: (suggestion) {
                      setState(() {
                        _debtorController.text = suggestion[2].toString();
                        _selectedDebtor = suggestion;
                      });
                    },
                  ),
                ),

                const SizedBox(
                  width: 15,
                ),

                // Warehouse Dropdown
                Expanded(
                  child: TypeAheadFormField<dynamic>(
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: _warehouseController,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        labelText: 'Warehouse',
                        labelStyle:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        filled: true,
                        fillColor: MediaQuery.of(context).platformBrightness ==
                                Brightness.dark
                            ? Colors.grey[900]
                            : Colors.white,
                        suffixIcon: Visibility(
                          visible: _warehouseController.text.isNotEmpty,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 25),
                            onPressed: () {
                              setState(() {
                                _warehouseController.clear();
                              });
                            },
                          ),
                        ),
                      ),
                      onSubmitted: (value) async {
                        bool salesOrderFlag = false;
                        if (_warehouse.isEmpty) {
                          final result =
                              await SalesOrderService.getWarehouseView(
                                  sessionId: userProvider.user!.sessionId);

                          _warehouse = result['warehouse'];
                          _warehouseHasMore = result['hasMore'];
                          //for checking if session is still valid
                          if (context.mounted) {
                            salesOrderFlag = handleSessionExpiredException(
                                _warehouse[0], context);
                          }
                        }
                        //if session is still valid
                        if (!salesOrderFlag) {
                          late final dynamic closestMatch;
                          //if input already exists from previous search result
                          //if yes then use the list to get the item/option
                          if (_prevSearchResult.containsKey('warehouse') &&
                              _prevSearchResult['warehouse']
                                  .containsKey(value)) {
                            closestMatch = _prevSearchResult['warehouse'][value]
                                .firstWhere(
                                    (warehouse) => warehouse
                                        .toString()
                                        .toLowerCase()
                                        .contains(value.toLowerCase()),
                                    orElse: () => null);

                            _prevSearchResult['warehouse'][closestMatch[2]] =
                                _prevSearchResult['warehouse'][value]
                                    .where((string) => string
                                        .toString()
                                        .toLowerCase()
                                        .contains(
                                            closestMatch[2].toLowerCase()))
                                    .toList();
                          } else {
                            //else then use the main list
                            closestMatch = _warehouse.firstWhere(
                                (warehouse) => warehouse
                                    .toString()
                                    .toLowerCase()
                                    .contains(value.toLowerCase()),
                                orElse: () => null);
                          }

                          _selectedWarehouse = closestMatch;
                          if (closestMatch != null) {
                            setState(() {
                              _warehouseController.text =
                                  closestMatch[2].toString();
                            });
                          }
                        }
                      },
                    ),
                    suggestionsCallback: (pattern) async {
                      bool salesOrderFlag = false;
                      //first time loading data
                      if (_warehouse.isEmpty) {
                        final result = await SalesOrderService.getWarehouseView(
                            sessionId: userProvider.user!.sessionId);

                        _warehouse = result['warehouse'];
                        _warehouseHasMore = result['hasMore'];
                        //for checking if session is still valid
                        if (context.mounted) {
                          salesOrderFlag = handleSessionExpiredException(
                              _warehouse[0], context);
                        }
                      }
                      //if session is still valid
                      if (!salesOrderFlag) {
                        if (_warehouseController.text.isEmpty) {
                          //this is to add 1 more item at the end of the list
                          //the last item will be used for Load More button
                          List<dynamic> list = [];
                          list = _warehouse
                              .where((warehouse) => warehouse
                                  .toString()
                                  .toLowerCase()
                                  .contains(pattern.toLowerCase()))
                              .toList();
                          list.add([]);
                          return list;
                        } else if (_warehouseController.text.length < 2) {
                          //use main list for search if  input character <2
                          return _warehouse
                              .where((warehouse) => warehouse
                                  .toString()
                                  .toLowerCase()
                                  .contains(pattern.toLowerCase()))
                              .toList();
                        } else {
                          //uses simple_search_value filter
                          late final Map<String, dynamic> search;

                          if (_prevSearchResult.containsKey('warehouse') &&
                              _prevSearchResult['warehouse']
                                  .containsKey(pattern)) {
                            //if input is already stored in previous search result
                            //then reuse that list
                            return _prevSearchResult['warehouse'][pattern];
                          } else {
                            //else then get a new list from API
                            search = await SalesOrderService.getWarehouseView(
                                sessionId: userProvider.user!.sessionId,
                                search: pattern);

                            List<dynamic> searchResult = search['warehouse']
                                .where((warehouse) => warehouse
                                    .toString()
                                    .toLowerCase()
                                    .contains(pattern.toLowerCase()))
                                .toList();

                            //create the previous search result
                            if (!_prevSearchResult.containsKey('warehouse')) {
                              _prevSearchResult['warehouse'] = {};
                            }
                            _prevSearchResult['warehouse'][pattern] =
                                searchResult;
                            return searchResult;
                          }
                        }
                      } else {
                        return [];
                      }
                    },
                    itemBuilder: (BuildContext context, suggestion) {
                      if (suggestion.isEmpty) {
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
                                            setState(() {
                                              _warehouse
                                                  .addAll(result['warehouse']);
                                              _warehouseHasMore =
                                                  result['hasMore'];
                                              _loadedWarehouse +=
                                                  _warehouse.length;
                                              _topIsLoadingMore.value = false;
                                              _topController.text = ' ';
                                              _topController.clear();
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
                        return ListTile(
                          title: Text(suggestion[2].toString(),
                              style: const TextStyle(fontSize: 12)),
                          subtitle: Text(suggestion[1].toString(),
                              style: const TextStyle(fontSize: 12)),
                        );
                      }
                    },
                    loadMore: _warehouseIsLoadingMore.value,
                    noItemsFoundBuilder: (value) {
                      return const Center(child: Text('No Items'));
                    },
                    onSuggestionSelected: (suggestion) {
                      setState(() {
                        _warehouseController.text = suggestion[2].toString();
                        _selectedWarehouse = suggestion;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // Terms of Payment Dropdown
                Expanded(
                  child: TypeAheadFormField<dynamic>(
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: _topController,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        labelText: 'Terms of Payment',
                        labelStyle:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        filled: true,
                        fillColor: MediaQuery.of(context).platformBrightness ==
                                Brightness.dark
                            ? Colors.grey[900]
                            : Colors.white,
                        suffixIcon: Visibility(
                          visible: _topController.text.isNotEmpty,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 25),
                            onPressed: () {
                              setState(() {
                                _topController.clear();
                              });
                            },
                          ),
                        ),
                      ),
                      onSubmitted: (value) async {
                        bool salesOrderFlag = false;
                        if (_tops.isEmpty) {
                          final result = await SalesOrderService.getTOPView(
                              sessionId: userProvider.user!.sessionId);

                          _tops = result['tops'];
                          _topsHasMore = result['hasMore'];
                          //for checking if session is still valid
                          if (context.mounted) {
                            salesOrderFlag = handleSessionExpiredException(
                                _tops[0], context);
                          }
                        }
                        //if session is still valid
                        if (!salesOrderFlag) {
                          late final dynamic closestMatch;
                          //if input already exists from previous search result
                          //if yes then use the list to get the item/option
                          if (_prevSearchResult.containsKey('top') &&
                              _prevSearchResult['top'].containsKey(value)) {
                            closestMatch = _prevSearchResult['top'][value]
                                .firstWhere(
                                    (tops) => tops
                                        .toString()
                                        .toLowerCase()
                                        .contains(value.toLowerCase()),
                                    orElse: () => null);

                            _prevSearchResult['top']
                                [closestMatch[2]] = _prevSearchResult['top']
                                    [value]
                                .where((string) => string
                                    .toString()
                                    .toLowerCase()
                                    .contains(closestMatch[2].toLowerCase()))
                                .toList();
                          } else {
                            //else then use the main list
                            closestMatch = _tops.firstWhere(
                                (tops) => tops
                                    .toString()
                                    .toLowerCase()
                                    .contains(value.toLowerCase()),
                                orElse: () => null);
                          }

                          _selectedTOP = closestMatch;
                          if (closestMatch != null) {
                            setState(() {
                              _topController.text = closestMatch[2].toString();
                            });
                          }
                        }
                      },
                    ),
                    suggestionsCallback: (pattern) async {
                      bool salesOrderFlag = false;
                      //first time loading data
                      if (_tops.isEmpty) {
                        final result = await SalesOrderService.getTOPView(
                            sessionId: userProvider.user!.sessionId);

                        _tops = result['tops'];
                        _topsHasMore = result['hasMore'];
                        //for checking if session is still valid
                        if (context.mounted) {
                          salesOrderFlag =
                              handleSessionExpiredException(_tops[0], context);
                        }
                      }
                      //if session is still valid
                      if (!salesOrderFlag) {
                        if (_topController.text.isEmpty) {
                          //this is to add 1 more item at the end of the list
                          //the last item will be used for Load More button
                          List<dynamic> list = [];
                          list = _tops
                              .where((top) => top
                                  .toString()
                                  .toLowerCase()
                                  .contains(pattern.toLowerCase()))
                              .toList();
                          list.add([]);
                          return list;
                        } else if (_topController.text.length < 2) {
                          //use main list for search if  input character <2
                          return _tops
                              .where((top) => top
                                  .toString()
                                  .toLowerCase()
                                  .contains(pattern.toLowerCase()))
                              .toList();
                        } else {
                          //uses simple_search_value filter
                          late final Map<String, dynamic> search;

                          if (_prevSearchResult.containsKey('top') &&
                              _prevSearchResult['top'].containsKey(pattern)) {
                            //if input is already stored in previous search result
                            //then reuse that list
                            return _prevSearchResult['top'][pattern];
                          } else {
                            //else then get a new list from API
                            search = await SalesOrderService.getTOPView(
                                sessionId: userProvider.user!.sessionId,
                                search: pattern);

                            List<dynamic> searchResult = search['top']
                                .where((top) => top
                                    .toString()
                                    .toLowerCase()
                                    .contains(pattern.toLowerCase()))
                                .toList();

                            //create the previous search result
                            if (!_prevSearchResult.containsKey('top')) {
                              _prevSearchResult['top'] = {};
                            }
                            _prevSearchResult['top'][pattern] = searchResult;
                            return searchResult;
                          }
                        }
                      } else {
                        return [];
                      }
                    },
                    itemBuilder: (BuildContext context, suggestion) {
                      if (suggestion.isEmpty) {
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
                                            setState(() {
                                              _tops.addAll(result['tops']);
                                              _topsHasMore = result['hasMore'];
                                              _loadedTops += _tops.length;
                                              _topIsLoadingMore.value = false;
                                              _topController.text = ' ';
                                              _topController.clear();
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
                        return ListTile(
                          title: Text(suggestion[2].toString(),
                              style: const TextStyle(fontSize: 12)),
                          subtitle: Text(suggestion[1].toString(),
                              style: const TextStyle(fontSize: 12)),
                        );
                      }
                    },
                    loadMore: _topIsLoadingMore.value,
                    noItemsFoundBuilder: (value) {
                      return const Center(child: Text('No Items'));
                    },
                    onSuggestionSelected: (suggestion) {
                      setState(() {
                        _topController.text = suggestion[2].toString();
                        _selectedTOP = suggestion;
                      });
                    },
                  ),
                ),

                const SizedBox(
                  width: 15,
                ),

                // Sales Representative Dropdown
                Expanded(
                  child: TypeAheadFormField<dynamic>(
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: _salesRepController,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        labelText: 'Sales Representative',
                        labelStyle:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        filled: true,
                        fillColor: MediaQuery.of(context).platformBrightness ==
                                Brightness.dark
                            ? Colors.grey[900]
                            : Colors.white,
                        suffixIcon: Visibility(
                          visible: _salesRepController.text.isNotEmpty,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 25),
                            onPressed: () {
                              setState(() {
                                _salesRepController.clear();
                              });
                            },
                          ),
                        ),
                      ),
                      onSubmitted: (value) async {
                        bool salesOrderFlag = false;
                        if (_salesReps.isEmpty) {
                          final result =
                              await SalesOrderService.getSalesRepView(
                                  sessionId: userProvider.user!.sessionId);

                          _salesReps = result['salesReps'];
                          _salesRepsHasMore = result['hasMore'];
                          //for checking if session is still valid
                          if (context.mounted) {
                            salesOrderFlag = handleSessionExpiredException(
                                _salesReps[0], context);
                          }
                        }
                        //if session is still valid
                        if (!salesOrderFlag) {
                          late final dynamic closestMatch;
                          //if input already exists from previous search result
                          //if yes then use the list to get the item/option
                          if (_prevSearchResult.containsKey('salesRep') &&
                              _prevSearchResult['salesRep']
                                  .containsKey(value)) {
                            closestMatch = _prevSearchResult['salesRep'][value]
                                .firstWhere(
                                    (salesRep) => salesRep
                                        .toString()
                                        .toLowerCase()
                                        .contains(value.toLowerCase()),
                                    orElse: () => null);

                            _prevSearchResult['salesRep'][closestMatch[2]] =
                                _prevSearchResult['salesRep'][value]
                                    .where((string) => string
                                        .toString()
                                        .toLowerCase()
                                        .contains(
                                            closestMatch[2].toLowerCase()))
                                    .toList();
                          } else {
                            //else then use the main list
                            closestMatch = _salesReps.firstWhere(
                                (salesRep) => salesRep
                                    .toString()
                                    .toLowerCase()
                                    .contains(value.toLowerCase()),
                                orElse: () => null);
                          }

                          _selectedSalesRep = closestMatch;
                          if (closestMatch != null) {
                            setState(() {
                              _salesRepController.text =
                                  closestMatch[2].toString();
                            });
                          }
                        }
                      },
                    ),
                    suggestionsCallback: (pattern) async {
                      bool salesOrderFlag = false;
                      //first time loading data
                      if (_salesReps.isEmpty) {
                        final result = await SalesOrderService.getSalesRepView(
                            sessionId: userProvider.user!.sessionId);

                        _salesReps = result['salesReps'];
                        _salesRepsHasMore = result['hasMore'];
                        //for checking if session is still valid
                        if (context.mounted) {
                          salesOrderFlag = handleSessionExpiredException(
                              _salesReps[0], context);
                        }
                      }
                      //if session is still valid

                      if (!salesOrderFlag) {
                        if (_salesRepController.text.isEmpty) {
                          //this is to add 1 more item at the end of the list
                          //the last item will be used for Load More button
                          List<dynamic> list = [];
                          list = _salesReps
                              .where((salesRep) => salesRep
                                  .toString()
                                  .toLowerCase()
                                  .contains(pattern.toLowerCase()))
                              .toList();
                          list.add([]);
                          return list;
                        } else if (_salesRepController.text.length < 2) {
                          //use main list for search if  input character <2
                          return _salesReps
                              .where((salesRep) => salesRep
                                  .toString()
                                  .toLowerCase()
                                  .contains(pattern.toLowerCase()))
                              .toList();
                        } else {
                          //uses simple_search_value filter
                          late final Map<String, dynamic> search;

                          if (_prevSearchResult.containsKey('salesRep') &&
                              _prevSearchResult['salesRep']
                                  .containsKey(pattern)) {
                            //if input is already stored in previous search result
                            //then reuse that list
                            return _prevSearchResult['salesRep'][pattern];
                          } else {
                            //else then get a new list from API
                            search = await SalesOrderService.getSalesRepView(
                                sessionId: userProvider.user!.sessionId,
                                search: pattern);

                            List<dynamic> searchResult = search['salesReps']
                                .where((salesRep) => salesRep
                                    .toString()
                                    .toLowerCase()
                                    .contains(pattern.toLowerCase()))
                                .toList();

                            //create the previous search result
                            if (!_prevSearchResult.containsKey('salesRep')) {
                              _prevSearchResult['salesRep'] = {};
                            }
                            _prevSearchResult['salesRep'][pattern] =
                                searchResult;
                            return searchResult;
                          }
                        }
                      } else {
                        return [];
                      }
                    },
                    itemBuilder: (BuildContext context, suggestion) {
                      if (suggestion.isEmpty) {
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
                                            setState(() {
                                              _salesReps
                                                  .addAll(result['salesReps']);
                                              _salesRepsHasMore =
                                                  result['hasMore'];
                                              _loadedSalesReps +=
                                                  _salesReps.length;
                                              _salesRepIsLoadingMore.value =
                                                  false;
                                              _salesRepController.text = ' ';
                                              _salesRepController.clear();
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
                        return ListTile(
                          title: Text(suggestion[2].toString(),
                              style: const TextStyle(fontSize: 12)),
                          subtitle: Text(suggestion[1].toString(),
                              style: const TextStyle(fontSize: 12)),
                        );
                      }
                    },
                    loadMore: _salesRepIsLoadingMore.value,
                    noItemsFoundBuilder: (value) {
                      return const Center(child: Text('No Items'));
                    },
                    onSuggestionSelected: (suggestion) {
                      setState(() {
                        _salesRepController.text = suggestion[2].toString();
                        _selectedSalesRep = suggestion;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Column(
              children: _itemsRowList,
            ),
            const SizedBox(height: 20),
            const Divider(),
            Row(children: [
              const Spacer(),
              InkWell(
                  onTap: () {
                    _addNewWidget();
                  },
                  child: InkWell(
                    onTap: () {
                      _addNewWidget();
                    },
                    child: Column(
                      children: [
                        Text(
                          'Add Item',
                          style: TextStyle(
                              color:
                                  MediaQuery.of(context).platformBrightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black),
                        ),
                        const SizedBox(height: 0.3),
                        Container(
                          height: 1,
                          width: 70,
                          color: MediaQuery.of(context).platformBrightness ==
                                  Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ],
                    ),
                  ))
            ]),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF795FCD),
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
                    String? soDate = _salesOrderDate?.toIso8601String();
                    if (soDate == null) {
                      showToast('Sales Order Date is empty');
                      proceed = false;
                    }

                    String? deliveryDate =
                        _salesOrderDelvDate?.toIso8601String();
                    if (deliveryDate == null) {
                      showToast('Delivery Date is empty');
                      proceed = false;
                    }
                    dynamic debtorID =
                        _selectedDebtor.isNotEmpty ? _selectedDebtor[0] : null;
                    if (debtorID == null) {
                      showToast('Debtor is empty');
                      proceed = false;
                    }

                    dynamic whsID = _selectedWarehouse.isNotEmpty
                        ? _selectedWarehouse[0]
                        : null;
                    if (whsID == null) {
                      showToast('Warehouse is empty');
                      proceed = false;
                    }

                    dynamic topID =
                        _selectedTOP.isNotEmpty ? _selectedTOP[0] : null;
                    if (topID == null) {
                      showToast('Terms of Payment is empty');
                      proceed = false;
                    }

                    dynamic salesrepID = _selectedSalesRep.isNotEmpty
                        ? _selectedSalesRep[0]
                        : null;
                    // -------------------------
                    // sales rep nullable?
                    // not sure
                    // -------------------------
                    // if (salesrepID == null) {
                    //   showToast('Sales Representative is empty');
                    //   proceed = false;
                    // }

                    String? particulars = _particularsController.text.isNotEmpty
                        ? _particularsController.text
                        : null;
                    // CHECK THE removedIndex LIST
                    List<dynamic> lines = [];

                    for (int index = 0; index < _itemsRowList.length; index++) {
                      if (!removedIndex.contains(index + 1)) {
                        int? lnNum = int.tryParse(
                            _itemsLineNumberControllerList[index].text);
                        int? itemID = _selectedItem.length > index
                            ? int.tryParse(_selectedItem[index][0].toString())
                            : null;
                        String? soUnit = _itemsUnitControllerList[index].text;
                        int? qty = int.tryParse(
                            _itemsQuantityControllerList[index].text);
                        int? conversionFactor =
                            int.tryParse(_conversionFactorController.text);
                        double? baseSellingPrice = double.tryParse(
                            _itemsPriceControllerList[index].text);

                        if (itemID == null) {
                          showToast('Item #${index + 1} is empty.');
                          proceed = false;
                          break;
                        }
                        if (qty == null) {
                          showToast('Item #${index + 1} has quantity empty.');
                          proceed = false;
                          break;
                        }
                        if (baseSellingPrice == null) {
                          showToast(
                              'Item #${index + 1} has Selling Price empty.');
                          proceed = false;
                          break;
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
                          showToast('Sales Order Created!', timeInSecForWeb: 5);

                          setState(() {
                            _referenceController.clear();
                            _salesOrderDate = null;
                            _salesOrderDateController.clear();
                            _salesOrderDelvDate = null;
                            _deliveryDateController.clear();
                            _debtorController.clear();
                            _warehouseController.clear();
                            _topController.clear();
                            _salesRepController.clear();
                            _particularsController.clear();
                            _conversionFactorController.clear();
                            for (var controller in _itemsControllerList) {
                              controller.clear();
                            }
                            for (var controller
                                in _itemsLineNumberControllerList) {
                              controller.clear();
                            }
                            _itemsLineNumberControllerList.clear();
                            for (var controller in _itemsUnitControllerList) {
                              controller.clear();
                            }
                            _itemsUnitControllerList.clear();
                            for (var controller
                                in _itemsQuantityControllerList) {
                              controller.clear();
                            }
                            _itemsQuantityControllerList.clear();
                            for (var controller in _itemsPriceControllerList) {
                              controller.clear();
                            }
                            _itemsPriceControllerList.clear();
                            _itemsRowList.clear();
                            _addNewWidget();
                          });
                        } else {
                          showToast('An Error Has Occured!');

                          if (kDebugMode) {
                            print(
                                'status code: ${response.statusCode}\nbody: ${response.body}');
                          }
                        }
                      }).catchError((error) {
                        showToast('An Error Has Occured!: $error');
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
                          : const Text('Create',
                              style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ]),
            const Divider(),
          ],
        ),
      ),
    );
  }
}
