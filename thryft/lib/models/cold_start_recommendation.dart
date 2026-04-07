import 'package:supabase_flutter/supabase_flutter.dart';

class ColdStartService {
  final _supabase = Supabase.instance.client;

  /// Fetches the top 10 highest-rated products that haven't been sold yet
  Future<List<String>> getTrendingProducts() async {
    try {
      final List<dynamic> data = await _supabase
          .from('products')
          .select('id')
          .eq('is_sold', false)
          .order('rating', ascending: false)
          .limit(10);
          
      return data.map((item) => item['id'] as String).toList();
    } catch (e) {
      print('Cold Start Error: $e');
      return [];
    }
  }
}