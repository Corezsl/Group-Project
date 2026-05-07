import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/repositories/create_listing_repository.dart';
import 'package:thryft/utils/listing_form_validator.dart';
import '../helpers/supabase_test_client.dart';
import '../helpers/seed_helper.dart';

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
    test('Partition 3: required field missing returns error', () {
      final result = validateListingForm(
        title: '', // missing title
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

    test('Partition 3b: missing image on new listing returns error', () {
      final result = validateListingForm(
        title: 'Test Jacket',
        price: '25.00',
        condition: 'Good',
        brand: 'Nike',
        department: 'Mens',
        category: 'Shirt',
        size: 'M',
        isNewListing: true,
        hasImage: false, // no image
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
}
