import 'package:flutter/material.dart';

import '../../core/widgets/glass_container.dart';
import '../../core/widgets/gradient_icon_badge.dart';
import '../../theme/app_theme.dart';
import '../theme/admin_theme.dart';

/// Carte KPI du cockpit : badge d'icône teinté, grand chiffre en serif,
/// libellé en capitales, indice optionnel. Toujours en `Expanded` dans une
/// rangée de hauteur égale côté appelant.
class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.hint,
    this.accentColor = AdminTheme.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? hint;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GradientIconBadge(
            icon: icon,
            size: 38,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accentColor.withValues(alpha: 0.95), accentColor.withValues(alpha: 0.55)],
            ),
            iconColor: AppColors.textPrimary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.headlineMedium?.copyWith(fontFamily: 'Libre Caslon Display', color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            maxLines: 2,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: AppLetterSpacing.caps,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(hint!, style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled)),
          ],
        ],
      ),
    );
  }
}
