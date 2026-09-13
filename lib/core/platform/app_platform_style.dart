import 'package:flutter/material.dart';

/// Registre de plateforme utilisé pour adapter la grammaire d'interaction
/// (navigation, action principale, présentation modale) sans jamais changer
/// la marque : couleurs, typographie et les quatre modules restent
/// identiques sur les trois registres — iOS, Android, Web/Desktop.
enum AppPlatformStyle {
  ios,
  android,
  desktop;

  /// Seuil du registre « desktop » (sidebar complète, mises en page denses
  /// à deux colonnes conçues pour une vraie surface de travail).
  ///
  /// Les surfaces intermédiaires sont gérées par [AppViewportClass] : une
  /// tablette conserve un rail compact permanent, tandis qu'un téléphone
  /// conserve le tiroir afin de préserver l'espace de lecture.
  static const double wideBreakpoint = 1000;

  /// Registre de densité du shell, indépendant du système d'exploitation.
  ///
  /// Le mobile conserve le tiroir, la tablette affiche un rail permanent
  /// pour ne pas sacrifier la largeur utile au contenu, et le desktop expose
  /// la sidebar complète repliable.
  static AppViewportClass viewportOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= wideBreakpoint) return AppViewportClass.desktop;
    if (width >= 600) return AppViewportClass.tablet;
    return AppViewportClass.mobile;
  }

  static AppPlatformStyle of(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= wideBreakpoint) {
      return AppPlatformStyle.desktop;
    }
    return Theme.of(context).platform == TargetPlatform.iOS
        ? AppPlatformStyle.ios
        : AppPlatformStyle.android;
  }
}

enum AppViewportClass { mobile, tablet, desktop }
