import 'package:flutter/material.dart';

/// Une destination de la navigation principale de JurisIA. Partagée entre la
/// sidebar unifiée ([JurisIASidebar]) et la palette de commandes desktop.
class NavDestination {
  const NavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screenTitle,
  });

  /// Libellé court affiché dans la sidebar.
  final String label;

  final IconData icon;
  final IconData selectedIcon;

  /// Titre complet de l'écran correspondant (barre de titre).
  final String screenTitle;
}

/// Les cinq espaces de JurisIA, dans l'ordre de l'`IndexedStack` de
/// [AppShell] : Litiges et consultations, Bibliothèque juridique, Espace
/// étudiant, Espace professionnel, Contacter un professionnel.
const List<NavDestination> kNavDestinations = [
  NavDestination(
    label: 'Litiges',
    icon: Icons.forum_outlined,
    selectedIcon: Icons.forum_rounded,
    screenTitle: 'Litiges et consultations',
  ),
  NavDestination(
    label: 'Bibliothèque',
    icon: Icons.local_library_outlined,
    selectedIcon: Icons.local_library_rounded,
    screenTitle: 'Bibliothèque juridique',
  ),
  NavDestination(
    label: 'Étudiant',
    icon: Icons.school_outlined,
    selectedIcon: Icons.school_rounded,
    screenTitle: 'Espace étudiant',
  ),
  NavDestination(
    label: 'Professionnel',
    icon: Icons.workspace_premium_outlined,
    selectedIcon: Icons.workspace_premium_rounded,
    screenTitle: 'Espace professionnel',
  ),
  NavDestination(
    label: 'Contacter',
    icon: Icons.support_agent_outlined,
    selectedIcon: Icons.support_agent_rounded,
    screenTitle: 'Contacter un professionnel',
  ),
];
