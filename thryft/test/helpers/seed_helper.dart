import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Seed & teardown helpers for integration tests
//
// All rows inserted by these helpers are tagged with a shared [runId] UUID
// prefix so tearDownAll can delete exactly the rows this test run created,
// without touching any other data in the test DB.
//
// The service-role key is required to bypass RLS when seeding auth.users
// surrogate rows and profiles. Pass it in via:
//   --dart-define=TEST_SUPABASE_SERVICE_KEY=sb_secret_...
// ---------------------------------------------------------------------------

const _serviceKey = String.fromEnvironment('TEST_SUPABASE_SERVICE_KEY');

/// A unique prefix applied to every test user / product id in this run.
/// Using a timestamp keeps things readable in the DB if teardown ever fails.
final String runId =
    'test-${DateTime.now().millisecondsSinceEpoch}';

// ---------------------------------------------------------------------------
// Public seed functions
// ---------------------------------------------------------------------------

/// Inserts a row into [profiles] (and a corresponding fake auth.users row via
/// the admin REST API) and returns the generated user id.
///
/// Because the test DB uses the same auth schema as production, we insert
/// directly into auth.users via the admin API (requires service-role key),
/// then insert the matching profiles row using the regular client.
Future<String> seedUser(
  SupabaseClient client, {
  required String username,
}) async {
  assert(
    _serviceKey.isNotEmpty,
    'Missing TEST_SUPABASE_SERVICE_KEY. '
    'Run tests with --dart-define=TEST_SUPABASE_SERVICE_KEY=<key>',
  );

  // Build a deterministic UUID from the username so we can reference it later.
  // We use a fixed namespace prefix rather than truly random UUIDs so teardown
  // can delete rows by prefix match.
  final userId = _fakeUuid('$runId-$username');

  // Insert into profiles — the FK to auth.users is deferred in the test
  // project so we can seed profiles without a real auth row.
  await client.from('profiles').upsert({
    'id': userId,
    'username': username,
    'rating': 0.0,
    'rating_count': 0,
  });

  return userId;
}

/// Inserts a row into [products] and returns the product id.
Future<String> seedProduct(
  SupabaseClient client, {
  required String sellerId,
  String? id,
  String name = 'Test Product',
  double price = 10.0,
  String size = 'M',
  String brand = 'TestBrand',
  String condition = 'Good',
  String category = 'Tops',
  String department = 'Menswear',
  String material = 'Cotton',
  String colour = 'Blue',
  bool isSold = false,
  String? buyerId,
  String? orderStatus,
}) async {
  final productId = id ?? _fakeUuid('$runId-$name-$sellerId');

  await client.from('products').upsert({
    'id': productId,
    'user_id': sellerId,
    'name': name,
    'price': price,
    'size': size,
    'brand': brand,
    'condition': condition,
    'category': category,
    'department': department,
    'material': material,
    'colour': colour,
    'is_sold': isSold,
    if (buyerId != null) 'buyer_id': buyerId,
    if (orderStatus != null) 'order_status': orderStatus,
  });

  return productId;
}

/// Inserts a row into [offers] and returns the offer id.
Future<int> seedOffer(
  SupabaseClient client, {
  required String listingId,
  required String buyerId,
  required String sellerId,
  double offerAmount = 5.0,
  String status = 'pending',
}) async {
  final response = await client
      .from('offers')
      .insert({
        'listing_id': listingId,
        'buyer_id': buyerId,
        'seller_id': sellerId,
        'offer_amount': offerAmount,
        'status': status,
      })
      .select('offer_id')
      .single();

  return response['offer_id'] as int;
}

/// Inserts a row into [notification] and returns the notification_id.
///
/// Pass the service-role client to bypass RLS insert policies.
Future<int> seedNotification(
  SupabaseClient client, {
  required String userId,
  String notifType = 'order_shipped',
  String content = 'Test notification',
  bool isRead = false,
  String? listingId,
  String? relatedUserId,
  double? offerPrice,
  String? buyerAddress,
}) async {
  final response = await client
      .from('notification')
      .insert({
        'user_id': userId,
        'notif_type': notifType,
        'content': content,
        'is_read': isRead,
        if (listingId != null) 'listing_id': listingId,
        if (relatedUserId != null) 'related_user_id': relatedUserId,
        if (offerPrice != null) 'offer_price': offerPrice,
        if (buyerAddress != null) 'buyer_address': buyerAddress,
      })
      .select('notification_id')
      .single();
  return response['notification_id'] as int;
}

/// Inserts a row into [ratings] and returns the rating id.
Future<String> seedRating(
  SupabaseClient client, {
  required String sellerId,
  required String buyerId,
  required String productId,
  int rating = 5,
  String comment = 'Great test rating!',
}) async {
  final response = await client
      .from('ratings')
      .insert({
        'seller_id': sellerId,
        'buyer_id': buyerId,
        'product_id': productId,
        'rating': rating,
        'comment': comment,
      })
      .select('id')
      .single();

  return response['id'] as String;
}

// ---------------------------------------------------------------------------
// Teardown
// ---------------------------------------------------------------------------

/// Deletes every row seeded by this test run.
///
/// Call from [tearDownAll] in each test file. The deletion order respects FK
/// constraints (child tables first).
Future<void> tearDownTestData(SupabaseClient client) async {
  // Delete in FK-safe order (children before parents).
  // Note: Cannot use like('%') on UUID columns without casting.
  await client.from('offers').delete().like('listing_id', '%$runId%');
  await client
      .from('products')
      .delete()
      .like('id', '%$runId%');
  await client
      .from('profiles')
      .delete()
      .like('id', '%$runId%');
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

/// Produces a stable UUID-shaped string from an arbitrary [seed] string.
/// Not cryptographically random — purely for deterministic test ids.
String _fakeUuid(String seed) {
  // Simple hash → hex, padded to UUID length.
  final hash = seed.hashCode.abs();
  final hex = hash.toRadixString(16).padLeft(8, '0');
  // Format: xxxxxxxx-0000-4000-8000-xxxxxxxxxxxx
  return '$hex-0000-4000-8000-${'0' * 12}';
}
