import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/product.dart';
import 'package:thryft/widgets/product_card.dart';
import 'package:go_router/go_router.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _profile;
  List<Product> _products = [];
  List<Map<String, dynamic>> _ratings = [];
  int _soldCount = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchProfileAndProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

      final loadedProducts = (productsData as List)
          .where((data) => data['is_sold'] != true) // Hide sold items from profile
          .map((data) => Product(
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
        isSold: data['is_sold'] == true,
        category: data['category']?.toString() ?? 'Other',
      )).toList();

      // 3. Fetch Ratings
      final ratingsData = await client
          .from('ratings')
          .select('*, products(*)')
          .eq('seller_id', widget.userId)
          .order('created_at', ascending: false);

      // 4. Fetch Sold Items Count
      final soldData = await client
          .from('products')
          .select('id')
          .eq('user_id', widget.userId)
          .eq('is_sold', true);
      
      final soldCount = (soldData as List).length;

      if (mounted) {
        setState(() {
          _profile = profileData;
          _products = loadedProducts;
          _ratings = List<Map<String, dynamic>>.from(ratingsData as List);
          _soldCount = soldCount;
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
    final rating = _profile?['rating'] ?? 0.0;
    final ratingCount = _profile?['rating_count'] ?? 0;
    final avatarUrl = _profile?['avatar_url'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(username),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey[200]),
        ),
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
                         rating is double ? rating.toStringAsFixed(1) : '$rating',
                         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                       ),
                       const SizedBox(width: 4),
                       Text(
                         '($ratingCount)',
                         style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                       ),
                       const SizedBox(width: 8),
                       Text(
                         '•',
                         style: TextStyle(color: Colors.grey[400]),
                       ),
                       const SizedBox(width: 8),
                       Text(
                         '$_soldCount sold',
                         style: TextStyle(color: Colors.grey[600], fontSize: 14),
                       ),
                     ],
                   )
                ],
              ),
            ),
          ),

          // Tabs
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: const Color.fromARGB(255, 71, 164, 245),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color.fromARGB(255, 71, 164, 245),
                tabs: [
                  Tab(text: 'Listings (${_products.length})'),
                  Tab(text: 'Reviews (${_ratings.length})'),
                ],
                onTap: (index) => setState(() {}),
              ),
            ),
          ),

          // Conditional Sliver Content
          if (_tabController.index == 0) ...[
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
                padding: const EdgeInsets.all(16.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16.0,
                    crossAxisSpacing: 16.0,
                    childAspectRatio: 0.65,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ProductCard(product: _products[index]),
                    childCount: _products.length,
                  ),
                ),
              ),
          ] else ...[
            // Reviews Tab
            if (_ratings.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text('No reviews yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final review = _ratings[index];
                      // final productName = review['products']?['name'] ?? 'Product';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.grey[200]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: List.generate(5, (starIndex) {
                                  return Icon(
                                    starIndex < (review['rating'] as int) ? Icons.star : Icons.star_border,
                                    color: Colors.amber,
                                    size: 16,
                                  );
                                }),
                              ),
                              const SizedBox(height: 8),
                              if (review['comment'] != null && review['comment'].toString().isNotEmpty)
                                Text(
                                  review['comment'],
                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                ),
                              const SizedBox(height: 8),
                              if (review['products'] != null) ...[
                                const Divider(height: 24),
                                InkWell(
                                  onTap: () {
                                    final p = review['products'];
                                    context.push('/product/${p['id']}', extra: {
                                      'id': p['id'].toString(),
                                      'name': p['name'].toString(),
                                      'price': p['price'].toString(),
                                      'size': p['size'].toString(),
                                      'condition': p['condition'].toString(),
                                      'brand': p['brand'].toString(),
                                      'imageUrl': p['image_url']?.toString() ?? '',
                                      'sellerId': widget.userId,
                                      'sellerName': _profile?['username'] ?? 'Unknown Seller',
                                      'is_sold': p['is_sold']?.toString() ?? 'false',
                                    });
                                  },
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: SizedBox(
                                          width: 60,
                                          height: 60,
                                          child: review['products']['image_url'] != null
                                              ? Image.network(
                                                  review['products']['image_url'],
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  color: Colors.grey[100],
                                                  child: const Icon(Icons.image, size: 24, color: Colors.grey),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              review['products']['name'] ?? 'Unknown Item',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '£${review['products']['price']}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: _ratings.length,
                  ),
                ),
              ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
