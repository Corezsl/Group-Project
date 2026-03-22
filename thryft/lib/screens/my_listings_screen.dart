import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/product.dart';
import 'package:thryft/widgets/standard_product_grid.dart';
import 'package:thryft/widgets/header.dart';
import 'package:thryft/widgets/footer.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  late Future<List<Product>> _listingsFuture;

  @override
  void initState() {
    super.initState();
    _listingsFuture = _fetchListings();
  }

  Future<List<Product>> _fetchListings() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];

    // Only show ACTIVE (unsold) listings on this screen
    final response = await Supabase.instance.client
        .from('products')
        .select('*, profiles(username)')
        .eq('user_id', userId)
        .eq('is_sold', false)
        .order('created_at', ascending: false);

    return (response as List).map((data) => Product(
      id: data['id'].toString(),
      name: data['name'].toString(),
      price: (data['price'] as num).toDouble(),
      originalPrice: data['original_price'] != null ? (data['original_price'] as num).toDouble() : null,
      size: data['size'].toString(),
      brand: data['brand'].toString(),
      condition: data['condition'].toString(),
      imageUrl: data['image_url']?.toString(),
      sellerId: data['user_id']?.toString(),
      sellerName: data['profiles'] != null ? data['profiles']['username']?.toString() : null,
      isSold: false,
      category: data['category']?.toString() ?? 'Other',
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
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.go('/account'),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'My Listings',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your active listings (sold items appear in Sold Items).',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  FutureBuilder<List<Product>>(
                    future: _listingsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 300,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final listings = snapshot.data ?? [];

                      return SizedBox(
                        width: double.infinity,
                        child: StandardProductGrid(
                          items: listings,
                          emptyIcon: Icons.inventory_2_outlined,
                          emptyTitle: 'You have no active listings',
                          emptySubtitle: 'Start selling your items today.',
                          dateFilterLabel: 'DATE LISTED',
                          extraButton: ElevatedButton(
                            onPressed: () => context.push('/create-listing'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Create a Listing',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
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
