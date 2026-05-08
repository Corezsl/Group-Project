import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/utils/responsive.dart';

// Big banner shown at the top of the home screen with a "Sell now" call to action.
// Has separate desktop and mobile layouts since the white card sits in different
// places, but they share the same content/button via _HeroBannerContent.
class HeroBanner extends StatelessWidget {
  const HeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // pick the layout based on screen width via the Responsive helper
    return Responsive.isMobile(context)
        ? _MobileHeroBanner()
        : _DesktopHeroBanner();
  }
}

// ─── Desktop ─────────────────────────────────────────────────────────────────

// Desktop layout: two side-by-side images in the background with a fixed-width
// white content card floating on the left.
class _DesktopHeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 400,
      color: Colors.grey[200],
      child: Stack(
        children: [
          // background — two images side-by-side filling the banner
          Positioned.fill(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Image.asset(
                    'assets/images/selling_image_1.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
                Expanded(
                  child: Image.asset(
                    'assets/images/selling_image_2.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
          // foreground white card pinned to the left
          Positioned(
            left: 50,
            top: 50,
            bottom: 50,
            child: Container(
              width: 350,
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: _HeroBannerContent(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mobile ──────────────────────────────────────────────────────────────────

// Mobile layout: same two background images, but the white card stretches full
// width with simple padding instead of being absolutely positioned.
class _MobileHeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.grey[200],
      child: Stack(
        children: [
          Positioned.fill(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Image.asset(
                    'assets/images/selling_image_1.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
                Expanded(
                  child: Image.asset(
                    'assets/images/selling_image_2.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: _HeroBannerContent(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared content ──────────────────────────────────────────────────────────

// Headline + Sell now button + Learn how it works link.
// Used by both layouts so the copy stays in one place.
class _HeroBannerContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Ready to declutter your wardrobe?',
          style: TextStyle(
            // smaller font on mobile so it fits
            fontSize: Responsive.isMobile(context) ? 24 : 32,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            // logged in -> go straight to create listing.
            // logged out -> show a snackbar and bounce to the auth screen.
            onPressed: () {
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
            style: FilledButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 71, 164, 245),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text('Sell now'),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => context.push('/help-center'),
            child: const Text(
              'Learn how it works',
              style: TextStyle(
                color: Color.fromARGB(255, 71, 164, 245),
                fontSize: 15,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
