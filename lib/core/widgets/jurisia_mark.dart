import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// La marque JurisIA : « la rose des précisions » — une étoile à huit
/// branches (quatre longues aux points cardinaux, quatre courtes aux
/// diagonales), construite en courbes symétriques comme une rose des vents
/// ou une pierre taillée vue de dessus. Une forme abstraite et radiante,
/// indépendante du nom — dans le même registre que les marques des grands
/// assistants IA — plutôt qu'une lettre ou un symbole juridique littéral
/// (balance, marteau). Rendue par [CustomPainter] : net à toute taille,
/// sans asset à embarquer, réutilisable dans toute l'application
/// (navigation, écran de démarrage, favicônes).
class JurisIAMark extends StatelessWidget {
  const JurisIAMark({super.key, this.size = 40, this.gradient});

  final double size;

  /// Dégradé de la marque. Par défaut, l'or brossé de l'application
  /// ([AppGradients.goldMetallic]).
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _JurisIAMarkPainter(gradient: gradient ?? AppGradients.goldMetallic),
      ),
    );
  }
}

class _JurisIAMarkPainter extends CustomPainter {
  const _JurisIAMarkPainter({required this.gradient});

  final Gradient gradient;

  static const int _pointCount = 8;
  static const double _longRadiusFactor = 0.46;
  static const double _shortRadiusFactor = 0.27;
  static const double _waistRadiusFactor = 0.06;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..shader = gradient.createShader(Offset.zero & size)
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    const angleStep = 2 * math.pi / _pointCount;

    // Huit pointes : quatre longues au nord/est/sud/ouest, quatre courtes
    // sur les diagonales — une rose des vents plutôt qu'une étoile plate.
    final tips = List<Offset>.generate(_pointCount, (i) {
      final angle = i * angleStep - math.pi / 2;
      final radius = (i.isEven ? _longRadiusFactor : _shortRadiusFactor) * s;
      return center + Offset(math.cos(angle), math.sin(angle)) * radius;
    });

    final path = Path()..moveTo(tips[0].dx, tips[0].dy);
    for (var i = 0; i < _pointCount; i++) {
      final nextTip = tips[(i + 1) % _pointCount];
      // Le point de creux entre deux pointes consécutives, utilisé comme
      // point de contrôle : c'est lui qui pince la courbe pour former des
      // facettes plutôt qu'un contour de fleur plein.
      final valleyAngle = (i + 0.5) * angleStep - math.pi / 2;
      final valley = center +
          Offset(math.cos(valleyAngle), math.sin(valleyAngle)) * (_waistRadiusFactor * s);
      path.quadraticBezierTo(valley.dx, valley.dy, nextTip.dx, nextTip.dy);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _JurisIAMarkPainter oldDelegate) => oldDelegate.gradient != gradient;
}

/// Composition « icône d'application » : la marque centrée sur un plateau
/// Bleu Nuit à coins arrondis, cerclé d'un filet d'or fin — la mise en page
/// qu'adopterait une icône d'accueil (iOS, Android, favicon, etc.).
class JurisIAAppIconTile extends StatelessWidget {
  const JurisIAAppIconTile({super.key, required this.size, this.cornerRadiusFactor = 0.22});

  final double size;

  /// Rayon des coins exprimé en fraction de [size] (0.22 ≈ squircle iOS,
  /// 0.5 pour un cercle Android adaptatif).
  final double cornerRadiusFactor;

  @override
  Widget build(BuildContext context) {
    final radius = size * cornerRadiusFactor;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.55), width: size * 0.012),
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.4),
          radius: 1.1,
          colors: [AppColors.nightBlue, AppColors.nightBlueDeep],
        ),
      ),
      alignment: Alignment.center,
      child: JurisIAMark(size: size * 0.62),
    );
  }
}
