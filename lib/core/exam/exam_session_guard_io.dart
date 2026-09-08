import 'package:flutter/widgets.dart';

/// Natif (Android, iOS, Windows, macOS) : surveille le passage en arrière-
/// plan réel de l'application via [WidgetsBindingObserver]. Ne réagit qu'à
/// [AppLifecycleState.paused] — jamais à `inactive`, qui se déclenche aussi
/// pour des interruptions transitoires sans quitter l'app (une boîte de
/// dialogue système, la demande d'autorisation micro du mode oral elle-même)
/// et déclencherait alors une fausse interruption de l'examen.
class ExamSessionGuard with WidgetsBindingObserver {
  ExamSessionGuard({required this.onInterrupted});

  final VoidCallback onInterrupted;
  bool _active = false;

  void start() {
    if (_active) return;
    _active = true;
    WidgetsBinding.instance.addObserver(this);
  }

  void stop() {
    if (!_active) return;
    _active = false;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_active) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      onInterrupted();
    }
  }
}
