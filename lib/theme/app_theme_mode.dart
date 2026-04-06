enum AppThemeMode {
  system,
  light,
  dark,
  midnight,
  amoled,
  warmLight,
  warmDark,
}

extension AppThemeModeLabel on AppThemeMode {
  String get label {
    switch (this) {
      case AppThemeMode.system:
        return 'System';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.midnight:
        return 'Midnight';
      case AppThemeMode.amoled:
        return 'AMOLED';
      case AppThemeMode.warmLight:
        return 'Warm Light';
      case AppThemeMode.warmDark:
        return 'Warm Dark';
    }
  }

  String get description {
    switch (this) {
      case AppThemeMode.system:
        return 'follows device setting';
      case AppThemeMode.light:
        return 'clean white background';
      case AppThemeMode.dark:
        return 'soft dark surfaces';
      case AppThemeMode.midnight:
        return 'deep navy, GitHub-style';
      case AppThemeMode.amoled:
        return 'pure black, saves battery';
      case AppThemeMode.warmLight:
        return 'warm cream, easy on the eyes';
      case AppThemeMode.warmDark:
        return 'warm dark, editorial feel';
    }
  }
}
