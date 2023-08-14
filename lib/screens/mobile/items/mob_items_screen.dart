import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rnd_mobile/api/sales_order_api.dart';
import 'package:rnd_mobile/providers/items/items_provider.dart';
import 'package:rnd_mobile/providers/user_provider.dart';
import 'package:rnd_mobile/utilities/session_handler.dart';
import 'package:rnd_mobile/widgets/mobile/mob_sales_order_items.dart';

class MobileItemsScreen extends StatefulWidget {
  const MobileItemsScreen({super.key});

  @override
  State<MobileItemsScreen> createState() => _MobileItemsScreenState();
}

class _MobileItemsScreenState extends State<MobileItemsScreen> {
  late final UserProvider userProvider;
  late final ItemsProvider salesOrderItemsProvider;
  bool isLoadingMore = false;
  late List<dynamic> items;
  late bool itemsHasMore;
  late String? searchValue;

  bool fromSearch = false;
  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProvider>(context, listen: false);
    salesOrderItemsProvider =
        Provider.of<ItemsProvider>(context, listen: false);
    items = salesOrderItemsProvider.items;
    itemsHasMore = salesOrderItemsProvider.hasMore;
    searchValue = salesOrderItemsProvider.search;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ItemsProvider>(
        builder: (context, salesOrderItemsProvider, _) {
      String? searchValue = salesOrderItemsProvider.search;
      List<dynamic> itemsCopy = items;
      if (searchValue != null && searchValue != '') {
        fromSearch = true;
        itemsCopy = items.where((item) {
          return item.any(
              (value) => value.toString().toLowerCase().contains(searchValue));
        }).toList();
      }

      return Column(
        children: [
          Expanded(
              child: Column(
            children: [
              Expanded(
                child: mobileSalesOrderItems(
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
                            final data = await SalesOrderService.getItemView(
                                sessionId: userProvider.user!.sessionId,
                                recordOffset:
                                    salesOrderItemsProvider.loadedItems);
                            if (mounted) {
                              bool salesOrderFlag =
                                  handleSessionExpiredException(data, context);
                              if (!salesOrderFlag) {
                                final List<dynamic> newSalesOrderItems =
                                    data['items'];
                                salesOrderItemsProvider.setItemsHasMore(
                                    hasMore: data['hasMore']);
                                salesOrderItemsProvider.incLoadedItems(
                                    resultLength: newSalesOrderItems.length);
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
}
