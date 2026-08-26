import 'package:flutter/material.dart';

import '../../../../core/widgets/glass_container.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/entities/professional_category.dart';

IconData iconForCategory(ProfessionalCategory category) {
  switch (category) {
    case ProfessionalCategory.notaire:
      return Icons.home_work_rounded;
    case ProfessionalCategory.avocat:
      return Icons.record_voice_over_rounded;
    case ProfessionalCategory.juriste:
      return Icons.menu_book_rounded;
    case ProfessionalCategory.huissier:
      return Icons.assignment_late_rounded;
    case ProfessionalCategory.greffier:
      return Icons.folder_shared_rounded;
    case ProfessionalCategory.juge:
      return Icons.gavel_rounded;
  }
}

/// Carte de sélection d'une catégorie de professionnel, dans la grille de
/// l'écran « Contacter un professionnel ».
class ProfessionalCategoryCard extends StatelessWidget {
  const ProfessionalCategoryCard({super.key, required this.category, required this.onTap});

  final ProfessionalCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassContainer(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(gradient: AppGradients.goldMetallic, shape: BoxShape.circle),
            child: Icon(iconForCategory(category), color: AppColors.nightBlueDeep, size: 22),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(category.label, style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              category.description,
              style: textTheme.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
