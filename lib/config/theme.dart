import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Paleta de alta moda editorial unificada
  static const Color primaryColor = Color(0xFF0F172A); // Obsidian / Negro profundo de alta gama
  static const Color primaryDark = Color(0xFF020617);
  static const Color accentIndigo = Color(0xFF4F46E5); // Acento índigo tecnológico (IA)
  static const Color accentBlue = Color(0xFF2563EB);   // Azul denim y categorías
  static const Color accentCyan = Color(0xFF0EA5E9);   // Destellos de curaduría
  static const Color luxuryWarm = Color(0xFF6B3019);   // Cuero cálido / atelier
  static const Color secondaryColor = Color(0xFF10B981); // Verde esmeralda éxito
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color errorColor = Color(0xFFEF4444);

  // Tipografías de Alta Costura
  static TextStyle get logoStyle => GoogleFonts.playfairDisplay(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        letterSpacing: 4.0,
        color: textPrimary,
      );

  static TextStyle get atelierSubStyle => GoogleFonts.plusJakartaSans(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 3.5,
        color: textSecondary,
      );

  static TextStyle get serifHeading => GoogleFonts.playfairDisplay(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: textPrimary,
      );

  static TextStyle get serifSubheading => GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get productTitle => GoogleFonts.playfairDisplay(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get bodySans => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: textSecondary,
      );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentIndigo,
        surface: backgroundColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: logoStyle,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w500,
          fontSize: 10,
        ),
      ),
    );
  }
}
