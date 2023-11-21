import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rnd_mobile/api/purchase_order_api.dart';
import 'package:rnd_mobile/models/purchase_order_model.dart';
import 'package:rnd_mobile/providers/user_provider.dart';
import 'package:rnd_mobile/screens/web/purchase_order/line/web_purch_order_line_more_screen.dart';
import 'package:rnd_mobile/utilities/session_handler.dart';

class WebPurchOrderLineScreen extends StatelessWidget {
  const WebPurchOrderLineScreen({required this.order, super.key});
  final PurchaseOrder order;
  @override
  Widget build(BuildContext context) {
    var poDate = DateFormat.yMMMd().format(order.poDate);
    var delvDate = DateFormat.yMMMd().format(order.deliveryDate);
    return Scaffold(
      appBar: AppBar(
        // backgroundColor: const Color(0xFF795FCD),
        backgroundColor: Colors.blueGrey,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Center(child: Text('Purchase Order')),
      ),
      body: Column(
        children: [
          Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 100, vertical: 15),
              child: Row(children: [
                Expanded(
                    child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Order Number: ',
                            textAlign: TextAlign.left,
                          ),
                        ),
                        Expanded(
                          child: Text(order.poNumber.toString(),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Supplier: ',
                            textAlign: TextAlign.left,
                          ),
                        ),
                        Expanded(
                          child: Text(order.supplierName.toString(),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                    const SizedBox(height: 15),
                  ],
                )),
                const SizedBox(width: 300),
                Expanded(
                    child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Warehouse: ',
                            textAlign: TextAlign.left,
                          ),
                        ),
                        Expanded(
                          child: Text(
                              order.warehouseDescription.toString().trim(),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Reference: ',
                            textAlign: TextAlign.left,
                          ),
                        ),
                        Expanded(
                          child: Text(order.reference.toString().trim(),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Ship To: ',
                            textAlign: TextAlign.left,
                          ),
                        ),
                        Expanded(
                          child: Text(order.address.toString().trim(),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ],
                )),
              ])),
          const Divider(),
          Column(
            children: [
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 100),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                      //borderRadius: BorderRadius.circular(20),
                      color: MediaQuery.of(context).platformBrightness ==
                              Brightness.dark
                          ? Colors.grey[900]
                          : Colors.grey[300],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 0.5,
                          blurRadius: 1,
                          offset: const Offset(0, 1),
                        ),
                      ],
                      border: Border.all(color: Colors.grey)),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 15,
                      ),
                      Expanded(
                          flex: 1,
                          child: Text('Order Date',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 12,
                              ))),
                      Expanded(
                          flex: 1,
                          child: Text('Delivery Date',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 12,
                              ))),
                      Expanded(
                          flex: 2,
                          child: Text('Terms of Payment',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 12,
                              ))),
                      SizedBox(
                        width: 15,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 100),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    // borderRadius: BorderRadius.circular(20),
                    color: MediaQuery.of(context).platformBrightness ==
                            Brightness.dark
                        ? Colors.grey[900]
                        : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 0.5,
                        blurRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 15,
                      ),
                      Expanded(
                          flex: 1,
                          child: Text(poDate.toString().trim(),
                              textAlign: TextAlign.left,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey))),
                      Expanded(
                          flex: 1,
                          child: Text(delvDate.toString().trim(),
                              textAlign: TextAlign.left,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey))),
                      Expanded(
                          flex: 2,
                          child: Text(order.address.toString().trim(),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey))),
                      const SizedBox(
                        width: 15,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 100),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                  // borderRadius: BorderRadius.circular(20),
                  color: MediaQuery.of(context).platformBrightness ==
                          Brightness.dark
                      ? Colors.grey[900]
                      : Colors.grey[300],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 0.5,
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                  border: Border.all(color: Colors.grey)),
              child: const Row(
                children: [
                  SizedBox(
                    width: 15,
                  ),
                  Expanded(
                      flex: 1,
                      child: Text('Item',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 12,
                          ))),
                  Expanded(
                      flex: 2,
                      child: Text('Description',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 12,
                          ))),
                  Expanded(
                      flex: 1,
                      child: Text('Quantity',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                          ))),
                  Expanded(
                      flex: 1,
                      child: Text('Unit',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                          ))),
                  Expanded(
                      flex: 1,
                      child: Text('Price',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                          ))),
                  Expanded(
                      flex: 1,
                      child: Text('Total',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                          ))),
                  SizedBox(
                    width: 15,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder(
                future: PurchOrderService.getPurchOrderLneView(
                    sessionId: Provider.of<UserProvider>(context, listen: false)
                        .user!
                        .sessionId,
                    poId: order.id),
                builder: (BuildContext context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
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

                      return CustomScrollView(slivers: <Widget>[
                        SliverList(
                            delegate: SliverChildBuilderDelegate(
                                (BuildContext context, int index) {
                          late final Color backgroundColor;
                          if (MediaQuery.of(context).platformBrightness ==
                              Brightness.dark) {
                            backgroundColor = index.isEven
                                ? Colors.grey[900]!
                                : Colors.grey[850]!;
                          } else {
                            backgroundColor =
                                index.isEven ? Colors.white : Colors.grey[50]!;
                          }
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 100),
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                // borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 0.5,
                                    blurRadius: 1,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (_, __, ___) =>
                                            WebPurchOrderLineMoreScreen(
                                                item: data[index]),
                                        transitionsBuilder: (_, a, __, c) =>
                                            FadeTransition(
                                                opacity: a, child: c),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 15),
                                      Expanded(
                                          flex: 1,
                                          child: Text(
                                              (data[index][5] ?? '--')
                                                  .toString()
                                                  .trim(),
                                              textAlign: TextAlign.left,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey))),
                                      Expanded(
                                          flex: 2,
                                          child: Text(
                                              (data[index][7] ?? '--')
                                                  .toString()
                                                  .trim(),
                                              textAlign: TextAlign.left,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey))),
                                      Expanded(
                                          flex: 1,
                                          child: Text(data[index][9].toString(),
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey))),
                                      Expanded(
                                          flex: 1,
                                          child: Text(
                                              (data[index][8] ?? '--')
                                                  .toString()
                                                  .trim(),
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey))),
                                      Expanded(
                                          flex: 1,
                                          child: Text(
                                              data[index][10].toString(),
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey))),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          data[index][9] != null &&
                                                  data[index][10] != null
                                              ? (data[index][9] *
                                                      double.parse(data[index]
                                                              [10]
                                                          .toString()))
                                                  .toString()
                                              : '--',
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                          width: 10,
                                          child:
                                              Icon(Icons.arrow_right_outlined)),
                                      const SizedBox(width: 5)
                                    ],
                                  )),
                            ),
                          );
                        }, childCount: data.length))
                      ]);
                    } else {
                      return const Center(child: Text('Empty'));
                    }
                  }
                }),
          ),
        ],
      ),
    );
  }
}
