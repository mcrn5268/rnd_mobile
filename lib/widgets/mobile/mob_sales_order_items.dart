import 'package:flutter/material.dart';
import 'package:rnd_mobile/widgets/mobile/mob_reusable_column.dart';

Widget mobileSalesOrderItems(
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) {
          var salesOrderItem = items[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Container(
              decoration: BoxDecoration(
                color: salesOrderItem[4] == 'Y'
                    ? Colors.green
                    : salesOrderItem[4] == 'N'
                        ? Colors.red
                        : Colors.grey,
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
              child: MouseRegion(
                cursor:
                    clickable ? SystemMouseCursors.click : MouseCursor.defer,
                child: InkWell(
                  onTap: clickable
                      ? () {
                          Navigator.pop(context, salesOrderItem);
                        }
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 3),
                    child: Container(
                      decoration: BoxDecoration(
                          color: MediaQuery.of(context).platformBrightness ==
                                  Brightness.dark
                              ? Colors.grey[900]
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 10),
                        child: MobileReusableColumn(
                            //Item Code
                            firstRowFirstText: salesOrderItem[1].toString(),
                            //Item Stock Status
                            firstRowSecondText: salesOrderItem[4] == 'Y'
                                ? 'In Stock'
                                : salesOrderItem[4] == 'N'
                                    ? 'Out of Stock'
                                    : '---',
                            //Description
                            secondRowFirstText:
                                salesOrderItem[2].toString().trim(),
                            //Group
                            thirdRowFirstText:
                                salesOrderItem[3].toString().trim(),
                            //Cost Method
                            thirdRowSecondText:
                                salesOrderItem[5].toString().trim(),
                            //Unit
                            fourthRowFirstText: salesOrderItem[6],
                            //Selling Price
                            fourthRowSecondText: salesOrderItem[7].toString(),
                            statusColor: salesOrderItem[4] == 'Y'
                                ? Colors.green
                                : salesOrderItem[4] == 'N'
                                    ? Colors.red
                                    : Colors.grey,
                            clickable: clickable),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
