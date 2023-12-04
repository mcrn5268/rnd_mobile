import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rnd_mobile/api/sales_order_api.dart';
import 'package:rnd_mobile/models/sales_order_model.dart';
import 'package:rnd_mobile/providers/sales_order/sales_order_provider.dart';
import 'package:rnd_mobile/providers/user_provider.dart';
import 'package:rnd_mobile/utilities/convert_lines_array_to_map.dart';
import 'package:rnd_mobile/utilities/generate_pdf.dart';
import 'package:rnd_mobile/utilities/session_handler.dart';
import 'package:rnd_mobile/widgets/item_details_row.dart';

Future<void> salesOrderShowDialog(
    {required BuildContext context, required SalesOrder order}) async {
  var soDate = DateFormat.yMMMd().format(order.soDate);
  var deliveryDate = DateFormat.yMMMd().format(order.deliveryDate);
  List<Map<String, dynamic>> dataMap = [];
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return SimpleDialog(insetPadding: const EdgeInsets.all(10), children: [
        Column(
          children: [
            Container(
              color: PlatformDispatcher.instance.platformBrightness ==
                      Brightness.dark
                  ? Colors.grey[850]
                  : Colors.grey[300],
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Stack(
                  children: [
                    const Center(
                      child: Text('Sales Order'),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        child: const Icon(Icons.clear, size: 15),
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            ItemDetailsRowWidget(
              title: 'Order Number',
              value: order.soNumber.toString(),
            ),
            const Divider(),
            ItemDetailsRowWidget(
              title: 'Customer',
              value: order.debtorName,
            ),
            const Divider(),
            ItemDetailsRowWidget(
              title: 'Sales Representative',
              value: order.salesRepName,
            ),
            const Divider(),
            ItemDetailsRowWidget(
              title: 'Warehouse',
              value: order.warehouseDescription,
            ),
            const Divider(),
            ItemDetailsRowWidget(
              title: 'Reference',
              value: order.reference,
            ),
            const Divider(),
            ItemDetailsRowWidget(
              title: 'Ship To',
              value: order.address,
            ),
            const Divider(),
          ],
        ),
        const SizedBox(height: 10),
        Column(
          children: [
            Container(
              color: PlatformDispatcher.instance.platformBrightness ==
                      Brightness.dark
                  ? Colors.grey[850]
                  : Colors.grey[300],
              child: const Padding(
                padding: EdgeInsets.only(top: 10, bottom: 10),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(width: 10),
                      Expanded(flex: 1, child: Text('Order Date')),
                      SizedBox(width: 10),
                      Expanded(flex: 1, child: Text('Delivery Date')),
                      SizedBox(width: 10),
                      Expanded(
                          flex: 2,
                          child: Text(
                            'Terms of Payment',
                            textAlign: TextAlign.right,
                          )),
                      SizedBox(width: 10),
                    ]),
              ),
            ),
            const Divider(),
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              const SizedBox(width: 10),
              Expanded(
                  flex: 1,
                  child: Text(
                    soDate,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  )),
              const SizedBox(width: 10),
              Expanded(
                  flex: 1,
                  child: Text(
                    deliveryDate,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  )),
              const SizedBox(width: 10),
              Expanded(
                  flex: 2,
                  child: Text(
                    order.topDescription.toString().trim(),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  )),
              const SizedBox(width: 10),
            ]),
            const Divider(),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          color:
              PlatformDispatcher.instance.platformBrightness == Brightness.dark
                  ? Colors.grey[850]
                  : Colors.grey[300],
          child: const Padding(
            padding: EdgeInsets.only(top: 10, bottom: 10),
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              SizedBox(width: 10),
              Expanded(flex: 2, child: Text('Item')),
              SizedBox(width: 10),
              Expanded(flex: 4, child: Text('Description')),
              SizedBox(width: 10),
              Expanded(flex: 1, child: Text('Qty')),
              SizedBox(width: 10),
              Expanded(flex: 2, child: Text('Unit')),
              SizedBox(width: 10),
              Expanded(flex: 2, child: Text('Price')),
              SizedBox(width: 15),
            ]),
          ),
        ),
        Center(
          child: FutureBuilder(
            future: SalesOrderService.getSalesOrderLneView(
                sessionId: Provider.of<UserProvider>(context, listen: false)
                    .user!
                    .sessionId,
                soId: order.id!),
            builder: (BuildContext context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else {
                List<dynamic> data = snapshot.data!;
                if (data.isNotEmpty) {
                  if (context.mounted) {
                    bool purchOrderFlag =
                        handleSessionExpiredException(data[0], context);
                    if (purchOrderFlag) {
                      return Container();
                    }
                  }
                }
                dataMap = [...ConvertLinesArrayToMap().salesOrder(data)];
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Divider(),
                      if (dataMap.isNotEmpty) ...[
                        for (var index = 0;
                            index < dataMap.length;
                            index++) ...[
                          Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  purchOrderMoreInfo(
                                      context: context, item: data[index]);
                                },
                                child: SizedBox(
                                  // height: 30,
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        const SizedBox(width: 10),
                                        Expanded(
                                            flex: 2,
                                            child: Text(
                                              (dataMap[index]['item_code'] ??
                                                      '-')
                                                  .toString()
                                                  .trim(),
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                            )),
                                        const SizedBox(width: 10),
                                        Expanded(
                                            flex: 4,
                                            child: Text(
                                              (dataMap[index]['item_desc'] ??
                                                      '-')
                                                  .toString()
                                                  .trim(),
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                            )),
                                        const SizedBox(width: 10),
                                        Expanded(
                                            flex: 1,
                                            child: Text(
                                              dataMap[index]['qty'].toString(),
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                              // textAlign: TextAlign.right,
                                            )),
                                        const SizedBox(width: 10),
                                        Expanded(
                                            flex: 2,
                                            child: Text(
                                              (dataMap[index]['so_unit'] ?? '-')
                                                  .toString()
                                                  .trim(),
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                              // textAlign: TextAlign.right,
                                            )),
                                        const SizedBox(width: 10),
                                        Expanded(
                                            flex: 2,
                                            child: Text(
                                              (dataMap[index]
                                                          ['selling_price'] ??
                                                      '-')
                                                  .toString()
                                                  .trim(),
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                              // textAlign: TextAlign.right,
                                            )),
                                        const SizedBox(
                                            width: 15,
                                            child: Icon(
                                                Icons.arrow_right_outlined)),
                                      ]),
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                        ],
                      ] else ...[
                        const Center(
                          child: Text('Empty'),
                        )
                      ],
                    ],
                  ),
                );
              }
            },
          ),
        ),
        Column(
          children: [
            const Divider(),
            // Generate PDF
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    onPressed: () async {
                      await generatePdf(
                          context: context,
                          title: 'SALES ORDER',
                          leftHeader: {
                            'Customer': order.debtorName,
                            'Terms': order.topDescription,
                          },
                          rightHeader: {
                            'Date': soDate,
                            'Delivery Date': deliveryDate
                          },
                          lines: [
                            {'name': 'Line', 'code': 'ln_num'},
                            {'name': 'Item Description', 'code': 'item_desc'},
                            {'name': 'Order Qty', 'code': 'qty'},
                            {'name': 'Unit', 'code': 'so_unit'},
                            {'name': 'Price', 'code': 'selling_price'},
                            {'name': 'Subtotal', 'code': 'subtotal'}
                          ],
                          dataMap: dataMap,
                          footer: [
                            'Prepared By',
                            'Noted By',
                            'Approved By',
                            'Received By'
                          ]);
                    },
                    child: const Text('Generate Full Size PDF')),
                ElevatedButton(
                    onPressed: () async {
                      await generatePdf(
                          context: context,
                          title: 'SALES ORDER',
                          leftHeader: {
                            'Customer': order.debtorName,
                            'Terms': order.topDescription,
                          },
                          rightHeader: {
                            'Date': soDate,
                            'Delivery Date': deliveryDate
                          },
                          lines: [
                            {'name': 'Line', 'code': 'ln_num'},
                            {'name': 'Item Description', 'code': 'item_desc'},
                            {'name': 'Order Qty', 'code': 'qty'},
                            {'name': 'Unit', 'code': 'so_unit'},
                            {'name': 'Price', 'code': 'selling_price'},
                            {'name': 'Subtotal', 'code': 'subtotal'}
                          ],
                          dataMap: dataMap,
                          footer: [
                            'Prepared By',
                            'Noted By',
                            'Approved By',
                            'Received By'
                          ],
                          small: true);
                    },
                    child: const Text('Generate Small Size PDF')),
              ],
            ),
          ],
        ),
      ]);
    },
  );
}

