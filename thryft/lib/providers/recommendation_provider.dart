import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/cold_start_recommendation.dart';
import 'package:thryft/models/product.dart';
import 'package:thryft/models/recommendation_service.dart';

class RecommendationProvider extends ChangeNotifier {
  final SupabaseClient _supabase;
  final RecommenderService _recommender;
  final ColdStartService _coldStart;

  RecommendationProvider({
    SupabaseClient? supabase,
    RecommenderService? recommender,
    ColdStartService? coldStart,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _recommender = recommender ?? RecommenderService(),
        _coldStart = coldStart ?? ColdStartService();

  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => List.unmodifiable(_products);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> refresh({int limit = 20}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;

      final List<String> ids = userId == null
          ? await _coldStart.getTrendingProducts(limit: limit)
          : await _recommender.recommendForUser(userId, limit: limit);

      if (ids.isEmpty) {
        _products = [];
        return;
      }

      final List<dynamic> rows = await _supabase
          .from('products')
          .select('*, profiles(username)')
          .inFilter('id', ids)
          .eq('is_sold', false);

      final byId = <String, Map<String, dynamic>>{};
      for (final r in rows) {
        byId[r['id'].toString()] = Map<String, dynamic>.from(r as Map);
      }

      // Preserve the recommender's ranked order.
      final ordered = <Product>[];
      for (final id in ids) {
        final row = byId[id];
        if (row == null) continue;
        ordered.add(_toProduct(row));
      }

      _products = ordered;
    } catch (e) {
      _error = e.toString();
      _products = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Product _toProduct(Map<String, dynamic> data) {
    return Product(
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
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString())
          : null,
    );
  }
}
