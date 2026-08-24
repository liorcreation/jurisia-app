import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Surface de « verre fumé » (flou d'arrière-plan + dégradé sombre
/// translucide) partagée par les barres de navigation et les feuilles
/// modales, pour une continuité visuelle du glassmorphism sur toute
/// surface flottant au-dessus du contenu.
class SmokedGlassSurface extends StatelessWidget {
  const SmokedGlassSurface({super.key, required this.child, this.border, this.borderRadius});

  final Widget child;
  final BoxBorder? border;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.smokedGlass,
        border: border,
        borderRadius: borderRadius,
      ),
      child: child,
    );

    final blurred = BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
      child: decorated,
    );

    return borderRadius != null
        ? ClipRRect(borderRadius: borderRadius!, child: blurred)
        : ClipRect(child: blurred);
  }
}
