import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';

/// Petite étiquette informative (catégorie, domaine, référence, mot-clé)
/// utilisée sur les cartes de résultat et la visionneuse de document.
class DocumentTag extends StatelessWidget {
  const DocumentTag({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.legalBlueDark.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
