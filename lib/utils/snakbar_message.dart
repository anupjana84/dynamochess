import 'package:flutter/material.dart';

void showSnackMessage(BuildContext context, String message, bool isError) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: isError ? Colors.red : Colors.green,
    duration: const Duration(seconds: 1),
  ));
}
