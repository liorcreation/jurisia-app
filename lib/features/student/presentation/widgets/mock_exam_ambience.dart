import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';

/// Fines poussières d'or en suspension, partagées par tous les écrans de
/// l'examen blanc — la même respiration « vivante » que le reste de
/// l'Espace étudiant.
class MockExamAmbience extends StatefulWidget {
  const MockExamAmbience({super.key});

  @override
  State<MockExamAmbience> createState() => _MockExamAmbienceState();
}

class _MockExamAmbienceState extends State<MockExamAmbience> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(painter: _MockExamAmbiencePainter(_controller.value)),
    );
  }
}

class _MockExamAmbiencePainter extends CustomPainter {
  const _MockExamAmbiencePainter(this.t);

  final double t;
  static const int _count = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < _count; i++) {
      final seed = i * 59.0;
      final baseX = seed % size.width;
      final drift = math.sin((t * 2 * math.pi) + seed) * 22;
      final x = (baseX + drift) % size.width;
      final y = (size.height * ((i / _count) + t) % 1.0);
      final radius = 0.7 + (i % 3) * 0.6;
      final opacity = 0.04 + 0.08 * (0.5 + 0.5 * math.sin((t * 2 * math.pi) + seed * 1.7));
      paint.color = AppColors.goldLight.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MockExamAmbiencePainter oldDelegate) => oldDelegate.t != t;
}
