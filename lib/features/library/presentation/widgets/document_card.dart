import 'package:flutter/material.dart';

import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../models/legal_document/legal_document_model.dart';
import '../../../../theme/app_theme.dart';
import 'document_category_badge.dart';
import 'document_tag.dart';

/// Carte de résultat de recherche : style glassmorphism, badge de catégorie
/// doré, référence et bouton de mise en favori rapide.
class LibraryDocumentCard extends StatelessWidget {
  const LibraryDocumentCard({
    super.key,
    required this.document,
    required this.onToggleFavorite,
    required this.onTap,
  });

  final LegalDocument document;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassContainer(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DocumentCategoryBadge(type: document.type),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(document.title, style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    DocumentTag(label: document.type.label),
                    DocumentTag(label: document.domain.label),
                    DocumentTag(label: document.reference),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  document.summary,
                  style: textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TapScale(
            child: IconButton(
              tooltip: document.isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
              icon: Icon(
                document.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                color: AppColors.gold,
              ),
              onPressed: onToggleFavorite,
            ),
          ),
        ],
      ),
    );
  }
}
