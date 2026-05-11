import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thryft/providers/search_provider.dart';
import 'package:thryft/utils/filter_form_validator.dart';

//FR1 #10 - Search bar text filtering
// Verifies SearchProvider debounces input, sets + clears loading and provides
//results list after debounce.
void main() {
  test('SearchProvider debounces and runs a search', () {
    final provider = SearchProvider();

    FakeAsync().run((fa) { //simulate user typing into search bar
      provider.onQueryChanged('abc');
      // Immediately after typing query and loading should be true
      expect(provider.query, 'abc'); //immediately after typing, set the query 
      expect(provider.isLoading, isTrue); // load = true

      // advance past the debounce and let async work flush
      fa.elapse(const Duration(milliseconds: 400));
      fa.flushMicrotasks();

      // _executeSearch catches network errors and sets loading to false
      expect(provider.isLoading, isFalse);
      expect(provider.results, isA<List>());
    });
  });

