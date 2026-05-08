// Static info page shown at /about. Linked from the site footer and nav drawer.
// Covers the company story, mission, values, and a CTA to the contact page.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thryft/utils/responsive.dart';
import 'package:thryft/widgets/footer.dart';
import 'package:thryft/widgets/app_drawer.dart';
import 'package:thryft/widgets/header.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    // All sizing is driven by whether we're on mobile — avoids separate layouts.
    final hPadding = isMobile ? 16.0 : 80.0;
    final titleSize = isMobile ? 28.0 : 48.0;
    final headingSize = isMobile ? 22.0 : 32.0;
    final bodySize = isMobile ? 15.0 : 18.0;
    final sectionGap = isMobile ? 32.0 : 60.0;

    return Scaffold(
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Header(),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 32 : 60,
                horizontal: hPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Title
                  Center(
                    child: Text(
                      'About Thryft',
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(height: isMobile ? 24 : 40),

                  // Story Section
                  Center(
                    child: Text(
                      'Our Story',
                      style: TextStyle(
                        fontSize: headingSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Founded in 2026, Thryft was born from a simple idea: great fashion '
                    'doesn\'t have to be new or expensive. We saw the potential in creating '
                    'a community where people could buy and sell pre-loved items, reducing '
                    'waste while building their wardrobes sustainably.\n\n'
                    'Today, we\'re proud to serve thousands of users who share our vision '
                    'for a more sustainable future in fashion.',
                    style: TextStyle(
                      fontSize: bodySize,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: sectionGap),

                  // Mission Section
                  Center(
                    child: Text(
                      'Our Mission',
                      style: TextStyle(
                        fontSize: headingSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'At Thryft, we believe in making sustainable fashion accessible to everyone. '
                    'Our mission is to create a trusted marketplace where you can buy and sell '
                    'quality second-hand goods, reducing waste while saving money.',
                    style: TextStyle(
                      fontSize: bodySize,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: sectionGap),

                  // Values Section
                  Center(
                    child: Text(
                      'Our Values',
                      style: TextStyle(
                        fontSize: headingSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Switch layout based on screen size — row on desktop, column on mobile.
                  isMobile
                      ? _buildMobileValueCards()
                      : _buildDesktopValueCards(),
                  SizedBox(height: sectionGap),

                  // CTA at the bottom — navigates to /contact.
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Want to learn more?',
                          style: TextStyle(
                            fontSize: isMobile ? 20.0 : 24.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => context.go('/contact'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF47A4F5),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 32 : 40,
                              vertical: isMobile ? 16 : 20,
                            ),
                            textStyle: TextStyle(fontSize: isMobile ? 16 : 18),
                          ),
                          child: const Text('Contact Us'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Footer(),
          ],
        ),
      ),
    );
  }

  // Three value cards laid out in a row for wider screens.
  Widget _buildDesktopValueCards() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildValueCard(
            'Sustainability',
            'We promote circular fashion by giving clothes a second life, '
                'reducing environmental impact.',
            Icons.eco,
          ),
        ),
        const SizedBox(width: 30),
        Expanded(
          child: _buildValueCard(
            'Affordability',
            'Quality fashion shouldn\'t break the bank. We make style '
                'accessible to everyone.',
            Icons.attach_money,
          ),
        ),
        const SizedBox(width: 30),
        Expanded(
          child: _buildValueCard(
            'Trust',
            'We ensure a safe and reliable platform for buyers and sellers '
                'to connect.',
            Icons.verified_user,
          ),
        ),
      ],
    );
  }

  // Same three cards stacked vertically for mobile screens.
  Widget _buildMobileValueCards() {
    return Column(
      children: [
        _buildValueCard(
          'Sustainability',
          'We promote circular fashion by giving clothes a second life, '
              'reducing environmental impact.',
          Icons.eco,
        ),
        const SizedBox(height: 16),
        _buildValueCard(
          'Affordability',
          'Quality fashion shouldn\'t break the bank. We make style '
              'accessible to everyone.',
          Icons.attach_money,
        ),
        const SizedBox(height: 16),
        _buildValueCard(
          'Trust',
          'We ensure a safe and reliable platform for buyers and sellers '
              'to connect.',
          Icons.verified_user,
        ),
      ],
    );
  }

  // Shared card layout used by both mobile and desktop value sections.
  Widget _buildValueCard(String title, String description, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Icon(icon, size: 60, color: const Color(0xFF47A4F5)),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
