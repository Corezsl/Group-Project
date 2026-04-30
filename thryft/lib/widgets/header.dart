import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/providers/notification_provider.dart';
import 'package:thryft/providers/search_provider.dart';
import 'package:thryft/utils/responsive.dart';
import 'package:thryft/widgets/filter_system.dart';
import 'package:thryft/widgets/notification_badge.dart';
import 'package:thryft/widgets/search_dropdown.dart';

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
                // Hamburger
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
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
