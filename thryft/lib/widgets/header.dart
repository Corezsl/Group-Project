import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/utils/responsive.dart';
import 'package:thryft/widgets/filter_system.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Responsive.isMobile(context) ? _MobileHeader() : _DesktopHeader();
  }
}

// ─── Desktop ────────────────────────────────────────────────────────────────

class _DesktopHeader extends StatefulWidget {
  const _DesktopHeader();

  @override
  State<_DesktopHeader> createState() => _DesktopHeaderState();
}

class _DesktopHeaderState extends State<_DesktopHeader> {
  bool _filterActive = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
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
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => context.go('/'),
                        child: Image.asset(
                          'assets/images/thyrft_logo.png',
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.white,
                              ),
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
                              fillColor: const Color.fromARGB(
                                50,
                                255,
                                255,
                                255,
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // static filter icon (no interaction)
                        IconButton(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          icon: Icon(
                            _filterActive
                                ? Icons.filter_alt
                                : Icons.filter_alt_outlined,
                            color: Colors.white,
                          ),
                          onPressed: () => setState(() => _filterActive = !_filterActive),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
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
                        onPressed: () {
                          final session =
                              Supabase.instance.client.auth.currentSession;
                          if (session != null) {
                            context.push('/account');
                          } else {
                            context.push('/auth');
                          }
                        },
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
              ],
            ),
            // reserved area: either shortcuts or filter panel
            SizedBox(
              height: 48,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _filterActive
                    ? const FilterPanel(key: ValueKey('filter'))
                    : const SizedBox.shrink(key: ValueKey('shortcuts')),
              ),
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
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.go('/'),
            child: Image.asset(
              'assets/images/thyrft_logo.png',
              height: 44,
              fit: BoxFit.contain,
            ),
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
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () {
              final session = Supabase.instance.client.auth.currentSession;
              if (session != null) {
                context.push('/account');
              } else {
                context.push('/auth');
              }
            },
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
            leading: const Icon(Icons.accessibility_new_outlined),
            title: const Text('Trousers'),
            onTap: () {
              Navigator.pop(context);
              context.go('/category/Trousers');
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
              final session = Supabase.instance.client.auth.currentSession;
              if (session != null) {
                context.push('/account');
              } else {
                context.push('/auth');
              }
            },
          ),
          const Divider(),
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
