import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../theme/admin_theme.dart';

/// Ligne de répartition animée : libellé, valeur, et une barre proportionnelle
/// qui se déploie à l'apparition — remplace la simple ligne label/valeur
/// (`_BreakdownRow`) du tableau de bord par quelque chose qui se lit d'un
/// coup d'œil.
class AdminBarRow extends StatelessWidget {
  const AdminBarRow({
    super.key,
    required this.label,
    required this.value,
    required this.maxValue,
    this.color = AdminTheme.accent,
  });

  final String label;
  final int value;
  final int maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final fraction = maxValue <= 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.bodySmall),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '$value',
                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: SizedBox(
              height: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(color: AppColors.legalBlueDark.withValues(alpha: 0.6)),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: fraction),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: v,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [color.withValues(alpha: 0.55), color]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
