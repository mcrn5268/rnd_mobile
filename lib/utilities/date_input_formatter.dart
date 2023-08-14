import 'package:flutter/services.dart';

class DateInputFormatter extends TextInputFormatter {
  final RegExp _datePattern = RegExp(r'^\d{0,4}-\d{0,2}-\d{0,2}$');
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (_isValidDate(newValue.text)) {
      if (newValue.text.length > 1 && newValue.text.length < oldValue.text.length) {
        // Detecting if a character was removed
        // Adjust the cursor position accordingly
        int cursorPosition = newValue.selection.baseOffset;
        if (newValue.text.length == 5 || newValue.text.length == 8) {
          cursorPosition--;
        }
        return newValue.copyWith(
          text: _formatDate(newValue.text),
          selection: TextSelection.collapsed(offset: cursorPosition),
        );
      }
      return newValue.copyWith(text: _formatDate(newValue.text));
    } else {
      return oldValue;
    }
  }

  bool _isValidDate(String text) {
    return text.isEmpty || _datePattern.hasMatch(text);
  }

  String _formatDate(String text) {
    String formattedDate = text.replaceAll('-', '');
    if (formattedDate.length >= 5) {
      formattedDate = '${formattedDate.substring(0, 4)}-${formattedDate.substring(4)}';
    }
    if (formattedDate.length >= 8) {
      formattedDate = '${formattedDate.substring(0, 7)}-${formattedDate.substring(7)}';
    }
    return formattedDate;
  }
}
