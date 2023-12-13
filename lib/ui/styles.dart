import 'package:flutter/material.dart';

class AppStyles {
  static const TextStyle tableHeaderText = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  static const TextStyle tableRowText = TextStyle(
    fontSize: 14,
  );

  static SnackBar successSnackBar(String message) {
    return SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 3),
    );
  }

   static SnackBar errorSnackBar(String message) {
    return SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 3),
    );
  }

  
}
