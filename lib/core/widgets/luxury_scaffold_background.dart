import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Fond d'écran signature de JurisIA : le dégradé Bleu Nuit habituel,
/// surmonté d'une micro-texture de fibre dorée quasi imperceptible qui
/// évoque le tissu d'une reliure juridique. Remplace la simple
/// [DecoratedBox] utilisée sur chaque écran.
class LuxuryScaffoldBackground extends StatelessWidget {
  const LuxuryScaffoldBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.background),
      child: CustomPaint(
        painter: const _AmbientGlowPainter(),
        child: CustomPaint(
          painter: const _FiberTexturePainter(),
          child: child,
        ),
      ),
    );
  }
}

/// Lueurs d'ambiance douces (« mesh gradient ») peintes une seule fois
/// derrière la texture de fibre : une touche d'or en haut à droite, une
/// touche de cobalt en bas à gauche — jamais assez marquées pour distraire
/// du contenu, juste de quoi donner une profondeur atmosphérique au fond
/// plat. Un dégradé radial qui s'éteint vers la transparence produit déjà
/// un bord doux sans le coût d'un vrai flou gaussien ; `shouldRepaint`
/// retourne toujours `false`, comme la texture de fibre, pour que Flutter
/// mette le calque en cache.
class _AmbientGlowPainter extends CustomPainter {
  const _AmbientGlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    _paintGlow(
      canvas,
      center: Offset(size.width * 0.88, size.height * 0.06),
      radius: size.longestSide * 0.55,
      color: AppColors.gold,
      maxAlpha: 0.10,
    );
    _paintGlow(
      canvas,
      center: Offset(size.width * 0.05, size.height * 0.92),
      radius: size.longestSide * 0.6,
      color: AppColors.cobalt,
      maxAlpha: 0.07,
    );
  }

  void _paintGlow(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
    required double maxAlpha,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: maxAlpha), color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Trame de fines fibres diagonales peintes une seule fois (l'aire ne
/// dépend que de la taille du canevas ; `shouldRepaint` retourne toujours
/// `false` afin que Flutter puisse mettre le calque en cache).
class _FiberTexturePainter extends CustomPainter {
  const _FiberTexturePainter();

  static const double _pitch = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.018)
      ..strokeWidth = 0.4;

    final diagonal = size.width + size.height;
    for (double offset = -size.height; offset < diagonal; offset += _pitch) {
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset - size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
