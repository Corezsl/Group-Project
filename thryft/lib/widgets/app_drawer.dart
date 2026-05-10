import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Slide-in side menu opened from the mobile Header's hamburger button.
// Lists category shortcuts, account links, and a Sell now button.
// Every tile pops the drawer first so the user can see the destination.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // logo header — also acts as a "go home" button
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 71, 164, 245),
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.pop(context);
                context.go('/');
              },
              child: Image.asset(
                'assets/images/thyrft_logo.png',
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
              ),
            ),
          ),
          // category shortcuts — go(...) replaces the stack so back doesnt loop through them
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              context.go('/');
            },
          ),
          ListTile(
            leading: const Icon(Icons.checkroom_outlined),
            title: const Text('Shirts'),
            onTap: () {
              Navigator.pop(context);
              context.go('/category/Shirt');
            },
          ),
          ListTile(
            leading: const Icon(Icons.dry_cleaning_outlined),
            title: const Text('Trousers'),
            onTap: () {
              Navigator.pop(context);
              context.go('/category/Trousers');
            },
          ),
          ListTile(
            leading: const Icon(Icons.beach_access_outlined),
            title: const Text('Shorts'),
            onTap: () {
              Navigator.pop(context);
              context.go('/category/Shorts');
            },
          ),
          ListTile(
            leading: const Icon(Icons.woman),
            title: const Text('Dresses'),
            onTap: () {
              Navigator.pop(context);
              context.go('/category/Dresses');
            },
          ),
          ListTile(
            leading: const Icon(Icons.directions_walk_outlined),
            title: const Text('Shoes'),
            onTap: () {
              Navigator.pop(context);
              context.go('/category/Shoes');
            },
          ),
          ListTile(
            leading: const Icon(Icons.watch_outlined),
            title: const Text('Accessories'),
            onTap: () {
              Navigator.pop(context);
              context.go('/category/Accessories');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Us'),
            onTap: () {
              Navigator.pop(context);
              context.go('/about');
            },
          ),
          const Divider(),
          // user-specific links — push(...) keeps them in the back stack
          ListTile(
            leading: const Icon(Icons.favorite_outline),
            title: const Text('Wishlist'),
            onTap: () {
              Navigator.pop(context);
              context.push('/wishlist');
            },
          ),
          // Account routes to /account if logged in, otherwise to the auth screen
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Account'),
            onTap: () {
              Navigator.pop(context);
              final session = Supabase.instance.client.auth.currentSession;
              if (session != null) {
                context.push('/account');
              } else {
                context.push('/auth');
              }
            },
          ),
          const Divider(),
          // Sell now: same auth-aware pattern, but also shows a snackbar explaining
          // why guests get bounced to the auth screen
          ListTile(
            leading: const Icon(Icons.sell_outlined),
            title: const Text('Sell now'),
            onTap: () {
              Navigator.pop(context);
              final session = Supabase.instance.client.auth.currentSession;
              if (session != null) {
                context.push('/create-listing');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'You need to be logged in to create a listing',
                    ),
                    duration: Duration(seconds: 3),
                  ),
                );
                context.push('/auth');
              }
            },
          ),
        ],
      ),
    );
  }
}
