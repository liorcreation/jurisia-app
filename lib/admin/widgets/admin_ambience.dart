import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';

/// Vie ambiante de la console : une lueur cobalt qui dérive lentement +
/// quelques grains en suspension — le pendant cobalt de `_SidebarAmbience`
/// / `_LibraryAmbience` de l'application grand public (mêmes proportions,
/// même douceur), pour que la console partage la respiration « vivante » de
/// la marque sans jamais se confondre avec le registre doré du grand public.
class AdminAmbience extends StatefulWidget {
  const AdminAmbience({super.key});

  @override
  State<AdminAmbience> createState() => _AdminAmbienceState();
}

class _AdminAmbienceState extends State<AdminAmbience> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 26))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(painter: _AdminAmbiencePainter(_controller.value)),
    );
  }
}

class _AdminMote {
  const _AdminMote({required this.x, required this.radius, required this.speed, required this.drift, required this.phase});

  final double x;
  final double radius;
  final double speed;
  final double drift;
  final double phase;
}

class _AdminAmbiencePainter extends CustomPainter {
  _AdminAmbiencePainter(this.t);

  final double t;

  static final math.Random _rng = math.Random(7);
  static final List<_AdminMote> _motes = List.generate(
    9,
    (_) => _AdminMote(
      x: _rng.nextDouble(),
      radius: 0.6 + _rng.nextDouble() * 1.4,
      speed: 0.10 + _rng.nextDouble() * 0.22,
      drift: _rng.nextDouble() * math.pi * 2,
      phase: _rng.nextDouble(),
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final phase = t * math.pi * 2;

    final glowCenter = Offset(
      size.width * (0.85 + 0.08 * math.sin(phase * 0.7)),
      size.height * (0.15 + 0.5 * math.sin(phase * 0.4)),
    );
    final glowRadius = size.longestSide * 0.45;
    canvas.drawCircle(
      glowCenter,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [AdminTheme.accent.withValues(alpha: 0.10), AdminTheme.accent.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: glowCenter, radius: glowRadius)),
    );

    final paint = Paint();
    for (final mote in _motes) {
      final progress = (mote.phase + t * mote.speed) % 1.0;
      final y = size.height * (1.04 - progress * 1.1);
      final x = size.width * mote.x + math.sin(progress * math.pi * 2 + mote.drift) * 10;
      final alpha = math.sin(progress * math.pi) * 0.14;
      if (alpha <= 0) continue;
      paint.color = AdminTheme.accentLight.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), mote.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AdminAmbiencePainter oldDelegate) => oldDelegate.t != t;
}
