import 'package:flutter/material.dart';
import 'package:thryft/utils/responsive.dart';
import 'widgets/footer.dart';
import 'widgets/header.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final hPadding = isMobile ? 16.0 : 80.0;
    final titleSize = isMobile ? 28.0 : 48.0;

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
                      'Privacy Policy',
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(height: isMobile ? 24 : 40),
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
            const Footer(),
          ],
        ),
      ),
    );
  }
}
