import 'package:flutter/material.dart';

/// Registre de plateforme utilisé pour adapter la grammaire d'interaction
/// (navigation, action principale, présentation modale) sans jamais changer
/// la marque : couleurs, typographie et les quatre modules restent
/// identiques sur les trois registres — iOS, Android, Web/Desktop.
enum AppPlatformStyle {
  ios,
  android,
  desktop;

  /// Seuil du registre « desktop » (sidebar permanente, mises en page denses
  /// à deux colonnes conçues pour ≥ 1180 px).
  ///
  /// Fixé à **1000** pour que la grammaire desktop ne s'active qu'à partir
  /// d'une vraie grande surface : une tablette **en paysage** (iPad ~1080–1194)
  /// ou une fenêtre d'ordinateur. Tout le reste — téléphones (toutes
  /// orientations, jusqu'à ~956 px en paysage sur les grands modèles) et
  /// **tablettes en portrait** (iPad ~744–834) — reste sur le registre
  /// mobile/tablette : même corps premium, mais navigation par tiroir
  /// (bouton hamburger) et non par colonne fixe de 316 px, ce qui laisse aux
  /// contenus la largeur nécessaire pour se déployer (leurs `LayoutBuilder`
  /// internes passent alors à deux ou trois colonnes selon la place).
  static const double wideBreakpoint = 1000;

  static AppPlatformStyle of(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= wideBreakpoint) {
      return AppPlatformStyle.desktop;
    }
    return Theme.of(context).platform == TargetPlatform.iOS
        ? AppPlatformStyle.ios
        : AppPlatformStyle.android;
  }
}
