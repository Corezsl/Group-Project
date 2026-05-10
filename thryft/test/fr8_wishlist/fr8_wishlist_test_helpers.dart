import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/product.dart';
import 'package:thryft/providers/wishlist_provider.dart';

import '../helpers/seed_helper.dart';
import '../helpers/supabase_test_client.dart';

const fr8TestPassword = 'Thryft!test99';

class Fr8WishlistTestContext {
  Fr8WishlistTestContext(this.scope);

  final String scope;

  late SupabaseClient client;
  late SupabaseClient serviceClient;
  late String sellerId;
  late String buyer1Id;
  late String buyer2Id;

  final listingIds = <String>[];
  final userIds = <String>[];

  String get _emailPrefix => 'fr8.$runId.$scope';

  String get _usernamePrefix {
    return 'fr8_${runId}_$scope'.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
  }

  Future<void> setUpAll() async {
    client = await getTestClient();
    serviceClient = getServiceClient();

    sellerId = await ensureTestUser(
      email: '$_emailPrefix.seller@thryft-test.local',
      username: '${_usernamePrefix}_seller',
    );
    buyer1Id = await ensureTestUser(
      email: '$_emailPrefix.buyer1@thryft-test.local',
      username: '${_usernamePrefix}_buyer_1',
    );
    buyer2Id = await ensureTestUser(
      email: '$_emailPrefix.buyer2@thryft-test.local',
      username: '${_usernamePrefix}_buyer_2',
    );

    userIds.addAll([sellerId, buyer1Id, buyer2Id]);
  }

  Future<void> tearDown() async {
    if (listingIds.isEmpty) return;

    // Clean up wishlist first
    for (final listingId in listingIds) {
      try {
        await client.from('wishlist').delete().eq('listing_id', listingId);
      } catch (e) {
        // Ignore cleanup errors
      }
    }

    // Then delete products to avoid FK constraint issues
    await serviceClient.from('products').delete().inFilter('id', List<String>.from(listingIds));

    listingIds.clear();
  }

  Future<void> tearDownAll() async {
    await tearDown();
    
    await client.auth.signOut();
    if (userIds.isEmpty) return;

    await serviceClient.from('profiles').delete().inFilter('id', userIds);
    for (final userId in userIds) {
      try {
        await serviceClient.auth.admin.deleteUser(userId);
      } catch (_) {}
    }
  }

  Future<String> ensureTestUser({
    required String email,
    required String username,
  }) async {
    try {
      final created = await serviceClient.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: fr8TestPassword,
          emailConfirm: true,
          userMetadata: {'username': username},
        ),
      );
      final user = created.user;
      if (user == null) throw StateError('Could not create test user $email');

      await serviceClient.from('profiles').upsert({
        'id': user.id,
        'username': username,
        'rating': 0.0,
        'rating_count': 0,
      });

      return user.id;
    } on AuthException catch (e) {
      if (!e.message.contains('already') && !e.message.contains('registered')) {
        rethrow;
      }

      final existing = await _findUserByEmail(email);
      if (existing == null) {
        throw StateError('Test user exists but could not be found: $email');
      }

      await serviceClient.from('profiles').upsert({
        'id': existing.id,
        'username': username,
        'rating': 0.0,
        'rating_count': 0,
      });

      return existing.id;
    }
  }

  Future<User?> _findUserByEmail(String email) async {
    for (var page = 1; page <= 5; page++) {
      final users = await serviceClient.auth.admin.listUsers(
        page: page,
        perPage: 1000,
      );
      for (final user in users) {
        if (user.email == email) return user;
      }
      if (users.length < 1000) break;
    }
    return null;
  }

  Future<String> seedProduct({
    required String name,
    required double price,
    String? sellerId,
  }) async {
    final actualSellerId = sellerId ?? this.sellerId;
    
    final productData = {
      'name': name,
      'price': price,
      'size': 'M',
      'brand': 'Test Brand',
      'condition': 'Good',
      'department': 'Tops',
      'category': 'T-Shirts',
      'material': 'Cotton',
      'colour': 'Blue',
      'user_id': actualSellerId,
      'created_at': DateTime.now().toIso8601String(),
    };

    final result = await serviceClient
        .from('products')
        .insert(productData)
        .select('id')
        .single();

    final listingId = result['id'] as String;
    listingIds.add(listingId);
    return listingId;
  }

  Future<Product> getProduct(String listingId) async {
    final result = await client
        .from('products')
        .select()
        .eq('id', listingId)
        .single();

    return Product(
      id: result['id'] as String,
      name: result['name'] as String,
      imageUrl: result['image_url'] as String?,
      price: (result['price'] as num).toDouble(),
      originalPrice: result['original_price'] != null 
          ? (result['original_price'] as num).toDouble() 
          : null,
      size: result['size'] as String,
      brand: result['brand'] as String,
      condition: result['condition'] as String,
      createdAt: result['created_at'] != null 
          ? DateTime.parse(result['created_at'] as String)
          : null,
      sellerId: result['user_id'] as String?,
      sellerName: null,
      isSold: result['is_sold'] as bool? ?? false,
      department: result['department'] as String,
      category: result['category'] as String,
      material: result['material'] as String,
      colour: result['colour'] as String,
    );
  }

  Future<WishlistProvider> createWishlistProvider(String userId) async {
    // For testing purposes, return a test provider
    return WishlistProvider.test();
  }

  Future<bool> isWishlisted(String userId, String listingId) async {
    final result = await client
        .from('wishlist')
        .select('listing_id')
        .eq('user_id', userId)
        .eq('listing_id', listingId)
        .maybeSingle();

    return result != null;
  }

  Future<void> addToWishlist(String userId, String listingId) async {
    // Prevent duplicates by checking first
    if (await isWishlisted(userId, listingId)) return;

    await client.from('wishlist').insert({
      'user_id': userId,
      'listing_id': listingId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeFromWishlist(String userId, String listingId) async {
    await client
        .from('wishlist')
        .delete()
        .eq('user_id', userId)
        .eq('listing_id', listingId);
  }

  Future<List<Map<String, dynamic>>> getWishlistItems(String userId) async {
    final result = await client
        .from('wishlist')
        .select('''
          listing_id,
          created_at,
          products (
            id,
            name,
            price,
            original_price,
            size,
            brand,
            condition,
            department,
            category,
            material,
            colour,
            user_id,
            image_url,
            created_at
          )
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return result;
  }
}
