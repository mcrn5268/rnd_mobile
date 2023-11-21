import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rnd_mobile/api/purchase_req_api.dart';
import 'package:rnd_mobile/models/purchase_req_model.dart';
import 'package:rnd_mobile/providers/user_provider.dart';
import 'package:rnd_mobile/screens/web/purchase_request/line/web_purch_req_line_more_screen.dart';
import 'package:rnd_mobile/utilities/session_handler.dart';

class WebPurchReqLineScreen extends StatelessWidget {
  const WebPurchReqLineScreen({required this.request, super.key});
  final PurchaseRequest request;
  @override
  Widget build(BuildContext context) {
    var requestDate = DateFormat.yMMMd().format(request.requestDate);
    var neededDate = DateFormat.yMMMd().format(request.neededDate);
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
        title: const Center(child: Text('Purchase Request')),
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
                            'Request Number: ',
                            textAlign: TextAlign.left,
                          ),
                        ),
                        Expanded(
                          child: Text(request.preqNum.toString(),
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
                            'Request Date: ',
                            textAlign: TextAlign.left,
                          ),
                        ),
                        Expanded(
                          child: Text(requestDate,
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
                            'Needed Date: ',
                            textAlign: TextAlign.left,
                          ),
                        ),
                        Expanded(
                          child: Text(neededDate,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
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
                          child: Text(request.warehouseDescription,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                    const SizedBox(height: 35),
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
                          child: Text(request.reference,
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
                      child: Text('Cost',
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
                future: PurchReqService.getPurchReqLneView(
                    sessionId: Provider.of<UserProvider>(context, listen: false)
                        .user!
                        .sessionId,
                    hdrId: request.id),
                builder: (BuildContext context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else {
                    List<dynamic> data = snapshot.data!;
                    if (data.isNotEmpty) {
                      if (context.mounted) {
                        bool purchReqFlag =
                            handleSessionExpiredException(data[0], context);
                        if (purchReqFlag) {
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
                                            WebPurchReqLineMoreScreen(
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
                                              (data[index][4] ?? '-')
                                                  .toString()
                                                  .trim(),
                                              textAlign: TextAlign.left,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey))),
                                      Expanded(
                                          flex: 2,
                                          child: Text(
                                              (data[index][6] ?? '-')
                                                  .toString()
                                                  .trim(),
                                              textAlign: TextAlign.left,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey))),
                                      Expanded(
                                          flex: 1,
                                          child: Text(data[index][7].toString(),
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey))),
                                      Expanded(
                                          flex: 1,
                                          child: Text(
                                              (data[index][8] ?? '-')
                                                  .toString()
                                                  .trim(),
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey))),
                                      Expanded(
                                          flex: 1,
                                          child: Text(
                                              (data[index][13] ?? '-')
                                                  .toString()
                                                  .trim(),
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey))),
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
