import 'package:flutter/material.dart';
import 'package:thryft/utils/responsive.dart';
import '../widgets/footer.dart';
import '../widgets/header.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

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
  ];

  @override
  Widget build(BuildContext context) {
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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxisCount = width >= 850
                          ? 3
                          : width >= Responsive.mobileBreakpoint
                              ? 2
                              : 1;

                      final aspectRatio = crossAxisCount == 1
                          ? 2.6
                          : crossAxisCount == 2
                              ? 1.7
                              : 1.4;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _faqItems.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 18,
                          childAspectRatio: aspectRatio,
                        ),
                        itemBuilder: (context, index) {
                          final item = _faqItems[index];
                          return _faqItem(
                            item['question']!,
                            item['answer']!,
                          );
                        },
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
