import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Indicateur animé « l'IA réfléchit » : une onde de poussière d'or —
/// une douzaine de particules dorées de taille et de phase variables qui
/// oscillent le long d'une vague — plutôt que de simples points.
class AiThinkingIndicator extends StatefulWidget {
  const AiThinkingIndicator({super.key, this.label = "L'assistant réfléchit…"});

  final String label;

  @override
  State<AiThinkingIndicator> createState() => _AiThinkingIndicatorState();
}

class _AiThinkingIndicatorState extends State<AiThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            size: const Size(56, 22),
            painter: _GoldDustPainter(t: _controller.value),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          widget.label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
        ),
      ],
    );
  }
}

/// Peint une douzaine de particules dorées réparties le long d'une onde
/// sinusoïdale, chacune avec sa propre phase, sa propre amplitude verticale
/// et sa propre pulsation d'opacité/taille — une « poussière d'or »
/// intelligente plutôt qu'un simple indicateur mécanique.
class _GoldDustPainter extends CustomPainter {
  const _GoldDustPainter({required this.t});

  final double t;
  static const int _particleCount = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;

    for (var i = 0; i < _particleCount; i++) {
      final phase = i / _particleCount;
      final x = size.width * phase;

      final wave = math.sin((t * 2 * math.pi) + phase * 2 * math.pi);
      final y = centerY + wave * (size.height * 0.32);

      final pulse = (math.sin((t * 2 * math.pi * 1.6) + phase * 4 * math.pi) + 1) / 2;
      final radius = 1.1 + pulse * 1.6;
      final opacity = 0.25 + pulse * 0.65;

      final color = Color.lerp(AppColors.goldDark, AppColors.goldLight, pulse)!;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = color.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GoldDustPainter oldDelegate) => oldDelegate.t != t;
}
