import 'package:flutter/material.dart';
import 'package:rnd_mobile/widgets/item_details_row.dart';

class WebSalesOrderLineMoreScreen extends StatelessWidget {
  const WebSalesOrderLineMoreScreen({required this.item, super.key});
  final List<dynamic> item;
  @override
  Widget build(BuildContext context) {
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
        title: const Center(child: Text('More Details')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 15),
            child: Column(
              children: [
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
