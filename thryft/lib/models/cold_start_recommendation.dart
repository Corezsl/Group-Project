import 'package:supabase_flutter/supabase_flutter.dart';

class ColdStartService {
  final _supabase = Supabase.instance.client;

  /// Cold-start fallback: recommend currently available "trending" products.
  ///
  /// We intentionally derive trending from recent `user_interactions` instead of
  /// relying on a `products.rating` column (ratings are stored separately).
  Future<List<String>> getTrendingProducts({
    int limit = 10,
    int lookbackDays = 14,
  }) async {
    try {
      final cutoff = DateTime.now().subtract(Duration(days: lookbackDays));

      // Pull recent interactions and compute trending client-side.
      // This avoids needing a PostgREST group-by/aggregate query.
      final List<dynamic> interactions = await _supabase
          .from('user_interactions')
          .select('product_id, interaction_type, created_at')
          .gte('created_at', cutoff.toIso8601String())
          .limit(5000);

      final Map<String, double> scores = {};
      for (final row in interactions) {
        final productId = row['product_id']?.toString();
        if (productId == null || productId.isEmpty) continue;

        final type = row['interaction_type']?.toString() ?? 'view';
        final createdAtRaw = row['created_at']?.toString();
        final createdAt = createdAtRaw == null ? null : DateTime.tryParse(createdAtRaw);

        final base = switch (type) {
          'purchase' => 10.0,
          'wishlist' => 3.0,
          _ => 1.0,
        };

        // Light recency boost (separate from the collaborative filter decay).
        final daysAgo = createdAt == null ? 0 : DateTime.now().difference(createdAt).inDays;
        final recency = (daysAgo <= 0) ? 1.0 : (1.0 / (1.0 + (daysAgo / 3.0)));

        scores[productId] = (scores[productId] ?? 0) + (base * recency);
      }

      if (scores.isEmpty) {
        // Fallback to newest available products.
        final List<dynamic> products = await _supabase
            .from('products')
            .select('id')
            .eq('is_sold', false)
            .order('created_at', ascending: false)
            .limit(limit);
        return products.map((item) => item['id'].toString()).toList();
      }

      final rankedIds = (scores.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .map((e) => e.key)
          .toList();

      // Filter out sold products while preserving ranked order.
      final List<dynamic> available = await _supabase
          .from('products')
          .select('id')
          .inFilter('id', rankedIds)
          .eq('is_sold', false);

      final availableSet = <String>{for (final p in available) p['id'].toString()};
      final result = <String>[];
      for (final id in rankedIds) {
        if (availableSet.contains(id)) result.add(id);
        if (result.length >= limit) break;
      }
      return result;
    } catch (e) {
      print('Cold Start Error: $e');
      return [];
    }
  }
}