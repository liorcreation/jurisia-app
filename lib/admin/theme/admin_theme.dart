import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Thème de la console d'administration : identique au registre « verre fumé
/// & or brossé » de l'application, mais l'**accent passe du doré au cobalt**.
/// Un opérateur ne doit jamais confondre la console et la production d'un
/// coup d'œil.
class AdminTheme {
  const AdminTheme._();

  /// Accent de la console (le cobalt de la charte, promu en couleur primaire).
  static const Color accent = AppColors.cobalt;
  static const Color accentDark = Color(0xFF1B4FC0);
  static const Color accentLight = Color(0xFF6EA0FF);

  static ThemeData get dark {
    final base = AppTheme.darkTheme;
    final scheme = base.colorScheme.copyWith(
      primary: accent,
      onPrimary: AppColors.textPrimary,
      primaryContainer: accentDark,
      secondary: AppColors.gold,
      onSecondary: AppColors.nightBlueDeep,
    );

    return base.copyWith(
      colorScheme: scheme,
      primaryColor: accent,
      splashColor: accent.withValues(alpha: 0.10),
      highlightColor: accent.withValues(alpha: 0.06),
      hoverColor: accent.withValues(alpha: 0.05),
      appBarTheme: base.appBarTheme.copyWith(
        iconTheme: const IconThemeData(color: accentLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: AppColors.textPrimary,
          disabledBackgroundColor: accentDark.withValues(alpha: 0.3),
          disabledForegroundColor: AppColors.textDisabled,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: AppColors.legalBlueDark,
        circularTrackColor: AppColors.legalBlueDark,
      ),
    );
  }
}
