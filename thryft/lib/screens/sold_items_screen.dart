import 'package:flutter/material.dart';
import 'package:thryft/widgets/header.dart';
import 'package:thryft/widgets/footer.dart';
import 'package:thryft/widgets/standard_product_grid.dart';
import 'package:thryft/models/product.dart';
import 'package:thryft/models/notification_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SoldItemsScreen extends StatefulWidget {
  const SoldItemsScreen({super.key});

  @override
  State<SoldItemsScreen> createState() => _SoldItemsScreenState();
}

class _SoldItemsScreenState extends State<SoldItemsScreen> {
  late Future<List<Product>> _soldItemsFuture;

  @override
  void initState() {
    super.initState();
    _soldItemsFuture = _fetchSoldItems();
  }

  Future<List<Product>> _fetchSoldItems() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await Supabase.instance.client
        .from('products')
        .select('*, profiles(username)')
        .eq('user_id', userId)
        .eq('is_sold', true)
        .order('created_at', ascending: false);

    final products = (response as List)
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
            description: data['description']?.toString(),
          ),
        )
        .toList();

    // Fetch buyer addresses from notifications for sold listings.
    final productIds = products.map((p) => p.id).toList();
    if (productIds.isEmpty) return products;

    try {
      final notifResponse = await Supabase.instance.client
          .from('notification')
          .select('listing_id, buyer_address')
          .eq('user_id', userId)
          .eq('notif_type', NotificationType.listingSold.toDbString())
          .inFilter('listing_id', productIds);

      final addressMap = <String, String>{};
      for (final row in notifResponse as List) {
        final listingId = row['listing_id']?.toString();
        final address = row['buyer_address']?.toString();
        if (listingId != null && address != null && address.isNotEmpty) {
          addressMap[listingId] = address;
        }
      }

      return products
          .map(
            (p) => Product(
              id: p.id,
              name: p.name,
              imageUrl: p.imageUrl,
              price: p.price,
              originalPrice: p.originalPrice,
              size: p.size,
              brand: p.brand,
              condition: p.condition,
              createdAt: p.createdAt,
              sellerId: p.sellerId,
              sellerName: p.sellerName,
              isSold: p.isSold,
              category: p.category,
              department: p.department,
              material: p.material,
              colour: p.colour,
              description: p.description,
              buyerAddress: addressMap[p.id],
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('Error fetching buyer addresses: $e');
      return products;
    }
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
                    'Sold Items',
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Items you have successfully sold to other users.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  FutureBuilder<List<Product>>(
                    future: _soldItemsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 300,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final soldItems = snapshot.data ?? [];

                      return SizedBox(
                        width: double.infinity,
                        child: StandardProductGrid(
                          items: soldItems,
                          emptyIcon: Icons.sell_outlined,
                          emptyTitle: 'No sold items yet',
                          emptySubtitle:
                              'Your sold items will appear here once they are purchased.',
                          dateFilterLabel: 'DATE SOLD',
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
