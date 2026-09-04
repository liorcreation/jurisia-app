import 'package:sentry_flutter/sentry_flutter.dart';

/// Suivi des erreurs en production (Sentry), avec repli gracieux : sans
/// DSN fourni, l'app tourne exactement comme avant — aucun SDK ne
/// s'initialise, aucun appel réseau superflu. Le DSN d'un projet Sentry
/// n'est pas un secret à protéger comme une clé d'API (il ne permet que
/// d'ENVOYER des événements, jamais de les lire) ; il peut être fourni au
/// build sans précaution particulière :
///
/// ```
/// flutter build web --release --dart-define=SENTRY_DSN=https://...@o0.ingest.sentry.io/0
/// ```
///
/// Créer un projet Sentry (offre gratuite, ~5 000 événements/mois) sur
/// https://sentry.io, puis coller son DSN ci-dessus — Projet Flutter,
/// une plateforme "Flutter".
class CrashReporting {
  const CrashReporting._();

  static const String _dsn = String.fromEnvironment('SENTRY_DSN');

  static bool get isConfigured => _dsn.isNotEmpty;

  /// Lance [appRunner] (typiquement `() => runApp(const MyApp())`) sous
  /// Sentry si un DSN est configuré, sinon l'exécute tel quel — jamais de
  /// branche séparée à maintenir côté appelant.
  static Future<void> runGuarded(
    Future<void> Function() appRunner, {
    String environment = 'production',
  }) async {
    if (!isConfigured) {
      await appRunner();
      return;
    }

    await SentryFlutter.init((options) {
      options.dsn = _dsn;
      options.environment = environment;
      // Le contenu des consultations/documents est sensible : jamais de
      // "breadcrumb" HTTP automatique (corps de requête compris) ni de
      // capture d'écran/session replay — seules les erreurs et leur pile
      // d'appels sont remontées.
      options.sendDefaultPii = false;
      options.attachScreenshot = false;
      options.enableUserInteractionBreadcrumbs = false;
      // Un peu de traçage des performances, sans suréchantillonner un
      // projet en phase de lancement.
      options.tracesSampleRate = 0.2;
    }, appRunner: appRunner);
  }
}
