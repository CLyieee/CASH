import 'package:flutter/material.dart';

/// Lightweight text style helper to replace GoogleFonts usage without
/// bringing in additional platform plugins.
class AppText {
  static TextStyle poppins({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? height,
    List<Shadow>? shadows,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      // No custom font-family to avoid asset setup; uses platform default
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      height: height,
      shadows: shadows,
      decoration: decoration,
    );
  }
}
