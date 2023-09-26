import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rnd_mobile/providers/purchase_order/purchase_order_provider.dart';
import 'package:rnd_mobile/screens/web/purchase_order/web_purch_order_hist_screen.dart';
import 'package:rnd_mobile/screens/web/purchase_order/web_purch_order_screen.dart';

class WebPurchOrderMain extends StatefulWidget {
  const WebPurchOrderMain({super.key});

  @override
  State<WebPurchOrderMain> createState() => _WebPurchOrderMainState();
}

class _WebPurchOrderMainState extends State<WebPurchOrderMain> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> menuItems = ['Order', 'History'];
  int selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  double scrollAmount = 200.0;
  late PurchOrderProvider purchOrderProvider;

  @override
  void initState() {
    super.initState();
    purchOrderProvider =
        Provider.of<PurchOrderProvider>(context, listen: false);
  }

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
                //mapping through menuItems to create the menu navigation for Purchase Order
                ...menuItems.map((item) {
                  int index = menuItems.indexOf(item);
                  return Stack(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            selectedIndex = index;
                            _searchController.clear();
                          });
                          purchOrderProvider.removeSearch();
                        },
                        child: Container(
                          height: 70,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: index == selectedIndex
                                    // ? const Color(0xFF795FCD)
                                    ? MediaQuery.of(context)
                                                .platformBrightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.blueGrey
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
                                    // ? const Color(0xFF795FCD)
                                    ? MediaQuery.of(context)
                                                .platformBrightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.blueGrey
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (index == 0) ...[
                        Visibility(
                          visible: Provider.of<PurchOrderProvider>(context,
                                      listen: true)
                                  .purchOrderPending !=
                              0,
                          child: Positioned(
                            right: 0,
                            top: 5,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle, color: Colors.red),
                              child: Center(
                                child: Text(
                                  Provider.of<PurchOrderProvider>(context,
                                          listen: true)
                                      .purchOrderPending
                                      .toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ]
                    ],
                  );
                }),
                const Spacer(),
                SizedBox(
                    height: 40,
                    width: 200,
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        hintText: 'Search',
                        hintStyle: const TextStyle(fontSize: 12),
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(30.0)),
                        ),
                        suffixIcon: Visibility(
                          visible: _searchController.text.isNotEmpty,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 25),
                            onPressed: () {
                              purchOrderProvider.removeSearch();
                              setState(() {
                                _searchController.clear();
                              });
                            },
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {});
                        purchOrderProvider.setSearch(search: value);
                      },
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
                        WebPurchOrderScreen(),
                        WebPurchOrderHistScreen(),
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
