import 'package:flutter/material.dart';

/// Responsive layout helper used across the app to switch between
/// mobile and desktop layouts (e.g. single-column vs side-by-side).
/// Screens call [Responsive.isMobile] or [Responsive.isDesktop] inside
/// their `build` methods to decide which widget tree to render.
class Responsive {

  // Anything below 860px is treated as a mobile/phone layout.
  static const double mobileBreakpoint = 860;

  /// Returns `true` when the screen width is below [mobileBreakpoint].

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  /// Returns `true` when the screen width is at or above [mobileBreakpoint].
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint;
}
