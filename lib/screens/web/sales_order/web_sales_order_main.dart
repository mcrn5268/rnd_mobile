import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rnd_mobile/providers/sales_order/sales_order_provider.dart';
import 'package:rnd_mobile/screens/web/sales_order/web_sales_create_order_screen.dart';
import 'package:rnd_mobile/screens/web/sales_order/web_sales_order_hist_screen.dart';

class WebSalesOrderMain extends StatefulWidget {
  const WebSalesOrderMain({super.key});

  @override
  State<WebSalesOrderMain> createState() => _WebSalesOrderMainState();
}

class _WebSalesOrderMainState extends State<WebSalesOrderMain> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> menuItems = ['Create', 'Orders History'];
  int selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  double scrollAmount = 200.0;
  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 60,
          color: MediaQuery.of(context).platformBrightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 100),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                //mapping through menuItems to create the menu navigation for Sales Order
                ...menuItems.map((item) {
                  int index = menuItems.indexOf(item);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedIndex = index;
                        _searchController.clear();
                      });
                      Provider.of<SalesOrderProvider>(context, listen: false)
                          .removeSearch();
                    },
                    child: Container(
                      height: 70,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: index == selectedIndex
                                ? const Color(0xFF795FCD)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 12,
                            color: index == selectedIndex
                                ? const Color(0xFF795FCD)
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const Spacer(),
                SizedBox(
                    height: 40,
                    width: 200,
                    child: Visibility(
                      visible: selectedIndex != 0,
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.zero,
                          hintText: 'Search',
                          hintStyle: const TextStyle(fontSize: 12),
                          prefixIcon: const Icon(Icons.search),
                          border: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(30.0)),
                          ),
                          suffixIcon: Visibility(
                            visible: _searchController.text.isNotEmpty,
                            child: IconButton(
                              icon: const Icon(Icons.close, size: 25),
                              onPressed: () {
                                if (selectedIndex == 1) {
                                  Provider.of<SalesOrderProvider>(context,
                                          listen: false)
                                      .removeSearch();
                                }
                                setState(() {
                                  _searchController.clear();
                                });
                              },
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {});
                          if (selectedIndex == 1) {
                            Provider.of<SalesOrderProvider>(context,
                                    listen: false)
                                .setSearch(search: value);
                          }
                        },
                      ),
                    ))
              ],
            ),
          ),
        ),
        const Divider(
          color: Colors.grey,
          height: 1.0,
        ),
        Expanded(
          child: Stack(
            children: [
              Scrollbar(
                thickness: 10,
                controller: _scrollController,
                thumbVisibility: MediaQuery.of(context).size.width < 1200,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width <= 1200
                        ? 1200
                        : MediaQuery.of(context).size.width,
                    child: IndexedStack(
                      index: selectedIndex,
                      children: const [
                        WebSalesCreateOrderScreen(),
                        WebSalesOrderHistScreen(),
                      ],
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: MediaQuery.of(context).size.width < 1200,
                child: Positioned(
                    left: 10,
                    bottom: 0,
                    child: InkWell(
                      onTap: () {
                        _scrollController.animateTo(
                          _scrollController.offset - scrollAmount,
                          curve: Curves.easeInOut,
                          duration: const Duration(milliseconds: 500),
                        );
                      },
                      child: const Icon(Icons.arrow_circle_left_outlined),
                    )),
              ),
              Visibility(
                visible: MediaQuery.of(context).size.width < 1200,
                child: Positioned(
                    right: 10,
                    bottom: 0,
                    child: InkWell(
                      onTap: () {
                        _scrollController.animateTo(
                          _scrollController.offset + scrollAmount,
                          curve: Curves.easeInOut,
                          duration: const Duration(milliseconds: 500),
                        );
                      },
                      child: const Icon(Icons.arrow_circle_right_outlined),
                    )),
              ),
            ],
          ),
        )
      ],
    );
  }
}
