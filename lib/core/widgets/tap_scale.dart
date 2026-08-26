import 'package:flutter/material.dart';

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
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
