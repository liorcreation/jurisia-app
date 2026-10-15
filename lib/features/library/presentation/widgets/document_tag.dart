import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';

/// Petite étiquette informative (catégorie, domaine, référence, mot-clé)
/// utilisée sur les cartes de résultat et la visionneuse de document.
class DocumentTag extends StatelessWidget {
  const DocumentTag({super.key, required this.label, this.light = false});

  final String label;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: light
            ? const Color(0xFFF2F5F8)
            : AppColors.legalBlueDark.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: light ? const Color(0xFFDCE4ED) : AppColors.glassBorder,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: light ? const Color(0xFF53657A) : AppColors.textSecondary,
        ),
      ),
    );
  }
}
