import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';

/// Signale qu'un document ne contient pour l'instant qu'une **synthèse**
/// (résumé + plan du texte + lien vers la source officielle) et non le
/// texte intégral article par article, qui sera intégré progressivement
/// par le pipeline d'import.
///
/// [compact] : pastille discrète pour les cartes de résultat.
/// Sinon : bandeau explicite pour la vue détaillée.
class SummaryOnlyBadge extends StatelessWidget {
  const SummaryOnlyBadge({super.key, this.compact = false});

  final bool compact;

  static const _accent = AppColors.warning;
  static const _label = 'Résumé — texte intégral à venir';
  static const _tooltip =
      'Seule une synthèse est disponible pour ce texte (résumé, plan et lien '
      'vers la source officielle). Le texte intégral, article par article, '
      'sera ajouté prochainement.';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (compact) {
      return Tooltip(
        message: _tooltip,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: _accent.withValues(alpha: 0.45), width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hourglass_bottom_rounded, size: 11, color: _accent),
              const SizedBox(width: 4),
              Text(
                'Résumé',
                style: textTheme.labelSmall?.copyWith(
                  color: _accent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: _accent.withValues(alpha: 0.40), width: 0.9),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.hourglass_bottom_rounded, size: 17, color: _accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _label,
                  style: textTheme.labelLarge?.copyWith(
                    color: _accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Cette fiche présente une synthèse du texte, son plan et le lien '
                  'vers la source officielle. Les articles seront intégrés '
                  'progressivement.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
