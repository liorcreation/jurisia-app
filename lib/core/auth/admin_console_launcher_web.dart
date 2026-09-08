import 'package:web/web.dart' as web;

import 'admin_handoff.dart';

/// Web : ouvre un onglet TOUT DE SUITE (synchrone dans le geste de tap),
/// avant tout aller-retour réseau, puis le redirige vers le lien
/// authentifié une fois obtenu. Un `window.open()` appelé après un
/// `await` — même un aller-retour réseau très rapide — perd le statut
/// « déclenché par l'utilisateur » aux yeux du navigateur et se fait
/// bloquer en silence par le bloqueur de pop-up ; ouvrir l'onglet en
/// premier, puis le faire naviguer via `location.replace`, contourne ce
/// piège tout en gardant la vraie destination dès qu'elle est connue.
Future<void> openAdminConsole() async {
  final tab = web.window.open('', '_blank');
  final link = await requestAdminHandoffLink();
  tab?.location.replace(link ?? kAdminConsoleUrl);
}
