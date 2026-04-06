import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/app_theme_mode.dart';
import '../theme/text_styles.dart';

class ThemeState {
  final AppThemeMode appThemeMode;
  final ThemeData theme;
  final ThemeData? darkTheme;
  final ThemeMode flutterThemeMode;

  const ThemeState({
    required this.appThemeMode,
    required this.theme,
    this.darkTheme,
    required this.flutterThemeMode,
  });
}

class ThemeCubit extends Cubit<ThemeState> {
  static const _boxName = 'settings';
  static const _key = 'theme_mode';

  ThemeCubit() : super(_resolve(AppThemeMode.warmLight)) {
    _load();
  }

  Future<void> _load() async {
    try {
      final box = Hive.box(_boxName);
      final name = box.get(_key, defaultValue: 'warmLight') as String;

      // Migration: if user was on an old cold theme before warm themes existed,
      // switch them to warmLight. Only warm/system themes are preserved.
      final migrated = box.get('_theme_migrated_v2', defaultValue: false);
      if (migrated != true) {
        await box.put('_theme_migrated_v2', true);
        if (name == 'light' || name == 'dark' || name == 'system' ||
            name == 'midnight' || name == 'amoled') {
          await box.put(_key, 'warmLight');
          emit(_resolve(AppThemeMode.warmLight));
          return;
        }
      }

      final mode = AppThemeMode.values.firstWhere(
        (m) => m.name == name,
        orElse: () => AppThemeMode.warmLight,
      );
      emit(_resolve(mode));
    } catch (_) {
      // Box not available, use default
    }
  }

  Future<void> setTheme(AppThemeMode mode) async {
    emit(_resolve(mode));
    try {
      final box = Hive.box(_boxName);
      await box.put(_key, mode.name);
    } catch (_) {
      // Persist failed, theme still applied in memory
    }
  }

  static ThemeState _resolve(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return ThemeState(
          appThemeMode: mode,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          flutterThemeMode: ThemeMode.system,
        );
      case AppThemeMode.light:
        return ThemeState(
          appThemeMode: mode,
          theme: AppTheme.light(),
          flutterThemeMode: ThemeMode.light,
        );
      case AppThemeMode.dark:
        return ThemeState(
          appThemeMode: mode,
          theme: AppTheme.dark(),
          flutterThemeMode: ThemeMode.dark,
        );
      case AppThemeMode.midnight:
        return ThemeState(
          appThemeMode: mode,
          theme: AppTheme.midnight(),
          flutterThemeMode: ThemeMode.dark,
        );
      case AppThemeMode.amoled:
        return ThemeState(
          appThemeMode: mode,
          theme: AppTheme.amoled(),
          flutterThemeMode: ThemeMode.dark,
        );
      case AppThemeMode.warmLight:
        return ThemeState(
          appThemeMode: mode,
          theme: AppTheme.warmLight(),
          flutterThemeMode: ThemeMode.light,
        );
      case AppThemeMode.warmDark:
        return ThemeState(
          appThemeMode: mode,
          theme: AppTheme.warmDark(),
          flutterThemeMode: ThemeMode.dark,
        );
    }
  }
}
