import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Un segment du donut : valeur, couleur, libellé (pour la légende externe).
class AdminDonutSegment {
  const AdminDonutSegment({required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;
}

/// Anneau de répartition animé — le centre de gravité visuel du cockpit.
/// Aucune dépendance de librairie de graphiques : quelques arcs peints,
/// balayés une fois à l'apparition, avec le total affiché au centre.
class AdminDonutChart extends StatelessWidget {
  const AdminDonutChart({super.key, required this.segments, this.size = 132, this.strokeWidth = 16});

  final List<AdminDonutSegment> segments;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<double>(0, (sum, s) => sum + s.value);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _DonutPainter(segments: segments, total: total, strokeWidth: strokeWidth, progress: progress),
          child: Center(
            child: Text(
              total <= 0 ? '—' : total.toInt().toString(),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontFamily: 'Libre Caslon Display', color: AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.segments, required this.total, required this.strokeWidth, required this.progress});

  final List<AdminDonutSegment> segments;
  final double total;
  final double strokeWidth;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = AppColors.legalBlueDark.withValues(alpha: 0.5),
    );

    if (total <= 0) return;

    var start = -math.pi / 2;
    const gap = 0.035;
    for (final segment in segments) {
      if (segment.value <= 0) continue;
      final rawSweep = (segment.value / total) * 2 * math.pi;
      final sweep = math.max(0.0, rawSweep - gap) * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = segment.color,
      );
      start += rawSweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.segments != segments || oldDelegate.total != total;
}

/// Légende compacte à côté du donut : puce de couleur + libellé + valeur.
class AdminDonutLegend extends StatelessWidget {
  const AdminDonutLegend({super.key, required this.segments});

  final List<AdminDonutSegment> segments;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final segment in segments)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: segment.color),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(segment.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.bodySmall),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  segment.value.toInt().toString(),
                  style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
