import 'package:flutter/material.dart';

// Bell icon with a small red unread-count bubble in the top right.
// Used in the Header — the count comes from NotificationProvider.unreadCount.
class NotificationBadge extends StatelessWidget {
  // unread notification count — when 0 the bubble is hidden entirely
  final int count;
  // tapped to open the notifications screen
  final VoidCallback onPressed;

  const NotificationBadge({
    super.key,
    required this.count,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Stack so the red bubble can sit on top of the bell icon.
    // Clip.none lets the bubble overhang the icon's bounds slightly.
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
            // IgnorePointer so taps on the bubble fall through to the bell underneath
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                // cap the display at 99+ so big numbers dont blow out the bubble
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
