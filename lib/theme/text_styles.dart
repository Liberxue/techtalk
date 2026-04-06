import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle _base(double size, FontWeight weight, Color color) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.5,
    );
  }

  static TextStyle display(Color color) =>
      _base(48, FontWeight.w400, color);

  static TextStyle headline(Color color) =>
      _base(24, FontWeight.w400, color);

  static TextStyle body(Color color) =>
      _base(18, FontWeight.w400, color).copyWith(letterSpacing: 0.3);

  static TextStyle bodyMedium(Color color) =>
      _base(18, FontWeight.w500, color).copyWith(letterSpacing: 0.3);

  static TextStyle label(Color color) =>
      _base(15, FontWeight.w400, color);

  static TextStyle labelMedium(Color color) =>
      _base(15, FontWeight.w500, color);

  static TextStyle caption(Color color) =>
      _base(13, FontWeight.w400, color);

  static TextStyle captionMedium(Color color) =>
      _base(13, FontWeight.w500, color);

  static TextStyle micro(Color color) =>
      _base(11, FontWeight.w400, color).copyWith(letterSpacing: 1.2);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() =>
      _buildTheme(const AppColorScheme.light(), Brightness.light);

  static ThemeData dark() =>
      _buildTheme(const AppColorScheme.dark(), Brightness.dark);

  static ThemeData midnight() =>
      _buildTheme(const AppColorScheme.midnight(), Brightness.dark);

  static ThemeData amoled() =>
      _buildTheme(const AppColorScheme.amoled(), Brightness.dark);

  static ThemeData warmLight() =>
      _buildTheme(const AppColorScheme.warmLight(), Brightness.light);

  static ThemeData warmDark() =>
      _buildTheme(const AppColorScheme.warmDark(), Brightness.dark);

  static ThemeData _buildTheme(AppColorScheme colors, Brightness brightness) {
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.accent,
        onPrimary: brightness == Brightness.light
            ? const Color(0xFFFFFFFF)
            : const Color(0xFF0A0A0A),
        secondary: colors.textSecondary,
        onSecondary: colors.textPrimary,
        error: colors.error,
        onError: const Color(0xFFFFFFFF),
        surface: colors.surface,
        onSurface: colors.textPrimary,
      ),
      dividerColor: colors.border,
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 0.5,
        space: 0,
      ),
      textTheme: GoogleFonts.jetBrainsMonoTextTheme().apply(
        bodyColor: colors.textPrimary,
        displayColor: colors.textPrimary,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
}
