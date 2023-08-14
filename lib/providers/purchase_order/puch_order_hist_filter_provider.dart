import 'package:flutter/material.dart';

enum OrderDataType { poDate, poNum, delvDate, other }

enum OrderStatus { approved, denied, pending, all }

enum OrderSort { asc, dsc }

class PurchOrderHistFilterProvider extends ChangeNotifier {
  OrderDataType? _dataType;
  OrderDataType? get dataType => _dataType;

  OrderStatus? _status;
  OrderStatus? get status => _status;

  OrderSort? _sort;
  OrderSort? get sort => _sort;

  DateTime? _fromDate;
  DateTime? _toDate;

  DateTime? get fromDate => _fromDate;
  DateTime? get toDate => _toDate;

  String? _otherValue;
  String? get otherValue => _otherValue;

  String? _otherDropdown;
  String? get otherDropdown => _otherDropdown;

  bool _firstCall = true;

  void setFilter(
      {required OrderDataType dataType,
      required OrderStatus status,
      required OrderSort sort,
      DateTime? fromDate,
      DateTime? toDate,
      String? otherDropdown,
      String? otherValue,
      bool notify = true}) {
    if (_dataType != dataType || _status != status || _sort != sort) {
      _dataType = dataType;
      _status = status;
      _sort = sort;
    } else {
      notify = false;
    }
    if ((dataType == OrderDataType.poDate ||
            dataType == OrderDataType.delvDate) &&
        (fromDate != null || toDate != null)) {
      _fromDate = fromDate;
      _toDate = toDate;
      if (!_firstCall) {
        notify = true;
      }
    }
    if (dataType == OrderDataType.other) {
      if (otherValue != '' && otherValue != null) {
        _otherValue = otherValue;
        _otherDropdown = otherDropdown;
        if (!_firstCall) {
          notify = true;
        }
      }
    }
    if (notify) {
      notifyListeners();
    }
    _firstCall = false;
  }

  void reset() {
    _dataType = null;
    _status = null;
    _sort = null;
    _firstCall = true;
  }
}
