import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';

/// Maintient une écoute microphone légère pendant l'évaluation afin de fournir
/// des niveaux sonores au [ExamNoiseGuard]. Aucun contenu audio n'est stocké :
/// seul le niveau d'amplitude est transmis au contrôleur.
class ExamMicrophoneGuard {
  SpeechToText? _speech;
  bool _active = false;
  bool _restarting = false;

  bool get isActive => _active;

  Future<bool> start({required void Function(double level) onSample}) async {
    if (_active) return true;

    final speech = SpeechToText();
    final initialized = await speech.initialize(
      onError: (_) {},
      onStatus: (status) {
        if (_active && status == SpeechToText.doneStatus) {
          unawaited(_restart(onSample));
        }
      },
    );
    if (!initialized) return false;

    _speech = speech;
    _active = true;
    await _listen(onSample);
    return true;
  }

  Future<void> _listen(void Function(double level) onSample) async {
    final speech = _speech;
    if (!_active || speech == null || speech.isListening) return;
    try {
      await speech.listen(
        onResult: (_) {},
        onSoundLevelChange: onSample,
        listenOptions: SpeechListenOptions(
          partialResults: false,
          cancelOnError: false,
        ),
      );
    } catch (_) {
      // L'autorisation ou le canal natif peuvent être indisponibles :
      // l'épreuve conserve son proctoring caméra/lifecycle.
    }
  }

  Future<void> _restart(void Function(double level) onSample) async {
    if (!_active || _restarting) return;
    _restarting = true;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (_active) await _listen(onSample);
    _restarting = false;
  }

  Future<void> stop() async {
    _active = false;
    _restarting = false;
    final speech = _speech;
    _speech = null;
    if (speech == null) return;
    try {
      await speech.cancel();
    } catch (_) {}
  }
}
