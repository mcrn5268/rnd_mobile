class Warehouse {
  final double whsId;
  final String whsDesc;
  final String whsCode;

  Warehouse(
      {required this.whsId, required this.whsDesc, required this.whsCode});

  bool contains(String query) {
    return whsDesc.toLowerCase().contains(query.toLowerCase()) ||
        whsCode.toLowerCase().contains(query.toLowerCase());
  }

  Warehouse? containsStringValue(String query) {
    if (whsDesc.toLowerCase().contains(query.toLowerCase()) ||
        whsCode.toLowerCase().contains(query.toLowerCase())) {
      return this;
    } else {
      return null;
    }
  }
}