Future<void> purchOrderMoreInfo(
    {required BuildContext context, required dynamic item}) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return SimpleDialog(insetPadding: const EdgeInsets.all(10), children: [
        Stack(
          children: [
            const Center(
              child: Text(
                'More Details',
                style: TextStyle(fontSize: 35),
              ),
            ),
            Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_left_outlined),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )),
          ],
        ),
        const SizedBox(height: 10),
        Center(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      const Divider(),
                      ItemDetailsRowWidget(
                        title: 'Item',
                        value: (item[4] ?? '--').toString().trim(),
                      ),
                      const Divider(),
                      ItemDetailsRowWidget(
                        title: 'Description',
                        value: (item[5] ?? '--').toString().trim(),
                      ),
                      const Divider(),
                      ItemDetailsRowWidget(
                        title: 'Quantity',
                        value: (item[9] ?? '--').toString().trim(),
                      ),
                      const Divider(),
                      ItemDetailsRowWidget(
                        title: 'Unit',
                        value: (item[6] ?? '--').toString().trim(),
                      ),
                      const Divider(),
                      ItemDetailsRowWidget(
                        title: 'Base Selling Price',
                        value: (item[10] ?? '--').toString().trim(),
                      ),
                      const Divider(),
                      ItemDetailsRowWidget(
                        title: 'Selling Price',
                        value: (item[11] ?? '--').toString().trim(),
                      ),
                      const Divider(),
                      ItemDetailsRowWidget(
                        title: 'Line Amount',
                        value: (item[12] ?? '--').toString().trim(),
                      ),
                      const Divider(),
                      ItemDetailsRowWidget(
                        title: 'Conversion Factor',
                        value: (item[13] ?? '--').toString().trim(),
                      ),
                      const Divider(),
                      ItemDetailsRowWidget(
                        title: 'Remarks',
                        value: (item[14] ?? '--').toString().trim(),
                      ),
                      const Divider(),
                      ItemDetailsRowWidget(
                        title: 'Weight',
                        value: (item[15] ?? '--').toString().trim(),
                      ),
                      const Divider(),
                      ItemDetailsRowWidget(
                        title: 'Volume',
                        value: (item[16] ?? '--').toString().trim(),
                      ),
                      const Divider(),
                      ItemDetailsRowWidget(
                        title: 'Cost Center',
                        value: (item[18] ?? '--').toString().trim(),
                      ),
                      const Divider(),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]);
    },
  );
}
