import 'package:flutter/material.dart';

class ItemDetailsRowWidget extends StatelessWidget {
  const ItemDetailsRowWidget(
      {Key? key, required this.title, required this.value})
      : super(key: key);

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              '$title: ',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
