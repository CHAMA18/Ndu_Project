import 'package:flutter/material.dart';

/// Central breakpoints and helpers for responsive layouts.
class AppBreakpoints {
  // Tune breakpoints to match common device classes
  static const double tablet = 900; // < 900 = mobile
  static const double desktop = 1200; // >= 1200 = desktop

  static bool isMobile(BuildContext context) => MediaQuery.sizeOf(context).width < tablet;
  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= tablet && w < desktop;
  }
  static bool isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width >= desktop;

  static double pagePadding(BuildContext context) => isMobile(context) ? 16 : 40;
  static double sectionGap(BuildContext context) => isMobile(context) ? 12 : 24;
  static double fieldGap(BuildContext context) => isMobile(context) ? 8 : 16;

  static double sidebarWidth(BuildContext context) {
    if (isDesktop(context)) return 320;
    if (isTablet(context)) return 260;
    final width = MediaQuery.sizeOf(context).width;
    final double mobileWidth = (width * 0.72).clamp(220.0, 300.0).toDouble();
    return mobileWidth;
  }
}
