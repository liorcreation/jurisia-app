import 'package:flutter/material.dart';

/// Porté par [AdminShell] à ses descendants : comment ouvrir la navigation
/// quand elle est un tiroir (mobile/tablette portrait) plutôt qu'un panneau
/// permanent (desktop). `null` en registre permanent — rien à ouvrir, la
/// sidebar est déjà visible. Fichier séparé de `admin_shell.dart` pour
/// éviter un cycle d'import : `AdminPageHeader` (utilisé par tous les
/// écrans) en a besoin, et `admin_shell.dart` importe justement tous ces
/// écrans.
class AdminShellScope extends InheritedWidget {
  const AdminShellScope({super.key, required this.openDrawer, required super.child});

  final VoidCallback? openDrawer;

  static VoidCallback? maybeOpenDrawer(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AdminShellScope>()?.openDrawer;
  }

  @override
  bool updateShouldNotify(AdminShellScope oldWidget) => openDrawer != oldWidget.openDrawer;
}
