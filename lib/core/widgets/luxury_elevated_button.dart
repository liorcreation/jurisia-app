import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Bouton d'action principal (« Générer », « Valider », « Analyser »...) :
/// dégradé d'or brossé, typographie sans-serif cristalline, et un éclat
/// métallique qui traverse rapidement le bouton au clic. Remplace
/// [ElevatedButton] aux points d'action à plus forte valeur de
/// l'application ; les actions secondaires conservent le thème
/// [ElevatedButtonTheme] standard.
class LuxuryElevatedButton extends StatefulWidget {
  const LuxuryElevatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.expand = true,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final IconData? icon;

  /// Si `true` (par défaut), le bouton occupe toute la largeur disponible —
  /// adapté aux appels à l'action principaux, en bas d'écran mobile comme
  /// desktop.
  final bool expand;

  @override
  State<LuxuryElevatedButton> createState() => _LuxuryElevatedButtonState();
}

class _LuxuryElevatedButtonState extends State<LuxuryElevatedButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shineController;
  bool _isPressed = false;

  bool get _enabled => widget.onPressed != null;

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!_enabled) return;
    _shineController.forward(from: 0);
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final label = DefaultTextStyle.merge(
      style: textTheme.labelLarge?.copyWith(
        color: AppColors.nightBlueDeep,
        fontWeight: FontWeight.w700,
        letterSpacing: AppLetterSpacing.label,
      ),
      child: IconTheme.merge(
        data: const IconThemeData(color: AppColors.nightBlueDeep, size: 18),
        child: widget.icon == null
            ? widget.child
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(widget.icon), const SizedBox(width: AppSpacing.sm), widget.child],
              ),
      ),
    );

    Widget button = AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Opacity(
        opacity: _enabled ? 1 : 0.45,
        child: Container(
          height: 52,
          width: widget.expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: AppGradients.goldMetallic,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: _enabled ? AppShadows.goldGlow : const [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(child: label),
                AnimatedBuilder(
                  animation: _shineController,
                  builder: (context, _) {
                    return CustomPaint(
                      size: Size.infinite,
                      painter: _MetallicShinePainter(progress: _shineController.value),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    button = MouseRegion(
      cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTap: _handleTap,
        onTapDown: _enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapCancel: () => setState(() => _isPressed = false),
        onTapUp: (_) => setState(() => _isPressed = false),
        child: button,
      ),
    );

    return widget.expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Bande de lumière diagonale qui traverse rapidement le bouton au clic,
/// comme un éclat sur du métal brossé.
class _MetallicShinePainter extends CustomPainter {
  const _MetallicShinePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final band = -0.6 + progress * 2.2;
    final gradient = LinearGradient(
      begin: Alignment(band - 0.4, -1),
      end: Alignment(band, 1),
      colors: const [
        Colors.transparent,
        Color(0x99FFFFFF),
        Colors.transparent,
      ],
      stops: const [0.35, 0.5, 0.65],
    );

    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  @override
  bool shouldRepaint(covariant _MetallicShinePainter oldDelegate) => oldDelegate.progress != progress;
}
