import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand typography — Montserrat (display/headlines) + Inter (body/labels).
class BrandTypography {
  BrandTypography._();

  /// Display / headline text style (Montserrat, heavy weight).
  static TextStyle displayLg({Color? color}) =>
      GoogleFonts.montserrat(fontSize: 34, fontWeight: FontWeight.w800, height: 40 / 34, letterSpacing: -0.02, color: color);

  static TextStyle headlineMd({Color? color}) =>
      GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w700, height: 32 / 24, color: color);

  static TextStyle headlineSm({Color? color}) =>
      GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700, height: 28 / 20, color: color);

  /// Timer / urgency display (Montserrat 900, tabular numbers).
  static TextStyle timerXl({Color? color}) =>
      GoogleFonts.montserrat(fontSize: 48, fontWeight: FontWeight.w900, height: 48 / 48, color: color);

  /// Body text (Inter).
  static TextStyle bodyLg({Color? color}) =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, height: 24 / 16, color: color);

  static TextStyle bodyMd({Color? color}) =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, height: 20 / 14, color: color);

  /// Bold label (Inter 700, tracking-wide uppercased).
  static TextStyle labelBold({Color? color}) =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, height: 16 / 12, letterSpacing: 0.05, color: color);

  /// Full [TextTheme] for use in Material [ThemeData.textTheme].
  static TextTheme get textTheme => TextTheme(
        displayLarge: displayLg(),
        headlineMedium: headlineMd(),
        headlineSmall: headlineSm(),
        bodyLarge: bodyLg(),
        bodyMedium: bodyMd(),
        labelSmall: labelBold(),
      );
}
