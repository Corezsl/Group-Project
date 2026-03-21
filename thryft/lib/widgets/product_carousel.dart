import 'package:flutter/material.dart';
import 'package:thryft/models/product.dart';
import 'package:thryft/widgets/product_card.dart';
import 'package:thryft/data/dummy_data.dart';

class ProductCarousel extends StatefulWidget {
  const ProductCarousel({super.key});

  @override
  State<ProductCarousel> createState() => _ProductCarouselState();
}

class _ProductCarouselState extends State<ProductCarousel> {
  final ScrollController _scrollController = ScrollController();

  // how far we scroll when pressing the arrows (roughly 2 cards)
  static const double _scrollAmount = 344;

  // placeholder product data(fetch real data from backend later in the project)
  final List<Product> products = dummyProducts;

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
      height: 280,
      child: Row(
        children: [
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
                return ProductCard(product: products[index]);
              },
            ),
          ),
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
