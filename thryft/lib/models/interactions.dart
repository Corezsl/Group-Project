class UserInteraction {
  final int? id;
  final String userId;
  final String productId;
  final String interactionType; 
  final DateTime? createdAt;

  UserInteraction({
    this.id,
    required this.userId,
    required this.productId,
    required this.interactionType,
    this.createdAt,
  });

  /// Map Supabase data to the Dart model
  factory UserInteraction.fromMap(Map<String, dynamic> map) {
    return UserInteraction(
      id: map['id'],
      userId: map['user_id'] ?? '',
      productId: map['product_id'] ?? '',
      interactionType: map['interaction_type'] ?? 'view',
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
    );
  }

  /// Converts the model back to a Map for database inserts
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'product_id': productId,
      'interaction_type': interactionType,
    };
  }

  /// Assigns a numerical weight to the interaction for the ML engine
  double get score {
    switch (interactionType) {
      case 'purchase':
        return 10.0; 
      case 'wishlist':
        return 3.0;
      case 'view':
      default:
        return 1.0;
    }
  }
}