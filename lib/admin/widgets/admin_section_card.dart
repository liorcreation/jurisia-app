import 'package:flutter/material.dart';

import '../../core/widgets/glass_container.dart';
import '../../theme/app_theme.dart';
import '../theme/admin_theme.dart';

/// Carte de section standard de la console : eyebrow (icône + libellé en
/// capitales cobalt) puis contenu libre — le même patron pour le tableau de
/// bord, les répartitions, et toute section qui a besoin d'un en-tête léger
/// sans passer par [AdminPageHeader] (réservé au haut d'écran).
class AdminSectionCard extends StatelessWidget {
  const AdminSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassContainer(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AdminTheme.accentLight),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: AdminTheme.accentLight,
                    letterSpacing: AppLetterSpacing.caps,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
