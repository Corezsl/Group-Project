// Displays products matching the filters chosen in the search/filter panel.
// Pushed onto the nav stack from the home or search screen with a SearchFilters object.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/product.dart';
import 'package:thryft/widgets/standard_product_grid.dart';
import 'package:thryft/providers/search_provider.dart';

class FilterResultsScreen extends StatefulWidget {
  // All the active filter values — only non-null ones are applied to the query.
  final SearchFilters filters;
  const FilterResultsScreen({super.key, required this.filters});

  @override
  State<FilterResultsScreen> createState() => _FilterResultsScreenState();
}

class _FilterResultsScreenState extends State<FilterResultsScreen> {
  late Future<List<Product>> _resultsFuture;

  @override
  void initState() {
    super.initState();
    _resultsFuture = _fetchFiltered(); // kick off the query immediately
  }

  // Builds and runs a dynamic Supabase query from the active filters.
  Future<List<Product>> _fetchFiltered() async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      var query = Supabase.instance.client
          .from('products')
          .select('*, profiles(username)')
          .eq('is_sold', false);

      // Hide the logged-in user's own listings from their results.
      if (currentUserId != null) {
        query = query.neq('user_id', currentUserId);
      }

      // Each filter is only applied if the user actually set it.
      final f = widget.filters;
      if (f.department != null) query = query.eq('department', f.department!);
      if (f.size != null) query = query.eq('size', f.size!);
      if (f.brand != null) query = query.eq('brand', f.brand!);
      if (f.condition != null) query = query.eq('condition', f.condition!);
      if (f.fitting != null) query = query.eq('fitting', f.fitting!);
      if (f.material != null) query = query.eq('material', f.material!);
      if (f.colour != null) query = query.eq('colour', f.colour!);
      if (f.minPrice != null) query = query.gte('price', f.minPrice!);
      if (f.maxPrice != null) query = query.lte('price', f.maxPrice!);

      // Apply sort order — defaults to newest first if none selected.
      List data;
      switch (f.sortBy) {
        case 'price_asc':
          data = await query.order('price', ascending: true);
          break;
        case 'price_desc':
          data = await query.order('price', ascending: false);
          break;
        default:
          data = await query.order('created_at', ascending: false);
      }

      return (data).map((row) => Product(
        id: row['id'].toString(),
        name: row['name'].toString(),
        price: (row['price'] as num).toDouble(),
        originalPrice: row['original_price'] != null ? (row['original_price'] as num).toDouble() : null,
        size: row['size']?.toString() ?? '',
        brand: row['brand']?.toString() ?? '',
        condition: row['condition']?.toString() ?? '',
        imageUrl: row['image_url']?.toString(),
        sellerId: row['user_id']?.toString(),
        sellerName: row['profiles'] != null ? row['profiles']['username']?.toString() : null,
        category: row['category']?.toString() ?? 'Other',
        department: row['department']?.toString() ?? 'All',
        createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'].toString()) : null,
        material: row['material']?.toString() ?? '',
        colour: row['colour']?.toString() ?? '',
        isSold: row['is_sold'] == true,
        description: row['description']?.toString(),
        imageUrl2: row['image_url_2']?.toString(),
        imageUrl3: row['image_url_3']?.toString(),
        imageUrl4: row['image_url_4']?.toString(),
        imageUrl5: row['image_url_5']?.toString(),
      )).toList();
    } catch (e) {
      debugPrint('Filter query error: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter results'),
      ),
      body: FutureBuilder<List<Product>>(
        future: _resultsFuture,
        builder: (context, snapshot) {
          // Show a spinner while the filtered query is in flight.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Falls back to an empty list if the fetch returned nothing.
          final items = snapshot.data ?? [];
          return SingleChildScrollView(
            child: Column(
              children: [
                // StandardProductGrid handles the empty state message internally.
                StandardProductGrid(
                  items: items,
                  emptyIcon: Icons.search_off,
                  emptyTitle: 'No results',
                  emptySubtitle: 'No items match your selected filters.',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}