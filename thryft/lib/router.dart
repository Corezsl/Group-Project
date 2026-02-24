import 'package:go_router/go_router.dart';
import 'package:thryft/screens/account_screen.dart';
import 'package:thryft/screens/home_screen.dart';
import 'package:thryft/screens/product_detail_screen.dart';
import 'package:thryft/screens/wishlist_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/account',
      builder: (context, state) => const AccountScreen(),
    ),
    GoRoute(
      path: '/wishlist',
      builder: (context, state) => const WishlistPage(),
    ),
    GoRoute(
      path: '/product/:id',
      builder: (context, state) {
        final product = state.extra as Map<String, String>?;
        if (product == null) {
          return const HomeScreen();
        }
        return ProductDetailScreen(product: product);
      },
    ),
  ],
);
