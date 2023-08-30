import 'package:flutter/material.dart';
import 'package:rnd_mobile/widgets/web/web_reusable_row.dart';

Widget webSalesOrderItems(
    {required List<dynamic> items,
    bool clickable = false,
    bool fromSearch = false}) {
  if (items.isEmpty) {
    return Center(
        child: Text(
            fromSearch
                ? 'No Matching Sales Order Item Found'
                : '0 Sales Orders Item',
            style: const TextStyle(fontSize: 30)));
  } else {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        var salesOrderItem = items[index];
        BorderRadius borderRadius;
        if (index == 0) {
          borderRadius = const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          );
        } else if (index == items.length - 1) {
          borderRadius = const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          );
        } else {
          borderRadius = BorderRadius.zero;
        }
        late final Color backgroundColor;
        if (MediaQuery.of(context).platformBrightness == Brightness.dark) {
          backgroundColor =
              index.isEven ? Colors.grey[900]! : Colors.grey[850]!;
        } else {
          backgroundColor = index.isEven ? Colors.white : Colors.grey[50]!;
        }
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: clickable ? 0 : 100),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 0.5,
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: MouseRegion(
              cursor: clickable ? SystemMouseCursors.click : MouseCursor.defer,
              child: InkWell(
                onTap: clickable
                    ? () {
                        Navigator.pop(context, salesOrderItem);
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.only(left: 15, right: 5),
                  child: Row(
                    children: [
                      //Item
                      WebReusableRow(
                        flex: 1,
                        text: salesOrderItem[1].toString().trim(),
                      ),
                      //Description
                      WebReusableRow(
                        flex: 2,
                        text: salesOrderItem[2].toString().trim(),
                      ),
                      //Group
                      WebReusableRow(
                        flex: 2,
                        text: salesOrderItem[3].toString().trim(),
                      ),
                      //Stock
                      WebReusableRow(
                        flex: 1,
                        text: salesOrderItem[4].toString().trim(),
                      ),
                      //Unit
                      WebReusableRow(
                        flex: 1,
                        text: salesOrderItem[5].toString().trim(),
                      ),
                      //Cost Method
                      WebReusableRow(
                        flex: 1,
                        text: salesOrderItem[6].toString().trim(),
                      ),
                      //Selling Price
                      WebReusableRow(
                        flex: 1,
                        text: salesOrderItem[7].toString().trim(),
                      ),
                      if (clickable) ...[
                        const SizedBox(
                          width: 10,
                          child: Icon(Icons.arrow_right_outlined),
                        ),
                      ] else ...[
                        const SizedBox(
                          width: 10,
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
