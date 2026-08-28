import '../supabase/supabase_config.dart';
import 'groq_api_datasource.dart';

/// Construit un [GroqDataSource] qui joint le jeton d'accès Supabase de
/// l'utilisateur connecté à chaque requête vers le relais.
///
/// Le relais (`server/groq-proxy/`) s'en sert pour appliquer les quotas et
/// le modèle correspondant à l'abonnement (voir la table `ai_limits`). Sans
/// session — utilisateur non connecté, Supabase non configuré — le relais
/// retombe sur ses limites par adresse IP et le service reste utilisable.
GroqDataSource buildGroqDataSource() {
  return GroqDataSource(
    accessToken: () async {
      if (!SupabaseConfig.isReady) return null;
      return SupabaseConfig.client.auth.currentSession?.accessToken;
    },
  );
}
