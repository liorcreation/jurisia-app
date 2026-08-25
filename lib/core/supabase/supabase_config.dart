import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuration de l'intégration Supabase (authentification et
/// persistance), partagée par toutes les fonctionnalités de l'application.
///
/// L'URL de projet et la clé publique (« anon key ») ne sont PAS des
/// secrets : Supabase est conçu pour que ces deux valeurs soient embarquées
/// dans le client (web compris) — la sécurité réelle des données est
/// assurée par les politiques Row Level Security définies dans
/// `server/supabase/schema.sql`, jamais par le secret de ces valeurs.
class SupabaseConfig {
  const SupabaseConfig._();

  static const String projectUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://gfpguuuzzyqoxjkhlhli.supabase.co',
  );

  /// Clé publique du projet (appelée « anon key » dans le tableau de bord
  /// Supabase, `publishableKey` côté SDK).
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_zBehM1ZVTng4CoAnCn5xMw_ygbRmvGa',
  );

  static bool get isConfigured => projectUrl.isNotEmpty && publishableKey.isNotEmpty;

  /// À appeler une fois, avant `runApp`. N'a aucun effet si le projet n'est
  /// pas encore configuré (voir `isConfigured`) : l'application démarre
  /// quand même, l'écran de connexion affichera un message explicite plutôt
  /// que de planter.
  static Future<void> initialize() async {
    if (!isConfigured) return;
    await Supabase.initialize(url: projectUrl, publishableKey: publishableKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
