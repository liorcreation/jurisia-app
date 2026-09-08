import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Web : Chrome (depuis la version 71) bloque `speechSynthesis.speak()` tant
/// que la page — ou l'un de ses appels précédents — n'a jamais eu
/// d'activation utilisateur authentique (un vrai clic). Le premier appel
/// réel de l'examen vocal a lieu après un aller-retour réseau (génération
/// des questions), ce qui peut suffire à faire perdre cette activation sur
/// certains navigateurs — même piège que `window.open()`/`requestFullscreen()`
/// déjà rencontrés cette session pour le SSO admin et le plein écran.
///
/// Émet donc, de façon strictement synchrone dans la pile d'appel du tap
/// sur "Commencer l'examen", un énoncé quasi silencieux. Contrairement à une
/// version précédente, on NE L'ANNULE PAS immédiatement après `speak()` :
/// Chrome ne semble enregistrer le déblocage "cette page a déjà parlé sur
/// geste utilisateur" que si l'énoncé démarre réellement (évènement
/// `onstart`) — l'annuler dans la même microtâche, avant qu'il n'ait eu la
/// moindre chance de démarrer, invalide le déblocage aussi sûrement que ne
/// jamais l'avoir tenté. Un énoncé d'un seul espace à volume quasi nul est de
/// toute façon si bref qu'il se termine de lui-même en une fraction de
/// seconde, sans laisser de son audible ni bloquer l'UI.
void primeWebSpeechSynthesis() {
  try {
    final utterance = web.SpeechSynthesisUtterance(' ')..volume = 0.01;
    web.window.speechSynthesis.speak(utterance);
  } catch (_) {
    // Best effort : une API absente/bloquée ne doit jamais empêcher le
    // démarrage de l'épreuve.
  }
}

/// Web : `getUserMedia` (utilisé en interne par `speech_to_text` pour
/// demander l'accès au micro) exige lui aussi une activation utilisateur
/// authentique pour faire apparaître l'invite d'autorisation — exactement
/// le même piège que `speechSynthesis.speak()` ci-dessus. Or `stt.initialize()`
/// n'est appelé qu'une fois l'écran vocal monté, après le round-trip réseau
/// de génération des questions : l'activation du clic sur "Commencer
/// l'examen" a toutes les chances d'avoir expiré d'ici là, et Chrome peut
/// alors ne jamais présenter l'invite (le micro reste indisponible en
/// silence). Démarre donc la demande de permission de façon strictement
/// synchrone dans la pile d'appel du clic : l'invite apparaît immédiatement,
/// et une fois accordée, elle reste mémorisée pour la suite de la session
/// (initialize() plus tard n'a alors plus besoin d'un geste actif).
void primeWebMicrophonePermission() {
  try {
    web.window.navigator.mediaDevices
        .getUserMedia(web.MediaStreamConstraints(audio: true.toJS))
        .toDart
        .then(
          (stream) {
            for (final track in stream.getTracks().toDart) {
              track.stop();
            }
          },
          onError: (_) {},
        );
  } catch (_) {
    // Best effort : une API absente/bloquée ne doit jamais empêcher le
    // démarrage de l'épreuve.
  }
}

/// Chromium (Chrome, Edge...) charge la liste des voix de façon
/// asynchrone : juste après le chargement de la page, `getVoices()` peut
/// renvoyer un tableau VIDE, et un `speak()` appelé avant que l'événement
/// `voiceschanged` ne se déclenche au moins une fois peut être abandonné
/// silencieusement (aucune voix à associer à l'énoncé). Attend donc que la
/// liste soit peuplée avant de prononcer quoi que ce soit — avec un délai
/// de repli, certains navigateurs ne déclenchant jamais l'événement quand
/// la liste est en réalité déjà prête dès le premier appel.
Future<void> waitForWebSpeechVoicesReady() async {
  try {
    if (web.window.speechSynthesis.getVoices().toDart.isNotEmpty) return;

    final completer = Completer<void>();
    void handler(web.Event _) {
      if (!completer.isCompleted) completer.complete();
    }

    web.window.speechSynthesis.onvoiceschanged = handler.toJS;
    await completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {},
    );
    web.window.speechSynthesis.onvoiceschanged = null;
  } catch (_) {
    // Best effort : une API absente/bloquée ne doit jamais empêcher le
    // démarrage de l'épreuve.
  }
}
