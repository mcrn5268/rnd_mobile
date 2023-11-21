import 'package:flutter/material.dart';

class ItemsProvider extends ChangeNotifier {
  List<dynamic> _items = [];
  String? _search;
  bool _hasMore = false;
  int _loadedItems = 15;

  List<dynamic> get items => _items;
  String? get search => _search;
  bool get hasMore => _hasMore;
  int get loadedItems => _loadedItems;

  // just to check if items already loaded once or not
  bool _didLoadDataAlready = false;
  bool get didLoadDataAlready => _didLoadDataAlready;

  void addItem({required List<dynamic> item, notify = true}) {
    _items.add(item);
    if (notify) {
      notifyListeners();
    }
  }

  void addItems({required List<dynamic> items, notify = true}) {
    _didLoadDataAlready = true;
    _items.addAll(items);
    if (notify) {
      notifyListeners();
    }
  }

  void clearItems({notify = true}) {
    _items.clear();
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

  void incLoadedItems({required int resultLength, bool notify = true}) {
    _loadedItems += resultLength;
    if (notify) {
      notifyListeners();
    }
  }

  void resetDidLoadDataAlready({notify = true}) {
    _didLoadDataAlready = false;
    if (notify) {
      notifyListeners();
    }
  }
}
