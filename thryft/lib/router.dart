import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thryft/about_page.dart';
import 'package:thryft/contact_page.dart';
import 'package:thryft/screens/account_screen.dart';
import 'package:thryft/screens/profile_settings_screen.dart';
import 'package:thryft/screens/cart_screen.dart';
import 'package:thryft/screens/create_listing_screen.dart';
import 'package:thryft/screens/home_screen.dart';
import 'package:thryft/screens/product_detail_screen.dart';
import 'package:thryft/screens/wishlist_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    // Core Pages
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/about',
      builder: (context, state) => const AboutPage(),
    ),
    GoRoute(
      path: '/contact',
      builder: (context, state) => const ContactPage(),
    ),

    // User & Shopping
    GoRoute(
      path: '/cart',
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/wishlist',
      builder: (context, state) => const WishlistPage(),
    ),
    GoRoute(
      path: '/account',
      builder: (context, state) => const AccountScreen(),
    ),
    GoRoute(
      path: '/profile-settings',
      builder: (context, state) => const ProfileSettingsScreen(),
    ),
    GoRoute(
      path: '/create-listing',
      builder: (context, state) => const CreateListingScreen(),
    ),

    // Dynamic Category Routing
    GoRoute(
      path: '/category/:name',
      builder: (context, state) {
        final categoryName = state.pathParameters['name']!;
        // Currently returns HomeScreen; update this when each CategoryScreen is implemented
        return const HomeScreen(); 
      },
    ),

    // Product Details
    GoRoute(
      path: '/product/:id',
      builder: (context, state) {
        final product = state.extra as Map<String, String>?;
        if (product == null) return const HomeScreen();
        return ProductDetailScreen(product: product);
      },
    ),
  ],
);