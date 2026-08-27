import 'package:flutter/material.dart';

import '../../widgets/glass_container.dart';
import '../../widgets/tap_scale.dart';
import '../../../theme/app_theme.dart';

/// Habillage commun des sections contextuelles de la sidebar (hors
/// historique Litiges) : un titre en capitales espacées, puis les lignes.
class SidebarSection extends StatelessWidget {
  const SidebarSection({super.key, required this.title, required this.children, this.action});

  final String title;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.sm, AppSpacing.xs),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textDisabled,
                        fontWeight: FontWeight.w700,
                        letterSpacing: AppLetterSpacing.caps,
                      ),
                ),
              ),
              ?action,
            ],
          ),
        ),
        ...children,
      ],
    );
  }
}

/// Une ligne cliquable compacte d'une section contextuelle.
class SidebarSectionTile extends StatelessWidget {
  const SidebarSectionTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 3),
      child: TapScale(
        child: GlassContainer(
          onTap: onTap,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.gold),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall,
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall,
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// État vide discret d'une section contextuelle.
class SidebarSectionEmpty extends StatelessWidget {
  const SidebarSectionEmpty(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
