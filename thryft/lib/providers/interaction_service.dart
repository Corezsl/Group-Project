import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/interactions.dart';


class InteractionService {
  final _supabase = Supabase.instance.client;

  /// Saves a new interaction to the database
  /// Call this when a user views a product, adds to wishlist, or purchases
  Future<void> logInteraction({
    required String productId,
    required String type,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final interaction = UserInteraction(
      userId: user.id,
      productId: productId,
      interactionType: type,
    );

    try {
      await _supabase.from('user_interactions').insert(interaction.toMap());
    } catch (e) {
      print('Error logging interaction: $e');
    }
  }

  /// Fetches all interactions from the database.
    Future<List<UserInteraction>> fetchAllInteractions() async {
    try {
      final List<dynamic> data = await _supabase
          .from('user_interactions')
          .select();

      return data.map((map) => UserInteraction.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching interactions: $e');
      return [];
    }
  }

  /// Helper to specifically check if a user has enough data to get recommendations.
  Future<bool> hasMinimumInteractions() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final response = await _supabase
        .from('user_interactions')
        .select('id')
        .eq('user_id', user.id)
        .limit(1);
    
    return (response as List).isNotEmpty;
  }
}