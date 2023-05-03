import 'package:dart_downloader_demo/presentation/views/dart_downloader_view.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const DartDownloaderApp());
}

class DartDownloaderApp extends StatelessWidget {
  const DartDownloaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Dart Downloader Demo",
      theme: ThemeData(
          primarySwatch: Colors.purple,
          primaryColor: Colors.purpleAccent,
          primaryColorLight: Colors.white,
          primaryColorDark: Colors.black),
      home: const DartDownloaderView(),
    );
  }
}
