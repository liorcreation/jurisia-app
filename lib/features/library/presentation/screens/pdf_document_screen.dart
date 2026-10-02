import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/glass_container.dart';
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
            'Visionneuse PDF',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (pdfUrl != null)
              IconButton(
                tooltip: 'Ouvrir le PDF dans un nouvel onglet',
                icon: const Icon(Icons.open_in_new_rounded),
                onPressed: () =>
                    launchUrl(Uri.parse(pdfUrl!), webOnlyWindowName: '_blank'),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _PdfDocumentToolbar(document: document),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.lg,
                  ),
                  child: pdfUrl == null
                      ? _PdfUnavailable(document: document)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.22),
                              ),
                              borderRadius: BorderRadius.circular(
                                AppRadius.medium,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.nightBlueDeep.withValues(
                                    alpha: 0.42,
                                  ),
                                  blurRadius: 28,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: PdfDocumentSurface(url: pdfUrl!),
                          ),
                        ),
                ),
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
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.nightBlueDeep.withValues(alpha: 0.96),
            AppColors.legalBlueDark.withValues(alpha: 0.7),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.gold.withValues(alpha: 0.2)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 640;
          final identity = Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppGradients.goldMetallic,
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppColors.nightBlueDeep,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LECTURE PDF',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.goldLight,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      document.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final source = Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_rounded,
                  size: 13,
                  color: AppColors.success,
                ),
                const SizedBox(width: 5),
                Text(
                  document.officialSourceName ?? 'Source JurisIA',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
          return compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    identity,
                    const SizedBox(height: AppSpacing.sm),
                    source,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: identity),
                    const SizedBox(width: AppSpacing.md),
                    Flexible(child: source),
                  ],
                );
        },
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
        child: GlassContainer(
          borderColor: AppColors.gold.withValues(alpha: 0.22),
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
