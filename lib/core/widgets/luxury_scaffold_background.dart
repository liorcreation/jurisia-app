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
        painter: const _FiberTexturePainter(),
        child: child,
      ),
    );
  }
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
