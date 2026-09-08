import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

/// Natif (Android, iOS, Windows, macOS) : surveille le passage en arrière-
/// plan réel de l'application via [WidgetsBindingObserver]. Ne réagit qu'à
/// [AppLifecycleState.paused] — jamais à `inactive`, qui se déclenche aussi
/// pour des interruptions transitoires sans quitter l'app (une boîte de
/// dialogue système, la demande d'autorisation micro du mode oral elle-même)
/// et déclencherait alors une fausse interruption de l'examen.
///
/// Applique aussi un plein écran forcé pendant l'épreuve, avec un
/// comportement qui diffère honnêtement par plateforme :
/// - Desktop (Windows/macOS) : vrai plein écran de fenêtre (`window_manager`)
///   ET détection de sa sortie (`onWindowLeaveFullScreen`) — ferme la faille
///   « réduire la fenêtre JurisIA et ouvrir un navigateur à côté sans jamais
///   la minimiser », que le seul cycle de vie de l'app ne détecte pas.
/// - Mobile (Android/iOS) : mode immersif (barres système masquées) pour
///   l'effet visuel plein écran, mais SANS détection de sortie indépendante
///   — Android ré-affiche les barres si l'utilisateur les fait glisser sans
///   notifier l'app (aucune API Flutter n'expose cet événement). Le seul
///   déclencheur d'interruption fiable sur mobile reste donc « quitter
///   l'application », déjà couvert ci-dessous.
class ExamSessionGuard with WidgetsBindingObserver, WindowListener {
  ExamSessionGuard({required this.onInterrupted});

  final VoidCallback onInterrupted;
  bool _active = false;

  static bool _windowManagerReady = false;

  bool get _isDesktop => Platform.isWindows || Platform.isMacOS;
  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  Future<void> start() async {
    if (_active) return;
    _active = true;
    WidgetsBinding.instance.addObserver(this);

    if (_isMobile) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else if (_isDesktop) {
      await _ensureWindowManagerReady();
      windowManager.addListener(this);
      try {
        await windowManager.setFullScreen(true);
      } catch (_) {
        // Best effort : une session native inhabituelle (fenêtre déjà
        // détruite, plateforme non supportée par le canal natif) ne doit
        // jamais empêcher l'examen de démarrer.
      }
    }
  }

  Future<void> stop() async {
    if (!_active) return;
    _active = false;
    WidgetsBinding.instance.removeObserver(this);

    if (_isMobile) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else if (_isDesktop) {
      windowManager.removeListener(this);
      try {
        await windowManager.setFullScreen(false);
      } catch (_) {}
    }
  }

  Future<void> _ensureWindowManagerReady() async {
    if (_windowManagerReady) return;
    try {
      await windowManager.ensureInitialized();
      _windowManagerReady = true;
    } catch (_) {
      // Nouvel essai à la prochaine tentative d'examen plutôt que de
      // bloquer celle-ci.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_active) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      onInterrupted();
    }
  }

  @override
  void onWindowLeaveFullScreen() {
    if (!_active) return;
    onInterrupted();
  }
}
