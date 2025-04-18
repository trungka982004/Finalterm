import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:io' show Platform; // ⛔ Chỉ dùng được khi không chạy web

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: HelloText(),
        ),
      ),
    );
  }
}

class HelloText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Cách 1: Nếu chạy web
    if (kIsWeb) {
      return const Text(
        "Hello",
        style: TextStyle(
          fontSize: 32,
          color: Colors.blue,
          fontFamily: 'Roboto',
        ),
      );
    }

    // Cách 2: Nếu chạy mobile (Android/iOS)
    // Note: Platform chỉ chạy được trên thiết bị thật, không chạy trên web
    if (Platform.isAndroid || Platform.isIOS) {
      return const Text(
        "Hello",
        style: TextStyle(
          fontSize: 32,
          color: Colors.red,
          fontFamily: 'Arial',
        ),
      );
    }

    // Default fallback
    return const Text("Hello");
  }
}
