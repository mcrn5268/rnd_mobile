import 'package:flutter/material.dart';

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
      backgroundColor: const Color(0xFF795FCD),
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
                    return InkWell(
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
                                borderRadius: BorderRadius.circular(16),
                              )
                            : null,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          widget.menuItems[index],
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                    );
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
