import 'package:flutter/material.dart';
import 'package:rnd_mobile/widgets/item_details_row.dart';

class WebPurchOrderLineMoreScreen extends StatelessWidget {
  const WebPurchOrderLineMoreScreen({required this.item, super.key});
  final List<dynamic> item;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF795FCD),
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
                  value: (item[5] ?? '--').toString().trim(),
                ),
                const Divider(),
                ItemDetailsRowWidget(
                  title: 'Description',
                  value: (item[7] ?? '--').toString().trim(),
                ),
                const Divider(),
                ItemDetailsRowWidget(
                  title: 'Quantity',
                  value: (item[9] ?? '--').toString().trim(),
                ),
                const Divider(),
                ItemDetailsRowWidget(
                  title: 'Unit',
                  value: (item[8] ?? '--').toString().trim(),
                ),
                const Divider(),
                ItemDetailsRowWidget(
                  title: 'Unit Price (Net VAT)',
                  value: (item[10] ?? '--').toString().trim(),
                ),
                const Divider(),
                ItemDetailsRowWidget(
                  title: 'Unit Price',
                  value: (item[11] ?? '--').toString().trim(),
                ),
                const Divider(),
                ItemDetailsRowWidget(
                  title: 'Extd. Price',
                  value: (item[12] ?? '--').toString().trim(),
                ),
                const Divider(),
                ItemDetailsRowWidget(
                  title: 'Vattable',
                  value: item[13] == 'Y' ? 'Yes' : 'No',
                ),
                const Divider(),
                ItemDetailsRowWidget(
                  title: 'Tax %',
                  value: (item[14] ?? '--').toString().trim(),
                ),
                const Divider(),
                ItemDetailsRowWidget(
                  title: 'Unit Tax',
                  value: (item[15] ?? '--').toString().trim(),
                ),
                const Divider(),
                ItemDetailsRowWidget(
                  title: 'Tax',
                  value: (item[16] ?? '--').toString().trim(),
                ),
                const Divider(),
                ItemDetailsRowWidget(
                  title: 'Conversion Factor',
                  value: (item[17] ?? '--').toString().trim(),
                ),
                const Divider(),
                ItemDetailsRowWidget(
                  title: 'Inventory GL Acct.',
                  value: (item[19] ?? '--').toString().trim(),
                ),
                const Divider(),
                ItemDetailsRowWidget(
                  title: 'Project',
                  value: (item[23] ?? '--').toString().trim(),
                ),
                const Divider(),
                ItemDetailsRowWidget(
                  title: 'PR No.',
                  value: (item[24] ?? '--').toString().trim(),
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
