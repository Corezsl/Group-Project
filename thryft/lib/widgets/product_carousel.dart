import 'package:flutter/material.dart';
import 'package:thryft/models/product.dart';
import 'package:thryft/widgets/product_card.dart';

class ProductCarousel extends StatefulWidget {
  const ProductCarousel({super.key});

  @override
  State<ProductCarousel> createState() => _ProductCarouselState();
}

class _ProductCarouselState extends State<ProductCarousel> {
  final ScrollController _scrollController = ScrollController();

  // how far we scroll when pressing the arrows (roughly 2 cards)
  static const double _scrollAmount = 344;

  // placeholder product data
  final List<Product> products = const [
    Product(
      id: '1',
      name: 'Vintage Denim Jacket',
      price: 24.99,
      originalPrice: 39.99,
      size: 'M',
      brand: 'Levi\'s',
      condition: 'Good',
    ),
    Product(
      id: '2',
      name: 'White Sneakers',
      price: 18.00,
      size: '42',
      brand: 'Nike',
      condition: 'Like New',
    ),
    Product(
      id: '3',
      name: 'Floral Summer Dress',
      price: 12.50,
      originalPrice: 22.00,
      size: 'S',
      brand: 'Zara',
      condition: 'Like New',
    ),
    Product(
      id: '4',
      name: 'Wool Coat',
      price: 45.00,
      size: 'L',
      brand: 'H&M',
      condition: 'Good',
    ),
    Product(
      id: '5',
      name: 'Leather Belt',
      price: 8.00,
      size: 'One Size',
      brand: 'Unbranded',
      condition: 'Fair',
    ),
    Product(
      id: '6',
      name: 'Graphic Tee',
      price: 6.99,
      originalPrice: 14.99,
      size: 'XL',
      brand: 'ASOS',
      condition: 'Good',
    ),
    Product(
      id: '7',
      name: 'Chino Trousers',
      price: 15.00,
      size: '32',
      brand: 'Gap',
      condition: 'Like New',
    ),
    Product(
      id: '8',
      name: 'Puffer Jacket',
      price: 30.00,
      size: 'M',
      brand: 'The North Face',
      condition: 'Good',
    ),
    Product(
      id: '9',
      name: 'Silk Blouse',
      price: 10.00,
      size: 'S',
      brand: 'Reiss',
      condition: 'Like New',
    ),
    Product(
      id: '10',
      name: 'Running Shoes',
      price: 22.00,
      originalPrice: 35.00,
      size: '40',
      brand: 'Adidas',
      condition: 'Good',
    ),
  ];

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
