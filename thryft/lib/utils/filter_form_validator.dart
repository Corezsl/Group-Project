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
  required String price, 
}) {

//checks price is within the valid range of 0.01 - 10000
final double? parsedPrice = double.tryParse(price);
if (parsedPrice == null || parsedPrice <= 0 || parsedPrice > 10000) {
  return 'Please enter a valid price greater than 0 or less than 10000.';}

//checks if size is valid (if not 'Any', or the default sizes)
if (size != 'Any' || !['XS', 'S', 'M', 'L', 'XL', 'XXL'].contains(size)) {
  return 'Invalid size';}

//validates department is either menswear, womenswear or any (default)
if (department != null && !['Menswear', 'Womenswear'].contains(department)) {
  return 'Invalid department';
}

//validates womenswear sizes
if (department == 'Womenswear' && size !=['6', '8', '10', '12', '14', '16', '18', '20', '22'].contains(size)) {
  return 'Invalid size for womenswear';
}
//validates menswear sizes
if (department == 'Menswear' && size !=['30R', '32R', '34R', '36R', '38R', '40R', '42R', '44R', '46R', '48R', '50R'].contains(size)) {
  return 'Invalid size for menswear';
}
//checks if brand is one of the predefined values
if (brand !=['Nike', 'Adidas', 'Zara', 'H&M'].contains(brand)) {
  return 'Invalid brand';
}
  //Add more validation rules as needed.
  
  return null; // null means valid
}

//FOR TESTING:

//step 1:create filtervalidationfrom()
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
