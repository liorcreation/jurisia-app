import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// Habillage commun des sections contextuelles de la sidebar (hors
/// historique Litiges) : un intitulé de groupe en petites capitales, puis
/// des lignes légères — la grammaire ChatGPT / Claude, sans carte de verre
/// par ligne (plus léger à faire défiler, moins de bruit visuel).
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
        SidebarGroupLabel(title, action: action),
        ...children,
      ],
    );
  }
}

/// Intitulé de groupe partagé par toutes les sections de la sidebar
/// (« Espaces », « Aujourd'hui », « Favoris »…) — un seul traitement pour
/// que la colonne se lise d'un bloc.
class SidebarGroupLabel extends StatelessWidget {
  const SidebarGroupLabel(this.text, {super.key, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.sm, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textDisabled,
                    fontWeight: FontWeight.w700,
                    letterSpacing: AppLetterSpacing.caps,
                    fontSize: 10.5,
                  ),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Une ligne cliquable compacte d'une section contextuelle : icône dorée,
/// titre (et sous-titre optionnel), fond qui se révèle au survol.
class SidebarSectionTile extends StatefulWidget {
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
  State<SidebarSectionTile> createState() => _SidebarSectionTileState();
}

class _SidebarSectionTileState extends State<SidebarSectionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 1),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 8, AppSpacing.sm, 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.medium),
                color: _hovered
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.transparent,
              ),
              child: Row(
                children: [
                  Icon(widget.icon, size: 15, color: AppColors.gold),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(fontSize: 13),
                        ),
                        if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 1),
                          Text(
                            widget.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelSmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  ?widget.trailing,
                ],
              ),
            ),
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
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(height: 1.4),
      ),
    );
  }
}
