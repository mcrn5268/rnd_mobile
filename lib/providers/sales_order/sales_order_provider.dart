import 'package:flutter/material.dart';
import 'package:rnd_mobile/models/sales_order_model.dart';

class SalesOrderProvider extends ChangeNotifier {
  List<SalesOrder> _salesOrderList = [];
  int _orderNumber = -1;
  String? _search;
  bool _hasMore = false;

  List<SalesOrder> get salesOrderList => _salesOrderList;
  int get orderNumber => _orderNumber;
  String? get search => _search;
  bool get hasMore => _hasMore;

  void setOrderNumber({required int orderNumber, bool notify = false}) {
    _orderNumber = orderNumber;
    if (notify) {
      notifyListeners();
    }
  }

  void clearOrderNumber() {
    _orderNumber = -1;
  }

  void setList({required List<SalesOrder> salesOrderList, bool notify = true}) {
    _salesOrderList = salesOrderList;
    if (notify) {
      notifyListeners();
    }
  }

  void clearList({bool notify = true}) {
    _salesOrderList.clear();
    if (notify) {
      notifyListeners();
    }
  }

  void addItem({required SalesOrder salesOrder, bool notify = true}) {
    _salesOrderList.add(salesOrder);
    if (notify) {
      notifyListeners();
    }
  }

  void addItems({required List<SalesOrder> salesOrders, bool notify = true}) {
    _salesOrderList.addAll(salesOrders);
    if (notify) {
      notifyListeners();
    }
  }

  void insertItemtoFirst({required SalesOrder item, bool notify = true}) {
    _salesOrderList.insert(0, item);
    if (notify) {
      notifyListeners();
    }
  }

  void updateItem(
      {required SalesOrder salesOrder,
      required String status,
      bool notify = true}) {
    int index = _salesOrderList.indexOf(salesOrder);
    if (status == 'Approved') {
      _salesOrderList[index].isFinal = true;
    } else if (status == 'Denied') {
      _salesOrderList[index].isCancelled = true;
    }
    if (notify) {
      notifyListeners();
    }
  }

  void removeItem({required SalesOrder salesOrder, bool notify = true}) {
    _salesOrderList.remove(salesOrder);
    if (notify) {
      notifyListeners();
    }
  }

  void setSearch({required String search, bool notify = true}) {
    _search = search;
    if (notify) {
      notifyListeners();
    }
  }

  void removeSearch({bool notify = true}) {
    _search = null;
    if (notify) {
      notifyListeners();
    }
  }

  void setItemsHasMore({required bool hasMore, bool notify = true}) {
    _hasMore = hasMore;
    if (notify) {
      notifyListeners();
    }
  }

  void removeItemsHasMore({bool notify = true}) {
    _hasMore = false;
    if (notify) {
      notifyListeners();
    }
  }
}
