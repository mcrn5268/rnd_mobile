import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rnd_mobile/providers/items/items_provider.dart';
import 'package:rnd_mobile/screens/mobile/items/mob_items_screen.dart';
import 'package:rnd_mobile/utilities/clip_path.dart';

class MobileItemsMain extends StatefulWidget {
  const MobileItemsMain({super.key});

  @override
  State<MobileItemsMain> createState() => _MobileItemsMainState();
}

class _MobileItemsMainState extends State<MobileItemsMain> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> menuItems = ['Items'];
  int selectedIndex = 0;

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
                    visible: true,
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
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                          ),
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
                                  Provider.of<ItemsProvider>(context,
                                          listen: false)
                                      .removeSearch();
                                  setState(() {
                                    _searchController.clear();
                                  });
                                },
                              ),
                            ),
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            Provider.of<ItemsProvider>(context, listen: false)
                                .setSearch(search: value);
                            setState(() {});
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
        const SizedBox(height: 20),
        // SizedBox(
        //   height: 40,
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.center,
        //     children: [
        //       ...menuItems.map((item) {
        //         int index = menuItems.indexOf(item);
        //         return GestureDetector(
        //           onTap: () {
        //             setState(() {
        //               selectedIndex = index;
        //               _searchController.clear();
        //             });

        //             Provider.of<ItemsProvider>(context, listen: false)
        //                 .removeSearch();
        //           },
        //           child: Container(
        //             height: 70,
        //             padding:
        //                 const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        //             decoration: BoxDecoration(
        //               border: Border(
        //                 bottom: BorderSide(
        //                   color: index == selectedIndex
        //                       ? const Color(0xFF795FCD)
        //                       : Colors.transparent,
        //                   width: 2,
        //                 ),
        //               ),
        //             ),
        //             child: Center(
        //               child: Text(
        //                 item,
        //                 style: TextStyle(
        //                   fontSize: 12,
        //                   color: index == selectedIndex
        //                       ? const Color(0xFF795FCD)
        //                       : Colors.grey,
        //                 ),
        //               ),
        //             ),
        //           ),
        //         );
        //       }),
        //     ],
        //   ),
        // ),
        Expanded(
          child: IndexedStack(index: selectedIndex, children: const [
            MobileItemsScreen(),
          ]),
        )
      ],
    );
  }
}
