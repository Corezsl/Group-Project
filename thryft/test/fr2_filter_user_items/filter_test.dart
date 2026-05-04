import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/router.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

// FR2: Partition 1 - Filter by single size
// Tests that the correct value is selected and follows the validation rules in place

void main() {
  late MockSupabaseClient client;
  late MockGoTrueClient auth;

  setUp(() {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    when(() => client.auth).thenReturn(auth);
  });

  group('FR2 #1 - Filter By Single Size', () {
    test('returns values that match the size type given', () {
      when(() => null); //NTS: returns values matched, and add an expect, replace null with the expected result.
    });


    //what to test for this section (size)- 
    //#1 Any user can select a value
    //#2 Does the value selected match the department value?
    //#3 

  });
}

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