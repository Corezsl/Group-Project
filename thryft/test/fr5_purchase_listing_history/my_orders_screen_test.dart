import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:thryft/models/product.dart';
import 'package:thryft/providers/wishlist_provider.dart';

// ---------------------------------------------------------------------------
// Fake WishlistProvider — identical to the one in user_listings_screen_test.
// ---------------------------------------------------------------------------

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
// Minimal order card widget — mirrors the InkWell + context.push in
// MyOrdersScreen._buildOrderCard without pulling in the full screen and its
// Supabase.instance.client dependency.
// ---------------------------------------------------------------------------

class _OrderCardTapTarget extends StatelessWidget {
  final Product product;
  const _OrderCardTapTarget({required this.product});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('order_card_tap'),
      onTap: () => context.push(
        '/product/${product.id}',
        extra: <String, String>{
          'id': product.id,
          'name': product.name,
          'price': product.price.toString(),
          'size': product.size,
          'brand': product.brand,
          'condition': product.condition,
          'imageUrl': product.imageUrl ?? '',
          'sellerId': product.sellerId ?? '',
          'sellerName': product.sellerName ?? '',
          'is_sold': product.isSold.toString(),
          'category': product.category,
        },
      ),
      child: Text(product.brand),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Product _purchasedProduct() => const Product(
      id: 'order-1',
      name: 'Blue Jacket',
      price: 25.0,
      size: 'M',
      brand: 'Nike',
      condition: 'Good',
      department: 'Menswear',
      category: 'Tops',
      material: 'Cotton',
      colour: 'Blue',
      isSold: true,
      sellerId: 'seller-1',
      sellerName: 'seller_user',
    );

/// Builds a test app where tapping [child] can navigate to /product/:id.
/// [onProductRoute] is called when the product detail route is reached,
/// letting the test assert the correct id was navigated to.
Widget _wrap(Widget child, {void Function(String id)? onProductRoute}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => Scaffold(body: child),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          onProductRoute?.call(state.pathParameters['id'] ?? '');
          return const Scaffold(body: Text('product detail'));
        },
      ),
    ],
  );
  return ChangeNotifierProvider<WishlistProvider>(
    create: (_) => _FakeWishlistProvider(),
    child: MaterialApp.router(routerConfig: router),
  );
}

// ---------------------------------------------------------------------------
// FR5 Partition 8 — View past purchase details
// -------------------------------------------------------------------------

void main() {
  group('FR5 #8 — past purchase detail tap', () {
    testWidgets('tapping order card navigates to /product/:id', (tester) async {
      String? navigatedId;
      final product = _purchasedProduct();

      await tester.pumpWidget(_wrap(
        _OrderCardTapTarget(product: product),
        onProductRoute: (id) => navigatedId = id,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('order_card_tap')));
      await tester.pumpAndSettle();

      expect(navigatedId, equals('order-1'));
      expect(find.text('product detail'), findsOneWidget);
    });

    testWidgets('product detail page shows after tap', (tester) async {
      await tester.pumpWidget(_wrap(
        _OrderCardTapTarget(product: _purchasedProduct()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('order_card_tap')));
      await tester.pumpAndSettle();

      expect(find.text('product detail'), findsOneWidget);
    });
  });
}
