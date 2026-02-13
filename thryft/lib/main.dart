import 'package:flutter/material.dart';
import 'package:thryft/widgets/header.dart';

void main() {
  runApp(const ThryftApp());
}

class ThryftApp extends StatelessWidget {
  const ThryftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          Header(),
        ],
      ),
    );
  }
}
