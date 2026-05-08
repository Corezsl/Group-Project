
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thryft/widgets/filter_system.dart';
import 'package:thryft/providers/search_provider.dart';

void main() {
  testWidgets('FilterPanel Apply maps UI inputs to SearchFilters', (tester) async {
    SearchFilters? applied;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FilterPanel(
          onApply: (f) => applied = f,
        ),
      ),
    ));

    // initially 'Department' dropdown shows 'All' (text exists)
    expect(find.text('Department:'), findsOneWidget);

    // open Department menu and select 'Womens'
    await tester.tap(find.text('All').first); // opens first 'All' encountered
    await tester.pumpAndSettle();
    await tester.tap(find.text('Womens').last); // chooses 'Womens'
    await tester.pumpAndSettle();

    // open Size menu and choose a size (size options depend on department)
    await tester.tap(find.text('Size:').first); // this just finds label; to open use the size Dropdown finder
    // safer: find the DropdownButton by looking for the specific value widget:
    await tester.tap(find.widgetWithText(DropdownButton<String>, 'All').at(1));
    await tester.pumpAndSettle();
    // choose a size value — adjust according to available size strings:
    await tester.tap(find.text('S').last); // if 'S' exists in getSizeOptions
    await tester.pumpAndSettle();

    // enter a max price (numeric)
    final priceField = find.byType(TextField);
    expect(priceField, findsWidgets);
    await tester.enterText(priceField.first, '49.99');
    await tester.pumpAndSettle();

    // tap Apply button
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    // Assert onApply was called and mapping is correct
    expect(applied, isNotNull);
    expect(applied!.department, equals('Womens'));
    // size assertion depends on the exact menu options; adjust to chosen size
    expect(applied!.maxPrice, equals(49.99));
    // 'All' selections should become null; if brand remained 'All' then:
    expect(applied!.brand, isNull);
  });
}
// ----------------------------------------------------
// Creating the base test logic
// ----------------------------------------------------


  //NTS: create filter validation function, which will be used to validate the inputs for the filter system, and then test that it is correctly validating the inputs and returning the expected results from database.


// FR2: Partition 1 - Filter by single size
// Tests that the correct value is selected and follows the validation rules in place


//what to test for this section (size)
//#1 Any user can select a val
//#2 Does the value selected match the department value?

//Files to test:
// Responsive Sizing
// Returns Screen
// Filter
//  - By size
//  - By price range
//  - By multiple items
//  - By specific text on items matched into the DB
//  - Resetting filter
//  - By price range (where value given exceeds amount -- just have it return everything as long as items closest to it)

// Mini Filter
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
//Functional Requirement 2: Users Should Be Able to Filter Items 
//Description: 
//Users should be able to narrow down and refine item listings using multiple filter options to quickly find products that match their preferences. The filtering functionality should be intuitive, responsive and reliable, allowing users to combine different criteria to reduce irrelevant results and improve browsing experience. 
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
