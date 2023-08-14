import 'package:flutter/material.dart';

enum ReqDataType { reqDate, purchReqNum, neededDate, other }

enum ReqStatus { approved, denied, pending, all }

enum ReqSort { asc, dsc }

class PurchReqHistFilterProvider extends ChangeNotifier {
  ReqDataType? _dataType;
  ReqDataType? get dataType => _dataType;

  ReqStatus? _status;
  ReqStatus? get status => _status;

  ReqSort? _sort;
  ReqSort? get sort => _sort;

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
      {required ReqDataType dataType,
      required ReqStatus status,
      required ReqSort sort,
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
    if ((dataType == ReqDataType.reqDate ||
        dataType == ReqDataType.neededDate)) {
      _fromDate = fromDate;
      _toDate = toDate;
      notify = true;
    }
    if (dataType == ReqDataType.other) {
      if (otherValue != '' && otherValue != null) {
        _otherValue = otherValue;
        _otherDropdown = otherDropdown;
        notify = true;
      }
    }
    if (notify && !_firstCall) {
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
