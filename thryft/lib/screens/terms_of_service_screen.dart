import 'package:flutter/material.dart';
import 'package:thryft/utils/responsive.dart';
import '../widgets/footer.dart';
import '../widgets/app_drawer.dart';
import '../widgets/header.dart';

// Static Terms of Service page.
//
// This is used by the router at /tos and gives users the basic rules for using
// Thryft. It does not load any data; it just shares the normal header, drawer,
// page content, and footer.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Adjust the spacing and title size so the page works on phones and desktop.
    final isMobile = Responsive.isMobile(context);
    final hPadding = isMobile ? 16.0 : 80.0;
    final titleSize = isMobile ? 28.0 : 48.0;

    return Scaffold(
      // Mobile users can still reach the main navigation from this page.
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Header(),
            // Main content wrapper for the terms text.
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
                      'Terms of Service',
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(height: isMobile ? 24 : 40),
                  // RichText keeps the headings and paragraphs flowing like one document.
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.7,
                        color: Colors.black87,
                      ),
                      children: [
                        TextSpan(
                          text: '1. Platform Use',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              '\n\nBy using Thryft, you agree to use the platform lawfully and respectfully. You are responsible for the accuracy of account and listing information.\n\n',
                        ),
                        TextSpan(
                          text: '2. Listing and Purchases',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              '\n\nSellers must provide accurate item descriptions and condition details. Buyers should review listings carefully before purchase.\n\n',
                        ),
                        TextSpan(
                          text: '3. Account Responsibility',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              '\n\nYou are responsible for maintaining the confidentiality of your account credentials and for activities under your account.\n\n',
                        ),
                        TextSpan(
                          text: '4. Policy Updates',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              '\n\nThese terms may be updated periodically. Continued use of Thryft after updates implies acceptance of the revised terms.',
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
}
