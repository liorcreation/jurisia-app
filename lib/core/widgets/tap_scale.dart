import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Léger rebond au tap (0.85× puis retour) pour les boutons d'action
/// rapide (favoris, bascules) qui n'ont pas déjà le retour tactile de
/// [GlassContainer]/[LuxuryElevatedButton] — un `IconButton` nu, par
/// exemple. N'intercepte pas le tap lui-même : enveloppe un enfant déjà
/// cliquable (typiquement un `IconButton`) et se contente d'observer les
/// évènements de pointeur pour piloter l'échelle.
class TapScale extends StatefulWidget {
  const TapScale({super.key, required this.child});

  final Widget child;

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final motionEnabled = AppMotion.isEnabled(context);
    return Listener(
      onPointerDown: motionEnabled ? (_) => _setPressed(true) : null,
      onPointerUp: motionEnabled ? (_) => _setPressed(false) : null,
      onPointerCancel: motionEnabled ? (_) => _setPressed(false) : null,
      child: AnimatedScale(
        scale: motionEnabled && _pressed ? 0.94 : 1.0,
        duration: AppMotion.duration(context, AppMotion.quick),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
