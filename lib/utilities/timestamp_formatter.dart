String formatTimestampMillis(int timestamp) {
  final now = DateTime.now();
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final difference = now.difference(date);

  if (difference.inDays >= 3) {
    return '${date.month}/${date.day}/${date.year}';
  } else if (difference.inDays >= 1) {
    final days = difference.inDays;
    return '$days ${days == 1 ? "day" : "days"} ago';
  } else if (difference.inHours >= 1) {
    final hours = difference.inHours;
    return '$hours ${hours == 1 ? "hour" : "hours"} ago';
  } else if (difference.inMinutes >= 1) {
    final minutes = difference.inMinutes;
    return '$minutes ${minutes == 1 ? "minute" : "minutes"} ago';
  } else {
    return 'Just now';
  }
}
