import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/product.dart';
import 'package:thryft/widgets/header.dart';
import 'package:thryft/widgets/footer.dart';
import 'package:thryft/widgets/standard_product_grid.dart';

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
      description: data['description']?.toString(),
      imageUrl2: data['image_url_2']?.toString(),
      imageUrl3: data['image_url_3']?.toString(),
      imageUrl4: data['image_url_4']?.toString(),
      imageUrl5: data['image_url_5']?.toString(),
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
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/create-listing'),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Listing'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
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