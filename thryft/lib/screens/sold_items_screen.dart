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

    final rawData = response as List;
    final products = rawData
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

    if (products.isEmpty) return products;

    final Map<String, String> addressByProductId = {};

    // ── Primary: look up buyer addresses from the address table via buyer_id ──
    final buyerIds = rawData
        .map((d) => d['buyer_id']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .toSet()
        .cast<String>()
        .toList();

    if (buyerIds.isNotEmpty) {
      try {
        final addressResponse = await Supabase.instance.client
            .from('address')
            .select('user_id, street, city, postal_code, country')
            .inFilter('user_id', buyerIds);

        final buyerAddressMap = <String, String>{};
        for (final row in addressResponse as List) {
          final uid = row['user_id']?.toString();
          final parts = [
            row['street'],
            row['city'],
            row['postal_code'],
            row['country'],
          ].where((p) => p != null && p.toString().isNotEmpty).toList();
          if (uid != null && parts.isNotEmpty) {
            buyerAddressMap[uid] = parts.join(', ');
          }
        }

        // Map each product to its buyer's address
        for (int i = 0; i < rawData.length; i++) {
          final buyerId = rawData[i]['buyer_id']?.toString();
          if (buyerId != null && buyerAddressMap.containsKey(buyerId)) {
            addressByProductId[products[i].id] = buyerAddressMap[buyerId]!;
          }
        }
      } catch (e) {
        debugPrint('Error fetching addresses from address table: $e');
      }
    }

    // ── Fallback: notification table (for historical / edge-case coverage) ──
    try {
      final notifResponse = await Supabase.instance.client
          .from('notification')
          .select('listing_id, buyer_address')
          .eq('user_id', userId)
          .eq('notif_type', NotificationType.listingSold.toDbString());
      debugPrint('Sold items: ${products.length} products, notif rows: ${(notifResponse as List).length}');
      for (final row in notifResponse as List) {
        debugPrint('  listing_id=${row['listing_id']} buyer_address=${row['buyer_address']}');
      }
      
      final productIdSet = products.map((p) => p.id).toSet();
      for (final row in notifResponse as List) {
        final listingId = row['listing_id']?.toString();
        final address = row['buyer_address']?.toString();
        if (listingId != null &&
            productIdSet.contains(listingId) &&
            address != null &&
            address.isNotEmpty) {
          addressByProductId[listingId] = address;
        }
      }
    } catch (e) {
      debugPrint('Error fetching notification addresses: $e');
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
            buyerAddress: addressByProductId[p.id],
          ),
        )
        .toList();
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
