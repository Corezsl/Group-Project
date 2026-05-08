import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/product.dart';
import 'package:thryft/widgets/standard_product_grid.dart';
import 'package:thryft/screens/reviews_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final SupabaseClient? supabaseClient;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.supabaseClient,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
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
      final client = widget.supabaseClient ?? Supabase.instance.client;
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

      // 2. Fetch Products (active only)
      final productsData = await client
          .from('products')
          .select()
          .eq('user_id', widget.userId)
          .eq('is_sold', false)
          .order('created_at', ascending: false);

      final loadedProducts = (productsData as List)
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
              sellerId: widget.userId,
              sellerName: profileData['username']?.toString(),
              isSold: false,
              department: data['department']?.toString() ?? 'All',
              category: data['category']?.toString() ?? 'Other',
              material: data['material'].toString(),
              colour: data['colour'].toString(),
            ),
          )
          .toList();

      // 3. Fetch Ratings with product info and buyer profile (via new FK to profiles)
      final ratingsData = await client
          .from('ratings')
          .select(
            '*, products(*), profiles!ratings_buyer_profile_fkey(username)',
          )
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('User Profile')),
        body: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    final username = _profile?['username'] ?? 'Unknown User';
    final ratingCount = _ratings.length;
    final rating = ratingCount > 0
        ? _ratings
                  .map((r) => (r['rating'] as num).toDouble())
                  .reduce((a, b) => a + b) /
              ratingCount
        : 0.0;
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
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl) as ImageProvider
                        : null,
                    child: avatarUrl == null
                        ? const Icon(Icons.person, size: 40, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        rating is double
                            ? rating.toStringAsFixed(1)
                            : '$rating',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        _StatBox(value: '$_soldCount', label: 'Sold'),
                        VerticalDivider(
                          width: 32,
                          thickness: 1,
                          color: Colors.grey[300],
                        ),
                        _StatBox(
                          value: ratingCount == 0
                              ? 'N/A'
                              : rating.toStringAsFixed(1),
                          label: ratingCount == 0
                              ? 'No reviews'
                              : 'Rating ($ratingCount)',
                          icon: ratingCount == 0 ? null : Icons.star,
                          iconColor: Colors.amber,
                        ),
                      ],
                    ),
                  ),
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
            SliverToBoxAdapter(
              child: StandardProductGrid(
                items: _products,
                emptyIcon: Icons.list_alt,
                emptyTitle: 'No active listings',
                emptySubtitle: 'This user has no active listings.',
              ),
            ),
          ] else ...[
            // Reviews Tab
            ReviewsScreen(
              ratings: _ratings,
              sellerId: widget.userId,
              sellerName: _profile?['username'] ?? 'Unknown Seller',
              currentUserId: (widget.supabaseClient ?? Supabase.instance.client)
                  .auth
                  .currentUser
                  ?.id,
              onReviewChanged: _fetchProfileAndProducts,
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
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final Color? iconColor;

  const _StatBox({
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 3),
            ],
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
