import 'package:flutter_test/flutter_test.dart';
import 'package:thryft/utils/filter_form_validator.dart';

String? _filterValidation({
  String size = 'All', //set to default value which is 'All'
  double minPrice = 0.1, //set as 0.01 in validation
  double? maxPrice, //set as 10000 in validation rules
  String department = 'All',
  String brand = 'All',
  String condition = 'All',
  String fitting = 'All',
  String material = 'All',
  String colour = 'All',
  String? ownedBy,
  double price = 10000, //set as 10000 as default so it shows all if unchanged
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
    test('Valid inputs pass validation', () {
      expect(_filterValidation(department: 'Mens'), isNull);
      expect(_filterValidation(department: 'Womens'), isNull);
    });

    test('Invalid department fails validation', () {
      expect(
        _filterValidation(department: 'Kids'), 
      equals('Invalid department, not implemented yet'));
    });
  });

  //FR1 Partition 2 - Filter Validation on Sizes
  group('FR1 #2 - Filter Validation on Sizes', () {
    test('Valid inputs pass validation', () {
      expect(_filterValidation(size: 'M', minPrice: 10.0, maxPrice: 50.0), isNull);
    });

    test('Invalid size fails validation', () {
      expect(
        _filterValidation(size: '30R', department: 'Womens'), 
      equals('Invalid size'));
    });

  group('FR1 #2 - Filter Validation on Price Range', () {
    test('Negative min price fails validation', () {
      expect(_filterValidation(price: -5.0), equals('Min price cannot be negative'));
    });

    test('Negative max price fails validation', () {
      expect(_filterValidation(maxPrice: -10.0), equals('Max price cannot be negative'));
    });
    test('Min price greater than max price fails validation', () {
      expect(_filterValidation(minPrice: 100.0, maxPrice: 50.0), equals('Min price cannot be greater than max price'));
    });
  });
  
  group('FR1 #3 - Filter Validation on Brand', () {
    // Assuming brand validation logic is added to _filterValidation
    test('Invalid brand fails validation', () {
      expect(_filterValidation(brand: 'UnknownBrand'), equals('Invalid brand'));
    });
  });
});
}