import 'package:flutter/material.dart';

void showMessage(BuildContext context, String message) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(message),
          );
        });
  }

Widget buildIndicator(int cur, int index) {
  return Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: cur == index ? Colors.pink[50] : Colors.grey,
    ),
  );
}