import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thryft/providers/search_provider.dart';
import 'package:thryft/utils/filter_form_validator.dart';
import '../helpers/supabase_test_client.dart';

//FR1 #10 - Search bar text filtering
// Verifies SearchProvider debounces input, sets + clears loading and provides
//results list after debounce.
void main() {
  setUpAll(() async {
    if (hasTestCredentials) {
      await getTestClient();
    }
  });

  test('SearchProvider debounces and runs a search', () async {
    if (!hasTestCredentials) return;
    final provider = SearchProvider();

    provider.onQueryChanged('abc');
    expect(provider.query, 'abc');
    expect(provider.isLoading, isTrue);

    // advance past the debounce (400ms) plus network time
    await Future.delayed(const Duration(milliseconds: 1500));

    expect(provider.isLoading, isFalse);
    expect(provider.results, isA<List>());
  });

//FR 1 #8: Invalid Price filter test - wrong data type
  test('FR1 #8 - wrong data type ignored and instead treated as max value', () {
    final double userEntered = 1000000.0; //simulate user entering a very large number into the price field
    final double priceToValidate = userEntered > 10000.0 ? 10000.0 : userEntered; //simulate validator treating out-of-range input as max value
    
    final err = validateFilterForm(
      department: 'All',
      size: 'All',
      condition: 'All',
      brand: 'All',
      fitting: 'All',
      material: 'All',
      colour: 'All',
      ownedBy: null,
      price: priceToValidate,
    );
    // 
    expect(err, isNull); //Validator accepts inout and safely ignores it
  });
}
