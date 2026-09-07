import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../theme/admin_theme.dart';

/// Puce de filtre premium — remplace le `ChoiceChip` Material par défaut :
/// fond de verre sombre au repos, dégradé cobalt + liseré lumineux à la
/// sélection, compteur en pastille. Utilisée par les barres de filtre de la
/// console (demandes de mise en relation, CMS Bibliothèque).
class AdminFilterChip extends StatelessWidget {
  const AdminFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            gradient: selected
                ? LinearGradient(
                    colors: [AdminTheme.accent.withValues(alpha: 0.34), AdminTheme.accent.withValues(alpha: 0.14)],
                  )
                : null,
            color: selected ? null : AppColors.legalBlueDark.withValues(alpha: 0.4),
            border: Border.all(
              color: selected ? AdminTheme.accent.withValues(alpha: 0.6) : AppColors.glassBorder,
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.textPrimary.withValues(alpha: 0.18) : AppColors.legalBlueDark,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '$count',
                    style: textTheme.labelSmall?.copyWith(
                      color: selected ? AppColors.textPrimary : AppColors.textDisabled,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
