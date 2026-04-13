import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../services/user_service.dart';

class AppTheme {
  static bool get isFemale =>
      Get.isRegistered<UserService>() &&
      Get.find<UserService>().targetGender.value == 'female';

  // ─── DYNAMIC PALETTE ───
  static Color get primary => isFemale ? Color(0xFFD63384) : Color(0xFFD4A853);
  static Color get primaryDark =>
      isFemale ? Color(0xFFB82871) : Color(0xFFB8912E);
  static Color get primaryLight =>
      isFemale ? Color(0xFFF78FB3) : Color(0xFFE8C97A);
  static Color get accent => isFemale ? Color(0xFFFFB8D2) : Color(0xFFC9963C);

  static Color get background =>
      isFemale ? Color(0xFFFFF0F5) : Color(0xFFF8F5F0);
  static Color get surface => Color(0xFFFFFFFF);
  static Color get card => Color(0xFFFFFFFF);

  static Color get darkBg => isFemale ? Color(0xFF2C1320) : Color(0xFF1A1A2E);
  static Color get darkCard => isFemale ? Color(0xFF422132) : Color(0xFF232340);

  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textMedium = Color(0xFF6B7280);
  static const Color textLight = Color(0xFFA0AEC0);

  static Color get gold => isFemale ? Color(0xFFD63384) : Color(0xFFD4A853);
  static const Color success = Color(0xFF22C55E);
  static const Color danger = Color(0xFFEF4444);

  // Gradients
  static LinearGradient get goldGradient => LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get darkGradient => LinearGradient(
    colors: [darkBg, isFemale ? Color(0xFF2A111E) : Color(0xFF16213E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient get premiumGradient => LinearGradient(
    colors: [darkBg, darkCard, darkBg],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get luxuryTheme => ThemeData(
    scaffoldBackgroundColor: background,
    primaryColor: primary,
    colorScheme: ColorScheme.light(
      primary: primary,
      surface: surface,
      onPrimary: Colors.white,
      onSurface: textDark,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme)
        .copyWith(
          displayLarge: GoogleFonts.playfairDisplay(
            color: textDark,
            fontWeight: FontWeight.w800,
            fontSize: 32,
          ),
          headlineMedium: GoogleFonts.playfairDisplay(
            color: textDark,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
          titleLarge: GoogleFonts.poppins(
            color: textDark,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
          titleMedium: GoogleFonts.poppins(
            color: textDark,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          bodyLarge: GoogleFonts.poppins(color: textDark, fontSize: 16),
          bodyMedium: GoogleFonts.poppins(color: textMedium, fontSize: 14),
        ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: textDark),
    ),
    cardTheme: CardThemeData(
      color: card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
    ),
  );
}
