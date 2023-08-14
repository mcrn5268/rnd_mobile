import 'package:intl/intl.dart';

class SalesOrder {
  final int? id;
  bool isCancelled;
  bool isFinal;
  final int soNumber;
  final String reference;
  final double? debtorId;
  final String debtorCode;
  final String debtorName;
  final String address;
  final DateTime soDate;
  final DateTime deliveryDate;
  final double? topId;
  final String topDescription;
  final double? salesRepId;
  final String salesRepName;
  final double? currency;
  final String currencyCode;
  final double? warehouseId;
  final String warehouseDescription;
  final String particulars;
  final double? priceLvId;
  final String priceLv;
  final double? userId;
  final String userName;

  SalesOrder({
    required this.id,
    required this.isCancelled,
    required this.isFinal,
    required this.soNumber,
    required this.reference,
    required this.debtorId,
    required this.debtorCode,
    required this.debtorName,
    required this.address,
    required this.soDate,
    required this.deliveryDate,
    required this.topId,
    required this.topDescription,
    required this.salesRepId,
    required this.salesRepName,
    required this.currency,
    required this.currencyCode,
    required this.warehouseId,
    required this.warehouseDescription,
    required this.particulars,
    required this.priceLvId,
    required this.priceLv,
    required this.userId,
    required this.userName,
  });

  factory SalesOrder.fromJson(List<dynamic> rowData) {
    return SalesOrder(
      id: rowData[0],
      isCancelled: rowData[1] == 'Y',
      isFinal: rowData[2] == 'Y',
      soNumber: rowData[3] ?? '--',
      reference: rowData[4] ?? '--',
      debtorId: rowData[5]?.toDouble(),
      debtorCode: rowData[6] ?? '--',
      debtorName: rowData[7] ?? '--',
      address: rowData[8] ?? '--',
      soDate: DateTime.parse(rowData[9]),
      deliveryDate: DateTime.parse(rowData[10]),
      topId: rowData[11]?.toDouble(),
      topDescription: rowData[12] ?? '--',
      salesRepId: rowData[13]?.toDouble(),
      salesRepName: rowData[14] ?? '--',
      currency: rowData[15]?.toDouble(),
      currencyCode: rowData[16] ?? '--',
      warehouseId: rowData[17]?.toDouble(),
      warehouseDescription: rowData[18] ?? '--',
      particulars: rowData[19] ?? '--',
      priceLvId: rowData[20]?.toDouble(),
      priceLv: rowData[21] ?? '--',
      userId: rowData[22]?.toDouble(),
      userName: rowData[23] ?? '--',
    );
  }
  bool containsQuery(String query) {
    query = query.toLowerCase();
    return
        // (id?.toString() ?? '').toLowerCase().contains(query) ||
        soNumber.toString().toLowerCase().contains(query) ||
            reference.toLowerCase().contains(query) ||
            // (debtorId?.toString() ?? '').toLowerCase().contains(query) ||
            // debtorCode.toLowerCase().contains(query) ||
            debtorName.toLowerCase().contains(query) ||
            // address.toLowerCase().contains(query) ||
            DateFormat.yMMMd().format(soDate).toLowerCase().contains(query) ||
            DateFormat.yMMMd()
                .format(deliveryDate)
                .toLowerCase()
                .contains(query) ||
            // (topId?.toString() ?? '').toLowerCase().contains(query) ||
            // topDescription.toLowerCase().contains(query) ||
            // (salesRepId?.toString() ?? '').toLowerCase().contains(query) ||
            // salesRepName.toLowerCase().contains(query) ||
            // (currency?.toString() ?? '').toLowerCase().contains(query) ||
            // currencyCode.toLowerCase().contains(query) ||
            // (warehouseId?.toString() ?? '').toLowerCase().contains(query) ||
            warehouseDescription.toLowerCase().contains(query);
    // particulars.toLowerCase().contains(query) ||
    // (priceLvId?.toString() ?? '').toLowerCase().contains(query) ||
    // priceLv.toLowerCase().contains(query) ||
    // (userId?.toString() ?? '').toLowerCase().contains(query) ||
    // userName.toLowerCase().contains(query);
  }
}
