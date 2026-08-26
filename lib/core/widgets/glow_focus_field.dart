import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Lueur cobalt douce autour d'un champ de saisie quand il a le focus —
/// généralise le traitement déjà appliqué au composeur de chat
/// (`ChatComposer`) pour l'étendre à tous les formulaires de l'application
/// (connexion, prise en main de rédaction, demande de contact). Enveloppe
/// n'importe quel champ sans lui imposer de `FocusNode` explicite : un
/// `TextField` interne remonte son focus au `Focus` englobant.
class GlowFocusField extends StatefulWidget {
  const GlowFocusField({super.key, required this.child, this.borderRadius = AppRadius.medium});

  final Widget child;
  final double borderRadius;

  @override
  State<GlowFocusField> createState() => _GlowFocusFieldState();
}

class _GlowFocusFieldState extends State<GlowFocusField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.fastOutSlowIn,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: AppColors.cobalt.withValues(alpha: 0.28),
                    blurRadius: 16,
                    spreadRadius: 0.5,
                  ),
                ]
              : const [],
        ),
        child: widget.child,
      ),
    );
  }
}
