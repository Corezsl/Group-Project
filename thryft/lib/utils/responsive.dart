import 'package:flutter/material.dart';

class Responsive {
  static const double mobileBreakpoint = 768;

  /// Returns true when the screen width is below the mobile breakpoint.
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  /// Returns true when the screen width is at or above the mobile breakpoint.
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint;
}
