String formatTimestamp(String timestamp) {
  return timestamp.replaceAll(RegExp(r'(\.\d+)?(Z|[+-]\d{2}:\d{2})'), '');
}