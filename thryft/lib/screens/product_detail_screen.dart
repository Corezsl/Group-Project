import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:thryft/models/product.dart';
import 'package:thryft/providers/cart_provider.dart';
import 'package:thryft/widgets/footer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, String> product;

  const ProductDetailScreen({super.key, required this.product});

  // App primary brand color
  static const Color brandColor = Color.fromARGB(255, 71, 164, 245);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(product['name'] ?? 'Product'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {},
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 800;

          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Image Gallery (60%)
                Expanded(
                  flex: 6,
                  child: Container(
                    color: Colors.white,
                    child: _buildImageGallery(context),
                  ),
                ),
                // Right Column: Info Panel (40%)
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: _buildInfoPanel(context),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Mobile: Stacked view
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildImageGallery(context),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildInfoPanel(context),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildImageGallery(BuildContext context) {
    return Hero(
      tag: 'product_image_${product['name']}',
      child: Container(
        constraints: const BoxConstraints(minHeight: 400),
        width: double.infinity,
        color: Colors.grey[100],
        child: Stack(
          alignment: Alignment.center,
          children: [
            product['imageUrl'] != null
              ? Image.network(
                  product['imageUrl']!,
                  fit: BoxFit.contain,
                )
              : const Icon(Icons.image, size: 100, color: Colors.grey),
            if (product['is_sold'] == 'true')
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text(
                  'SOLD',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4.0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Title & Meta
        Text(
          product['name'] ?? 'Unknown Item',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          "${product['size'] ?? 'N/A'} · ${product['condition'] ?? 'N/A'} · ${product['brand'] ?? 'Unbranded'}",
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        const SizedBox(height: 16),

        // 2. Pricing
        if (product['originalPrice'] != null)
          Text(
            "£${product['originalPrice']}",
            style: TextStyle(
              color: Colors.grey[500],
              decoration: TextDecoration.lineThrough,
              fontSize: 14,
            ),
          ),
        Text(
          "£${product['price'] ?? '0.00'}",
          style: const TextStyle(
            color: brandColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: const [
            Icon(Icons.shield_outlined, color: brandColor, size: 16),
            SizedBox(width: 4),
            Text(
              "Includes Buyer Protection",
              style: TextStyle(color: brandColor, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        const SizedBox(height: 16),

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
        (() {
          final currentUser = Supabase.instance.client.auth.currentUser;
          final isOwner = currentUser != null && product['sellerId'] == currentUser.id;
          final isSold = product['is_sold'] == 'true';

          // Sold item: show sold banner for everyone
          if (isSold) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sell_outlined, color: Colors.grey[500], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'This item has been sold',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          if (isOwner) {
            return SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  context.push('/create-listing', extra: product);
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: brandColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text(
                  "Edit listing",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }

          return Column(
            children: [
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
                        category: product['category'] ?? 'Other',
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product['name']} added to cart'),
                        duration: const Duration(seconds: 2),
                        action: SnackBarAction(
                          label: 'View Cart',
                          onPressed: () => context.push('/cart'),
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
        })(),
        const SizedBox(height: 32),

        // 7. Buyer Protection Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield, color: brandColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Buyer Protection fee",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.4),
                        children: const [
                          TextSpan(text: "Our "),
                          TextSpan(
                            text: "Buyer Protection",
                            style: TextStyle(color: brandColor, decoration: TextDecoration.underline),
                          ),
                          TextSpan(
                            text: " is added for a fee to every purchase made with the \"Buy now\" button. Buyer Protection includes our ",
                          ),
                          TextSpan(
                            text: "Refund Policy",
                            style: TextStyle(color: brandColor, decoration: TextDecoration.underline),
                          ),
                          TextSpan(text: "."),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // 8. Seller Profile Row
        if (product['sellerId'] != null) ...[
          InkWell(
            onTap: () {
              context.push('/user/${product['sellerId']}');
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[200],
                    child: const Icon(Icons.person, color: Colors.grey, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['sellerName'] ?? 'Unknown Seller',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "5.0 (0)",
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 40),
        if (!isDesktop(context)) const Footer(),
      ],
    );
  }

  bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 800;
  }

  Widget _buildDetailRow(String key, String value, {bool isLink = false}) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            key,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isLink ? brandColor : Colors.black87,
              fontWeight: isLink ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

