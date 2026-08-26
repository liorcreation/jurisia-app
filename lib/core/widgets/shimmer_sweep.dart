import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Balayage diagonal or en boucle, façon « shimmer » — même technique que
/// le reflet ponctuel de [GlassContainer]/`ChatBubble` (un dégradé
/// translucide peint par-dessus le contenu, jamais un blend mode
/// destructif), mais rejoué indéfiniment. Remplace les indicateurs de
/// chargement basiques partout où une vraie attente existe (voir
/// `AuthGate`, l'écran de préparation d'évaluation).
class ShimmerSweep extends StatefulWidget {
  const ShimmerSweep({super.key, required this.child, this.duration = const Duration(milliseconds: 1800)});

  final Widget child;
  final Duration duration;

  @override
  State<ShimmerSweep> createState() => _ShimmerSweepState();
}

class _ShimmerSweepState extends State<ShimmerSweep> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(painter: _ShimmerSweepPainter(progress: _controller.value)),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShimmerSweepPainter extends CustomPainter {
  const _ShimmerSweepPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final band = -0.5 + progress * 2.0;
    final gradient = LinearGradient(
      begin: Alignment(band - 0.5, -1),
      end: Alignment(band, 1),
      colors: [
        Colors.transparent,
        AppColors.goldLight.withValues(alpha: 0.35),
        Colors.transparent,
      ],
      stops: const [0.35, 0.5, 0.65],
    );

    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  @override
  bool shouldRepaint(covariant _ShimmerSweepPainter oldDelegate) => oldDelegate.progress != progress;
}
