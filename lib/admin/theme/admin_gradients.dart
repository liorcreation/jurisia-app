import 'package:flutter/material.dart';

import 'admin_theme.dart';

/// Dégradés et ombres « cobalt brossé » de la console — le pendant, côté
/// admin, des dégradés `AppGradients.gold*` de l'application grand public.
/// Même grammaire (bandes multiples simulant un métal brossé, halo doux),
/// teinte cobalt pour qu'un opérateur ne confonde jamais un écran de la
/// console avec la production.
class AdminGradients {
  const AdminGradients._();

  static const LinearGradient cobaltMetallic = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AdminTheme.accentLight,
      AdminTheme.accent,
      AdminTheme.accentDark,
      AdminTheme.accent,
      AdminTheme.accentLight,
    ],
    stops: [0.0, 0.3, 0.55, 0.78, 1.0],
  );

  static const LinearGradient cobaltSheen = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AdminTheme.accentDark, AdminTheme.accentLight, AdminTheme.accentDark],
  );

  static const LinearGradient cobaltGlass = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x402E6FF2), Color(0x1A0F2C4E)],
  );

  static List<BoxShadow> get cobaltGlow => [
        BoxShadow(color: AdminTheme.accent.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 6)),
      ];

  static List<BoxShadow> get cobaltGlowSoft => [
        BoxShadow(color: AdminTheme.accent.withValues(alpha: 0.45), blurRadius: 14, offset: Offset.zero),
      ];
}
