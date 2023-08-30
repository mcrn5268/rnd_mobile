import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rnd_mobile/providers/purchase_request/purchase_req_provider.dart';
import 'package:rnd_mobile/screens/web/purchase_request/web_purch_req_hist_screen.dart';
import 'package:rnd_mobile/screens/web/purchase_request/web_purch_req_screen.dart';

class WebPurchReqMain extends StatefulWidget {
  const WebPurchReqMain({super.key});

  @override
  State<WebPurchReqMain> createState() => _WebPurchReqMainState();
}

class _WebPurchReqMainState extends State<WebPurchReqMain> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> menuItems = ['Request', 'History'];
  int selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  double scrollAmount = 200.0;
  late PurchReqProvider purchReqProvider;

  @override
  void initState() {
    super.initState();
    purchReqProvider = Provider.of<PurchReqProvider>(context, listen: false);
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
                //mapping through menuItems to create the menu navigation for Purchase Request
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
                          purchReqProvider.removeSearch();
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
                          visible: Provider.of<PurchReqProvider>(context,
                                          listen: true).purchReqPending != 0,
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
                                  Provider.of<PurchReqProvider>(context,
                                          listen: true)
                                      .purchReqPending
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
                              purchReqProvider.removeSearch();
                              setState(() {
                                _searchController.clear();
                              });
                            },
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {});
                        purchReqProvider.setSearch(search: value);
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
                        WebPurchReqScreen(),
                        WebPurchReqHistScreen(),
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
