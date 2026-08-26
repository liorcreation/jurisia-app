import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/luxury_scaffold_background.dart';
import '../../../../models/legal_document/legal_document_model.dart';
import '../../../../theme/app_theme.dart';
import '../controllers/library_controller.dart';
import '../widgets/document_category_badge.dart';
import '../widgets/document_tag.dart';

const _months = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

String _formatDate(DateTime date) => '${date.day} ${_months[date.month - 1]} ${date.year}';

/// Visionneuse plein écran d'un document juridique : typographie sérif
/// haute lisibilité pour le texte intégral, copie, téléchargement et
/// bascule en favori.
class DocumentDetailScreen extends StatelessWidget {
  const DocumentDetailScreen({super.key, required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LibraryController>();
    final document = controller.documentById(documentId);

    if (document == null) {
      return LuxuryScaffoldBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(),
          body: Center(
            child: Text('Document introuvable.', style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      );
    }

    final readingStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontFamily: 'Lora',
      color: AppColors.textPrimary,
      height: 1.9,
      fontSize: 16.5,
    );

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(document.type.label),
          actions: [
            IconButton(
              tooltip: document.isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
              icon: Icon(
                document.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                color: AppColors.gold,
              ),
              onPressed: () => controller.toggleBookmark(document.id),
            ),
            IconButton(
              tooltip: 'Copier le texte',
              icon: const Icon(Icons.copy_rounded),
              onPressed: () => _copyText(
                context,
                document.fullContent,
                snackBarMessage: 'Texte copié dans le presse-papiers.',
              ),
            ),
            IconButton(
              tooltip: 'Télécharger',
              icon: const Icon(Icons.download_rounded),
              onPressed: () {
                controller.recordDownload(document.id);
                _copyText(
                  context,
                  document.fullContent,
                  snackBarMessage: 'Document copié : collez-le dans un fichier pour le conserver.',
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  GlassContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DocumentCategoryBadge(type: document.type),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    document.title,
                                    style: Theme.of(context).textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(document.reference, style: Theme.of(context).textTheme.bodyMedium),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            DocumentTag(label: document.type.label),
                            DocumentTag(label: document.domain.label),
                            DocumentTag(label: _formatDate(document.datePublication)),
                            for (final tag in document.tags) DocumentTag(label: tag),
                          ],
                        ),
                        if (document.summary.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            document.summary,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  GlassContainer(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: SelectableText(
                      document.fullContent.isNotEmpty
                          ? document.fullContent
                          : "Le texte intégral de ce document n'est pas encore disponible.",
                      style: readingStyle,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _copyText(BuildContext context, String content, {required String snackBarMessage}) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(snackBarMessage)));
  }
}
