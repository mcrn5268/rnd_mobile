import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rnd_mobile/providers/sales_order/sales_order_provider.dart';
import 'package:rnd_mobile/screens/mobile/sales_order/mob_sales_create_order_screen.dart';
import 'package:rnd_mobile/screens/mobile/sales_order/mob_sales_order_hist_screen.dart';
import 'package:rnd_mobile/utilities/clip_path.dart';
import 'package:rnd_mobile/widgets/lazy_indexedstack.dart';

class MobileSalersOrderMain extends StatefulWidget {
  const MobileSalersOrderMain({super.key});

  @override
  State<MobileSalersOrderMain> createState() => _MobileSalersOrderMainState();
}

class _MobileSalersOrderMainState extends State<MobileSalersOrderMain> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> menuItems = ['Create', 'History'];
  int selectedIndex = 0;
  late Brightness brightness;

  @override
  void initState() {
    super.initState();
    brightness = PlatformDispatcher.instance.platformBrightness;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Stack(
                children: [
                  Container(
                    height: 50,
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: ClipPath(
                      clipper: AppBarClipper(),
                      child: Container(
                        // color: Colors.deepPurple,
                        color: Colors.blueGrey,
                        height: 50,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: selectedIndex != 0,
                    child: Align(
                      alignment: Alignment.center,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
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
                        height: 50,
                        width: MediaQuery.of(context).size.width - 50,
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 18),
                            hintText: 'Search',
                            hintStyle: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                            prefixIcon:
                                const Icon(Icons.search, color: Colors.grey),
                            suffixIcon: Visibility(
                              visible: _searchController.text.isNotEmpty,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 25),
                                onPressed: () {
                                  if (selectedIndex == 1) {
                                    Provider.of<SalesOrderProvider>(context,
                                            listen: false)
                                        .removeSearch();
                                    setState(() {
                                      _searchController.clear();
                                    });
                                  }
                                },
                              ),
                            ),
                            border: InputBorder.none,
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
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...menuItems.map((item) {
                int index = menuItems.indexOf(item);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                      _searchController.clear();
                    });

                    if (selectedIndex == 1) {
                      Provider.of<SalesOrderProvider>(context, listen: false)
                          .removeSearch();
                    }
                  },
                  child: Container(
                    height: 70,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: index == selectedIndex
                              // ? const Color(0xFF795FCD)
                              ? Colors.blueGrey
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
                              ? brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.blueGrey
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        Expanded(
          child: LazyIndexedStack(index: selectedIndex, children: const [
            MobileSalesCreateOrderScreen(),
            MobileSalesOrderHistScreen(),
          ]),
        )
      ],
    );
  }
}
