/// Natif : aucune restriction de geste utilisateur pour la synthèse vocale
/// (contrairement au web) — rien à débloquer.
void primeWebSpeechSynthesis() {}

/// Natif : les voix du moteur de synthèse système sont disponibles
/// immédiatement — rien à attendre.
Future<void> waitForWebSpeechVoicesReady() async {}
