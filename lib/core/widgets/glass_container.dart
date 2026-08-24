import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Conteneur à effet de verre dépoli sombre (Dark Glassmorphism), signature
/// de JurisIA : fond translucide Bleu Juridique, flou d'arrière-plan,
/// bordure en or brossé ultra-fine (0.5px, incrustée en dégradé plutôt
/// qu'en aplat), légère élévation au survol et reflet qui glisse sur la
/// surface au toucher.
class GlassContainer extends StatefulWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
    this.borderRadius = AppRadius.medium,
    this.blurSigma = 18,
    this.gradient = AppGradients.glassCard,
    this.borderColor = AppColors.glassBorder,
    this.borderWidth = 0.5,
    this.width,
    this.height,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final Gradient gradient;
  final Color borderColor;
  final double borderWidth;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  @override
  State<GlassContainer> createState() => _GlassContainerState();
}

class _GlassContainerState extends State<GlassContainer> with SingleTickerProviderStateMixin {
  late final AnimationController _shineController;
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  void _playShine() {
    if (_shineController.isAnimating) return;
    _shineController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);

    Widget content = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: widget.blurSigma, sigmaY: widget.blurSigma),
        child: AnimatedBuilder(
          animation: _shineController,
          builder: (context, child) {
            return CustomPaint(
              foregroundPainter: _ShineSweepPainter(
                progress: _shineController.value,
                radius: widget.borderRadius,
              ),
              child: child,
            );
          },
          child: Container(
            width: widget.width,
            height: widget.height,
            padding: widget.padding,
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: radius,
              boxShadow: _isHovered ? AppShadows.cardElevated : AppShadows.card,
            ),
            child: widget.child,
          ),
        ),
      ),
    );

    content = CustomPaint(
      foregroundPainter: _GradientBorderPainter(
        color: widget.borderColor,
        width: widget.borderWidth,
        radius: widget.borderRadius,
      ),
      child: content,
    );

    final wrapped = widget.margin != null ? Padding(padding: widget.margin!, child: content) : content;

    if (widget.onTap == null) return wrapped;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : (_isHovered ? 1.015 : 1.0),
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: () {
              _playShine();
              widget.onTap!();
            },
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapCancel: () => setState(() => _isPressed = false),
            onTapUp: (_) => setState(() => _isPressed = false),
            borderRadius: radius,
            child: wrapped,
          ),
        ),
      ),
    );
  }
}

/// Bordure incrustée en dégradé (simule un filet d'or brossé) : dessinée en
/// contour plutôt qu'en aplat, elle réagit à la lumière selon l'angle.
class _GradientBorderPainter extends CustomPainter {
  const _GradientBorderPainter({required this.color, required this.width, required this.radius});

  final Color color;
  final double width;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (width <= 0) return;
    final rect = (Offset.zero & size).deflate(width / 2);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.withValues(alpha: (color.a * 1.5).clamp(0, 1)),
        color.withValues(alpha: color.a * 0.35),
        color.withValues(alpha: color.a * 1.1 > 1 ? 1 : color.a * 1.1),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..shader = gradient.createShader(Offset.zero & size);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.width != width || oldDelegate.radius != radius;
  }
}

/// Reflet diagonal qui glisse une fois sur la surface de la carte au
/// toucher, comme la lumière sur du verre poli.
class _ShineSweepPainter extends CustomPainter {
  const _ShineSweepPainter({required this.progress, required this.radius});

  final double progress;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

    final band = -1 + progress * 3;
    final gradient = LinearGradient(
      begin: Alignment(band - 0.5, -1),
      end: Alignment(band, 1),
      colors: [
        Colors.transparent,
        AppColors.goldLight.withValues(alpha: 0.20),
        Colors.transparent,
      ],
      stops: const [0.35, 0.5, 0.65],
    );

    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ShineSweepPainter oldDelegate) => oldDelegate.progress != progress;
}
