import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/providers/notification_provider.dart';
import 'package:thryft/providers/search_provider.dart';
import 'package:thryft/utils/responsive.dart';
import 'package:thryft/widgets/app_drawer.dart';
import 'package:thryft/widgets/filter_system.dart';
import 'package:thryft/widgets/notification_badge.dart';
import 'package:thryft/widgets/search_dropdown.dart';

// Top bar shown on almost every screen — logo, search, filter toggle, and
// account/cart/wishlist/notification icons. Has separate desktop and mobile
// layouts since the desktop one also has a category shortcut row underneath.
class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    // pick the layout based on screen width via the Responsive helper
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
  // toggles the filter panel under the search bar
  bool _filterActive = false;

  // LayerLink anchors the search dropdown overlay directly under the search bar
  final _layerLink = LayerLink();
  final _searchController = TextEditingController();
  late final FocusNode _searchFocusNode;
  // currently shown search dropdown overlay (null when not focused)
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

  // shows/hides the dropdown when the search field gains or loses focus.
  // small delay on remove so a tap inside the dropdown can register before it disappears.
  void _onFocusChange() {
    if (_searchFocusNode.hasFocus) {
      _showOverlay();
    } else {
      _searchController.clear();
      if (mounted) context.read<SearchProvider>().clearResults();
      Future.delayed(const Duration(milliseconds: 150), _removeOverlay);
    }
  }

  // inserts the SearchDropdown into the overlay layer linked to the search bar
  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (_) => SearchDropdown(
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
                // logo on the left — tap to go home
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
                // centre block: search field + filter toggle button
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Row(
                      children: [
                        Expanded(
                          // CompositedTransformTarget gives the dropdown overlay something to anchor to
                          child: CompositedTransformTarget(
                            link: _layerLink,
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              textInputAction: TextInputAction.search,
                              // typing live-updates the dropdown results
                              onChanged: (v) => context
                                  .read<SearchProvider>()
                                  .onQueryChanged(v),
                              // pressing enter records the search and pushes to the search results screen
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
                // right block: notification bell + wishlist + cart + account icons
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // bell only shows when logged in (no notifications for guests)
                      Consumer<NotificationProvider>(
                        builder: (context, notifProvider, _) {
                          final session =
                              Supabase.instance.client.auth.currentSession;
                          if (session == null) return const SizedBox.shrink();
                          return NotificationBadge(
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
                      // person icon goes to account if logged in, otherwise to the auth screen
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
            // reserved area: either shortcuts or filter panel.
            // AnimatedSwitcher fades between the two when the filter button is toggled.
            SizedBox(
              height: 48,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _filterActive
                    ? const FilterPanel(key: ValueKey('filter'))
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

// Mobile state mirrors the desktop one — same overlay/focus dance, just a
// tighter layout and a hamburger menu instead of a category shortcut row.
class _MobileHeaderState extends State<_MobileHeader> {
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

  // mobile dropdown stretches almost full width (minus a 16px gutter)
  void _showOverlay() {
    _removeOverlay();
    final screenWidth = MediaQuery.of(context).size.width;
    _overlayEntry = OverlayEntry(
      builder: (_) => SearchDropdown(
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
      color: const Color.fromARGB(255, 71, 164, 245),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 60,
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
                    padding: const EdgeInsets.symmetric(horizontal: 4),
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    _filterActive
                        ? Icons.filter_alt
                        : Icons.filter_alt_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _filterActive = !_filterActive),
                ),
                // Notification bell
                Consumer<NotificationProvider>(
                  builder: (context, notifProvider, _) {
                    final session =
                        Supabase.instance.client.auth.currentSession;
                    if (session == null) return const SizedBox.shrink();
                    return NotificationBadge(
                      count: notifProvider.unreadCount,
                      onPressed: () => context.push('/notifications'),
                    );
                  },
                ),
                // Cart icon
                IconButton(
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () => context.push('/cart'),
                ),
                IconButton(
                  icon: const Icon(Icons.person_outline, color: Colors.white),
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
                // Hamburger — opens the AppDrawer.
                // If the parent Scaffold has a drawer registered, use that; otherwise
                // slide one in manually via showGeneralDialog so the menu still works
                // on screens that dont set up a Scaffold.drawer.
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () {
                      if (Scaffold.maybeOf(ctx)?.hasDrawer ?? false) {
                        Scaffold.of(ctx).openDrawer();
                      } else {
                        showGeneralDialog(
                          context: ctx,
                          barrierDismissible: true,
                          barrierLabel: 'Drawer',
                          barrierColor: Colors.black54,
                          transitionDuration: const Duration(milliseconds: 250),
                          pageBuilder:
                              (context, animation, secondaryAnimation) {
                                return const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Material(
                                    elevation: 16,
                                    child: AppDrawer(),
                                  ),
                                );
                              },
                          transitionBuilder:
                              (context, animation, secondaryAnimation, child) {
                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(-1, 0),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                );
                              },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _filterActive
                ? const SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: FilterPanel(key: ValueKey('filter')),
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ],
      ),
    );
  }
}
