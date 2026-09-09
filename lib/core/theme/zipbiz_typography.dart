import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'zipbiz_colors.dart';

/// ZipBiz Typography Hierarchy matching Vibrant Service Nexus Design System
class ZipBizTypography {
  // Display Typography (Hanken Grotesk)
  static TextStyle displayLarge = GoogleFonts.hankenGrotesk(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 56 / 48,
    letterSpacing: -0.02 * 48,
    color: ZipBizColors.onSurface,
  );

  // Headlines (Hanken Grotesk)
  static TextStyle headlineLarge = GoogleFonts.hankenGrotesk(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 40 / 32,
    color: ZipBizColors.onSurface,
  );

  static TextStyle headlineLargeMobile = GoogleFonts.hankenGrotesk(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 36 / 28,
    color: ZipBizColors.onSurface,
  );

  static TextStyle headlineMedium = GoogleFonts.hankenGrotesk(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
    color: ZipBizColors.onSurface,
  );

  static TextStyle headlineSmall = GoogleFonts.hankenGrotesk(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
    color: ZipBizColors.onSurface,
  );

  // Body Typography (Work Sans)
  static TextStyle bodyLarge = GoogleFonts.workSans(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 28 / 18,
    color: ZipBizColors.onSurface,
  );

  static TextStyle bodyMedium = GoogleFonts.workSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    color: ZipBizColors.onSurface,
  );

  static TextStyle bodySmall = GoogleFonts.workSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: ZipBizColors.onSurfaceVariant,
  );

  // Labels & Buttons (Work Sans)
  static TextStyle labelLarge = GoogleFonts.workSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    letterSpacing: 0.05 * 14,
    color: ZipBizColors.onSurface,
  );

  static TextStyle labelMedium = GoogleFonts.workSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    color: ZipBizColors.onSurfaceVariant,
  );

  static TextStyle labelSmall = GoogleFonts.workSans(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 14 / 10,
    color: ZipBizColors.onSurfaceVariant,
  );
}
