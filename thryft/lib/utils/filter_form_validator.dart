import 'package:thryft/utils/size_options.dart';
//Validation utility for Filter Form (FR1).

// This is a pure function that checks all user inputs 
// before being used to query the database.

String? validateFilterForm({
  required String? department,
  required String size,
  required String condition,
  required String brand,
  required String fitting,
  required String material,
  required String colour,
  required String? ownedBy,
  required double? price, 
}) {

//checks price is within the valid range of 0.01 - 10000
if (price != null && price <= 0 && price > 10000) {
  return 'Please enter a valid price greater than 0 or less than 10000.';}

//checks if size is valid (if not 'Any', or the default sizes)
if (size != 'Any' || !['XS', 'S', 'M', 'L', 'XL', 'XXL'].contains(size)) {
  return 'Invalid size';}

//validates department is either menswear, womenswear or any (default)
if (department != null && !['Mens', 'Womens'].contains(department)) {
  return 'Invalid department';
}

  // validate size against canonical lists from size_options.dart
  final allowedSizes = getSizeOptions(department: department);
  // allow 'All' or 'Any' as tokens meaning "no size filter"
  if (size != 'All' && size != 'Any' && !allowedSizes.contains(size)) {
    return 'Invalid size';
  }

  // validate condition, fitting, material and colour against canonical lists
  if (!conditions.contains(condition)) {
    return 'Invalid condition';
  }
  if (!fittings.contains(fitting)) {
    return 'Invalid fitting';
  }
  if (!materials.contains(material)) {
    return 'Invalid material';
  }
  if (!colours.contains(colour)) {
    return 'Invalid colour';
  }

  // validate brand against canonical brands list
  final brandTrimmed = brand.trim();
  if (brandTrimmed.isEmpty || !brands.contains(brandTrimmed)) {
    return 'Invalid brand';
  }

  // Add more validation rules as needed.

  return null; // null means valid
}

//FOR TESTING:

//step 1:create filtervalidationfrom() DONE
//step2:incorporate into filter system in filter_system.dart
//step 3: create test for filter validation function, and then test that the filter system is correctly validating the inputs and returning the expected results from database.
//step 4:TESRING PART:(format similar can be found for fr3):
//const _sellerEmail = 'fr4.seller@thryft-test.local';
//const _sellerPassword = 'Thryft!test99';

//const _buyerEmail = 'fr4.buyer@thryft-test.local';
//const _buyerPassword = 'Thryft!test99'; CREATE SELLER AND BUYER IN SUPABASE WITH THESE CREDENTIALS TO TEST FILTERING.
//make test with all possible values for filter(valid and invalid values),
//test when a user is signed in and signed out with filter validation, and then test that the correct values are returned from the database, and that incorrect values are rejected by the filter validation function.
//follow test plan for patritions outlined in the test plan document, 
//and ensure that all edge cases are covered, such as invalid input formats, 
//empty values, and combinations of filters that may not return any results.
