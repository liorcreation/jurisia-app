import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Dégradé « portail » : or à un bout, cobalt à l'autre — la seule surface
/// de l'application grand public qui mélange les deux registres, parce que
/// cet emblème est littéralement le pont entre les deux mondes (compte
/// personnel, deux applications déployées séparément).
const LinearGradient _portalGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.goldLight, AppColors.gold, AppColors.cobalt, AppColors.legalBlueLight],
  stops: [0.0, 0.4, 0.68, 1.0],
);

/// L'emblème du portail vers la console d'administration : un anneau qui
/// tourne lentement, dégradé du portail (or → cobalt), une lueur qui
/// respire, une plaque nocturne au centre. Purement visuel — le tap, le
/// tooltip et la vérification du rôle de personnel vivent chez l'appelant
/// (voir `JurisIASidebar`, la seule surface où cet emblème apparaît :
/// jamais en survol du contenu d'un écran, pour ne jamais recouvrir une
/// action déjà en place — barre d'app, composeur, bulles de conversation).
class PortalOrb extends StatefulWidget {
  const PortalOrb({super.key, this.size = 40, this.iconSize});

  final double size;
  final double? iconSize;

  @override
  State<PortalOrb> createState() => _PortalOrbState();
}

class _PortalOrbState extends State<PortalOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final iconSize = widget.iconSize ?? size * 0.42;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final breathe = (math.sin(_controller.value * 2 * math.pi) + 1) / 2;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.cobalt.withValues(alpha: 0.28 + breathe * 0.16),
                blurRadius: 14 + breathe * 5,
                spreadRadius: 0.5,
              ),
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.16 + breathe * 0.09),
                blurRadius: 9,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.4),
                radius: 1.1,
                colors: [AppColors.nightBlue, AppColors.nightBlueDeep],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              size: Size.square(size),
              painter: _PortalRingPainter(progress: _controller.value),
            ),
          ),
          Icon(Icons.auto_awesome_rounded, size: iconSize, color: AppColors.textPrimary),
        ],
      ),
    );
  }
}

/// Anneau qui tourne lentement, dégradé du portail — la tête lumineuse
/// glisse de l'or au cobalt et inversement, jamais figée.
class _PortalRingPainter extends CustomPainter {
  const _PortalRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 1.4;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(progress * 2 * math.pi);
    canvas.translate(-center.dx, -center.dy);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..shader = _portalGradient.createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PortalRingPainter oldDelegate) => oldDelegate.progress != progress;
}
