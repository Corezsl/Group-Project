import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/product.dart';
import 'package:thryft/widgets/header.dart';
import 'package:thryft/widgets/footer.dart';
import 'package:thryft/widgets/standard_product_grid.dart';
import 'package:go_router/go_router.dart';

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
    _listingsFuture = _fetchMyListings();
  }

  Future<List<Product>> _fetchMyListings() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];

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
      isSold: data['is_sold'] == true,
      department: data['department']?.toString() ?? 'All',
      category: data['category']?.toString() ?? 'Other',
      material: data['material'].toString(),
      colour: data['colour'].toString(),
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
                    'My Listings',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage the items you currently have up for sale.',
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
                      
                      final items = snapshot.data ?? [];

                      return SizedBox(
                        width: double.infinity,
                        child: StandardProductGrid(
                          items: items,
                          emptyIcon: Icons.list_alt,
                          emptyTitle: 'No active listings',
                          emptySubtitle: 'Items you list for sale will appear here.',
                          extraGridCard: GestureDetector(
                            onTap: () => context.go('/create-listing'),
                            behavior: HitTestBehavior.opaque,
                            child: SizedBox(
                              width: 140,
                              child: Card(
                                color: Colors.blue,
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.add_circle_outline, size: 28, color: Colors.white),
                                      SizedBox(height: 6),
                                      Text(
                                        'Create Listing',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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