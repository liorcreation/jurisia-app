import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../theme/admin_theme.dart';

/// Monogramme cobalt — la première lettre d'un e-mail/nom sur un disque à
/// dégradé, teinte dérivée du texte pour que deux personnes différentes se
/// distinguent d'un coup d'œil sans jamais recourir à une vraie photo.
/// Utilisé partout où la console désigne une personne (personnel, auteur
/// d'une demande ou d'un brouillon).
class AdminAvatar extends StatelessWidget {
  const AdminAvatar({super.key, required this.seed, this.size = 34});

  final String seed;
  final double size;

  static const _hues = [
    AdminTheme.accent,
    AppColors.metalEmerald,
    AppColors.metalRoseGold,
    AppColors.metalBronze,
    AppColors.metalSilver,
    AppColors.gold,
  ];

  Color get _tint => _hues[seed.isEmpty ? 0 : seed.codeUnitAt(0) % _hues.length];

  @override
  Widget build(BuildContext context) {
    final initial = seed.isEmpty ? '?' : seed.substring(0, 1).toUpperCase();
    final tint = _tint;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint.withValues(alpha: 0.95), tint.withValues(alpha: 0.55)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.6),
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}
