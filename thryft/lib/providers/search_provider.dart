import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/product.dart';

class SearchFilters {
  final String? size;
  final String? category;
  final String? condition;
  final String? department;
  final String? brand;
  final String? fitting;
  final String? material;
  final String? colour;
  final double? minPrice;
  final double? maxPrice;
  final String sortBy; // 'newest', 'price_asc', 'price_desc'

  const SearchFilters({
    this.size,
    this.category,
    this.condition,
    this.department,
    this.brand,
    this.fitting,
    this.material,
    this.colour,
    this.minPrice,
    this.maxPrice,
    this.sortBy = 'newest',
  });

  SearchFilters copyWith({
    Object? size = _sentinel,
    Object? category = _sentinel,
    Object? condition = _sentinel,
    Object? department = _sentinel,
    Object? brand = _sentinel,
    Object? fitting = _sentinel,
    Object? material = _sentinel,
    Object? colour = _sentinel,
    Object? minPrice = _sentinel,
    Object? maxPrice = _sentinel,
    String? sortBy,
  }) {
    return SearchFilters(
      size: size == _sentinel ? this.size : size as String?,
      category: category == _sentinel ? this.category : category as String?,
      condition: condition == _sentinel ? this.condition : condition as String?,
      department: department == _sentinel ? this.department : department as String?,
      brand: brand == _sentinel ? this.brand : brand as String?,
      fitting: fitting == _sentinel ? this.fitting : fitting as String?,
      material: material == _sentinel ? this.material : material as String?,
      colour: colour == _sentinel ? this.colour : colour as String?,
      minPrice: minPrice == _sentinel ? this.minPrice : minPrice as double?,
      maxPrice: maxPrice == _sentinel ? this.maxPrice : maxPrice as double?,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  bool get hasActiveFilters =>
      size != null ||
      category != null ||
      condition != null ||
      department != null ||
      brand != null ||
      fitting != null ||
      material != null ||
      colour != null ||
      minPrice != null ||
      maxPrice != null ||
      sortBy != 'newest';
}

// Sentinel for copyWith null distinction
const _sentinel = Object();

class SearchProvider extends ChangeNotifier {
  List<Product> _results = [];
  bool _isLoading = false;
  String _query = '';
  List<String> _recentSearches = [];
  SearchFilters _filters = const SearchFilters();
  Timer? _debounce;

  static const _recentSearchesKey = 'recent_searches';
  static const _maxRecentSearches = 8;

  SearchProvider() {
    _loadRecentSearches();
  }

  List<Product> get results => List.unmodifiable(_results);
  bool get isLoading => _isLoading;
  String get query => _query;
  List<String> get recentSearches => List.unmodifiable(_recentSearches);
  SearchFilters get filters => _filters;

  // on every keystroke — debounced internally
  void onQueryChanged(String value) {
    _query = value;
    notifyListeners();

    _debounce?.cancel();
    if (value.trim().isEmpty) {
      _results = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _debounce = Timer(const Duration(milliseconds: 350), () {
      _executeSearch(value.trim());
    });
  }

  // when the user explicitly submits (saves to recent searches)
  Future<void> submitSearch(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    _query = trimmed;
    await _executeSearch(trimmed, saveToRecent: true);
  }

  Future<void> updateFilters(SearchFilters newFilters) async {
    _filters = newFilters;
    notifyListeners();
    if (_query.trim().isNotEmpty) {
      await _executeSearch(_query.trim());
    }
  }

  void clearFilters() {
    _filters = const SearchFilters();
    notifyListeners();
    if (_query.trim().isNotEmpty) {
      _executeSearch(_query.trim());
    }
  }

  Future<void> _executeSearch(String q, {bool saveToRecent = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      var queryBuilder = Supabase.instance.client
          .from('products')
          .select('*, profiles(username)')
          .or('name.ilike.%$q%,brand.ilike.%$q%,category.ilike.%$q%')
          .eq('is_sold', false);

      if (_filters.size != null) {
        queryBuilder = queryBuilder.eq('size', _filters.size!);
      }
      if (_filters.category != null) {
        queryBuilder = queryBuilder.eq('category', _filters.category!);
      }
      if (_filters.condition != null) {
        queryBuilder = queryBuilder.eq('condition', _filters.condition!);
      }
      if (_filters.department != null) {
        queryBuilder = queryBuilder.eq('department', _filters.department!);
      }
      if (_filters.brand != null) {
        queryBuilder = queryBuilder.eq('brand', _filters.brand!);
      }
      if (_filters.fitting != null) {
        queryBuilder = queryBuilder.eq('fitting', _filters.fitting!);
      }
      if (_filters.material != null) {
        queryBuilder = queryBuilder.eq('material', _filters.material!);
      }
      if (_filters.colour != null) {
        queryBuilder = queryBuilder.eq('colour', _filters.colour!);
      }
      if (_filters.minPrice != null) {
        queryBuilder = queryBuilder.gte('price', _filters.minPrice!);
      }
      if (_filters.maxPrice != null) {
        queryBuilder = queryBuilder.lte('price', _filters.maxPrice!);
      }

      final List data;
      switch (_filters.sortBy) {
        case 'price_asc':
          data = await queryBuilder.order('price', ascending: true);
          break;
        case 'price_desc':
          data = await queryBuilder.order('price', ascending: false);
          break;
        default:
          data = await queryBuilder.order('created_at', ascending: false);
      }

      _results = data.map((row) {
        return Product(
          id: row['id'].toString(),
          name: row['name'].toString(),
          price: (row['price'] as num).toDouble(),
          originalPrice: row['original_price'] != null
              ? (row['original_price'] as num).toDouble()
              : null,
          size: row['size'].toString(),
          brand: row['brand'].toString(),
          condition: row['condition'].toString(),
          imageUrl: row['image_url']?.toString(),
          sellerId: row['user_id']?.toString(),
          sellerName: row['profiles'] != null
              ? row['profiles']['username']?.toString()
              : null,
          category: row['category']?.toString() ?? 'Other',
          createdAt: row['created_at'] != null
              ? DateTime.tryParse(row['created_at'].toString())
              : null,
          department: row['department']?.toString() ?? 'All',
          material: row['material'].toString(),
          colour: row['colour'].toString(),
          description: row['description']?.toString(),
          imageUrl2: row['image_url_2']?.toString(),
          imageUrl3: row['image_url_3']?.toString(),
          imageUrl4: row['image_url_4']?.toString(),
          imageUrl5: row['image_url_5']?.toString(),
        );
      }).toList();

      if (saveToRecent) {
        await _saveRecentSearch(q);
      }
    } catch (e) {
      debugPrint('Search error: $e');
      _results = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    _recentSearches = prefs.getStringList(_recentSearchesKey) ?? [];
    notifyListeners();
  }

  Future<void> _saveRecentSearch(String q) async {
    _recentSearches.remove(q);
    _recentSearches.insert(0, q);
    if (_recentSearches.length > _maxRecentSearches) {
      _recentSearches = _recentSearches.sublist(0, _maxRecentSearches);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, _recentSearches);
    notifyListeners();
  }

  Future<void> removeRecentSearch(String q) async {
    _recentSearches.remove(q);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, _recentSearches);
    notifyListeners();
  }

  Future<void> clearRecentSearches() async {
    _recentSearches = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
    notifyListeners();
  }

  void clearResults() {
    _debounce?.cancel();
    _query = '';
    _results = [];
    _isLoading = false;
    _filters = const SearchFilters();
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
