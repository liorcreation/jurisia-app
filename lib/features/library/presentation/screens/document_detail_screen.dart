import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/platform/app_platform_style.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/luxury_scaffold_background.dart';
import '../../../../core/widgets/shimmer_sweep.dart';
import '../../../../core/widgets/tap_scale.dart';
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

int _wordCount(String text) =>
    text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

List<String> _paragraphs(String text) => text
    .trim()
    .split(RegExp(r'\n\s*\n'))
    .map((p) => p.trim())
    .where((p) => p.isNotEmpty)
    .toList();

void _copyToClipboard(BuildContext context, String content, {required String message}) {
  Clipboard.setData(ClipboardData(text: content));
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// Visionneuse d'un document juridique : sur desktop, une véritable édition —
/// en-tête avec la barre de progression de lecture, lettrine sur le premier
/// paragraphe, colonne de lecture en sérif ample, et une fiche latérale
/// (métadonnées, actions, textes à rapprocher). Le fil vertical sobre est
/// conservé sur mobile.
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

    if (AppPlatformStyle.of(context) == AppPlatformStyle.desktop) {
      return _DesktopReader(document: document, controller: controller);
    }

    return _MobileReader(document: document, controller: controller);
  }
}

// ===========================================================================
//  DESKTOP — « l'édition »
// ===========================================================================

class _DesktopReader extends StatefulWidget {
  const _DesktopReader({required this.document, required this.controller});

  final LegalDocument document;
  final LibraryController controller;

  @override
  State<_DesktopReader> createState() => _DesktopReaderState();
}

