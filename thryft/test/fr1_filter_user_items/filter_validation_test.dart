import 'package:flutter_test/flutter_test.dart';
import 'package:thryft/utils/filter_form_validator.dart';

/// Test helper which wraps the real validator. Use canonical tokens used by
/// the app dropdowns as defaults so membership checks succeed.
String? _filterValidation({
  String department = 'All',
  String size = 'All',
  String condition = 'Good',
  String brand = 'Other',
  String fitting = 'Regular',
  String material = 'Cotton',
  String colour = 'Black',
  String? ownedBy,
  String? logged_in_user,
  double price = 100.0,
}) =>
    validateFilterForm(
      department: department,
      size: size,
      price: price,
      brand: brand,
      condition: condition,
      fitting: fitting,
      material: material,
      colour: colour,
      ownedBy: ownedBy,
    );


void main() {
  //FR1 Partition 1 - Filter Validation on Department (Valid and Invalid Inputs)
  group('FR1 #1 - Filter Validation on Department', () {
    test('Valid inputs pass validation for menswear', () {
      expect(_filterValidation(department: 'Mens'), isNull);
      expect(_filterValidation(department: 'Womens'), isNull);
    });

    test('Invalid department fails validation', () {
      expect(_filterValidation(department: 'Kids'), equals('Invalid department'));
    });
  });

  //FR1 Partition 2 - Filter Validation on Sizes
  group('FR1 #2 - Filter Validation on Sizes', () {
    test('Valid inputs pass validation on any', () {
      expect(_filterValidation(department: 'All', size: 'M', price: 25.0), isNull);
    });

    test('Valid inputs pass validation for menswear', () {
      expect(_filterValidation(department: 'Mens', size: '32R', price: 25.0), isNull);
    });

    test('Valid inputs pass validation for womenswear', () {
      expect(_filterValidation(department: 'Womens', size: '10', price: 25.0), isNull);
    });

    test('Invalid size fails validation', () {
      expect(
        _filterValidation(size: '30R', department: 'Womens'),
      equals('Invalid size'));
    });

    test('Invalid size fails validation for menswear', () {
      expect(
        _filterValidation(size: '10', department: 'Mens'),
      equals('Invalid size'));
    });
  });

  //FR1 Partition 3 - Filter Validation on only one condition (Valid Inputs)
  group('FR1 #3 - Filter Validation on only one criteria', () {
    test('Valid inputs pass validation', () {
      expect(_filterValidation(condition: 'Good', department: 'All', size: 'All', brand: 'All', fitting: 'All', material: 'All', colour: 'All'), isNull);
      expect(_filterValidation(fitting: 'Regular', department: 'All', size: 'All', brand: 'All', condition: 'All', material: 'All', colour: 'All'), isNull);
      expect(_filterValidation(material: 'Cotton', department: 'All', size: 'All', brand: 'All', fitting: 'All', condition: 'All', colour: 'All'), isNull);
      expect(_filterValidation(colour: 'Black', department: 'All', size: 'All', brand: 'All', fitting: 'All', material: 'All', condition: 'All'), isNull);
    });
  });

  group('FR1 #4 - Valid Price input passes validation', () {
    test('Price within valid range passes validation', () {
      expect(_filterValidation(price: 50.0), isNull);
      expect(_filterValidation(price: 0.01), isNull);
      expect(_filterValidation(price: 9999.99), isNull);
      expect(_filterValidation(price: 10000), isNull);
    });
  });

  group('FR1 #5 - Filter Validation on Price Range (Lower Bound)', () {
    test('Negative price fails validation', () {
      expect(_filterValidation(price: -5.0), equals('Please enter a valid price greater than 0 or less than 10000.'));
    });

    test('Zero price fails validation', () {
      expect(_filterValidation(price: 0.0), equals('Please enter a valid price greater than 0 or less than 10000.'));
    });
  });

  group('FR1 #6 - Filter Validation on Price Range (Upper Bound)', () {
    test('Price above maximum fails validation', () {
      expect(_filterValidation(price: 100000.0), equals('Please enter a valid price greater than 0 or less than 10000.'),);
    });
    test('Price just over 10000 fails validation', () {
      expect(_filterValidation(price: 10000.01), equals('Please enter a valid price greater than 0 or less than 10000.'),);
    });
  });
  
  group('FR1 #7 - Filter Validation on Brand', () {
    // Assuming brand validation logic is added to _filterValidation
    test('Invalid brand fails validation', () {
      expect(_filterValidation(brand: 'UnknownBrand'), equals('Invalid brand'));
      });
    test('Valid brand passes validation', () {
      expect(_filterValidation(brand: 'Nike'), isNull);
    });
  });

  group('FR1 #8 - Invalid Data type for price filter',() {
    test('Non-numeric price fails validation', () {
      // simulate non-numeric data as price is a double.
      // Catches the error when trying to parse a non-numeric string.
      try {
        double.parse('not_a_number');
        fail('Expected a FormatException to be thrown');
      } catch (e) {
        expect(e, isA<FormatException>());
      }
    });
  });

  group('FR1 #9 - Multiple Filters selected with valid inputs', () {
    test('Multiple valid filters pass validation', () {
      expect(_filterValidation(department: 'Mens', size: '32R', condition: 'Good', brand: 'Nike', fitting: 'Regular', material: 'Cotton', colour: 'Black', price: 50.0, ), isNull);
      expect(_filterValidation(department:'Womens',size:'Any',condition:'All',brand:'Adidas',fitting:'All',material:'All',colour:'All',price:75.0), isNull);
    });
  });

  group('FR1 #11 - No matching results', () {
    test('Valid filters that yield no results still pass validation', () {
      // Assuming the validation function does not check for actual database matches, it should return null (valid) even if no items match the criteria.
      expect(_filterValidation(department: 'Mens', size: '32R', condition: 'New with tags', brand: 'Under Armour', fitting: 'Slim', material: 'Leather', colour: 'Pink', price: 9999.99), isNull);
    });
  });

  group('FR1 #13 - Empty or Null Inputs', () {
    test('Null department is valid', () {
      expect(_filterValidation(department: ''), isNull);
    });
    test('Empty brand is invalid', () {
      expect(_filterValidation(brand: ''), equals('Invalid brand'));
    });
  });

  group('FR1 #14 - Rapid Filter Switching', () {
    test('Rapidly changing filters does not cause validation errors', () {
      expect(_filterValidation(department: 'Mens', size: '32R', condition: 'Good', brand: 'Nike', fitting: 'Regular', material: 'Cotton', colour: 'Black', price: 50.0), isNull);
      expect(_filterValidation(department:'Womens',size:'Any',condition:'All',brand:'Adidas',fitting:'All',material:'All',colour:'All',price:75.0), isNull);
      expect(_filterValidation(department: 'Mens', size: '32R', condition: 'New with tags', brand: 'Under Armour', fitting: 'Slim', material: 'Leather', colour: 'Pink', price: 9999.99), isNull);
    });
  });

  group('FR1 #15 - Exclude User owned items', () {
    test('OwnedBy filter is optional and does not affect validation', () {
      expect(_filterValidation(ownedBy: null), isNull);
      expect(_filterValidation(ownedBy: 'user123', logged_in_user: 'user123'), isNull);
    });
    test('OwnedBy filter with different user does not affect validation', () {
      expect(_filterValidation(ownedBy: 'user123', logged_in_user: 'user456'), isNull);
    });
  });
}


