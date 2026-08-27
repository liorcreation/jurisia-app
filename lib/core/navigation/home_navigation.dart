import 'package:flutter/material.dart';

import '../shell/app_shell.dart';

/// Coquille de navigation principale de JurisIA. Historiquement une barre
/// inférieure (mobile) + rail latéral (desktop) ; désormais une **sidebar
/// unifiée** identique sur toutes les plateformes — voir [AppShell]. Ce
/// wrapper est conservé pour le point d'entrée [AuthGate] et les tests
/// existants.
class HomeNavigation extends StatelessWidget {
  const HomeNavigation({super.key});

  @override
  Widget build(BuildContext context) => const AppShell();
}
