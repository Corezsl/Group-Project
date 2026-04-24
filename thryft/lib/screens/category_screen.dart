import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/product.dart';
import 'package:thryft/widgets/header.dart';
import 'package:thryft/widgets/footer.dart';
import 'package:thryft/widgets/standard_product_grid.dart';

class CategoryScreen extends StatefulWidget {
  final String category;

  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchByCategory();
  }

  @override
  void didUpdateWidget(CategoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) {
      _productsFuture = _fetchByCategory();
    }
  }

  Future<List<Product>> _fetchByCategory() async {
    final categoryParam = widget.category.trim();
    if (categoryParam.isEmpty) {
      final response = await Supabase.instance.client
          .from('products')
          .select('*, profiles(username)')
          .eq('is_sold', false)
          .order('created_at', ascending: false);
      return (response as List).map((data) => Product(
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
        department: data['department']?.toString() ?? 'All',
        material: data['material'].toString(),
        colour: data['colour'].toString(),
        sellerName: data['profiles'] != null
            ? data['profiles']['username']?.toString()
            : null,
        isSold: data['is_sold'] == true,
        category: data['category']?.toString() ?? 'Other',
        description: data['description']?.toString(),
      )).toList();
    }

    // Normalize and build singular/plural variants, then search with wildcards.
    final normalized = categoryParam.toLowerCase();
    final altVariant = normalized.endsWith('s')
        ? normalized.substring(0, normalized.length - 1)
        : '${normalized}s';
    final patternA = '%$normalized%';
    final patternB = '%$altVariant%';

    final response = await Supabase.instance.client
        .from('products')
        .select('*, profiles(username)')
        //used ilike to search for similar terms
        .or('category.ilike.$patternA,category.ilike.$patternB')
        .eq('is_sold', false)
        .order('created_at', ascending: false);

    return (response as List).map((data) => Product(
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
      department: data['department']?.toString() ?? 'All',
      material: data['material'].toString(),
      colour: data['colour'].toString(),
      sellerName: data['profiles'] != null
          ? data['profiles']['username']?.toString()
          : null,
      isSold: data['is_sold'] == true,
      category: data['category']?.toString() ?? 'Other',
      description: data['description']?.toString(),
    )).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Header(),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.category,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Browse all ${widget.category.toLowerCase()} listings.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  FutureBuilder<List<Product>>(
                    future: _productsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 300,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final items = snapshot.data ?? [];

                      return SizedBox(
                        width: double.infinity,
                        child: StandardProductGrid(
                          items: items,
                          emptyIcon: Icons.checkroom_outlined,
                          emptyTitle: 'No listings found',
                          emptySubtitle:
                              'There are no ${widget.category.toLowerCase()} listings right now. Check back later!',
                        ),
                      );
                    },
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
