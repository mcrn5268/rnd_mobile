class Debtor {
  final double debtorId;
  final String debtorName;
  final String debtorCode;

  Debtor(
      {required this.debtorId,
      required this.debtorName,
      required this.debtorCode});

  bool contains(String query) {
    return debtorName.toLowerCase().contains(query.toLowerCase()) ||
        debtorCode.toLowerCase().contains(query.toLowerCase());
  }

  Debtor? containsStringValue(String query) {
    if (debtorName.toLowerCase().contains(query.toLowerCase()) ||
        debtorCode.toLowerCase().contains(query.toLowerCase())) {
      return this;
    } else {
      return null;
    }
  }
}
