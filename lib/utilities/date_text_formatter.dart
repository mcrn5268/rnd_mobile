import 'package:flutter/services.dart';

// class DateTextFormatter extends TextInputFormatter {
//   @override
//   TextEditingValue formatEditUpdate(
//       TextEditingValue oldValue, TextEditingValue newValue) {
//     // Check if text was deleted
//     if (oldValue.text.length > newValue.text.length) {
//       // Find the index of the deleted character
//       int deleteIndex = 0;
//       while (deleteIndex < newValue.text.length &&
//           oldValue.text[deleteIndex] == newValue.text[deleteIndex]) {
//         deleteIndex++;
//       }

//       // Check if a slash was deleted
//       if (oldValue.text[deleteIndex] == '/') {
//         // Move cursor to before the deleted slash and delete the slash from the text
//         return newValue.copyWith(
//             text: newValue.text.substring(0, deleteIndex) +
//                 newValue.text.substring(deleteIndex + 1),
//             selection: TextSelection.collapsed(offset: deleteIndex));
//       }
//     }

//     var dateText = _addSeperators(newValue.text, '/');
//     int newCursorPosition = newValue.selection.baseOffset +
//         (dateText.length - newValue.text.length);
//     if (dateText.length > newValue.text.length &&
//         newCursorPosition > 0 &&
//         dateText[newCursorPosition - 1] == '/') {
//       newCursorPosition += 1;
//     }
//     // Ensure that the new cursor position is within the valid range
//     newCursorPosition = newCursorPosition.clamp(0, dateText.length);
//     return newValue.copyWith(
//         text: dateText,
//         selection: TextSelection.collapsed(offset: newCursorPosition));
//   }

//   String _addSeperators(String value, String seperator) {
//     value = value.replaceAll('/', '');
//     var newString = '';
//     for (int i = 0; i < value.length; i++) {
//       newString += value[i];
//       if (i == 1) {
//         newString += seperator;
//       }
//       if (i == 3) {
//         newString += seperator;
//       }
//       if (i == 7) {
//         break;
//       }
//     }
//     return newString;
//   }
// }



class DateTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // check if the new value is shorter than the old value
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }
    // check if the new value is longer than the maximum allowed length
    if (newValue.text.length > 10) {
      return oldValue;
    }
    var dateText = _addSeperators(newValue.text, '/');
    return newValue.copyWith(
        text: dateText,
        selection: updateCursorPosition(dateText, newValue.selection));
  }

  String _addSeperators(String value, String seperator) {
    value = value.replaceAll('/', '');
    var newString = '';
    for (int i = 0; i < value.length; i++) {
      newString += value[i];
      if (i == 1 || i == 3) {
        newString += seperator;
      }
    }
    return newString;
  }

  TextSelection updateCursorPosition(String text, TextSelection oldSelection) {
    int offset = oldSelection.extentOffset;
    if (text.length > offset && text[offset] == '/') {
      offset++;
    }
    return TextSelection.fromPosition(TextPosition(offset: offset));
  }
}
