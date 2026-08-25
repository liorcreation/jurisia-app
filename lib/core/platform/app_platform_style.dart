import 'package:flutter/material.dart';

/// Registre de plateforme utilisé pour adapter la grammaire d'interaction
/// (navigation, action principale, présentation modale) sans jamais changer
/// la marque : couleurs, typographie et les quatre modules restent
/// identiques sur les trois registres — iOS, Android, Web/Desktop.
enum AppPlatformStyle {
  ios,
  android,
  desktop;

  static const double wideBreakpoint = 800;

  static AppPlatformStyle of(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= wideBreakpoint) {
      return AppPlatformStyle.desktop;
    }
    return Theme.of(context).platform == TargetPlatform.iOS
        ? AppPlatformStyle.ios
        : AppPlatformStyle.android;
  }
}
