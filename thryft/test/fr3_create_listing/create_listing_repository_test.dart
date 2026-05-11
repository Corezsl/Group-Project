import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/repositories/create_listing_repository.dart';
import 'package:thryft/utils/listing_form_validator.dart';
import '../helpers/supabase_test_client.dart';

// ---------------------------------------------------------------------------
// Reuse existing test accounts to avoid email rate limits.
// ---------------------------------------------------------------------------
const _sellerEmail = 'fr4.seller@thryft-test.local';
const _sellerPassword = 'Thryft!test99';

Future<String> _signInOrSignUp(
  SupabaseClient client,
  String email,
  String password,
  String username,
) async {
  try {
    final res = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return res.user!.id;
  } on AuthException {
    final res = await client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );
    return res.user!.id;
  }
}

/// A set of valid form fields used as a baseline for validator tests.
/// Individual tests override one field at a time to check specific errors.
Map<String, dynamic> _validFormFields() => {
      'title': 'Test Vintage Jacket',
      'price': '25.00',
      'condition': 'Good',
      'brand': 'Nike',
      'department': 'Mens',
      'category': 'Shirt',
      'size': 'M',
      'isNewListing': true,
      'hasImage': true,
    };

void main() {
  // ---------------------------------------------------------------------------
  // Validator tests — pure function, no DB needed
  // ---------------------------------------------------------------------------
  group('FR3 — validateListingForm', () {
    test('Partition 3a: missing title returns error', () {
      final result = validateListingForm(
        title: '',
        price: '25.00',
        condition: 'Good',
        brand: 'Nike',
        department: 'Mens',
        category: 'Shirt',
        size: 'M',
        isNewListing: true,
        hasImage: true,
      );
      expect(result, isNotNull);
      expect(result, contains('required fields'));
    });

    test('Partition 3b: missing price returns error', () {
      final result = validateListingForm(
        title: 'Test Jacket',
        price: '',
        condition: 'Good',
        brand: 'Nike',
        department: 'Mens',
        category: 'Shirt',
        size: 'M',
        isNewListing: true,
        hasImage: true,
      );
      expect(result, isNotNull);
      expect(result, contains('required fields'));
    });

    test('Partition 3c: missing condition returns error', () {
      final result = validateListingForm(
        title: 'Test Jacket',
        price: '25.00',
        condition: null,
        brand: 'Nike',
        department: 'Mens',
        category: 'Shirt',
        size: 'M',
        isNewListing: true,
        hasImage: true,
      );
      expect(result, isNotNull);
      expect(result, contains('required fields'));
    });

    test('Partition 3d: missing brand returns error', () {
      final result = validateListingForm(
        title: 'Test Jacket',
        price: '25.00',
        condition: 'Good',
        brand: null,
        department: 'Mens',
        category: 'Shirt',
        size: 'M',
        isNewListing: true,
        hasImage: true,
      );
      expect(result, isNotNull);
      expect(result, contains('required fields'));
    });

    test('Partition 3e: missing department returns error', () {
      final result = validateListingForm(
        title: 'Test Jacket',
        price: '25.00',
        condition: 'Good',
        brand: 'Nike',
        department: null,
        category: 'Shirt',
        size: 'M',
        isNewListing: true,
        hasImage: true,
      );
      expect(result, isNotNull);
      expect(result, contains('required fields'));
    });

    test('Partition 3f: missing image on new listing returns error', () {
      final result = validateListingForm(
        title: 'Test Jacket',
        price: '25.00',
        condition: 'Good',
        brand: 'Nike',
        department: 'Mens',
        category: 'Shirt',
        size: 'M',
        isNewListing: true,
        hasImage: false,
      );
      expect(result, isNotNull);
      expect(result, contains('required fields'));
    });

    test('Partition 4: negative price returns error', () {
      final result = validateListingForm(
        title: 'Test Jacket',
        price: '-5.00',
        condition: 'Good',
        brand: 'Nike',
        department: 'Mens',
        category: 'Shirt',
        size: 'M',
        isNewListing: true,
        hasImage: true,
      );
      expect(result, isNotNull);
      expect(result, contains('valid price'));
    });

    test('Partition 5: price of 0 returns error', () {
      final result = validateListingForm(
        title: 'Test Jacket',
        price: '0',
        condition: 'Good',
        brand: 'Nike',
        department: 'Mens',
        category: 'Shirt',
        size: 'M',
        isNewListing: true,
        hasImage: true,
      );
      expect(result, isNotNull);
      expect(result, contains('valid price'));
    });

    test('Partition 6: missing size for non-Accessories category returns error',
        () {
      final result = validateListingForm(
        title: 'Test Jacket',
        price: '25.00',
        condition: 'Good',
        brand: 'Nike',
        department: 'Mens',
        category: 'Shirt',
        size: null, // missing size
        isNewListing: true,
        hasImage: true,
      );
      expect(result, isNotNull);
      expect(result, contains('size'));
    });

    test('Partition 8: Accessories — size not required, validation passes', () {
      final result = validateListingForm(
        title: 'Cool Sunglasses',
        price: '15.00',
        condition: 'New with tags',
        brand: 'Nike',
        department: 'All',
        category: 'Accessories',
        size: null, // no size needed for accessories
        isNewListing: true,
        hasImage: true,
      );
      expect(result, isNull);
    });

    test('Partition 11: description over 200 characters returns error', () {
      final longDesc = 'A' * 201;
      final result = validateListingForm(
        title: 'Test Jacket',
        price: '25.00',
        condition: 'Good',
        brand: 'Nike',
        department: 'Mens',
        category: 'Shirt',
        size: 'M',
        isNewListing: true,
        hasImage: true,
        description: longDesc,
      );
      expect(result, isNotNull);
      expect(result, contains('200 characters'));
    });

    test('Partition 12: description between 0 and 200 characters passes', () {
      final result = validateListingForm(
        title: 'Test Jacket',
        price: '25.00',
        condition: 'Good',
        brand: 'Nike',
        department: 'Mens',
        category: 'Shirt',
        size: 'M',
        isNewListing: true,
        hasImage: true,
        description: 'Lovely vintage jacket in great condition.',
      );
      expect(result, isNull);
    });

    test('Partition 13: minimum acceptable price £0.01 passes', () {
      final result = validateListingForm(
        title: 'Cheap Item',
        price: '0.01',
        condition: 'Good',
        brand: 'Nike',
        department: 'Mens',
        category: 'Shirt',
        size: 'M',
        isNewListing: true,
        hasImage: true,
      );
      expect(result, isNull);
    });

    test('Partition 14: maximum acceptable price £10000 passes', () {
      final result = validateListingForm(
        title: 'Expensive Item',
        price: '10000',
        condition: 'Good',
        brand: 'Nike',
        department: 'Mens',
        category: 'Shirt',
        size: 'M',
        isNewListing: true,
        hasImage: true,
      );
      expect(result, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Repository tests — live DB
  // ---------------------------------------------------------------------------
  if (!hasTestCredentials) {
    test('FR3 repository tests', () {},
        skip: 'No Supabase credentials — pass '
            '--dart-define=TEST_SUPABASE_URL and TEST_SUPABASE_ANON_KEY to run');
    return;
  }

  late SupabaseClient client;
  late SupabaseClient admin;
  late CreateListingRepository repo;
  late String sellerId;

  setUpAll(() async {
    client = await getTestClient();
    admin = getServiceClient();

    sellerId = await _signInOrSignUp(
        client, _sellerEmail, _sellerPassword, 'fr4_seller');

    repo = CreateListingRepository(client);
  });

  tearDownAll(() async {
    // Clean up any products created during tests
    await admin.from('products').delete().eq('user_id', sellerId);
    await client.auth.signOut();
  });

  // -------------------------------------------------------------------------
  // FR3 Partition 1 — Create listing with all required fields
  // -------------------------------------------------------------------------
  group('FR3 #1 — create listing with all required fields', () {
    late String productId;

    test('insert succeeds and row appears in DB', () async {
      productId = await repo.createListing({
        'name': 'FR3 Test Jacket',
        'price': 25.00,
        'size': 'M',
        'brand': 'Nike',
        'condition': 'Good',
        'department': 'Mens',
        'category': 'Shirt',
        'material': 'Cotton',
        'colour': 'Blue',
      });

      // Verify the row exists in DB
      final row = await client
          .from('products')
          .select('name, price, size, brand')
          .eq('id', productId)
          .single();

      expect(row['name'], 'FR3 Test Jacket');
      expect((row['price'] as num).toDouble(), 25.00);
      expect(row['size'], 'M');
      expect(row['brand'], 'Nike');
    });

    tearDown(() async {
      await admin.from('products').delete().eq('id', productId);
    });
  });

  // -------------------------------------------------------------------------
  // FR3 Partition 2 — Create listing while logged out
  // -------------------------------------------------------------------------
  group('FR3 #2 — create listing while logged out', () {
    setUp(() async {
      await client.auth.signOut();
    });

    tearDown(() async {
      await _signInOrSignUp(
          client, _sellerEmail, _sellerPassword, 'fr4_seller');
    });

    test('throws NotLoggedInException', () {
      expect(
        () => repo.createListing({
          'name': 'Should Fail',
          'price': 10.00,
          'size': 'M',
          'brand': 'Nike',
          'condition': 'Good',
          'department': 'Mens',
          'category': 'Shirt',
          'material': 'Cotton',
          'colour': 'Blue',
        }),
        throwsA(isA<NotLoggedInException>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // FR3 Partition 7 — Create listing with multiple pictures
  // -------------------------------------------------------------------------
  group('FR3 #7 — listing with multiple image URLs', () {
    late String productId;

    test('secondary image URLs are persisted in DB', () async {
      productId = await repo.createListing({
        'name': 'FR3 Multi Photo Item',
        'price': 30.00,
        'size': 'L',
        'brand': 'Adidas',
        'condition': 'Very good',
        'department': 'Mens',
        'category': 'Shirt',
        'material': 'Polyester',
        'colour': 'Black',
        'image_url': 'https://example.com/main.jpg',
        'image_url_2': 'https://example.com/photo2.jpg',
        'image_url_3': 'https://example.com/photo3.jpg',
        'image_url_4': 'https://example.com/photo4.jpg',
        'image_url_5': 'https://example.com/photo5.jpg',
      });

      final row = await client
          .from('products')
          .select('image_url, image_url_2, image_url_3, image_url_4, image_url_5')
          .eq('id', productId)
          .single();

      expect(row['image_url'], 'https://example.com/main.jpg');
      expect(row['image_url_2'], 'https://example.com/photo2.jpg');
      expect(row['image_url_3'], 'https://example.com/photo3.jpg');
      expect(row['image_url_4'], 'https://example.com/photo4.jpg');
      expect(row['image_url_5'], 'https://example.com/photo5.jpg');
    });

    tearDown(() async {
      await admin.from('products').delete().eq('id', productId);
    });
  });

  // -------------------------------------------------------------------------
  // FR3 Partition 9 — No card details in account
  // -------------------------------------------------------------------------
  group('FR3 #9 — no card details', () {
    test('hasPaymentMethod returns false for user with no card', () async {
      final result = await repo.hasPaymentMethod(sellerId);
      expect(result, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // FR3 Partition 10 — No address in account
  // -------------------------------------------------------------------------
  group('FR3 #10 — no address', () {
    test('hasAddress returns false for user with no address', () async {
      final result = await repo.hasAddress(sellerId);
      expect(result, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // FR3 Partition 13 — Minimum acceptable price boundary (DB level)
  // -------------------------------------------------------------------------
  group('FR3 #13 — minimum price £0.01 in DB', () {
    late String productId;

    test('insert succeeds with price 0.01', () async {
      productId = await repo.createListing({
        'name': 'FR3 Cheap Item',
        'price': 0.01,
        'size': 'S',
        'brand': 'Other',
        'condition': 'Good',
        'department': 'All',
        'category': 'Shirt',
        'material': 'Cotton',
        'colour': 'White',
      });

      final row = await client
          .from('products')
          .select('price')
          .eq('id', productId)
          .single();

      expect((row['price'] as num).toDouble(), 0.01);
    });

    tearDown(() async {
      await admin.from('products').delete().eq('id', productId);
    });
  });

  // -------------------------------------------------------------------------
  // FR3 Partition 14 — Maximum acceptable price boundary (DB level)
  // -------------------------------------------------------------------------
  group('FR3 #14 — maximum price £10000 in DB', () {
    late String productId;

    test('insert succeeds with price 10000', () async {
      productId = await repo.createListing({
        'name': 'FR3 Expensive Item',
        'price': 10000.0,
        'size': 'XL',
        'brand': 'Other',
        'condition': 'New with tags',
        'department': 'All',
        'category': 'Shirt',
        'material': 'Silk',
        'colour': 'Black',
      });

      final row = await client
          .from('products')
          .select('price')
          .eq('id', productId)
          .single();

      expect((row['price'] as num).toDouble(), 10000.0);
    });

    tearDown(() async {
      await admin.from('products').delete().eq('id', productId);
    });
  });
}
