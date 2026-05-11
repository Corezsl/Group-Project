import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../helpers/supabase_test_client.dart';
import '../helpers/seed_helper.dart' as seed;


//Integration tests for FR1 #10 - Search and filter queries on user items. 
//These tests use the real Supabase client to query a test database 
//seeded with known data, and check that the expected rows are returned for various 
//filter combinations. This validates query logic work to return the right results logged-in users.
void main() {
  if (!hasTestCredentials) {
    test('FR1 integration tests - skipped (no credentials)', () {},
        skip:
            'No Supabase credentials — pass --dart-define=TEST_SUPABASE_URL and TEST_SUPABASE_ANON_KEY');
    return;
  }

  late SupabaseClient client; // regular user client — respects RLS
  late SupabaseClient admin; // service-role client — bypasses RLS for seeding/cleanup
  late String sellerId;

  setUpAll(() async {
    client = await getTestClient();
    admin = getServiceClient();
    // create a deterministic test seller id
    sellerId = await seed.seedUser(admin, username: 'fr1_seller');
  });

  tearDownAll(() async {
    // remove any test rows created by seed helper
    await seed.tearDownTestData(admin);
  });

  group('FR1 integration - filter queries', () {
    // Each test seeds own product and remove after test
    test('FR1 #1 - Department filter returns seeded product', () async {
      final productId = await seed.seedProduct(
        admin, sellerId: sellerId, name: 'Mens Nike Shirt', brand: 'Nike', size: 'M', price: 20.0, department: 'Mens',);
      try {
        final List rows = await client
            .from('products')
            .select()
            .eq('department', 'Mens') as List;
        final ids = rows.map((r) => r['id'].toString()).toList();
        expect(ids, contains(productId));
      } finally {
        await admin.from('products').delete().eq('id', productId);
      }
    });

    test('FR1 #2 - Dynamic Size filter returns seeded product', () async {
      final productId = await seed.seedProduct(
        admin, sellerId: sellerId, name: 'Blue Pants', brand: 'SizeBrand', size: '32R', price: 30.0, department: 'Mens',);
      try {
        final List rows = await client
            .from('products')
            .select()
            .eq('size', '32R') as List;
        final ids = rows.map((r) => r['id'].toString()).toList();
        expect(ids, contains(productId));
      } finally {
        await admin.from('products').delete().eq('id', productId);
      }
    });


    test('FR1 #10 filter by brand + size + department returns seeded product', () async {
      final productId = await seed.seedProduct( admin, sellerId: sellerId, name: 'Nike Mens Shirt', brand: 'Nike', size: 'M', price: 25.0, department: 'Mens',);
      try {
        // query the product table
        final response = await client
          .from('products')
          .select()
          .eq('is_sold', false)
          .eq('brand', 'Nike')
          .eq('size', 'M')
          .eq('department', 'Mens');

        // helper returns rows, cast to list for inspection
        final List rows = response as List;
        final ids = rows.map((r) => r['id'].toString()).toList();
        expect(ids, contains(productId));
      } finally {
        await admin.from('products').delete().eq('id', productId);
      }
    });

    test('FR1 #11 - No matching results returns empty set', () async {
      // Query for a brand that we do not seed — expect no rows with that brand
      final List rows = await client
          .from('products')
          .select()
          .eq('brand', 'DefinitelyDoesNotExistBrand') as List;
      expect(rows, isEmpty);
    });
  });
}