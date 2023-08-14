import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:rnd_mobile/main.dart';
import 'package:rnd_mobile/providers/purchase_order/puch_order_hist_filter_provider.dart';
import 'package:rnd_mobile/providers/purchase_order/purch_order_filter_provider.dart';
import 'package:rnd_mobile/providers/purchase_request/purch_req_filter_provider.dart';
import 'package:rnd_mobile/providers/purchase_request/purch_req_hist_filter_provider.dart';
import 'package:rnd_mobile/providers/purchase_order/purchase_order_provider.dart';
import 'package:rnd_mobile/providers/purchase_request/purchase_req_provider.dart';
import 'package:rnd_mobile/providers/sales_order/sales_order_hist_filter.provider.dart';
import 'package:rnd_mobile/providers/items/items_provider.dart';
import 'package:rnd_mobile/providers/sales_order/sales_order_provider.dart';
import 'package:rnd_mobile/providers/user_provider.dart';
import 'package:rnd_mobile/utilities/session_handler.dart';
import 'package:rnd_mobile/utilities/shared_pref.dart';

void clearData(BuildContext context) {
  try {
    //purchase request
    Provider.of<PurchReqFilterProvider>(context, listen: false).reset();
    Provider.of<PurchReqHistFilterProvider>(context, listen: false).reset();
    Provider.of<PurchReqProvider>(context, listen: false).clearReqNumber();
    Provider.of<PurchReqProvider>(context, listen: false)
        .clearList(notify: false);
    //purchase order
    Provider.of<PurchOrderFilterProvider>(context, listen: false).reset();
    Provider.of<PurchOrderHistFilterProvider>(context, listen: false).reset();
    Provider.of<PurchOrderProvider>(context, listen: false).clearOrderNumber();
    Provider.of<PurchOrderProvider>(context, listen: false)
        .clearList(notify: false);
    //sales order
    Provider.of<SalesOrderHistFilterProvider>(context, listen: false).reset();
    Provider.of<SalesOrderProvider>(context, listen: false).clearOrderNumber();
    Provider.of<SalesOrderProvider>(context, listen: false)
        .clearList(notify: false);

    //items
    Provider.of<ItemsProvider>(context, listen: false)
        .clearItems(notify: false);

    //user provider
    Provider.of<UserProvider>(context, listen: false).clearUser(notify: false);
  } catch (e) {
    if (kDebugMode) {
      print('Error: $e');
    }
  } finally {
    SharedPreferencesService().removeUser();
    //Navigator.of(context).popUntil((route) => route.isFirst);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      alreadyShowedDialog = false;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MyApp(),
        ),
      );
    });
  }
}
