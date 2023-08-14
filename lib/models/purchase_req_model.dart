import 'package:intl/intl.dart';

class PurchaseRequest {
  final int id;
  final int preqNum;
  final DateTime requestDate;
  final DateTime neededDate;
  final String reference;
  final int warehouseId;
  final String warehouseDescription;
  final int costCenterId;
  final String costCenterDescription;
  final String requestedBy;
  final String reason;
  bool isFinal;
  bool isCancelled;
  final int userId;
  final String userName;

  PurchaseRequest({
    required this.id,
    required this.preqNum,
    required this.requestDate,
    required this.neededDate,
    required this.reference,
    required this.warehouseId,
    required this.warehouseDescription,
    required this.costCenterId,
    required this.costCenterDescription,
    required this.requestedBy,
    required this.reason,
    required this.isFinal,
    required this.isCancelled,
    required this.userId,
    required this.userName,
  });

  factory PurchaseRequest.fromJson(List<dynamic> rowData) {
    return PurchaseRequest(
      id: rowData[0],
      preqNum: rowData[1],
      requestDate: DateTime.parse(rowData[2]),
      neededDate: DateTime.parse(rowData[3]),
      reference: rowData[4] ?? '--',
      warehouseId: rowData[5] ?? '--',
      warehouseDescription: rowData[6] ?? '--',
      costCenterId: rowData[7] ?? '-',
      costCenterDescription: rowData[8] ?? '--',
      requestedBy: rowData[9] ?? '--',
      reason: rowData[10] ?? '--',
      isFinal: rowData[11] == 'Y',
      isCancelled: rowData[12] == 'Y',
      userId: rowData[13] ?? '--',
      userName: rowData[14] ?? '--',
    );
  }
  bool containsQuery(String query) {
    query = query.toLowerCase();
    return 
    // id.toString().toLowerCase().contains(query) ||
        preqNum.toString().toLowerCase().contains(query) ||
        DateFormat.yMMMd().format(requestDate).toLowerCase().contains(query) ||
        // DateFormat.yMMMd().format(neededDate).toLowerCase().contains(query) ||
        reference.toLowerCase().contains(query) ||
        warehouseId.toString().toLowerCase().contains(query) ||
        warehouseDescription.toLowerCase().contains(query) ||
        costCenterId.toString().toLowerCase().contains(query) ||
        // costCenterDescription.toLowerCase().contains(query) ||
        requestedBy.toLowerCase().contains(query) ||
        reason.toLowerCase().contains(query);
    // userId.toString().toLowerCase().contains(query) ||
    // userName.toLowerCase().contains(query);
  }
}
