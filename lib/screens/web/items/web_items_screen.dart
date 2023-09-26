import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rnd_mobile/api/sales_order_api.dart';
import 'package:rnd_mobile/providers/items/items_provider.dart';
import 'package:rnd_mobile/providers/user_provider.dart';
import 'package:rnd_mobile/utilities/session_handler.dart';
import 'package:rnd_mobile/widgets/web/web_reusable_row.dart';
import 'package:rnd_mobile/widgets/web/web_sales_order_items.dart';

class WebSalesOrderItemsScreen extends StatefulWidget {
  const WebSalesOrderItemsScreen({super.key});

  @override
  State<WebSalesOrderItemsScreen> createState() =>
      _WebSalesOrderItemsScreenState();
}

class _WebSalesOrderItemsScreenState extends State<WebSalesOrderItemsScreen> {
  late final UserProvider userProvider;
  late final ItemsProvider salesOrderItemsProvider;
  bool isLoadingMore = false;
  late List<dynamic> items;
  late bool itemsHasMore;
  late String? searchValue;
  late Future itemsData;
  bool initialLoad = false;

  bool fromSearch = false;

  Future<dynamic> _getSalesOrderItemsData() {
    return SalesOrderService.getItemView(
        sessionId: userProvider.user!.sessionId);
  }

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProvider>(context, listen: false);
    salesOrderItemsProvider =
        Provider.of<ItemsProvider>(context, listen: false);
    itemsData = _getSalesOrderItemsData();
    items = salesOrderItemsProvider.items;
    itemsHasMore = salesOrderItemsProvider.hasMore;
    searchValue = salesOrderItemsProvider.search;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: itemsData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          if (!initialLoad) {
            bool salesOrderItemsFlag =
                handleSessionExpiredException(snapshot.data!, context);
            if (!salesOrderItemsFlag) {
              final List<dynamic> data = snapshot.data!['items'];
              salesOrderItemsProvider.addItems(items: data, notify: false);
            }
            initialLoad = true;
          }

          return Consumer<ItemsProvider>(
              builder: (context, salesOrderItemsProvider, _) {
            String? searchValue = salesOrderItemsProvider.search;
            List<dynamic> itemsCopy = items;
            if (searchValue != null && searchValue != '') {
              fromSearch = true;
              itemsCopy = items.where((item) {
                return item.any((value) =>
                    value.toString().toLowerCase().contains(searchValue));
              }).toList();
            }

            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 100, vertical: 15),
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
                      border: Border.all(
                        color: Colors.grey,
                        width: 1,
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 15),
                      child: Row(
                        children: [
                          WebReusableRow(
                            flex: 1,
                            text: 'Item',
                          ),
                          WebReusableRow(
                            flex: 2,
                            text: 'Description',
                          ),
                          WebReusableRow(
                            flex: 2,
                            text: 'Group',
                          ),
                          WebReusableRow(
                            flex: 1,
                            text: 'Stock',
                          ),
                          WebReusableRow(
                            flex: 1,
                            text: 'Unit',
                          ),
                          WebReusableRow(
                            flex: 1,
                            text: 'Cost Method',
                          ),
                          WebReusableRow(
                            flex: 1,
                            text: 'Selling Price',
                          ),
                          SizedBox(
                            width: 15,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                    child: Column(
                  children: [
                    Expanded(
                      child: webSalesOrderItems(
                          items: itemsCopy, fromSearch: fromSearch),
                    ),
                    const Divider(),
                    Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Visibility(
                            visible: itemsHasMore,
                            child: ElevatedButton(
                                onPressed: () async {
                                  setState(() {
                                    isLoadingMore = true;
                                  });
                                  final data =
                                      await SalesOrderService.getItemView(
                                          sessionId:
                                              userProvider.user!.sessionId,
                                          recordOffset: salesOrderItemsProvider
                                              .loadedItems);
                                  if (mounted) {
                                    bool salesOrderFlag =
                                        handleSessionExpiredException(
                                            data, context);
                                    if (!salesOrderFlag) {
                                      final List<dynamic> newSalesOrderItems =
                                          data['items'];
                                      salesOrderItemsProvider.setItemsHasMore(
                                          hasMore: data['hasMore']);
                                      salesOrderItemsProvider.incLoadedItems(
                                          resultLength:
                                              newSalesOrderItems.length);
                                      salesOrderItemsProvider.addItems(
                                          items: newSalesOrderItems);
                                      setState(() {
                                        items = salesOrderItemsProvider.items;
                                        isLoadingMore = false;
                                        itemsHasMore =
                                            salesOrderItemsProvider.hasMore;
                                      });
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    elevation: 0),
                                child: isLoadingMore
                                    ? const CircularProgressIndicator()
                                    : const Text('Load More',
                                        style: TextStyle(color: Colors.grey))),
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Visibility(
                              visible: !itemsHasMore,
                              child: const Text('End of Results')),
                        ),
                      ],
                    ),
                    const Divider(),
                  ],
                ))
              ],
            );
          });
        }
      },
    );
  }
}
