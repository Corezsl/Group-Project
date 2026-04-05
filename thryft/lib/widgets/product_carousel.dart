import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/product.dart';
import 'package:thryft/widgets/product_card.dart';

class ProductCarousel extends StatefulWidget {
  final String? category;

  const ProductCarousel({super.key, this.category});

  @override
  State<ProductCarousel> createState() => _ProductCarouselState();
}

class _ProductCarouselState extends State<ProductCarousel> {
  final ScrollController _scrollController = ScrollController();

  // how far we scroll when pressing the arrows (roughly 2 cards)
  static const double _scrollAmount = 344;

  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProducts();
  }

  Future<List<Product>> _fetchProducts() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    var query = Supabase.instance.client
        .from('products')
        .select('*, profiles(username)');

    if (userId != null) {
      // Exclude products created by the current user
      query = query.neq('user_id', userId);
    }
    if (widget.category != null) {
      query = query.eq('category', widget.category!);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .where((data) => data['is_sold'] != true) // Filter out sold items
        .map(
          (data) => Product(
            id: data['id'].toString(),
            name: data['name'].toString(),
            price: (data['price'] as num).toDouble(),
            originalPrice: data['original_price'] != null
                ? (data['original_price'] as num).toDouble()
                : null,
            size: data['size'].toString(),
            brand: data['brand'].toString(),
            condition: data['condition'].toString(),
            imageUrl: data['image_url']?.toString(),
            sellerId: data['user_id']?.toString(),
            sellerName: data['profiles'] != null
                ? data['profiles']['username']?.toString()
                : null,
            isSold: data['is_sold'] == true,
            category: data['category']?.toString() ?? 'Other',
            department: data['department']?.toString() ?? 'All',
            material: data['material'].toString(),
            colour: data['colour'].toString(),
          ),
        )
        .toList();
  }

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
      child: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading products.'));
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return const Center(
              child: Text(
                'No products available right now.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return Row(
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
          );
        },
      ),
    );
  }
}
