import 'package:flutter/material.dart';
import 'package:thryft/widgets/header.dart';
import 'package:thryft/widgets/product_carousel.dart';
import 'package:thryft/widgets/category_section.dart';

void main() {
  runApp(const ThryftApp());
}

class ThryftApp extends StatelessWidget {
  const ThryftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Thryft',
      theme: ThemeData(
        useMaterial3: true,
        // Primary colour theme
        primaryColor: const Color.fromARGB(255, 71, 164, 245),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 71, 164, 245),
          primary: const Color.fromARGB(255, 71, 164, 245),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Header(),
            
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Shop by Category",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            const CategorySection(),

            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "New Arrivals",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            // other widgets can be added here
            const SizedBox(height: 16),
            const ProductCarousel(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

