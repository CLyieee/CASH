import 'package:flutter/material.dart';

class ResponsiveHelper {
  /// Get responsive value based on screen width
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1024 && desktop != null) return desktop;
    if (width >= 600 && tablet != null) return tablet;
    return mobile;
  }

  /// Check if screen is small (< 360dp width)
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }

  /// Check if screen is extra small (< 320dp width)
  static bool isExtraSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 320;
  }

  /// Check if screen is mobile (< 600dp width)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// Check if screen is tablet (>= 600dp and < 1024dp width)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1024;
  }

  /// Check if screen is desktop (>= 1024dp width)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  /// Get responsive font size
  static double fontSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return responsive<double>(
      context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.1,
      desktop: desktop ?? mobile * 1.2,
    );
  }

  /// Get responsive spacing
  static double spacing(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return responsive<double>(
      context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.2,
      desktop: desktop ?? mobile * 1.5,
    );
  }

  /// Get responsive padding
  static EdgeInsets padding(
    BuildContext context, {
    required EdgeInsets mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
  }) {
    return responsive<EdgeInsets>(
      context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.2,
      desktop: desktop ?? mobile * 1.5,
    );
  }

  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get safe area height (excludes system UI)
  static double safeHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom;
  }

  /// Get horizontal padding based on screen size
  static double horizontalPadding(BuildContext context) {
    final width = screenWidth(context);
    if (width < 360) return 16.0;
    if (width < 600) return 20.0;
    if (width < 1024) return 32.0;
    return 48.0;
  }

  /// Get vertical padding based on screen size
  static double verticalPadding(BuildContext context) {
    final height = screenHeight(context);
    if (height < 600) return 16.0;
    if (height < 800) return 24.0;
    return 32.0;
  }

  /// Clamp font size to prevent overflow
  static double clampFontSize(
    BuildContext context,
    double size, {
    double? min,
    double? max,
  }) {
    final width = screenWidth(context);
    final scaleFactor = width / 375; // Base on iPhone X width
    final scaledSize = size * scaleFactor;
    return scaledSize.clamp(min ?? size * 0.8, max ?? size * 1.3);
  }

  /// Get grid cross axis count based on screen width
  static int gridCrossAxisCount(BuildContext context, {int mobile = 2}) {
    final width = screenWidth(context);
    if (width >= 1200) return mobile * 3;
    if (width >= 900) return mobile * 2;
    if (width >= 600) return (mobile * 1.5).ceil();
    return mobile;
  }

  /// Get responsive container constraints
  static BoxConstraints containerConstraints(BuildContext context) {
    final width = screenWidth(context);
    if (width >= 1200) return const BoxConstraints(maxWidth: 1200);
    if (width >= 900) return const BoxConstraints(maxWidth: 900);
    if (width >= 600) return const BoxConstraints(maxWidth: 600);
    return BoxConstraints(maxWidth: width);
  }

  /// Get responsive card padding
  static EdgeInsets cardPadding(BuildContext context) {
    if (isSmallScreen(context)) return const EdgeInsets.all(12);
    if (isMobile(context)) return const EdgeInsets.all(16);
    if (isTablet(context)) return const EdgeInsets.all(20);
    return const EdgeInsets.all(24);
  }

  /// Get responsive icon size
  static double iconSize(BuildContext context, {double base = 24}) {
    if (isSmallScreen(context)) return base * 0.85;
    if (isMobile(context)) return base;
    if (isTablet(context)) return base * 1.2;
    return base * 1.4;
  }

  /// Get responsive border radius
  static double borderRadius(BuildContext context, {double base = 16}) {
    if (isSmallScreen(context)) return base * 0.85;
    if (isMobile(context)) return base;
    if (isTablet(context)) return base * 1.1;
    return base * 1.2;
  }
}
