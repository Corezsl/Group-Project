import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:thryft/models/product.dart';
import 'package:thryft/providers/wishlist_provider.dart';
import 'package:thryft/widgets/standard_product_grid.dart';

// Satisfies Consumer<WishlistProvider> in ProductCard without touching Supabase.
class _FakeWishlistProvider extends WishlistProvider {
  _FakeWishlistProvider() : super.test();

  @override
  bool isWishlisted(String productId) => false;

  @override
  Future<void> toggleWishlist(Product product) async {}

  @override
  List<Product> get items => [];
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Product _product(String id) => Product(
      id: id,
      name: 'Item $id',
      price: 10.0,
      size: 'M',
      brand: 'Nike',
      condition: 'Good',
      department: 'Menswear',
      category: 'Tops',
      material: 'Cotton',
      colour: 'Black',
      isSold: false,
    );

/// Wraps [child] with the minimal MaterialApp + GoRouter needed for widgets
/// that call context.go / context.push internally (e.g. ProductCard).
Widget _wrap(Widget child) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => Scaffold(body: child)),
      GoRoute(
        path: '/product/:id',
        builder: (_, __) => const Scaffold(body: SizedBox()),
      ),
    ],
  );
  return ChangeNotifierProvider<WishlistProvider>(
    create: (_) => _FakeWishlistProvider(),
    child: MaterialApp.router(routerConfig: router),
  );
}

// ---------------------------------------------------------------------------
// FR4 Partition 4 — View own listings
// Tests the StandardProductGrid widget which MyListingsScreen delegates to.
// ---------------------------------------------------------------------------

void main() {
  group('FR4 #4 — view own listings', () {
    testWidgets('three active listings are all rendered as cards', (tester) async {
      final items = [_product('1'), _product('2'), _product('3')];

      await tester.pumpWidget(_wrap(
        StandardProductGrid(
          items: items,
          emptyTitle: 'No active listings',
          emptySubtitle: 'Items you list for sale will appear here.',
          emptyIcon: Icons.list_alt,
        ),
      ));
      await tester.pumpAndSettle();

      // ProductCard renders brand and price — assert three of each appear.
      expect(find.text('Nike'), findsNWidgets(3));
      expect(find.text('£10.00'), findsNWidgets(3));
    });

    testWidgets('empty listing shows empty-state title', (tester) async {
      await tester.pumpWidget(_wrap(
        const StandardProductGrid(
          items: [],
          emptyTitle: 'No active listings',
          emptySubtitle: 'Items you list for sale will appear here.',
          emptyIcon: Icons.list_alt,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No active listings'), findsOneWidget);
    });

    testWidgets('pagination summary shows correct item count', (tester) async {
      final items = List.generate(3, (i) => _product('$i'));

      await tester.pumpWidget(_wrap(
        StandardProductGrid(
          items: items,
          emptyTitle: 'No active listings',
          emptySubtitle: '',
          emptyIcon: Icons.list_alt,
        ),
      ));
      await tester.pumpAndSettle();

      // StandardProductGrid shows "Showing 1-N of N" when items exist.
      expect(find.textContaining('3'), findsWidgets);
    });
  });
}