class _DesktopReaderState extends State<_DesktopReader> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _openRelated(String id) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<LibraryController>.value(
          value: widget.controller,
          child: DocumentDetailScreen(documentId: id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;
    final related = [
      for (final id in doc.relatedDocumentIds)
        if (widget.controller.documentById(id) != null) widget.controller.documentById(id)!,
    ];

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(child: IgnorePointer(child: _ReaderGlow())),
              Column(
                children: [
                  _ReadingProgress(controller: _scroll),
                  _ReaderHeader(
                    document: doc,
                    isFavorite: doc.isFavorite,
                    onBack: () => Navigator.of(context).maybePop(),
                    onToggleFavorite: () => widget.controller.toggleBookmark(doc.id),
                    onCopy: () => _copyToClipboard(
                      context,
                      doc.fullContent,
                      message: 'Texte copié dans le presse-papiers.',
                    ),
                    onDownload: () {
                      widget.controller.recordDownload(doc.id);
                      _copyToClipboard(
                        context,
                        doc.fullContent,
                        message: 'Document copié : collez-le dans un fichier pour le conserver.',
                      );
                    },
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 1060;

                        final reading = SingleChildScrollView(
                          controller: _scroll,
                          padding: wide
                              ? const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xl, AppSpacing.lg, AppSpacing.xxl)
                              : const EdgeInsets.all(AppSpacing.xl),
                          child: Align(
                            alignment: wide ? Alignment.topLeft : Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: wide ? 740 : 800),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _DocumentHero(document: doc),
                                  const SizedBox(height: AppSpacing.xl),
                                  if (!wide) ...[
                                    _FactSheet(document: doc),
                                    const SizedBox(height: AppSpacing.md),
                                    _ActionStack(
                                      isFavorite: doc.isFavorite,
                                      sourceUrl: doc.sourceUrl,
                                      onToggleFavorite: () => widget.controller.toggleBookmark(doc.id),
                                      onCopy: () => _copyToClipboard(context, doc.fullContent,
                                          message: 'Texte copié dans le presse-papiers.'),
                                      onDownload: () {
                                        widget.controller.recordDownload(doc.id);
                                        _copyToClipboard(context, doc.fullContent,
                                            message: 'Document copié : collez-le dans un fichier.');
                                      },
                                    ),
                                    const SizedBox(height: AppSpacing.xl),
                                  ],
                                  _ReadingBody(content: doc.fullContent),
                                  if (!wide && related.isNotEmpty) ...[
                                    const SizedBox(height: AppSpacing.xxl),
                                    _RelatedDocs(documents: related, onOpen: _openRelated),
                                  ],
                                  const SizedBox(height: AppSpacing.xxl),
                                ],
                              ),
                            ),
                          ),
                        );

                        if (!wide) return reading;

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: reading),
                            SizedBox(
                              width: 352,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(0, AppSpacing.xl, AppSpacing.lg, AppSpacing.xxl),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _FactSheet(document: doc),
                                    const SizedBox(height: AppSpacing.md),
                                    _ActionStack(
                                      isFavorite: doc.isFavorite,
                                      sourceUrl: doc.sourceUrl,
                                      onToggleFavorite: () => widget.controller.toggleBookmark(doc.id),
                                      onCopy: () => _copyToClipboard(context, doc.fullContent,
                                          message: 'Texte copié dans le presse-papiers.'),
                                      onDownload: () {
                                        widget.controller.recordDownload(doc.id);
                                        _copyToClipboard(context, doc.fullContent,
                                            message: 'Document copié : collez-le dans un fichier.');
                                      },
                                    ),
                                    if (related.isNotEmpty) ...[
                                      const SizedBox(height: AppSpacing.lg),
                                      _RelatedDocs(documents: related, onOpen: _openRelated),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barre de progression de lecture — un filet d'or qui avance au fil du
/// défilement, en tête de la visionneuse.
class _ReadingProgress extends StatefulWidget {
  const _ReadingProgress({required this.controller});

  final ScrollController controller;

  @override
  State<_ReadingProgress> createState() => _ReadingProgressState();
}

class _ReadingProgressState extends State<_ReadingProgress> {
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  void _update() {
    if (!widget.controller.hasClients) return;
    final max = widget.controller.position.maxScrollExtent;
    final value = max <= 0 ? 0.0 : (widget.controller.offset / max).clamp(0.0, 1.0);
    if ((value - _progress).abs() > 0.001) setState(() => _progress = value);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2.5,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: _progress <= 0 ? 0.0001 : _progress,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppGradients.goldSheen,
              boxShadow: [
                BoxShadow(color: AppColors.gold.withValues(alpha: 0.5), blurRadius: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReaderHeader extends StatelessWidget {
  const _ReaderHeader({
    required this.document,
    required this.isFavorite,
    required this.onBack,
    required this.onToggleFavorite,
    required this.onCopy,
    required this.onDownload,
  });

  final LegalDocument document;
  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onToggleFavorite;
  final VoidCallback onCopy;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.smokedGlass,
        border: Border(
          bottom: BorderSide(color: AppColors.gold.withValues(alpha: 0.18), width: 0.6),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          _RoundIcon(icon: Icons.arrow_back_rounded, tooltip: 'Retour à la bibliothèque', onTap: onBack),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    'Bibliothèque',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelMedium?.copyWith(color: AppColors.textDisabled),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 15, color: AppColors.textDisabled),
                Flexible(
                  child: Text(
                    document.type.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.goldLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _RoundIcon(
            icon: isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
            tooltip: isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
            active: isFavorite,
            onTap: onToggleFavorite,
          ),
          const SizedBox(width: 6),
          _RoundIcon(icon: Icons.copy_rounded, tooltip: 'Copier le texte', onTap: onCopy),
          const SizedBox(width: 6),
          _RoundIcon(icon: Icons.download_rounded, tooltip: 'Télécharger', onTap: onDownload),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: TapScale(
        child: Material(
          color: active
              ? AppColors.gold.withValues(alpha: 0.18)
              : AppColors.legalBlueDark.withValues(alpha: 0.5),
          shape: CircleBorder(
            side: BorderSide(
              color: active ? AppColors.gold.withValues(alpha: 0.6) : AppColors.glassBorder,
              width: 0.6,
            ),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Icon(icon, size: 18, color: active ? AppColors.goldLight : AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentHero extends StatelessWidget {
  const _DocumentHero({required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final words = _wordCount(document.fullContent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 66,
          height: 66,
          child: Stack(
            alignment: Alignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.gold.withValues(alpha: 0.28),
                      AppColors.gold.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: const SizedBox.expand(),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.small),
                child: ShimmerSweep(
                  duration: const Duration(milliseconds: 4200),
                  child: DocumentCategoryBadge(type: document.type, size: 58),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          document.title,
          style: textTheme.displaySmall?.copyWith(height: 1.12),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          document.reference,
          style: textTheme.titleSmall?.copyWith(
            color: AppColors.goldLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: 60,
          height: 2,
          decoration: BoxDecoration(
            gradient: AppGradients.goldSheen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        if (document.summary.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            document.summary,
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: 6,
          children: [
            _MetaItem(icon: Icons.event_rounded, label: 'Publié le ${_formatDate(document.datePublication)}'),
            if (document.dateEntreeEnVigueur != null)
              _MetaItem(
                icon: Icons.play_circle_outline_rounded,
                label: 'En vigueur depuis le ${_formatDate(document.dateEntreeEnVigueur!)}',
              ),
            _MetaItem(icon: Icons.balance_rounded, label: document.domain.label),
            if (words > 0)
              _MetaItem(icon: Icons.notes_rounded, label: '≈ ${_thousands(words)} mots'),
          ],
        ),
      ],
    );
  }

  static String _thousands(int value) {
    final s = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textDisabled),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// Le corps du texte : sérif ample, paragraphes justifiés, lettrine dorée
/// sur le premier paragraphe.
class _ReadingBody extends StatelessWidget {
  const _ReadingBody({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final readingStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontFamily: 'Lora',
          color: AppColors.textPrimary,
          height: 1.9,
          fontSize: 17,
        );

    final paragraphs = _paragraphs(content);
    if (paragraphs.isEmpty) {
      return Text(
        "Le texte intégral de ce document n'est pas encore disponible.",
        style: readingStyle?.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < paragraphs.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md + 2),
          if (i == 0)
            _DropCapParagraph(text: paragraphs[0], style: readingStyle)
          else
            SelectableText(
              paragraphs[i],
              textAlign: TextAlign.justify,
              style: readingStyle,
            ),
        ],
      ],
    );
  }
}

class _DropCapParagraph extends StatelessWidget {
  const _DropCapParagraph({required this.text, required this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final initial = text.isEmpty ? '' : text.substring(0, 1);
    final rest = text.length > 1 ? text.substring(1) : '';

    return SelectableText.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Transform.translate(
              offset: const Offset(0, 6),
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontFamily: 'Libre Caslon Display',
                    fontWeight: FontWeight.w700,
                    fontSize: 50,
                    height: 0.9,
                    color: AppColors.gold,
                    shadows: [
                      Shadow(color: Color(0x55C9A227), blurRadius: 14),
                    ],
                  ),
                ),
              ),
            ),
          ),
          TextSpan(text: rest, style: style),
        ],
      ),
      textAlign: TextAlign.justify,
    );
  }
}

class _FactSheet extends StatelessWidget {
  const _FactSheet({required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _MiniLabel('Fiche du texte'),
          const SizedBox(height: AppSpacing.md),
          _FactRow(label: 'Catégorie', value: document.type.label),
          _FactRow(label: 'Branche', value: document.domain.label),
          _FactRow(label: 'Référence', value: document.reference),
          _FactRow(label: 'Publication', value: _formatDate(document.datePublication)),
          if (document.dateEntreeEnVigueur != null)
            _FactRow(label: 'Entrée en vigueur', value: _formatDate(document.dateEntreeEnVigueur!)),
          if (document.viewCount > 0)
            _FactRow(label: 'Consultations', value: '${document.viewCount}'),
          if (document.tags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1, thickness: 0.6),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 6,
              runSpacing: 5,
              children: [for (final tag in document.tags) DocumentTag(label: tag)],
            ),
          ],
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(
              label,
              style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodySmall?.copyWith(color: AppColors.textPrimary, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionStack extends StatelessWidget {
  const _ActionStack({
    required this.isFavorite,
    required this.sourceUrl,
    required this.onToggleFavorite,
    required this.onCopy,
    required this.onDownload,
  });

  final bool isFavorite;
  final String? sourceUrl;
  final VoidCallback onToggleFavorite;
  final VoidCallback onCopy;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActionButton(
          icon: isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
          label: isFavorite ? 'Dans vos favoris' : 'Ajouter aux favoris',
          filled: isFavorite,
          onTap: onToggleFavorite,
        ),
        const SizedBox(height: 8),
        _ActionButton(icon: Icons.copy_rounded, label: 'Copier le texte', onTap: onCopy),
        const SizedBox(height: 8),
        _ActionButton(icon: Icons.download_rounded, label: 'Télécharger', onTap: onDownload),
        if (sourceUrl != null && sourceUrl!.isNotEmpty) ...[
          const SizedBox(height: 8),
          _ActionButton(
            icon: Icons.open_in_new_rounded,
            label: 'Source officielle',
            onTap: () => launchUrl(Uri.parse(sourceUrl!), webOnlyWindowName: '_blank'),
          ),
        ],
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final filled = widget.filled;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              gradient: filled ? AppGradients.goldMetallic : null,
              color: filled
                  ? null
                  : _hovered
                      ? AppColors.gold.withValues(alpha: 0.12)
                      : AppColors.legalBlueDark.withValues(alpha: 0.5),
              border: Border.all(
                color: filled ? Colors.transparent : AppColors.gold.withValues(alpha: 0.5),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 15,
                  color: filled ? AppColors.nightBlueDeep : AppColors.goldLight,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: filled ? AppColors.nightBlueDeep : AppColors.goldLight,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RelatedDocs extends StatelessWidget {
  const _RelatedDocs({required this.documents, required this.onOpen});

  final List<LegalDocument> documents;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _MiniLabel('À rapprocher de'),
        const SizedBox(height: AppSpacing.sm),
        for (final doc in documents)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: GlassContainer(
              onTap: () => onOpen(doc.id),
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              child: Row(
                children: [
                  DocumentCategoryBadge(type: doc.type, size: 34),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          doc.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(fontSize: 12.5, height: 1.2),
                        ),
                        Text(
                          doc.type.label,
                          style: textTheme.labelSmall?.copyWith(color: AppColors.goldLight),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MiniLabel extends StatelessWidget {
  const _MiniLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 1.5,
          decoration: BoxDecoration(
            gradient: AppGradients.goldSheen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textDisabled,
                fontWeight: FontWeight.w700,
                letterSpacing: AppLetterSpacing.caps,
                fontSize: 10.5,
              ),
        ),
      ],
    );
  }
}

/// Une lueur d'or qui dérive très lentement derrière le texte — le souffle
/// vivant de la visionneuse, sans jamais gêner la lecture.
class _ReaderGlow extends StatefulWidget {
  const _ReaderGlow();

  @override
  State<_ReaderGlow> createState() => _ReaderGlowState();
}

class _ReaderGlowState extends State<_ReaderGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 26))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(painter: _GlowPainter(_controller.value)),
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = t * 2 * math.pi;
    final center = Offset(
      size.width * (0.24 + 0.1 * math.sin(phase)),
      size.height * (0.32 + 0.24 * math.sin(phase * 0.5)),
    );
    final radius = size.shortestSide * 0.7;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.06),
            AppColors.gold.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) => oldDelegate.t != t;
}

// ===========================================================================
//  MOBILE — le fil vertical sobre
// ===========================================================================

class _MobileReader extends StatelessWidget {
  const _MobileReader({required this.document, required this.controller});

  final LegalDocument document;
  final LibraryController controller;

  @override
  Widget build(BuildContext context) {
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
            TapScale(
              child: IconButton(
                tooltip: document.isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                icon: Icon(
                  document.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                  color: AppColors.gold,
                ),
                onPressed: () => controller.toggleBookmark(document.id),
              ),
            ),
            IconButton(
              tooltip: 'Copier le texte',
              icon: const Icon(Icons.copy_rounded),
              onPressed: () => _copyToClipboard(
                context,
                document.fullContent,
                message: 'Texte copié dans le presse-papiers.',
              ),
            ),
            IconButton(
              tooltip: 'Télécharger',
              icon: const Icon(Icons.download_rounded),
              onPressed: () {
                controller.recordDownload(document.id);
                _copyToClipboard(
                  context,
                  document.fullContent,
                  message: 'Document copié : collez-le dans un fichier pour le conserver.',
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
                                  Text(document.title, style: Theme.of(context).textTheme.headlineSmall),
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
}
