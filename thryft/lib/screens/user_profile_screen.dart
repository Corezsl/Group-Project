import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/product.dart';
import 'package:thryft/widgets/product_card.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _profile;
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchProfileAndProducts();
  }

  Future<void> _fetchProfileAndProducts() async {
    try {
      final client = Supabase.instance.client;
      // 1. Fetch Profile
      final profileData = await client
          .from('profiles')
          .select()
          .eq('id', widget.userId)
          .maybeSingle();

      if (profileData == null) {
        if (mounted) {
          setState(() {
            _error = 'User not found.';
            _isLoading = false;
          });
        }
        return;
      }

      // 2. Fetch Products
      final productsData = await client
          .from('products')
          .select()
          .eq('user_id', widget.userId)
          .order('created_at', ascending: false);

      final loadedProducts = (productsData as List).map((data) => Product(
        id: data['id'].toString(),
        name: data['name'].toString(),
        price: (data['price'] as num).toDouble(),
        originalPrice: data['original_price'] != null ? (data['original_price'] as num).toDouble() : null,
        size: data['size'].toString(),
        brand: data['brand'].toString(),
        condition: data['condition'].toString(),
        imageUrl: data['image_url']?.toString(),
        sellerId: widget.userId,
        sellerName: profileData['username']?.toString(),
      )).toList();

      if (mounted) {
        setState(() {
          _profile = profileData;
          _products = loadedProducts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading profile: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('User Profile')),
        body: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
      );
    }

    final username = _profile?['username'] ?? 'Unknown User';
    final rating = _profile?['rating'] ?? 5.0;
    final ratingCount = _profile?['rating_count'] ?? 0;
    final avatarUrl = _profile?['avatar_url'];

    return Scaffold(
      appBar: AppBar(
        title: Text(username),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                   CircleAvatar(
                     radius: 40,
                     backgroundColor: Colors.grey[200],
                     backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) as ImageProvider : null,
                     child: avatarUrl == null ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
                   ),
                   const SizedBox(height: 16),
                   Text(
                     username,
                     style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                   ),
                   const SizedBox(height: 8),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       const Icon(Icons.star, color: Colors.amber, size: 20),
                       const SizedBox(width: 4),
                       Text(
                         '$rating',
                         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                       ),
                       const SizedBox(width: 4),
                       Text(
                         '($ratingCount)',
                         style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                       ),
                     ],
                   )
                ],
              ),
            ),
          ),
          
          const SliverToBoxAdapter(
            child: Divider(height: 1),
          ),

          // Listings Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Text(
                '${_products.length} listings',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          // Grid
          if (_products.isEmpty)
             const SliverToBoxAdapter(
               child: Padding(
                 padding: EdgeInsets.all(32.0),
                 child: Center(
                   child: Text('This user has no active listings.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                 ),
               )
             )
          else
             SliverPadding(
               padding: const EdgeInsets.symmetric(horizontal: 16.0),
               sliver: SliverGrid(
                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                   crossAxisCount: 2,
                   mainAxisSpacing: 16.0,
                   crossAxisSpacing: 16.0,
                   childAspectRatio: 0.65,
                 ),
                 delegate: SliverChildBuilderDelegate(
                   (context, index) {
                     return ProductCard(product: _products[index]);
                   },
                   childCount: _products.length,
                 ),
               ),
             ),
             
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}
