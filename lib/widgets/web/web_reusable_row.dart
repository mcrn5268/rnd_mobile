import 'package:flutter/material.dart';

class WebReusableRow extends StatelessWidget {
  final int flex;
  final String text;
  final Color? color;

  const WebReusableRow({
    Key? key,
    required this.flex,
    required this.text,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Center(
        child: Text(text,
            style: TextStyle(fontSize: 12, color: color ?? Colors.grey)),
      ),
    );
  }
}
