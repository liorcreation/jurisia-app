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
/// sur "Commencer l'examen", un énoncé quasi silencieux immédiatement
/// annulé : ça n'émet aucun son audible, mais ça inscrit fermement
/// l'activation utilisateur avant que la vraie consigne vocale ne soit
/// prononcée quelques instants plus tard.
void primeWebSpeechSynthesis() {
  try {
    final utterance = web.SpeechSynthesisUtterance(' ')..volume = 0.01;
    web.window.speechSynthesis.speak(utterance);
    web.window.speechSynthesis.cancel();
  } catch (_) {
    // Best effort : une API absente/bloquée ne doit jamais empêcher le
    // démarrage de l'épreuve.
  }
}
