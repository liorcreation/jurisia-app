import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/luxury_scaffold_background.dart';
import '../../../../models/legal_document/legal_document_model.dart';
import '../../../../theme/app_theme.dart';
import '../widgets/pdf_document_surface.dart';

String? pdfUrlForDocument(LegalDocument document) {
  final fileUrl = document.fileUrl?.trim();
  if (fileUrl != null && fileUrl.isNotEmpty) return fileUrl;

  final sourceUrl = document.sourceUrl?.trim();
  if (sourceUrl == null || sourceUrl.isEmpty) return null;
  final withoutQuery = sourceUrl.toLowerCase().split('?').first;
  return withoutQuery.endsWith('.pdf') ? sourceUrl : null;
}

/// Visionneuse PDF dédiée à la bibliothèque : le document occupe la scène
/// principale, avec une barre de lecture premium et un accès source séparé.
class PdfDocumentScreen extends StatelessWidget {
  const PdfDocumentScreen({
    super.key,
    required this.document,
    required this.pdfUrl,
  });

  final LegalDocument document;
  final String? pdfUrl;

  @override
  Widget build(BuildContext context) {
    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Retour',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            document.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (pdfUrl != null)
              IconButton(
                tooltip: 'Ouvrir le PDF dans un nouvel onglet',
                icon: const Icon(Icons.open_in_new_rounded),
                onPressed: () => launchUrl(
                  Uri.parse(pdfUrl!),
                  webOnlyWindowName: '_blank',
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _PdfDocumentToolbar(document: document),
              Expanded(
                child: pdfUrl == null
                    ? _PdfUnavailable(document: document)
                    : PdfDocumentSurface(url: pdfUrl!),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PdfDocumentToolbar extends StatelessWidget {
  const _PdfDocumentToolbar({required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.nightBlueDeep.withValues(alpha: 0.88),
        border: Border(
          bottom: BorderSide(color: AppColors.gold.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.picture_as_pdf_rounded,
            color: AppColors.gold,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'DOCUMENT PDF',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.gold,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const Spacer(),
          Text(
            document.officialSourceName ?? 'Bibliothèque JurisIA',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textDisabled,
                ),
          ),
        ],
      ),
    );
  }
}

class _PdfUnavailable extends StatelessWidget {
  const _PdfUnavailable({required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.picture_as_pdf_outlined,
                size: 52,
                color: AppColors.textDisabled,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'PDF non encore rattaché',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Le document « ${document.title} » est bien classé dans son pack, mais son fichier PDF doit être publié dans le stockage documentaire de JurisIA.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

