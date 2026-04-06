import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

class LanguageSelector extends StatelessWidget {
  final String selected;
  final List<String> languages;
  final ValueChanged<String> onChanged;

  const LanguageSelector({
    super.key,
    required this.selected,
    required this.languages,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: languages.map((lang) {
        final isActive = lang == selected;
        return GestureDetector(
          onTap: () => onChanged(lang),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              lang,
              style: isActive
                  ? AppTextStyles.labelMedium(colors.textPrimary)
                  : AppTextStyles.label(colors.textMuted),
            ),
          ),
        );
      }).toList(),
    );
  }
}
