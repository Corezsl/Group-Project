import 'package:flutter/material.dart';
import 'package:thryft/utils/responsive.dart';
import 'package:thryft/widgets/footer.dart';
import 'package:thryft/widgets/header.dart';
import 'package:thryft/widgets/hero_banner.dart';
import 'package:thryft/widgets/product_carousel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final hPadding = isMobile ? 12.0 : 16.0;
    final sectionGap = isMobile ? 20.0 : 32.0;
    final headingSize = isMobile ? 18.0 : 20.0;

    return Scaffold(
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Header(),
            const HeroBanner(),
            SizedBox(height: isMobile ? 16 : 24),

            // ── Shirts & Tops ───────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPadding),
              child: Text(
                'Shirts & Tops',
                style: TextStyle(
                  fontSize: headingSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const ProductCarousel(category: 'Shirt'),
            SizedBox(height: sectionGap),

            // ── Trousers ────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPadding),
              child: Text(
                'Trousers',
                style: TextStyle(
                  fontSize: headingSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const ProductCarousel(category: 'Trousers'),
            SizedBox(height: sectionGap),

            // ── Accessories ──────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPadding),
              child: Text(
                'Accessories',
                style: TextStyle(
                  fontSize: headingSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const ProductCarousel(category: 'Accessories'),
            SizedBox(height: isMobile ? 24 : 40),

            const Footer(),
          ],
        ),
      ),
    );
  }
}
