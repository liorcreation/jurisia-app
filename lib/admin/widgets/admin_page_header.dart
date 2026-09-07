import 'package:flutter/material.dart';

import '../../core/widgets/gradient_icon_badge.dart';
import '../../core/widgets/smoked_glass_surface.dart';
import '../../theme/app_theme.dart';
import '../shell/admin_shell_scope.dart';
import '../theme/admin_theme.dart';

/// En-tête premium partagé par tous les écrans de la console — remplace
/// l'`AppBar` générique par un bandeau de verre fumé cerclé d'un filet
/// cobalt en pied : badge d'icône à dégradé, eyebrow, titre en serif,
/// sous-titre optionnel, actions à droite. Une seule composition pour toute
/// la console, pour que chaque section se sente couper du même tissu.
class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    super.key,
    required this.icon,
    required this.title,
    this.eyebrow = 'CONSOLE JURISIA',
    this.subtitle,
    this.actions = const [],
    this.bottom,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final openDrawer = AdminShellScope.maybeOpenDrawer(context);
    final compact = openDrawer != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AdminTheme.accent.withValues(alpha: 0.28), width: 0.7)),
        boxShadow: AdminGradients.cobaltGlowSoft.map((s) => s.scale(0.25)).toList(),
      ),
      child: SmokedGlassSurface(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? AppSpacing.sm : AppSpacing.lg,
            AppSpacing.sm,
            compact ? AppSpacing.sm : AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (openDrawer != null) ...[
                    IconButton(
                      onPressed: openDrawer,
                      icon: const Icon(Icons.menu_rounded),
                      color: AdminTheme.accentLight,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 2),
                  ],
                  GradientIconBadge(
                    icon: icon,
                    size: compact ? 36 : 46,
                    gradient: AdminGradients.cobaltMetallic,
                    iconColor: AppColors.textPrimary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          eyebrow,
                          style: textTheme.labelSmall?.copyWith(
                            color: AdminTheme.accentLight,
                            letterSpacing: AppLetterSpacing.caps,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: (compact ? textTheme.titleLarge : textTheme.headlineSmall)
                              ?.copyWith(fontFamily: 'Libre Caslon Display'),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(width: AppSpacing.md),
                    IconTheme.merge(
                      data: const IconThemeData(color: AdminTheme.accentLight),
                      child: Row(mainAxisSize: MainAxisSize.min, children: actions),
                    ),
                  ],
                ],
              ),
              if (bottom != null) ...[
                const SizedBox(height: AppSpacing.md),
                bottom!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
