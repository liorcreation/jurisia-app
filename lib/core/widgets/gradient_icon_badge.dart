import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Badge d'icône à deux niveaux : un anneau de verre translucide, et une
/// puce à dégradé centrée qui porte l'icône — remplace le simple cercle
/// plat (`Container` + dégradé + icône) utilisé jusqu'ici pour les icônes
/// d'action génériques (cartes de module, catégories de professionnel).
/// Les badges qui encodent un état signifiant par la couleur
/// (`DocumentCategoryBadge`, `ModuleStatusBadge`) gardent leur propre
/// traitement, déjà distinct et déjà animé.
class GradientIconBadge extends StatelessWidget {
  const GradientIconBadge({
    super.key,
    required this.icon,
    this.size = 44,
    this.gradient = AppGradients.goldMetallic,
    this.iconColor = AppColors.nightBlueDeep,
  });

  final IconData icon;
  final double size;
  final Gradient gradient;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final innerSize = size * 0.72;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: 0.08),
              border: Border.all(color: AppColors.glassBorder, width: 0.75),
            ),
          ),
          Container(
            width: innerSize,
            height: innerSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: gradient,
              boxShadow: AppShadows.goldGlowSoft,
            ),
            child: Icon(icon, color: iconColor, size: innerSize * 0.5),
          ),
        ],
      ),
    );
  }
}
