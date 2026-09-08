/// Natif : aucune restriction de geste utilisateur pour la synthèse vocale
/// (contrairement au web) — rien à débloquer.
void primeWebSpeechSynthesis() {}

/// Natif : la permission micro est gérée par le système d'exploitation au
/// moment de l'appel réel — rien à préparer à l'avance.
void primeWebMicrophonePermission() {}

/// Natif : les voix du moteur de synthèse système sont disponibles
/// immédiatement — rien à attendre.
Future<void> waitForWebSpeechVoicesReady() async {}
