import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color.fromARGB(255, 71, 164, 245),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 80),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // About Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'About Thryft',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your trusted marketplace for sustainable and affordable second-hand goods.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 60),
              
              // Quick Links Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Links',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFooterLink(context, 'About Us'),
                    _buildFooterLink(context, 'Contact'),
                  ],
                ),
              ),
              const SizedBox(width: 60),
              
              // Support Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Support',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFooterLink(context, 'Help Center'),
                    _buildFooterLink(context, 'Terms of Service'),
                    _buildFooterLink(context, 'Privacy Policy'),
                    _buildFooterLink(context, 'Returns'),
                  ],
                ),
              ),
              const SizedBox(width: 60),
              
              // Contact Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact Us',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Email: info@thryft.com',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Phone: +44 123 456 7890',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Divider(color: Colors.black26),
          const SizedBox(height: 20),
          // Copyright Section
          const Text(
            '© 2026 Thryft. All rights reserved.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          _handleFooterLinkTap(context, text);
        },
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }

  void _handleFooterLinkTap(BuildContext context, String linkText) {
    switch (linkText) {
      case 'About Us':
        _showComingSoonMessage(context, 'About Us');
        break;
      case 'Contact':
        _showComingSoonMessage(context, 'Contact');
        break;
      case 'Help Center':
        _showComingSoonMessage(context, 'Help Center');
        break;
      case 'Terms of Service':
        _showInfoDialog(context, 'Terms of Service',
            'Terms of Service content will be displayed here.');
        break;
      case 'Privacy Policy':
        _showInfoDialog(context, 'Privacy Policy',
            'Privacy Policy content will be displayed here.');
        break;
      case 'Returns':
        _showInfoDialog(context, 'Returns Policy',
            'Returns policy information will be displayed here.');
        break;
      default:
        break;
    }
  }

  void _showComingSoonMessage(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}