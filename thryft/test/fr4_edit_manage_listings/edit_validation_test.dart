import 'package:flutter_test/flutter_test.dart';
import 'package:thryft/utils/listing_form_validator.dart';

// Base set of valid inputs — individual tests override one field at a time.
String? _validate({
  String title = 'Nice jacket',
  String price = '15.00',
  String? condition = 'Good',
  String? brand = 'Nike',
  String? department = 'Menswear',
  String? category = 'Tops',
  String? size = 'M',
  bool isNewListing = true,
  bool hasImage = true,
}) =>
    validateListingForm(
      title: title,
      price: price,
      condition: condition,
      brand: brand,
      department: department,
      category: category,
      size: size,
      isNewListing: isNewListing,
      hasImage: hasImage,
    );

void main() {
  // -------------------------------------------------------------------------
  // FR4 Partition 7 — Edit with empty required field (invalid)
  // -------------------------------------------------------------------------
  group('FR4 #7 — empty required field', () {
    test('empty title returns error', () {
      expect(_validate(title: ''), isNotNull);
    });

    test('whitespace-only title is accepted by isEmpty check — known gap', () {
      // isEmpty returns false for ' ', so whitespace passes validation.
      // This documents the current behaviour; a trim() fix is a separate task.
      expect(_validate(title: ' '), isNull);
    });

    test('single character title is valid', () {
      expect(_validate(title: 'a'), isNull);
    });

    test('null condition returns error', () {
      expect(_validate(condition: null), isNotNull);
    });

    test('null brand returns error', () {
      expect(_validate(brand: null), isNotNull);
    });

    test('null department returns error', () {
      expect(_validate(department: null), isNotNull);
    });

    test('new listing with no image returns error', () {
      expect(_validate(isNewListing: true, hasImage: false), isNotNull);
    });

    test('edit mode with no image is allowed', () {
      expect(_validate(isNewListing: false, hasImage: false), isNull);
    });

    test('non-Accessories category with null size returns error', () {
      expect(_validate(category: 'Tops', size: null), isNotNull);
    });

    test('Accessories category with null size is valid', () {
      expect(_validate(category: 'Accessories', size: null), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // FR4 Partition 1 — Price boundary values
  // Valid range: > 0 and <= 10000
  // -------------------------------------------------------------------------
  group('FR4 #1 — price boundary values', () {
    test('price 0 is invalid (at lower boundary, exclusive)', () {
      expect(_validate(price: '0'), isNotNull);
    });

    test('price 0.01 is valid (just above lower boundary)', () {
      expect(_validate(price: '0.01'), isNull);
    });

    test('price 15.00 is valid (midpoint of typical range)', () {
      expect(_validate(price: '15.00'), isNull);
    });

    test('price 5000 is valid (midpoint of full valid range)', () {
      expect(_validate(price: '5000'), isNull);
    });

    test('price 10000 is valid (at upper boundary, inclusive)', () {
      expect(_validate(price: '10000'), isNull);
    });

    test('price 10000.01 is invalid (just above upper boundary)', () {
      expect(_validate(price: '10000.01'), isNotNull);
    });

    test('negative price -5000 is invalid (midpoint of invalid lower range)',
        () {
      expect(_validate(price: '-5000'), isNotNull);
    });

    test('non-numeric price string is invalid', () {
      expect(_validate(price: 'abc'), isNotNull);
    });

    test('empty price string is invalid', () {
      expect(_validate(price: ''), isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // Valid baseline — all fields correct returns null (no error)
  // -------------------------------------------------------------------------
  group('valid form', () {
    test('fully populated valid inputs return null', () {
      expect(_validate(), isNull);
    });
  });
}
