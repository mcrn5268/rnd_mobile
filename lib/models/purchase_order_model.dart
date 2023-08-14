import 'package:intl/intl.dart';

class PurchaseOrder {
  final int id;
  bool isFinal;
  bool isCancelled;
  final int poNumber;
  final String reference;
  final double supplierId;
  final String supplierCode;
  final String supplierName;
  final String address;
  final double warehouseId;
  final String warehouseDescription;
  final String warehouseAddress;
  final String purpose;
  final String remarks;
  final DateTime poDate;
  final DateTime deliveryDate;
  final double topId;
  final String topDescription;
  final double userId;
  final String userName;

  PurchaseOrder({
    required this.id,
    required this.isFinal,
    required this.isCancelled,
    required this.poNumber,
    required this.reference,
    required this.supplierId,
    required this.supplierCode,
    required this.supplierName,
    required this.address,
    required this.warehouseId,
    required this.warehouseDescription,
    required this.warehouseAddress,
    required this.purpose,
    required this.remarks,
    required this.poDate,
    required this.deliveryDate,
    required this.topId,
    required this.topDescription,
    required this.userId,
    required this.userName,
  });

  factory PurchaseOrder.fromJson(List<dynamic> rowData) {
    return PurchaseOrder(
      id: rowData[0],
      isFinal: rowData[1] == 'Y',
      isCancelled: rowData[2] == 'Y',
      poNumber: rowData[3]?? '--',
      reference: rowData[4] ?? '--',
      supplierId: rowData[5].toDouble(),
      supplierCode: rowData[6] ?? '--',
      supplierName: rowData[7] ?? '--',
      address: rowData[8] ?? '--',
      warehouseId: rowData[9].toDouble(),
      warehouseDescription: rowData[10] ?? '--',
      warehouseAddress: rowData[11] ?? '--',
      purpose: rowData[12] ?? '--',
      remarks: rowData[13] ?? '--',
      poDate: DateTime.parse(rowData[14]),
      deliveryDate: DateTime.parse(rowData[15]),
      topId: rowData[16].toDouble(),
      topDescription: rowData[17] ?? '--',
      userId: rowData[18].toDouble(),
      userName: rowData[19] ?? '--',
    );
  }
  bool containsQuery(String query) {
    query = query.toLowerCase();
    return
        // id.toString().toLowerCase().contains(query) ||
        // isFinal.toString().toLowerCase().contains(query) ||
        // isCancelled.toString().toLowerCase().contains(query) ||
        poNumber.toString().toLowerCase().contains(query) ||
            reference.toLowerCase().contains(query) ||
            // supplierId.toString().toLowerCase().contains(query) ||
            // supplierCode.toLowerCase().contains(query) ||
            // supplierName.toLowerCase().contains(query) ||
            // address.toLowerCase().contains(query) ||
            // warehouseId.toString().toLowerCase().contains(query) ||
            warehouseDescription.toLowerCase().contains(query) ||
            // warehouseAddress.toLowerCase().contains(query) ||
            purpose.toLowerCase().contains(query) ||
            remarks.toLowerCase().contains(query) ||
            DateFormat.yMMMd().format(poDate).toLowerCase().contains(query) ||
            DateFormat.yMMMd()
                .format(deliveryDate)
                .toLowerCase()
                .contains(query);
    // topId.toString().toLowerCase().contains(query) ||
    // topDescription.toLowerCase().contains(query) ||
    // userId.toString().toLowerCase().contains(query) ||
    // userName.toLowerCase().contains(query);
  }
}
