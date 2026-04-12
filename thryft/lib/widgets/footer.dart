import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thryft/utils/responsive.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Container(
      width: double.infinity,
      color: const Color.fromARGB(255, 71, 164, 245),
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 24 : 40,
        horizontal: isMobile ? 16 : 80,
      ),
      child: Column(
        children: [
          isMobile ? _buildMobileLayout(context) : _buildDesktopLayout(context),
          SizedBox(height: isMobile ? 24 : 40),
          const Divider(color: Colors.white),
          const SizedBox(height: 20),
          const Text(
            '© 2026 Thryft. All rights reserved.',
            style: TextStyle(fontSize: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ─── Desktop: 4 columns side by side ──────────────────────────────────────

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _aboutColumn()),
        const SizedBox(width: 60),
        Expanded(child: _quickLinksColumn(context)),
        const SizedBox(width: 60),
        Expanded(child: _supportColumn(context)),
        const SizedBox(width: 60),
        Expanded(child: _contactColumn()),
      ],
    );
  }

  // ─── Mobile: stacked vertically ───────────────────────────────────────────

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _aboutColumn(),
        const SizedBox(height: 24),
        _quickLinksColumn(context),
        const SizedBox(height: 24),
        _supportColumn(context),
        const SizedBox(height: 24),
        _contactColumn(),
      ],
    );
  }

  // ─── Column builders ──────────────────────────────────────────────────────

  Widget _aboutColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'About Thryft',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Your trusted marketplace for sustainable and affordable second-hand goods.',
          style: TextStyle(fontSize: 14, color: Colors.white),
        ),
      ],
    );
  }

  Widget _quickLinksColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Links',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        _buildFooterLink(context, 'About Us'),
        _buildFooterLink(context, 'Contact'),
      ],
    );
  }

  Widget _supportColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Support',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        _buildFooterLink(context, 'Help Center'),
        _buildFooterLink(context, 'Terms of Service'),
        _buildFooterLink(context, 'Privacy Policy'),
        _buildFooterLink(context, 'Returns'),
      ],
    );
  }

  Widget _contactColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Contact Us',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Email: info@thryft.com',
          style: TextStyle(fontSize: 14, color: Colors.white),
        ),
        SizedBox(height: 8),
        Text(
          'Phone: +44 123 456 7890',
          style: TextStyle(fontSize: 14, color: Colors.white),
        ),
        SizedBox(height: 8),
        Text(
          'Business Hours:\n\nMonday - Friday: 9am - 6pm\nWeekend: 10am - 4pm',
          style: TextStyle(fontSize: 14, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildFooterLink(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _handleFooterLinkTap(context, text),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }

  void _handleFooterLinkTap(BuildContext context, String linkText) {
    switch (linkText) {
      case 'About Us':
        context.go('/about');
        break;
      case 'Contact':
        context.go('/contact');
        break;
      case 'Help Center':
        context.go('/help-center');
        break;
      case 'Terms of Service':
        context.go('/terms-of-service');
        break;
      case 'Privacy Policy':
        context.go('/privacy-policy');
        break;
      case 'Returns':
        context.go('/returns');
        break;
      default:
        break;
    }
  }
}