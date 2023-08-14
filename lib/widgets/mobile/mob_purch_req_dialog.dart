import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rnd_mobile/api/purchase_req_api.dart';
import 'package:rnd_mobile/models/purchase_req_model.dart';
import 'package:rnd_mobile/providers/purchase_request/purchase_req_provider.dart';
import 'package:rnd_mobile/providers/user_provider.dart';
import 'package:rnd_mobile/utilities/session_handler.dart';
import 'package:rnd_mobile/widgets/item_details_row.dart';

Future<void> purchReqShowDialog(
    {required BuildContext context, required PurchaseRequest request}) async {
  var requestDate = DateFormat.yMMMd().format(request.requestDate);
  var neededDate = DateFormat.yMMMd().format(request.neededDate);
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return SimpleDialog(insetPadding: const EdgeInsets.all(10), children: [
        Column(
          children: [
            Container(
              color: Colors.grey[850],
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Stack(
                  children: [
                    const Center(
                      child: Text('Purchase Request'),
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
              title: 'Request Number',
              value: request.preqNum.toString(),
            ),
            const Divider(),
            ItemDetailsRowWidget(title: 'Request Date', value: requestDate),
            const Divider(),
            ItemDetailsRowWidget(title: 'Needed Date', value: neededDate),
            const Divider(),
          ],
        ),
        const SizedBox(height: 10),
        Center(
          child: FutureBuilder(
            future: PurchReqService.getPurchReqLneView(
                sessionId: Provider.of<UserProvider>(context, listen: false)
                    .user!
                    .sessionId,
                hdrId: request.id),
            builder: (BuildContext context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else {
                List<dynamic> data = snapshot.data!;
                if (context.mounted) {
                  bool purchOrderFlag =
                      handleSessionExpiredException(data[0], context);
                  if (purchOrderFlag) {
                    return Container();
                  }
                }
                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.50,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          color: Colors.grey[850],
                          child: const Padding(
                            padding: EdgeInsets.only(top: 10, bottom: 10),
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(width: 10),
                                  Expanded(flex: 2, child: Text('Item')),
                                  SizedBox(width: 10),
                                  Expanded(flex: 4, child: Text('Description')),
                                  SizedBox(width: 10),
                                  Expanded(flex: 1, child: Text('Qty')),
                                  SizedBox(width: 10),
                                  Expanded(flex: 1, child: Text('Unit')),
                                  SizedBox(width: 10),
                                  Expanded(flex: 1, child: Text('Cost')),
                                  SizedBox(width: 15),
                                ]),
                          ),
                        ),
                        const Divider(),
                        for (var index = 0; index < data.length; index++) ...[
                          Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  purchReqMoreInfo(
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
                                                (data[index][4] ?? '-')
                                                    .toString()
                                                    .trim(),
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey))),
                                        const SizedBox(width: 10),
                                        Expanded(
                                            flex: 4,
                                            child: Text(
                                                (data[index][6] ?? '-')
                                                    .toString()
                                                    .trim(),
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey))),
                                        const SizedBox(width: 10),
                                        Expanded(
                                            flex: 1,
                                            child: Text(
                                              data[index][7].toString(),
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                              textAlign: TextAlign.right,
                                            )),
                                        const SizedBox(width: 10),
                                        Expanded(
                                            flex: 1,
                                            child: Text(
                                              (data[index][8] ?? '-')
                                                  .toString()
                                                  .trim(),
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                              textAlign: TextAlign.right,
                                            )),
                                        const SizedBox(width: 10),
                                        Expanded(
                                            flex: 1,
                                            child: Text(
                                              data[index][13] ?? '-',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                              textAlign: TextAlign.right,
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
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ]);
    },
  );
}

Future<void> purchReqMoreInfo(
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
                        value: (item[4] ?? '-').toString().trim(),
                      ),
                      const Divider(),
                      ItemDetailsRowWidget(
                        title: 'Description',
                        value: (item[6] ?? '-').toString().trim(),
                      ),
                      const Divider(),
                      ItemDetailsRowWidget(
                        title: 'Quantity',
                        value: (item[7] ?? '-').toString().trim(),
                      ),
                      const Divider(),
                      ItemDetailsRowWidget(
                        title: 'Unit',
                        value: (item[8] ?? '-').toString().trim(),
                      ),
                      const Divider(),
                      ItemDetailsRowWidget(
                        title: 'Request Balance',
                        value: (item[10] ?? '-').toString().trim(),
                      ),
                      const Divider(),
                      ItemDetailsRowWidget(
                        title: 'Supplier',
                        value: (item[12] ?? '-').toString().trim(),
                      ),
                      const Divider(),
                      ItemDetailsRowWidget(
                        title: 'Supplier Unit Price',
                        value: (item[13] ?? '-').toString().trim(),
                      ),
                      const Divider(),
                      ItemDetailsRowWidget(
                        title: 'Cost Center',
                        value: (item[18] ?? '-').toString().trim(),
                      ),
                      const Divider(),
                      ItemDetailsRowWidget(
                        title: 'Project',
                        value: (item[20] ?? '-').toString().trim(),
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
