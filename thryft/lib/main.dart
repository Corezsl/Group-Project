import 'package:flutter/material.dart';
import 'package:thryft/widgets/header.dart';
import 'package:thryft/widgets/product_carousel.dart';

void main() {
  runApp(const ThryftApp());
}

class ThryftApp extends StatelessWidget {
  const ThryftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomePage());
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Header(),

            // other widgets can be added here
            const SizedBox(height: 16),
            const ProductCarousel(),
          ],
        ),
      ),
    );
  }
}
