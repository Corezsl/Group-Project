// Static returns policy page at /returns. Linked from the site footer.
// Content is hardcoded — no network call needed. IntrinsicHeight keeps
// the footer pinned to the bottom even when the text is shorter than the viewport.

import 'package:flutter/material.dart';
import 'package:thryft/utils/responsive.dart';
import '../widgets/footer.dart';
import '../widgets/app_drawer.dart';
import '../widgets/header.dart';

class ReturnsScreen extends StatelessWidget {
  const ReturnsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Responsive padding and title size — tighter on mobile.
    final isMobile = Responsive.isMobile(context);
    final hPadding = isMobile ? 16.0 : 80.0;
    final titleSize = isMobile ? 28.0 : 48.0;

    return Scaffold(
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          // IntrinsicHeight lets the Expanded child push the footer to the bottom.
          child: IntrinsicHeight(
            child: Column(
              children: [
                const Header(),
                Expanded(
                  child: Container(
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
                            'Returns Policy',
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 24 : 40),
                        // Policy body — four paragraphs in a single Text widget with newlines.
                        const Text(
                          'Return requests must be submitted within 7 days of delivery.\n\n'
                          'Items must be returned in the same condition as received, with all original details and accessories included.\n\n'
                          'Refunds are processed after item inspection and may take several business days to appear in your account.\n\n'
                          'For return assistance, contact support from the Contact page and include your order reference.',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.7,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Footer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
