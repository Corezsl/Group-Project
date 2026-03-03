import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thryft/utils/responsive.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Responsive.isMobile(context) ? _MobileHeader() : _DesktopHeader();
  }
}

// ─── Desktop ────────────────────────────────────────────────────────────────

class _DesktopHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      color: const Color.fromARGB(255, 71, 164, 245),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Image.asset(
                        'assets/images/thyrft_logo.png',
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 500,
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      hintText: 'Search',
                      hintStyle: const TextStyle(color: Colors.white70),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color.fromARGB(50, 255, 255, 255),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FilledButton.tonal(
                        onPressed: null,
                        style: FilledButton.styleFrom(
                          textStyle: const TextStyle(fontSize: 16.0),
                        ),
                        child: const Text('SELL NOW'),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(
                          Icons.favorite_outline,
                          color: Colors.white,
                        ),
                        onPressed: () => context.push('/wishlist'),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.shopping_cart_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () => context.push('/cart'),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.person_outline,
                          color: Colors.white,
                        ),
                        onPressed: () => context.push('/account'),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => context.go('/'),
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text('Home'),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: null,
                  child: const Text(
                    'Shirts',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: null,
                  child: const Text(
                    'Trousers',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: null,
                  child: const Text(
                    'Shoes',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: null,
                  child: const Text(
                    'Accessories',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () => context.go('/about'),
                  child: const Text(
                    'About Us',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Mobile ─────────────────────────────────────────────────────────────────

class _MobileHeader extends StatelessWidget {
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: const Color.fromARGB(255, 71, 164, 245),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // Logo
          Image.asset(
            'assets/images/thyrft_logo.png',
            height: 44,
            fit: BoxFit.contain,
          ),
          // Expanded search bar
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 20,
                  ),
                  hintText: 'Search',
                  hintStyle: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  border: const OutlineInputBorder(borderSide: BorderSide.none),
                  filled: true,
                  fillColor: const Color.fromARGB(50, 255, 255, 255),
                  isDense: true,
                ),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
          // Cart icon
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            onPressed: () => context.push('/cart'),
          ),
          // Hamburger
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mobile Drawer ───────────────────────────────────────────────────────────

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 71, 164, 245),
            ),
            child: Image.asset(
              'assets/images/thyrft_logo.png',
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
            ),
          ),
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
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.accessibility_new_outlined),
            title: const Text('Trousers'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.directions_walk_outlined),
            title: const Text('Shoes'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.watch_outlined),
            title: const Text('Accessories'),
            onTap: () => Navigator.pop(context),
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
          ListTile(
            leading: const Icon(Icons.favorite_outline),
            title: const Text('Wishlist'),
            onTap: () {
              Navigator.pop(context);
              context.push('/wishlist');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Account'),
            onTap: () {
              Navigator.pop(context);
              context.push('/account');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.sell_outlined),
            title: const Text('Sell now'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
