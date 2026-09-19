import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';

/// Signale qu'une notice documentaire renvoie à une source externe et que le
/// texte de cette source n'est pas reproduit dans l'application.
///
/// [compact] : pastille discrète pour les cartes de résultat.
/// Sinon : bandeau explicite pour la vue détaillée.
class SummaryOnlyBadge extends StatelessWidget {
  const SummaryOnlyBadge({super.key, this.compact = false});

  final bool compact;

  static const _accent = AppColors.warning;
  static const _label = 'Référence documentaire';
  static const _tooltip =
      'Cette fiche présente une référence, un plan de lecture et un lien vers '
      'la source. Le contenu complet JurisIA est disponible dans les cours '
      'portant le label « contenu JurisIA ». ';

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
              const Icon(Icons.menu_book_outlined, size: 11, color: _accent),
              const SizedBox(width: 4),
              Text(
                'Référence',
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
          const Icon(Icons.menu_book_outlined, size: 17, color: _accent),
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
                  'Cette notice présente la source, son plan et le lien officiel '
                  'sans reproduire le document externe. Consultez les cours '
                  'originaux JurisIA pour le contenu pédagogique complet.',
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
