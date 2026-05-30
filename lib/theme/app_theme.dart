import 'package:flutter/material.dart';

// Backward-compat alias — existing files import AppColors.*
// Values are kept in sync with AppTheme tokens below.
class AppColors {
  static const primary       = AppTheme.primary;
  static const primaryDark   = AppTheme.primaryDark;
  static const primarySoft   = AppTheme.primaryLight;
  static const background    = AppTheme.bgPage;
  static const surfaceSoft   = Color(0xFFF0F4F1);
  static const textMain      = AppTheme.textPrimary;
  static const textSecondary = AppTheme.textSecondary;
  static const border        = AppTheme.borderLight;
  static const safe          = AppTheme.riskNone;
  static const moderate      = AppTheme.riskMedium;
  static const high          = AppTheme.riskHigh;
  static const extreme       = AppTheme.riskExtreme;
  static const water         = AppTheme.markerBlue;
  static const nasa          = Color(0xFF378ADD);
}

class AppTheme {
  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const Color bgPage       = Color(0xFFF4F6F4);
  static const Color bgCard       = Color(0xFFFFFFFF);
  static const Color bgHero       = Color(0xFF0D1F1A);
  static const Color bgDark       = Color(0xFF0D1620);
  static const Color bgDarkAlt    = Color(0xFF111E1A);

  // ── Brand ─────────────────────────────────────────────────────────────────
  static const Color primary      = Color(0xFF1D9E75);
  static const Color primaryLight = Color(0xFFE1F5EE);
  static const Color primaryDark  = Color(0xFF0F6E56);

  // ── Heat risk ─────────────────────────────────────────────────────────────
  static const Color riskExtreme  = Color(0xFFE24B4A);
  static const Color riskHigh     = Color(0xFFE24B4A);
  static const Color riskMedium   = Color(0xFFEF9F27);
  static const Color riskLow      = Color(0xFF1D9E75);
  static const Color riskNone     = Color(0xFF639922);

  // ── Risk badge backgrounds ────────────────────────────────────────────────
  static const Color riskExtremeBg = Color(0xFFFCEBEB);
  static const Color riskMediumBg  = Color(0xFFFAEEDA);
  static const Color riskLowBg     = Color(0xFFEAF3DE);

  // ── Risk badge text (dark, accessible on light bg) ────────────────────────
  static const Color riskExtremeText = Color(0xFFA32D2D);
  static const Color riskMediumText  = Color(0xFF854F0B);
  static const Color riskLowText     = Color(0xFF3B6D11);

  // ── Markers ───────────────────────────────────────────────────────────────
  static const Color markerRed    = Color(0xFFE24B4A);
  static const Color markerOrange = Color(0xFFEF9F27);
  static const Color markerGreen  = Color(0xFF1D9E75);
  static const Color markerBlue   = Color(0xFF378ADD);
  static const Color markerTree   = Color(0xFF639922);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFF1A2E1F);
  static const Color textSecondary  = Color(0xFF5A7060);
  static const Color textHint       = Color(0xFF8FA896);
  static const Color textOnDark     = Color(0xFFFFFFFF);
  static const Color textOnDarkMid  = Color(0x99FFFFFF);
  static const Color textOnDarkDim  = Color(0x66FFFFFF);

  // ── Borders ───────────────────────────────────────────────────────────────
  static const Color borderLight  = Color(0xFFE0E8E2);
  static const Color borderMid    = Color(0xFFC8D5CC);

  // ── Map ───────────────────────────────────────────────────────────────────
  static const Color mapBg        = Color(0xFFE8F0EC);

  // ── Overlays ──────────────────────────────────────────────────────────────
  static const Color statBoxOnDark  = Color(0x12FFFFFF); // rgba(255,255,255,0.07)
  static const Color chipBgOnDark   = Color(0x14FFFFFF); // rgba(255,255,255,0.08)

  // ── Spot type icon backgrounds ────────────────────────────────────────────
  static const Color spotBgBlue = Color(0xFFE6F1FB); // air-conditioned + water

  // ── Status ────────────────────────────────────────────────────────────────
  static const Color statusOpen      = Color(0xFF1D9E75);
  static const Color statusOpenBg    = Color(0xFFE1F5EE);
  static const Color statusClosed    = Color(0xFFE24B4A);
  static const Color statusClosedBg  = Color(0xFFFCEBEB);

  // ── Spacing (8px base grid) ────────────────────────────────────────────────
  static const double spaceXS  = 4.0;
  static const double spaceSM  = 8.0;
  static const double spaceMD  = 16.0;
  static const double spaceLG  = 24.0;
  static const double spaceXL  = 32.0;

  // ── Radii ─────────────────────────────────────────────────────────────────
  static const double radiusSM   = 6.0;
  static const double radiusMD   = 10.0;
  static const double radiusLG   = 14.0;
  static const double radiusPill = 20.0;

  // ── ThemeData ─────────────────────────────────────────────────────────────
  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: textOnDark,
      primaryContainer: primaryLight,
      onPrimaryContainer: primaryDark,
      secondary: primaryDark,
      onSecondary: textOnDark,
      secondaryContainer: primaryLight,
      onSecondaryContainer: primaryDark,
      error: riskExtreme,
      onError: textOnDark,
      surface: bgCard,
      onSurface: textPrimary,
      surfaceContainerHighest: bgPage,
      outline: borderLight,
      outlineVariant: borderMid,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bgPage,
      fontFamily: 'Roboto',

      textTheme: const TextTheme(
        // Display — temperature, large numbers
        displayLarge:  TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: textPrimary),
        displayMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: textPrimary),
        // Headings
        headlineLarge:  TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textPrimary),
        headlineMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
        // Body
        bodyLarge:  TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: textPrimary,   height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary, height: 1.5),
        bodySmall:  TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: textSecondary, height: 1.5),
        // Labels
        labelLarge:  TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textPrimary),
        labelSmall:  TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textSecondary, letterSpacing: 0.3),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: bgCard,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),

      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
          side: const BorderSide(color: borderLight, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgCard,
        hintStyle: const TextStyle(color: textHint, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: borderLight, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: borderLight, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: primary, width: 1.0),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textOnDark,
          minimumSize: const Size(64, 46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMD)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(64, 38),
          side: const BorderSide(color: primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMD)),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          elevation: 0,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        elevation: 0,
        backgroundColor: bgCard,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primaryLight,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? primary : textHint,
            size: 22,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: states.contains(WidgetState.selected) ? primary : textHint,
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: bgCard,
        selectedColor: primary,
        disabledColor: bgPage,
        side: const BorderSide(color: borderLight, width: 0.5),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPill)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      ),

      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 0.5,
        space: 0,
      ),
    );
  }
}
