class Debtor {
  final String debtorName;
  final String debtorCode;

  Debtor({required this.debtorName, required this.debtorCode});

  bool contains(String query) {
    return debtorName.toLowerCase().contains(query.toLowerCase()) ||
        debtorCode.toLowerCase().contains(query.toLowerCase());
  }
}
