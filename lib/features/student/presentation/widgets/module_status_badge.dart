import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';

enum ModuleStatus { locked, inProgress, completed }

/// Badge circulaire indiquant le statut d'un module : un sceau en or
/// vieilli tant qu'il est verrouillé, qui se brise en une volée de
/// particules dorées à l'instant précis où le module se débloque.
class ModuleStatusBadge extends StatefulWidget {
  const ModuleStatusBadge({super.key, required this.status, this.size = 44});

  final ModuleStatus status;
  final double size;

  @override
  State<ModuleStatusBadge> createState() => _ModuleStatusBadgeState();
}

class _ModuleStatusBadgeState extends State<ModuleStatusBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _burstController;

  @override
  void initState() {
    super.initState();
    _burstController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  }

  @override
  void didUpdateWidget(covariant ModuleStatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status == ModuleStatus.locked && widget.status != ModuleStatus.locked) {
      _burstController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _burstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.status == ModuleStatus.locked;
    final completed = widget.status == ModuleStatus.completed;
    final canvasSize = widget.size * 1.9;

    return SizedBox(
      width: canvasSize,
      height: canvasSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _burstController,
            builder: (context, _) => CustomPaint(
              size: Size(canvasSize, canvasSize),
              painter: _ParticleBurstPainter(progress: _burstController.value),
            ),
          ),
          Container(
            width: widget.size,
            height: widget.size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: locked ? AppGradients.goldAged : AppGradients.goldMetallic,
              shape: BoxShape.circle,
              border: locked
                  ? Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 0.8)
                  : null,
              boxShadow: locked ? const [] : AppShadows.goldGlowSoft,
            ),
            child: Icon(
              locked
                  ? Icons.lock_rounded
                  : completed
                      ? Icons.check_rounded
                      : Icons.menu_book_rounded,
              color: AppColors.nightBlueDeep,
              size: widget.size * 0.46,
            ),
          ),
        ],
      ),
    );
  }
}

/// Volée de particules dorées qui explose depuis le centre du sceau à
/// l'instant du déblocage, chaque particule suivant un angle et une
/// vitesse fixes pour une trajectoire cohérente d'une image à l'autre.
class _ParticleBurstPainter extends CustomPainter {
  const _ParticleBurstPainter({required this.progress});

  final double progress;
  static const int _count = 14;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final center = size.center(Offset.zero);
    final maxRadius = size.width / 2;

    for (var i = 0; i < _count; i++) {
      final angle = (i / _count) * 2 * math.pi + (i.isEven ? 0.18 : -0.12);
      final speedFactor = 0.55 + (i % 3) * 0.22;
      final distance = maxRadius * progress * speedFactor;
      final offset = center + Offset(math.cos(angle), math.sin(angle)) * distance;

      final opacity = (1 - progress).clamp(0.0, 1.0) * 0.9;
      final radius = 2.4 * (1 - progress * 0.55);

      canvas.drawCircle(offset, radius, Paint()..color = AppColors.goldLight.withValues(alpha: opacity));
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleBurstPainter oldDelegate) => oldDelegate.progress != progress;
}
