// Static FAQ page at /help-center. Linked from the site footer and app drawer.
// Renders responsive FAQ cards — 1, 2, or 3 columns depending on screen width.
// FAQ entries are defined as a compile-time constant list so no network call is needed.

import 'package:flutter/material.dart';
import 'package:thryft/utils/responsive.dart';
import '../widgets/footer.dart';
import '../widgets/app_drawer.dart';
import '../widgets/header.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  // All FAQ entries — add new ones here to have them appear automatically.
  static const List<Map<String, String>> _faqItems = [
    {
      'question': 'How do I buy an item?',
      'answer':
          'Browse products, open the item details, then add to cart and checkout.',
    },
    {
      'question': 'How do I list an item for sale?',
      'answer':
          'Go to the Create Listing page from your account and complete the listing form.',
    },
    {
      'question': 'How can I contact support?',
      'answer':
          'Use the Contact page form and include your order details for faster support.',
    },
    {
      'question':
          'Am I able to negotiate with the seller if I think the price is too expensive?',
      'answer':
          'Yes, users are able to negotiate with sellers if they think the listed price is too expensive. Each listing includes a "Make an Offer" button, allowing buyers to submit their own proposed price to the seller. The seller can then choose to accept or reject the offer. Once an offer is accepted, the listing will be marked as sold.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Responsive sizing — padding and font sizes scale down on mobile.
    final isMobile = Responsive.isMobile(context);
    final hPadding = isMobile ? 16.0 : 80.0;
    final titleSize = isMobile ? 28.0 : 48.0;
    final headingSize = isMobile ? 20.0 : 28.0;

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
                  Center(
                    child: Text(
                      'Help Center',
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(height: isMobile ? 24 : 40),
                  Text(
                    'Frequently Asked Questions',
                    style: TextStyle(
                      fontSize: headingSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // LayoutBuilder lets us pick column count based on available width
                  // rather than device type, so the cards work in split-screen too.
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxisCount = width >= 850
                          ? 3
                          : width >= Responsive.mobileBreakpoint
                              ? 2
                              : 1;

                      final itemWidth =
                          (width - (crossAxisCount - 1) * 16) /
                              crossAxisCount;

                      return Wrap(
                        spacing: 16,
                        runSpacing: 18,
                        children: _faqItems.map((item) {
                          return SizedBox(
                            width: itemWidth,
                            child: _faqItem(
                              item['question']!,
                              item['answer']!,
                            ),
                          );
                        }).toList(),
                      );
                    },
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

  // Single FAQ card — question as the bold heading, answer as body text below.
  Widget _faqItem(String question, String answer) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              answer,
              style: const TextStyle(
                fontSize: 15,
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
