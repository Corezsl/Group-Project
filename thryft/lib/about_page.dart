import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'widgets/footer.dart';
import 'widgets/header.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Header(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Title
                  Center(
                    child: const Text(
                      'About Thryft',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Story Section
                  Center(
                    child: const Text(
                      'Our Story',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Founded in 2026, Thryft was born from a simple idea: great fashion '
                    'doesn\'t have to be new or expensive. We saw the potential in creating '
                    'a community where people could buy and sell pre-loved items, reducing '
                    'waste while building their wardrobes sustainably.\n\n'
                    'Today, we\'re proud to serve thousands of users who share our vision '
                    'for a more sustainable future in fashion.',
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Mission Section
                  Center(
                    child: const Text(
                      'Our Mission',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'At Thryft, we believe in making sustainable fashion accessible to everyone. '
                    'Our mission is to create a trusted marketplace where you can buy and sell '
                    'quality second-hand goods, reducing waste while saving money.',
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 60),
                  
                  // Values Section
                  Center(
                    child: const Text(
                      'Our Values',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  Row(
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
                  ),
                  const SizedBox(height: 60),
                  
                  // Contact CTA
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'Want to learn more?',
                          style: TextStyle(
                            fontSize: 24,
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 20,
                            ),
                            textStyle: const TextStyle(fontSize: 18),
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

  Widget _buildValueCard(String title, String description, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Icon(
              icon,
              size: 60,
              color: const Color(0xFF47A4F5),
            ),
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
