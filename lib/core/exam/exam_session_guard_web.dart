import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Web : surveille l'événement `visibilitychange` du document — déclenché
/// dès que l'onglet passe en arrière-plan (changement d'onglet, minimisation,
/// changement d'application sur mobile web).
class ExamSessionGuard {
  ExamSessionGuard({required this.onInterrupted});

  final VoidCallback onInterrupted;
  JSFunction? _listener;

  void start() {
    if (_listener != null) return;
    final listener = ((web.Event _) {
      if (web.document.hidden) onInterrupted();
    }).toJS;
    _listener = listener;
    web.document.addEventListener('visibilitychange', listener);
  }

  void stop() {
    final listener = _listener;
    if (listener == null) return;
    web.document.removeEventListener('visibilitychange', listener);
    _listener = null;
  }
}
