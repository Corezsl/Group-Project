import 'package:flutter_test/flutter_test.dart';
import 'package:thryft/utils/filter_form_validator.dart';

String? _filterValidation({
  String size = 'Any', //set to default value
  double minPrice = 0.1, //set as 0.01 in validation (need to double check)
  double? maxPrice, //set as 10000 in validation rules (need to check aswell)
  String department = 'Any',
  String brand = 'Any',
  String condition = 'Any',
  String fitting = 'Any',
  String material = 'Any',
  String colour = 'Any',
  String? ownedBy,
}) =>
    validateFilterForm(
      department: department,
      size: size,
      maxPrice: 10000, //set as 10000 as in validation rules
      brand: brand,
      condition: condition,
      fitting: fitting,
      material: material,
      colour: colour,
      ownedBy: ownedBy,
    );

  
  // This is base logic for default sizing
  //if (size != 'Any' || !['XS', 'S', 'M', 'L', 'XL', 'XXL'].contains(size)) {
  //  return 'Invalid size';
  //}
  //if (minPrice != null && minPrice < 0) {
  //  return 'Min price cannot be negative';
  //}
  //if (maxPrice != null && maxPrice < 0) {
  //  return 'Max price cannot be negative';
  //}
  //if (minPrice != null && maxPrice != null && minPrice > maxPrice) {
  //  return 'Min price cannot be greater than max price'; 
  //}
  //if (department != null && !['Menswear', 'Womenswear'].contains(department)) {
  //  return 'Invalid department';
  //}
  //if (department == 'Womenswear' && size != null && !['6', '8', '10', '12', '14', '16', '18', '20', '22'].contains(size)) {
  //  return 'Invalid size for womenswear';
  //}
  //if (department == 'Menswear' && size != null && !['30R', '32R', '34R', '36R', '38R', '40R', '42R', '44R', '46R', '48R', '50R'].contains(size)) {
  //  return 'Invalid size for menswear';
  //}
  //if (brand != null && !['Nike', 'Adidas', 'Zara', 'H&M'].contains(brand)) {
  //  return 'Invalid brand';
  //}
  // Add more validation rules as needed.
  
  //return null; // null means valid



void main() {
  group('FR1 #1 - Filter Validation on Sizes', () {
    test('Valid inputs pass validation', () {
      expect(_filterValidation(size: 'M', minPrice: 10.0, maxPrice: 50.0), isNull);
    });

    test('Invalid size fails validation', () {
      expect(
        _filterValidation(size: '30R', department: 'Womenswear'), 
      equals('Invalid size'));
    });

  group('FR1 #2 - Filter Validation on Price Range', () {
    test('Negative min price fails validation', () {
      expect(_filterValidation(minPrice: -5.0), equals('Min price cannot be negative'));
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
  );
});
}