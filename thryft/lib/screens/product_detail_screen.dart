import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thryft/models/product.dart';
import 'package:thryft/providers/cart_provider.dart';
import 'package:thryft/router.dart';
import 'package:thryft/widgets/footer.dart';
import 'package:thryft/widgets/header.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, String> product;

  const ProductDetailScreen({super.key, required this.product});

  // App primary brand color
  static const Color brandColor = Color.fromARGB(255, 71, 164, 245);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Header(),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 800) {
                  return _buildDesktopLayout(context);
                } else {
                  return _buildMobileLayout(context);
                }
              },
            ),
            const Footer(),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: Image Gallery (60%)
          Expanded(
            flex: 6,
            child: _buildImageGallery(),
          ),
          const SizedBox(width: 48),
          // Right Side: Info Panel (40%)
          Expanded(
            flex: 4,
            child: _buildInfoPanel(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildImageGallery(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildInfoPanel(context),
        ),
      ],
    );
  }

  Widget _buildImageGallery() {
    return Hero(
      tag: 'product_image_${product['id']}',
      child: Container(
        height: 500,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F3),
          borderRadius: BorderRadius.circular(2),
        ),
        child: product['imageUrl'] != null
            ? Image.network(
                product['imageUrl']!,
                fit: BoxFit.cover,
              )
            : const Center(
                child: Icon(Icons.image, size: 80, color: Colors.grey),
              ),
      ),
    );
  }

  Widget _buildInfoPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Title & Price
        Text(
          product['name'] ?? 'Product',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "£${product['price'] ?? '0.00'}",
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: brandColor,
          ),
        ),
        const SizedBox(height: 24),

        // 2. Buyer Protection (Shield icon area)
        Row(
          children: [
            const Icon(Icons.shield_outlined, color: brandColor, size: 20),
            const SizedBox(width: 8),
            const Text(
              "Includes Buyer Protection",
              style: TextStyle(color: brandColor, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            border: Border.all(color: const Color(0xFFEEEEEE)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            "Buyer Protection fee: shield box detailing the protection policy.",
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ),
        const SizedBox(height: 24),

        // 3. Details Table
        _buildDetailRow("Brand", product['brand'] ?? '-', isLink: true),
        const SizedBox(height: 12),
        _buildDetailRow("Size", product['size'] ?? '-'),
        const SizedBox(height: 12),
        _buildDetailRow("Condition", product['condition'] ?? '-'),
        const SizedBox(height: 12),
        _buildDetailRow("Colour", "Various"), // Hardcoded for prototype
        const SizedBox(height: 16),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        const SizedBox(height: 16),

        // 4. Description
        const Text(
          "This is a vintage item in great condition. "
          "Fetch a real item description from backend later in the project.",
          style: TextStyle(color: Colors.black87, height: 1.5, fontSize: 15),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        const SizedBox(height: 16),

        // 5. Postage
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Postage",
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
            Text(
              "from £2.29",
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 6. Action Buttons
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              final cartProvider = context.read<CartProvider>();
              cartProvider.addItem(
                Product(
                  id: product['id'] ?? product['name']!,
                  name: product['name'] ?? 'Product',
                  price: double.tryParse(product['price'] ?? '0') ?? 0,
                  originalPrice: product['originalPrice'] != null
                      ? double.tryParse(product['originalPrice']!)
                      : null,
                  size: product['size'] ?? '',
                  brand: product['brand'] ?? '',
                  condition: product['condition'] ?? '',
                  imageUrl: product['imageUrl'],
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product['name']} added to cart'),
                  duration: const Duration(seconds: 2),
                  action: SnackBarAction(
                    label: 'View Cart',
                    onPressed: () => router.push('/cart'),
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: brandColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text(
              "Buy now",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: brandColor,
              side: const BorderSide(color: brandColor, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text(
              "Make an offer",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: brandColor,
              side: const BorderSide(color: brandColor, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text(
              "Ask seller",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLink = false}) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isLink ? brandColor : Colors.black87,
              fontSize: 14,
              fontWeight: isLink ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
