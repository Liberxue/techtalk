import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/theme_cubit.dart';
import 'app_theme_mode.dart';

class AppColors {
  AppColors._();

  static AppColorScheme of(BuildContext context) {
    try {
      // watch (not read) so widgets rebuild when theme changes
      final cubit = context.watch<ThemeCubit>();
      final mode = cubit.state.appThemeMode;
      final brightness = MediaQuery.platformBrightnessOf(context);

      switch (mode) {
        case AppThemeMode.light:
          return const AppColorScheme.light();
        case AppThemeMode.dark:
          return const AppColorScheme.dark();
        case AppThemeMode.midnight:
          return const AppColorScheme.midnight();
        case AppThemeMode.amoled:
          return const AppColorScheme.amoled();
        case AppThemeMode.warmLight:
          return const AppColorScheme.warmLight();
        case AppThemeMode.warmDark:
          return const AppColorScheme.warmDark();
        case AppThemeMode.system:
          return brightness == Brightness.dark
              ? const AppColorScheme.dark()
              : const AppColorScheme.light();
      }
    } catch (_) {
      // Fallback for contexts without cubit (e.g. tests)
      return Theme.of(context).brightness == Brightness.dark
          ? const AppColorScheme.dark()
          : const AppColorScheme.light();
    }
  }
}

class AppColorScheme {
  final Color background;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color success;
  final Color error;
  final Color amber;

  const AppColorScheme.light()
      : background = const Color(0xFFFFFFFF),
        surface = const Color(0xFFF7F7F5),
        border = const Color(0xFFE8E8E5),
        textPrimary = const Color(0xFF0A0A0A),
        textSecondary = const Color(0xFF6B6B6B),
        textMuted = const Color(0xFFABABAB),
        accent = const Color(0xFF0066FF),
        success = const Color(0xFF00875A),
        error = const Color(0xFFD93025),
        amber = const Color(0xFFD97706);

  const AppColorScheme.dark()
      : background = const Color(0xFF0A0A0A),
        surface = const Color(0xFF141414),
        border = const Color(0xFF1F1F1F),
        textPrimary = const Color(0xFFF5F5F5),
        textSecondary = const Color(0xFF888888),
        textMuted = const Color(0xFF444444),
        accent = const Color(0xFF4D8FFF),
        success = const Color(0xFF00C48C),
        error = const Color(0xFFFF5A5F),
        amber = const Color(0xFFF5A623);

  const AppColorScheme.midnight()
      : background = const Color(0xFF0D1117),
        surface = const Color(0xFF161B22),
        border = const Color(0xFF21262D),
        textPrimary = const Color(0xFFE6EDF3),
        textSecondary = const Color(0xFF8B949E),
        textMuted = const Color(0xFF484F58),
        accent = const Color(0xFF58A6FF),
        success = const Color(0xFF3FB950),
        error = const Color(0xFFF85149),
        amber = const Color(0xFFD29922);

  const AppColorScheme.amoled()
      : background = const Color(0xFF000000),
        surface = const Color(0xFF0A0A0A),
        border = const Color(0xFF1A1A1A),
        textPrimary = const Color(0xFFFFFFFF),
        textSecondary = const Color(0xFF999999),
        textMuted = const Color(0xFF333333),
        accent = const Color(0xFF4D8FFF),
        success = const Color(0xFF00C48C),
        error = const Color(0xFFFF5A5F),
        amber = const Color(0xFFF5A623);

  const AppColorScheme.warmLight()
      : background = const Color(0xFFF8F5F0),
        surface = const Color(0xFFEDE8E0),
        border = const Color(0xFFD8D2C8),
        textPrimary = const Color(0xFF1A1A1A),
        textSecondary = const Color(0xFF6B6358),
        textMuted = const Color(0xFFA89F94),
        accent = const Color(0xFF3D6B4F),
        success = const Color(0xFF3D6B4F),
        error = const Color(0xFFC45544),
        amber = const Color(0xFFC49234);

  const AppColorScheme.warmDark()
      : background = const Color(0xFF1C1A17),
        surface = const Color(0xFF262320),
        border = const Color(0xFF3A3632),
        textPrimary = const Color(0xFFEDE8E0),
        textSecondary = const Color(0xFF9B9288),
        textMuted = const Color(0xFF5A5550),
        accent = const Color(0xFF5B9A6F),
        success = const Color(0xFF5B9A6F),
        error = const Color(0xFFE06B5A),
        amber = const Color(0xFFD4A244);
}
