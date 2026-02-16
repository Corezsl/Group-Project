import 'package:flutter/material.dart';
import 'package:thryft/screens/product_detail_screen.dart';

class ProductCarousel extends StatefulWidget {
  const ProductCarousel({super.key});

  @override
  State<ProductCarousel> createState() => _ProductCarouselState();
}

class _ProductCarouselState extends State<ProductCarousel> {
  final ScrollController _scrollController = ScrollController();

  // how far we scroll when pressing the arrows
  static const double _scrollAmount = 344; // roughly 2 cards

  // placeholder product data for now
  final List<Map<String, String>> products = List.generate(10, (index) {
    return {'name': 'Product ${index + 1}', 'price': '\$${(index + 1) * 5}.00'};
  });

  void _scrollLeft() {
    _scrollController.animateTo(
      (_scrollController.offset - _scrollAmount).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      (_scrollController.offset + _scrollAmount).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Row(
        children: [
          // left arrow
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 32),
            onPressed: _scrollLeft,
            color: Colors.black87,
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              controller: _scrollController,
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final product = products[index];
                // ... inside itemBuilder
              return SizedBox(
                width: 160,
                child: Card(
                  clipBehavior: Clip.antiAlias, // Ensures ink splash is contained
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(product: product),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Wrapped in Hero for animation
                          Expanded(
                            child: Hero(
                              tag: 'product_image_${product['name']}',
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // ... rest of your text widgets (name, price) remain the same
                          const SizedBox(height: 8),
                          Text(
                            product['name']!,
                            // ... styles
                          ),
                          // ...
                        ],
                      ),
                    ),
                  ),
                ),
              );
              },
            ),
          ),
          // right arrow
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 32),
            onPressed: _scrollRight,
            color: Colors.black87,
          ),
        ],
      ),
    );
  }
}
