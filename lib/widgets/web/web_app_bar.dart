import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rnd_mobile/models/purchase_order_model.dart';
import 'package:rnd_mobile/models/purchase_req_model.dart';
import 'package:rnd_mobile/providers/purchase_order/purchase_order_provider.dart';
import 'package:rnd_mobile/providers/purchase_request/purchase_req_provider.dart';

bool first = true;

class WebCustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const WebCustomAppBar({
    Key? key,
    required this.menuItems,
    required this.onMenuItemSelected,
    required this.selectedIndex,
    required this.actions,
  }) : super(key: key);

  final List<String> menuItems;
  final ValueChanged<int> onMenuItemSelected;
  final int selectedIndex;
  final List<Widget> actions;

  @override
  State<WebCustomAppBar> createState() => _WebCustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _WebCustomAppBarState extends State<WebCustomAppBar> {
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // backgroundColor: const Color(0xFF795FCD),
      backgroundColor: Colors.blueGrey,
      flexibleSpace: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              margin: const EdgeInsets.all(8),
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/images/PrimeLogo.png'),
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.menuItems.length,
                  (index) {
                    final isSelected =
                        index == (first ? widget.selectedIndex : selectedIndex);
                    if (index == 4) {
                      return Container();
                    } else {
                      return Consumer2<PurchReqProvider, PurchOrderProvider>(
                        builder: (context, purchReqProvider, purchOrderProvider,
                            child) {
                          return Stack(
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  setState(() {
                                    selectedIndex = index;
                                  });
                                  first = false;
                                  widget.onMenuItemSelected(index);
                                },
                                child: Container(
                                  decoration: isSelected
                                      ? BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        )
                                      : null,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: Text(
                                    widget.menuItems[index],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                              if (index == 0) ...[
                                Visibility(
                                  visible:
                                      purchReqProvider.purchReqPending != 0,
                                  child: Positioned(
                                    right: 10,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.red),
                                    ),
                                  ),
                                ),
                              ],
                              if (index == 1) ...[
                                Visibility(
                                  visible:
                                      purchOrderProvider.purchOrderPending != 0,
                                  child: Positioned(
                                    right: 10,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.red),
                                    ),
                                  ),
                                ),
                              ]
                            ],
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Row(children: widget.actions),
          ),
        ],
      ),
    );
  }
}
