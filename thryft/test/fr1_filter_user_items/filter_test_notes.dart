// ----------------------------------------------------
// Creating the base test logic
// ----------------------------------------------------


//Files to test:
// Responsive Sizing
// Filter
//  - By size
//  - By price range
//  - By multiple items
//  - By specific text on items matched into the DB
//  - Resetting filter
//  - By price range (where value given exceeds amount -- just have it return everything as long as items closest to it)
// Mini Filter:
// -Re-ordering results
// - Filtering on items which have already been filtered (2x over)

// That it fetches the items from supabase
// Returning 0 items case
// Test search bar functionality
// Filter building/ search bar on screen (header)
// Fetching timeout test case/ test response time for retrieval

//Results screen: 
//  - That it renders mini-filter
//  - That it updates when mini filter selected
//  - How it copes with pagination (where applciable)
//  - That it renders in reasonable time
//  - That it contains the header and footer as every screen does





//FROM CW1 ----------
//Users Should Be Able to Filter Items 
//- narrow down and refine item listings using multiple filter options to find products that match 
//- The filtering functionality should be intuitive, responsive and reliable, allowing users to combine different criteria to reduce irrelevant results 
//System Requirements: 
//Size filtering using valid ranges (XS–XXL, 6–22, 30Reg–50Reg). 
//Brand filtering based on a catalogue of predefined brands, with an option to request new additions. 
//Condition filtering using a mandatory range from “acceptable” to “new”. 
//Fit filtering from a predefined list (e.g., Slim to Baggy). 
//Price range filtering using a slider or manual entry of float values. 
//Material filtering based on seller-provided garment material. 
//Colour filtering using a list of valid common colours. 
//Item type filtering (e.g., raincoat, jumper, skirt). 
//Validation: 
//Dropdown values allow only valid sizes. 
//Brand search system checks all values and allows requests for new brand entries (not directly added to the database). 
//Predefined lists allow only one condition to be selected. 
//Dropdown list ensures valid fit types. 
//Price range fields only accept integer or float values within min/max limits. 
//Material filtering only allows selections from a predefined list and may accept multiple values. 
//Colour list filters through primary and secondary user-provided colours. 
//Optional category dropdown for item purpose/type. 

//FIR TESTING:


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
