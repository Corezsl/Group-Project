import 'package:go_router/go_router.dart';
import 'package:thryft/screens/home_screen.dart';
import 'package:thryft/screens/product_detail_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/product/:id',
      builder: (context, state) {
        final product = state.extra as Map<String, String>?;
        if (product == null) {
          // If product data is missing (e.g. direct URL access),
          // redirect to home since we don't have a way to fetch product by ID yet.
          return const HomeScreen();
        }
        return ProductDetailScreen(product: product);
      },
    ),
  ],
);
