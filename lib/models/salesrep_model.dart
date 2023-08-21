class SalesRep {
  final double salesRepId;
  final String salesRepName;
  final String salesRepCode;

  SalesRep(
      {required this.salesRepId,
      required this.salesRepName,
      required this.salesRepCode});

  bool contains(String query) {
    return salesRepName.toLowerCase().contains(query.toLowerCase()) ||
        salesRepCode.toLowerCase().contains(query.toLowerCase());
  }

  SalesRep? containsStringValue(String query) {
    if (salesRepName.toLowerCase().contains(query.toLowerCase()) ||
        salesRepCode.toLowerCase().contains(query.toLowerCase())) {
      return this;
    } else {
      return null;
    }
  }
}
