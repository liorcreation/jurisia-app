import 'package:flutter/foundation.dart';

/// Détection de bruit ambiant suspect pendant une évaluation — signal
/// distinct de l'interruption "quitter l'app" : un déclenchement disqualifie
/// immédiatement la tentative (comme un score < 10/20), sans régénération.
///
/// Réutilise le niveau sonore déjà capté par `speech_to_text`
/// (`onSoundLevelChange`) via [onSample], mais reste [armed] uniquement
/// pendant de courtes fenêtres de silence dédiées entre deux temps de
/// l'épreuve — jamais pendant que l'assistant vocal lui-même parle (son
/// propre son, capté par le micro, déclencherait sans arrêt une fausse
/// alerte) ni pendant que l'étudiant répond (sa voix y est normale).
class ExamNoiseGuard {
  ExamNoiseGuard({required this.onDisqualified});

  final VoidCallback onDisqualified;

  /// Niveau (échelle brute de speech_to_text, environ -2 à 10 en pratique)
  /// au-delà duquel un échantillon est jugé bruyant. Seuil de première
  /// approche, à affiner sur de vrais appareils.
  static const double _loudThreshold = 4.0;

  /// Échantillons consécutifs bruyants avant disqualification — évite
  /// qu'un pic isolé (toux, bruit bref) ne pénalise injustement.
  static const int _consecutiveTrigger = 5;

  bool armed = false;
  int _consecutiveHits = 0;
  bool _disqualified = false;

  void onSample(double level) {
    if (!armed || _disqualified) {
      _consecutiveHits = 0;
      return;
    }
    if (level >= _loudThreshold) {
      _consecutiveHits++;
      if (_consecutiveHits >= _consecutiveTrigger) {
        _disqualified = true;
        onDisqualified();
      }
    } else {
      _consecutiveHits = 0;
    }
  }

  void reset() {
    _consecutiveHits = 0;
    _disqualified = false;
    armed = false;
  }
}
