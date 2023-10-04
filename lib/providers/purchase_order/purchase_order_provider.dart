import 'package:flutter/material.dart';
import 'package:rnd_mobile/models/purchase_order_model.dart';

class PurchOrderProvider extends ChangeNotifier {
  List<PurchaseOrder> _purchaseOrderList = [];
  int _orderNumber = -1;
  String? _search;
  bool _hasMore = false;

  List<PurchaseOrder> get purchaseOrderList => _purchaseOrderList;
  int get orderNumber => _orderNumber;
  String? get search => _search;
  bool get hasMore => _hasMore;
  int get purchOrderPending => _purchaseOrderList
      .where((purchOrder) => !purchOrder.isFinal && !purchOrder.isCancelled)
      .length;

  void setOrderNumber({required int orderNumber, bool notify = false}) {
    _orderNumber = orderNumber;
    if (notify) {
      notifyListeners();
    }
  }

  void clearOrderNumber() {
    _orderNumber = -1;
  }

  void setList(
      {required List<PurchaseOrder> purchaseOrderList, bool notify = true}) {
    _purchaseOrderList = purchaseOrderList;
    if (notify) {
      notifyListeners();
    }
  }

  void clearList({bool notify = true}) {
    _purchaseOrderList.clear();
    if (notify) {
      notifyListeners();
    }
  }

  void addItem({required PurchaseOrder purchOrder, bool notify = true}) {
    _purchaseOrderList.add(purchOrder);
    if (notify) {
      notifyListeners();
    }
  }

  void addItems(
      {required List<PurchaseOrder> purchOrders, bool notify = true}) {
    _purchaseOrderList.addAll(purchOrders);
    if (notify) {
      notifyListeners();
    }
  }

  void insertItemtoFirst({required PurchaseOrder item, bool notify = true}) {
    _purchaseOrderList.insert(0, item);
    if (notify) {
      notifyListeners();
    }
  }

  void updateItem(
      {required PurchaseOrder purchOrder,
      required String status,
      bool notify = true}) {
    int index = _purchaseOrderList.indexOf(purchOrder);
    if (status == 'Approved') {
      _purchaseOrderList[index].isFinal = true;
    } else if (status == 'Denied') {
      _purchaseOrderList[index].isCancelled = true;
    }
    if (notify) {
      notifyListeners();
    }
  }

  void removeItem({required PurchaseOrder purchOrder, bool notify = true}) {
    _purchaseOrderList.remove(purchOrder);
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
