import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/providers/notification_provider.dart';
import 'package:thryft/providers/search_provider.dart';
import 'package:thryft/utils/responsive.dart';
import 'package:thryft/widgets/filter_system.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Responsive.isMobile(context)
        ? const _MobileHeader()
        : const _DesktopHeader();
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

  final _layerLink = LayerLink();
  final _searchController = TextEditingController();
  late final FocusNode _searchFocusNode;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchFocusNode.removeListener(_onFocusChange);
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_searchFocusNode.hasFocus) {
      _showOverlay();
    } else {
      _searchController.clear();
      if (mounted) context.read<SearchProvider>().clearResults();
      Future.delayed(const Duration(milliseconds: 150), _removeOverlay);
    }
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (_) => _SearchDropdown(
        layerLink: _layerLink,
        controller: _searchController,
        dropdownWidth: 500,
        onDismiss: () => _searchFocusNode.unfocus(),
        onNavigate: _removeOverlay,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

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
                          child: CompositedTransformTarget(
                            link: _layerLink,
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              textInputAction: TextInputAction.search,
                              onChanged: (v) => context
                                  .read<SearchProvider>()
                                  .onQueryChanged(v),
                              onSubmitted: (v) {
                                final q = v.trim();
                                if (q.isNotEmpty) {
                                  context.read<SearchProvider>().submitSearch(
                                    q,
                                  );
                                  _searchFocusNode.unfocus();
                                  context.push(
                                    '/search?q=${Uri.encodeComponent(q)}',
                                  );
                                }
                              },
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.white,
                                ),
                                hintText: 'Search',
                                hintStyle: const TextStyle(
                                  color: Colors.white70,
                                ),
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
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          icon: Icon(
                            _filterActive
                                ? Icons.filter_alt
                                : Icons.filter_alt_outlined,
                            color: Colors.white,
                          ),
                          onPressed: () =>
                              setState(() => _filterActive = !_filterActive),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Consumer<NotificationProvider>(
                        builder: (context, notifProvider, _) {
                          final session =
                              Supabase.instance.client.auth.currentSession;
                          if (session == null) return const SizedBox.shrink();
                          return _NotificationBadge(
                            count: notifProvider.unreadCount,
                            onPressed: () => context.push('/notifications'),
                          );
                        },
                      ),
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
                    ? const FilterPanel(
                        key: ValueKey('filter'),
                      )
                    : Container(
                        key: const ValueKey('shortcuts'),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () => context.go('/'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Home'),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: () => context.go('/category/Shirts'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Shirts'),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: () => context.go('/category/Trousers'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Trousers'),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: () => context.go('/category/Shorts'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Shorts'),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: () => context.go('/category/Dresses'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Dresses'),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: () => context.go('/category/Shoes'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Shoes'),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: () =>
                                  context.go('/category/Accessories'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Accessories'),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: () => context.go('/about'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('About Us'),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Mobile ─────────────────────────────────────────────────────────────────

class _MobileHeader extends StatefulWidget {
  const _MobileHeader();

  @override
  State<_MobileHeader> createState() => _MobileHeaderState();
}

class _MobileHeaderState extends State<_MobileHeader> {
  final _layerLink = LayerLink();
  final _searchController = TextEditingController();
  late final FocusNode _searchFocusNode;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchFocusNode.removeListener(_onFocusChange);
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_searchFocusNode.hasFocus) {
      _showOverlay();
    } else {
      _searchController.clear();
      if (mounted) context.read<SearchProvider>().clearResults();
      Future.delayed(const Duration(milliseconds: 150), _removeOverlay);
    }
  }

  void _showOverlay() {
    _removeOverlay();
    final screenWidth = MediaQuery.of(context).size.width;
    _overlayEntry = OverlayEntry(
      builder: (_) => _SearchDropdown(
        layerLink: _layerLink,
        controller: _searchController,
        dropdownWidth: screenWidth - 16,
        onDismiss: () => _searchFocusNode.unfocus(),
        onNavigate: _removeOverlay,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
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
              child: CompositedTransformTarget(
                link: _layerLink,
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  textInputAction: TextInputAction.search,
                  onChanged: (v) =>
                      context.read<SearchProvider>().onQueryChanged(v),
                  onSubmitted: (v) {
                    final q = v.trim();
                    if (q.isNotEmpty) {
                      context.read<SearchProvider>().submitSearch(q);
                      _searchFocusNode.unfocus();
                      context.push('/search?q=${Uri.encodeComponent(q)}');
                    }
                  },
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
                    border: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color.fromARGB(50, 255, 255, 255),
                    isDense: true,
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
          // Notification bell
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, _) {
              final session = Supabase.instance.client.auth.currentSession;
              if (session == null) return const SizedBox.shrink();
              return _NotificationBadge(
                count: notifProvider.unreadCount,
                onPressed: () => context.push('/notifications'),
              );
            },
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

// ─── Search dropdown overlay ─────────────────────────────────────────────────

class _SearchDropdown extends StatelessWidget {
  final LayerLink layerLink;
  final TextEditingController controller;
  final double dropdownWidth;
  final VoidCallback onDismiss;
  final VoidCallback onNavigate;

  const _SearchDropdown({
    required this.layerLink,
    required this.controller,
    required this.dropdownWidth,
    required this.onDismiss,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Full-screen barrier: tap outside dismisses
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onDismiss,
          ),
        ),
        CompositedTransformFollower(
          link: layerLink,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          showWhenUnlinked: false,
          child: GestureDetector(
            // Absorb taps so they don't hit the barrier above
            onTap: () {},
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: dropdownWidth,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 380),
                  child: Consumer<SearchProvider>(
                    builder: (context, provider, _) {
                      if (provider.query.isEmpty) {
                        return _buildIdle(context, provider);
                      }
                      if (provider.isLoading) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      if (provider.results.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No results for "${provider.query}"',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        );
                      }
                      return _buildResults(context, provider);
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdle(BuildContext context, SearchProvider provider) {
    if (provider.recentSearches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Start typing to search...',
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
      );
    }
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent searches',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              TextButton(
                onPressed: provider.clearRecentSearches,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Clear all', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        ...provider.recentSearches
            .take(5)
            .map(
              (q) => ListTile(
                dense: true,
                leading: const Icon(
                  Icons.history,
                  size: 18,
                  color: Colors.grey,
                ),
                title: Text(q, style: const TextStyle(fontSize: 14)),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                  onPressed: () => provider.removeRecentSearch(q),
                ),
                onTap: () {
                  controller.text = q;
                  provider.onQueryChanged(q);
                },
              ),
            ),
      ],
    );
  }

  Widget _buildResults(BuildContext context, SearchProvider provider) {
    final shown = provider.results.take(5).toList();
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        ...shown.map(
          (product) => ListTile(
            dense: true,
            leading: SizedBox(
              width: 36,
              height: 36,
              child: product.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.image_not_supported,
                          size: 24,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.image_not_supported,
                      size: 24,
                      color: Colors.grey,
                    ),
            ),
            title: Text(
              product.name,
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '£${product.price.toStringAsFixed(2)} · ${product.brand}',
              style: const TextStyle(fontSize: 12),
            ),
            onTap: () {
              onDismiss();
              context.push(
                '/product/${product.id}',
                extra: product.toRouteExtra(),
              );
            },
          ),
        ),
      ],
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

// ─── Notification Badge ───────────────────────────────────────────────────────

class _NotificationBadge extends StatelessWidget {
  final int count;
  final VoidCallback onPressed;

  const _NotificationBadge({required this.count, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: onPressed,
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
