import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/theme_cubit.dart';
import '../theme/app_theme_mode.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: padding.top + 16,
              left: 24,
              right: 24,
              bottom: 16,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Settings',
                style: AppTextStyles.body(colors.textPrimary),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(bottom: padding.bottom + 80),
              children: [
                _sectionLabel('APPEARANCE', colors),
                _themeRow(context, colors),
                _divider(colors),
                _sectionLabel('PRACTICE', colors),
                _row('DEFAULT LANG', 'English', colors),
                _divider(colors),
                _row('SPEECH RATE', 'natural', colors),
                _divider(colors),
                _sectionLabel('ABOUT', colors),
                _row('VERSION', '1.0.0', colors),
                _divider(colors),
                _row('BUILD', '1', colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, AppColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 8),
      child: Text(
        label,
        style: AppTextStyles.micro(colors.textMuted),
      ),
    );
  }

  Widget _themeRow(BuildContext context, AppColorScheme colors) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showThemePicker(context, colors),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Text(
                  'THEME',
                  style: AppTextStyles.caption(colors.textMuted)
                      .copyWith(letterSpacing: 1.0),
                ),
                const Spacer(),
                Text(
                  state.appThemeMode.label,
                  style: AppTextStyles.label(colors.textPrimary),
                ),
                const SizedBox(width: 8),
                Text('→', style: AppTextStyles.caption(colors.textMuted)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showThemePicker(BuildContext context, AppColorScheme colors) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) {
        return BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, state) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 24, bottom: 16),
                      child: Text(
                        'THEME',
                        style: AppTextStyles.micro(colors.textMuted),
                      ),
                    ),
                  ...AppThemeMode.values.map((mode) {
                    final isActive = state.appThemeMode == mode;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.read<ThemeCubit>().setTheme(mode);
                        Navigator.pop(sheetContext);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        color: isActive
                            ? colors.surface
                            : Colors.transparent,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mode.label,
                                    style: AppTextStyles.label(
                                      isActive
                                          ? colors.accent
                                          : colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    mode.description,
                                    style: AppTextStyles.caption(
                                        colors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            if (isActive)
                              Text(
                                '✓',
                                style:
                                    AppTextStyles.label(colors.accent),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _row(String label, String value, AppColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.caption(colors.textMuted)
                .copyWith(letterSpacing: 1.0),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.label(colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _divider(AppColorScheme colors) {
    return Divider(
      height: 0.5,
      indent: 24,
      endIndent: 24,
      color: colors.border,
    );
  }
}
