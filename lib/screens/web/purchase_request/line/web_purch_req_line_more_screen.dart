import 'package:flutter/material.dart';
import 'package:rnd_mobile/widgets/item_details_row.dart';

class WebPurchReqLineMoreScreen extends StatelessWidget {
  const WebPurchReqLineMoreScreen({required this.item, super.key});
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
            child: Column(children: [
              const Divider(),
              ItemDetailsRowWidget(
                  title: 'Item', value: (item[4] ?? '-').toString().trim()),
              const Divider(),
              ItemDetailsRowWidget(
                  title: 'Description',
                  value: (item[6] ?? '-').toString().trim()),
              const Divider(),
              ItemDetailsRowWidget(
                  title: 'Quantity', value: (item[7] ?? '-').toString().trim()),
              const Divider(),
              ItemDetailsRowWidget(
                  title: 'Unit', value: (item[8] ?? '-').toString().trim()),
              const Divider(),
              ItemDetailsRowWidget(
                  title: 'Request Balance',
                  value: (item[10] ?? '-').toString().trim()),
              const Divider(),
              ItemDetailsRowWidget(
                  title: 'Supplier',
                  value: (item[12] ?? '-').toString().trim()),
              const Divider(),
              ItemDetailsRowWidget(
                  title: 'Supplier Unit Price',
                  value: (item[13] ?? '-').toString().trim()),
              const Divider(),
              ItemDetailsRowWidget(
                  title: 'Cost Center',
                  value: (item[18] ?? '-').toString().trim()),
              const Divider(),
              ItemDetailsRowWidget(
                  title: 'Project', value: (item[20] ?? '-').toString().trim()),
            ]),
          ),
        ],
      ),
    );
  }
}
