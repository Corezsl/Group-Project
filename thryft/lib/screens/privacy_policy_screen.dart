// Static privacy policy page at /privacy-policy. Linked from the site footer.
// Content is hardcoded — no network call required. Uses IntrinsicHeight so the
// footer always sits at the bottom even when the content is shorter than the viewport.

import 'package:flutter/material.dart';
import 'package:thryft/utils/responsive.dart';
import '../widgets/footer.dart';
import '../widgets/app_drawer.dart';
import '../widgets/header.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
                            'Privacy Policy',
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 24 : 40),
                        // Policy body — all four paragraphs in a single styled Text widget.
                        const Text(
                          'We collect basic account and transaction information to provide and improve Thryft services.\n\n'
                          'Information is used for account management, order processing, customer support, and security monitoring.\n\n'
                          'We do not sell your personal data to third parties. Data may be shared with trusted service providers solely to operate the platform.\n\n'
                          'You may request account data updates or deletion by contacting support through the Contact page.',
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
