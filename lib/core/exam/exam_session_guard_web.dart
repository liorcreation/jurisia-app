import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Web : surveille l'événement `visibilitychange` du document — déclenché
/// dès que l'onglet passe en arrière-plan (changement d'onglet, minimisation,
/// changement d'application sur mobile web) — ET demande le plein écran du
/// navigateur pendant l'épreuve, en surveillant sa sortie (`fullscreenchange`)
/// comme second déclencheur d'interruption : ferme la faille « réduire la
/// fenêtre du navigateur et ouvrir un autre onglet/une autre app à côté sans
/// jamais changer d'onglet JurisIA », que `visibilitychange` seul ne détecte
/// pas.
class ExamSessionGuard {
  ExamSessionGuard({required this.onInterrupted});

  final VoidCallback onInterrupted;
  JSFunction? _visibilityListener;
  JSFunction? _fullscreenListener;

  void start() {
    if (_visibilityListener != null) return;

    final visibilityListener = ((web.Event _) {
      if (web.document.hidden) onInterrupted();
    }).toJS;
    _visibilityListener = visibilityListener;
    web.document.addEventListener('visibilitychange', visibilityListener);

    final fullscreenListener = ((web.Event _) {
      if (web.document.fullscreenElement == null) onInterrupted();
    }).toJS;
    _fullscreenListener = fullscreenListener;
    web.document.addEventListener('fullscreenchange', fullscreenListener);

    // Doit rester synchrone, dans la pile d'appel du geste de l'utilisateur
    // qui a déclenché `start()` (voir MockExamController.start) : un appel
    // différé après un aller-retour réseau serait silencieusement refusé
    // par le navigateur, comme window.open() pour le SSO admin.
    web.document.documentElement?.requestFullscreen();
  }

  void stop() {
    final visibilityListener = _visibilityListener;
    if (visibilityListener != null) {
      web.document.removeEventListener('visibilitychange', visibilityListener);
      _visibilityListener = null;
    }
    final fullscreenListener = _fullscreenListener;
    if (fullscreenListener != null) {
      web.document.removeEventListener('fullscreenchange', fullscreenListener);
      _fullscreenListener = null;
    }
    if (web.document.fullscreenElement != null) {
      web.document.exitFullscreen();
    }
  }
}
