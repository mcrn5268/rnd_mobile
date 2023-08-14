import 'package:flutter/material.dart';
import 'package:rnd_mobile/models/purchase_req_model.dart';

class PurchReqProvider extends ChangeNotifier {
  List<PurchaseRequest> _purchaseRequestList = [];
  int _reqNumber = -1;
  String? _search;

  List<PurchaseRequest> get purchaseRequestList => _purchaseRequestList;
  int get reqNumber => _reqNumber;
  String? get search => _search;

  void setReqNumber({required int reqNumber, bool notify = false}) {
    _reqNumber = reqNumber;
    if (notify) {
      notifyListeners();
    }
  }

  void clearReqNumber() {
    _reqNumber = -1;
  }

  void setList(
      {required List<PurchaseRequest> purchaseRequestList,
      bool notify = true}) {
    _purchaseRequestList = purchaseRequestList;
    if (notify) {
      notifyListeners();
    }
  }

  void clearList({bool notify = true}) {
    _purchaseRequestList.clear();
    if (notify) {
      notifyListeners();
    }
  }

  void addItem({required PurchaseRequest purchReq, bool notify = true}) {
    _purchaseRequestList.add(purchReq);
    if (notify) {
      notifyListeners();
    }
  }

  void addItems(
      {required List<PurchaseRequest> purchReqs, bool notify = true}) {
    _purchaseRequestList.addAll(purchReqs);
    if (notify) {
      notifyListeners();
    }
  }

  void insertItemtoFirst({required PurchaseRequest item, bool notify = true}) {
    _purchaseRequestList.insert(0, item);
    if (notify) {
      notifyListeners();
    }
  }

  void updateItem(
      {required PurchaseRequest purchReq,
      required String status,
      bool notify = true}) {
    int index = _purchaseRequestList.indexOf(purchReq);
    if (status == 'Approved') {
      _purchaseRequestList[index].isFinal = true;
    } else if (status == 'Denied') {
      _purchaseRequestList[index].isCancelled = true;
    }
    if (notify) {
      notifyListeners();
    }
  }

  void removeItem({required PurchaseRequest purchReq, bool notify = true}) {
    _purchaseRequestList.remove(purchReq);
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
}
