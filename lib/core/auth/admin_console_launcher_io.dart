import 'package:url_launcher/url_launcher.dart';

import 'admin_handoff.dart';

/// Natif (mobile, desktop) : ouvre le navigateur système. Aucune contrainte
/// de bloqueur de pop-up ici — un aller-retour réseau avant l'ouverture ne
/// pose pas de problème.
Future<void> openAdminConsole() async {
  final link = await requestAdminHandoffLink();
  await launchUrl(Uri.parse(link ?? kAdminConsoleUrl), mode: LaunchMode.externalApplication);
}
