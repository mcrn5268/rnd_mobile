class TermsOfPayment {
  final double topId;
  final String topDesc;
  final String topCode;

  TermsOfPayment(
      {required this.topId, required this.topDesc, required this.topCode});

  bool contains(String query) {
    return topDesc.toLowerCase().contains(query.toLowerCase()) ||
        topCode.toLowerCase().contains(query.toLowerCase());
  }

  TermsOfPayment? containsStringValue(String query) {
    if (topDesc.toLowerCase().contains(query.toLowerCase()) ||
        topCode.toLowerCase().contains(query.toLowerCase())) {
      return this;
    } else {
      return null;
    }
  }
}
