/// Ouvre la console d'administration, déjà authentifié si possible (voir
/// `admin_handoff.dart`). Deux implémentations : le web doit ouvrir l'onglet
/// de façon synchrone (avant tout aller-retour réseau) pour échapper au
/// bloqueur de pop-up des navigateurs — voir `admin_console_launcher_web
/// .dart` pour le détail. Le natif (mobile, desktop) n'a pas cette
/// contrainte — voir `admin_console_launcher_io.dart`.
library;

export 'admin_console_launcher_io.dart'
    if (dart.library.html) 'admin_console_launcher_web.dart';
