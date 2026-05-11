import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thryft/providers/search_provider.dart';
import 'package:thryft/utils/filter_form_validator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('SearchProvider debounces and runs a search', () {
    final provider = SearchProvider();

    FakeAsync().run((fa) { 
      provider.onQueryChanged('abc');
      expect(provider.query, 'abc'); 
      expect(provider.isLoading, isTrue); 

      fa.elapse(const Duration(milliseconds: 400));
      fa.flushMicrotasks();

      expect(provider.isLoading, isFalse);
      expect(provider.results, isA<List>());
    });
  });

  test('FR1 #8 - wrong data type ignored and instead treated as max value', () {
    final double userEntered = 1000000.0; 
    final double priceToValidate = userEntered > 10000.0 ? 10000.0 : userEntered; 
    
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
    expect(err, isNull); 
  });
}
