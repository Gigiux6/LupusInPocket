import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Existing colors...
  static const Color primaryColor = Color(0xFFFF007F); 
  static const Color cyanColor = Color(0xFF00FFFF); 
  static const Color yellowColor = Color(0xFFEBFF00); 
  static const Color secondaryColor = yellowColor; 
  static const Color backgroundColor = Color(0xFF0A0F24); 
  static const Color surfaceColor = Color(0xFF151B38);

  // --- NEW MEDIEVAL THEMES ---
  static const Color leatherBrown = Color(0xFF3D261C);
  static const Color goldBorder = Color(0xFFA67C00);
  
  // DAY
  static const Color dayBg = Color(0xFFE6D5B8); // Parchment
  static const Color dayText = Color(0xFF3E2723); // Burnt Brown
  static const Color dayAccent = Color(0xFFD84315); // Burnt Orange
  static const Color daySurface = Color(0xFFF5E6D3);

  // NIGHT
  static const Color nightBg = Color(0xFF0F141A); // Ebony/Midnight
  static const Color nightText = Color(0xFFE0E0E0); // Lunar Silver
  static const Color nightAccent = Color(0xFF5E35B1); // Deep Purple
  static const Color nightSurface = Color(0xFF1C252E);
  static const Color candleGlow = Color(0xFFFF9800); // Orange Glow
  static const Color textSecondary = Colors.white70;

  static ThemeData getTheme() {
    final Brightness brightness = Brightness.light;
    final Color bg = dayBg;
    final Color surface = daySurface;
    final Color text = dayText;

    return ThemeData(
      brightness: brightness,
      primaryColor: leatherBrown,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: leatherBrown,
        onPrimary: Colors.white,
        secondary: dayAccent,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: text,
        error: Colors.red,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.almendraTextTheme(
        ThemeData.light().textTheme
      ).copyWith(
        displayLarge: GoogleFonts.medievalSharp(
          fontSize: 48,
          color: dayText,
          letterSpacing: 2,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: GoogleFonts.medievalSharp(
          fontSize: 32,
          color: dayText,
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: GoogleFonts.medievalSharp(
          fontSize: 24,
          color: text,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: const TextStyle(
          fontSize: 18,
          color: dayText,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: dayText, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: dayText, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: dayAccent, width: 3),
        ),
        labelStyle: const TextStyle(color: Colors.black54),
      ),
      cardTheme: CardThemeData(
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: dayText, width: 2),
        ),
        elevation: 4,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: leatherBrown,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dayBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: goldBorder, width: 3),
        ),
      ),
    );
  }
}

class GamePhaseTheme {
  final Color bg;
  final Color surface;
  final Color text;
  final Color accent;
  final Color borderColor;
  final bool isNight;

  GamePhaseTheme({
    required this.bg,
    required this.surface,
    required this.text,
    required this.accent,
    required this.borderColor,
    required this.isNight,
  });

  static GamePhaseTheme get(bool isNight) {
    if (isNight) {
      return GamePhaseTheme(
        bg: AppTheme.nightBg,
        surface: AppTheme.nightSurface,
        text: AppTheme.nightText,
        accent: AppTheme.nightAccent,
        borderColor: AppTheme.nightText.withOpacity(0.5),
        isNight: true,
      );
    } else {
      return GamePhaseTheme(
        bg: AppTheme.dayBg,
        surface: AppTheme.daySurface,
        text: AppTheme.dayText,
        accent: AppTheme.dayAccent,
        borderColor: AppTheme.dayText.withOpacity(0.6),
        isNight: false,
      );
    }
  }
}

