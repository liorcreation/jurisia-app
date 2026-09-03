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
import '../widgets/summary_only_badge.dart';

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
  late final List<GlobalKey> _articleKeys;
  int _activeArticle = 0;

  @override
  void initState() {
    super.initState();
    _articleKeys = List.generate(widget.document.articles.length, (_) => GlobalKey());
    if (widget.document.isStructured) _scroll.addListener(_trackActiveArticle);
  }

  @override
  void dispose() {
    _scroll.removeListener(_trackActiveArticle);
    _scroll.dispose();
    super.dispose();
  }

  void _trackActiveArticle() {
    if (!_scroll.hasClients) return;
    var current = 0;
    for (var i = 0; i < _articleKeys.length; i++) {
      final ctx = _articleKeys[i].currentContext;
      final box = ctx?.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final dy = box.localToGlobal(Offset.zero).dy;
      if (dy <= 220) current = i;
    }
    if (current != _activeArticle) setState(() => _activeArticle = current);
  }

  void _scrollToArticle(int index) {
    final ctx = _articleKeys[index].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 320),
      curve: Curves.fastOutSlowIn,
      alignment: 0.06,
    );
  }

  /// Texte plein assemblé (prose ou articles concaténés) pour la copie / le
  /// « téléchargement ».
  String get _assembledText {
    final doc = widget.document;
    if (doc.fullContent.trim().isNotEmpty) return doc.fullContent;
    if (doc.articles.isEmpty) return '';
    return doc.articles.map((a) {
      final head = a.heading.isEmpty ? '' : ' — ${a.heading}';
      return 'Article ${a.number}$head\n${a.text}';
    }).join('\n\n');
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

  void _openSource() {
    final url = widget.document.sourceUrl;
    if (url != null && url.isNotEmpty) {
      launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;
    final structured = doc.isStructured;
    final hasProse = !structured && doc.fullContent.trim().isNotEmpty;
    final copyText = _assembledText;
    final related = [
      for (final id in doc.relatedDocumentIds)
        if (widget.controller.documentById(id) != null) widget.controller.documentById(id)!,
    ];

    void doCopy() => _copyToClipboard(context, copyText, message: 'Texte copié dans le presse-papiers.');
    void doDownload() {
      widget.controller.recordDownload(doc.id);
      _copyToClipboard(context, copyText, message: 'Document copié : collez-le dans un fichier pour le conserver.');
    }

    final actions = _ActionStack(
      isFavorite: doc.isFavorite,
      sourceUrl: doc.sourceUrl,
      sourceName: doc.officialSourceName,
      onToggleFavorite: () => widget.controller.toggleBookmark(doc.id),
      onCopy: copyText.isEmpty ? null : doCopy,
      onDownload: copyText.isEmpty ? null : doDownload,
    );

    final Widget body = structured
        ? _ArticleList(articles: doc.articles, itemKeys: _articleKeys)
        : hasProse
            ? _ReadingBody(content: doc.fullContent)
            : _OutlineFallback(document: doc, onSource: _openSource);

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
                    canCopy: copyText.isNotEmpty,
                    onBack: () => Navigator.of(context).maybePop(),
                    onToggleFavorite: () => widget.controller.toggleBookmark(doc.id),
                    onCopy: doCopy,
                    onDownload: doDownload,
                    onSource: doc.sourceUrl != null ? _openSource : null,
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 1060;
                        // Colonne principale : entête, fiche + actions quand
                        // elles ne sont pas dans un rail, puis le corps.
                        final railHoldsFacts = wide && !structured;
                        final showFactsInline = !railHoldsFacts;

                        final mainColumn = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DocumentHero(document: doc),
                            if (doc.awaitingFullText) ...[
                              const SizedBox(height: AppSpacing.lg),
                              const SummaryOnlyBadge(),
                            ],
                            const SizedBox(height: AppSpacing.xl),
                            if (showFactsInline) ...[
                              _FactSheet(document: doc),
                              // Sur un texte structuré, les actions vivent
                              // dans l'en-tête ; inutile de les répéter ici.
                              if (!structured) ...[
                                const SizedBox(height: AppSpacing.md),
                                actions,
                              ],
                              const SizedBox(height: AppSpacing.xl),
                            ],
                            if (structured && !wide) ...[
                              _SommairePanel(
                                articles: doc.articles,
                                active: _activeArticle,
                                onTap: _scrollToArticle,
                              ),
                              const SizedBox(height: AppSpacing.xl),
                            ],
                            body,
                            if (showFactsInline && related.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xxl),
                              _RelatedDocs(documents: related, onOpen: _openRelated),
                            ],
                            const SizedBox(height: AppSpacing.xxl),
                          ],
                        );

                        final scroller = SingleChildScrollView(
                          controller: _scroll,
                          padding: wide
                              ? EdgeInsets.fromLTRB(
                                  structured ? AppSpacing.xl : AppSpacing.xxl,
                                  AppSpacing.xl,
                                  AppSpacing.lg,
                                  AppSpacing.xxl,
                                )
                              : const EdgeInsets.all(AppSpacing.xl),
                          child: Align(
                            alignment: wide ? Alignment.topLeft : Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: wide ? (structured ? 720 : 740) : 800),
                              child: mainColumn,
                            ),
                          ),
                        );

                        if (!wide) return scroller;

                        if (structured) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 300,
                                child: _SommaireRail(
                                  articles: doc.articles,
                                  active: _activeArticle,
                                  onTap: _scrollToArticle,
                                ),
                              ),
                              Expanded(child: scroller),
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: scroller),
                            SizedBox(
                              width: 352,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(0, AppSpacing.xl, AppSpacing.lg, AppSpacing.xxl),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _FactSheet(document: doc),
                                    const SizedBox(height: AppSpacing.md),
                                    actions,
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
    required this.canCopy,
    required this.onBack,
    required this.onToggleFavorite,
    required this.onCopy,
    required this.onDownload,
    this.onSource,
  });

  final LegalDocument document;
  final bool isFavorite;
  final bool canCopy;
  final VoidCallback onBack;
  final VoidCallback onToggleFavorite;
  final VoidCallback onCopy;
  final VoidCallback onDownload;
  final VoidCallback? onSource;

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
          if (onSource != null) ...[
            const SizedBox(width: 6),
            _RoundIcon(icon: Icons.open_in_new_rounded, tooltip: 'Source officielle', onTap: onSource),
          ],
          if (canCopy) ...[
            const SizedBox(width: 6),
            _RoundIcon(icon: Icons.copy_rounded, tooltip: 'Copier le texte', onTap: onCopy),
            const SizedBox(width: 6),
            _RoundIcon(icon: Icons.download_rounded, tooltip: 'Télécharger', onTap: onDownload),
          ],
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
  final VoidCallback? onTap;
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
            if (document.isStructured)
              _MetaItem(
                icon: Icons.format_list_numbered_rounded,
                label: '${document.articles.length} article${document.articles.length > 1 ? "s" : ""}',
              )
            else if (words > 0)
              _MetaItem(icon: Icons.notes_rounded, label: '≈ ${_thousands(words)} mots'),
            if (document.status != LegalDocumentStatus.enVigueur)
              _MetaItem(icon: Icons.gavel_rounded, label: document.status.label),
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

// --- Texte structuré : articles + sommaire -------------------------------

TextStyle? _articleReadingStyle(BuildContext context) =>
    Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontFamily: 'Lora',
          color: AppColors.textPrimary,
          height: 1.85,
          fontSize: 16.5,
        );

/// Renvoie les segments de [current] qui n'apparaissent pas dans [previous]
/// (nouveaux titres de division à afficher au-dessus de l'article).
List<String> _newDivisions(List<String> previous, List<String> current) {
  final result = <String>[];
  for (var i = 0; i < current.length; i++) {
    if (i >= previous.length || previous[i] != current[i]) {
      result.addAll(current.sublist(i));
      break;
    }
  }
  return result;
}

class _ArticleList extends StatelessWidget {
  const _ArticleList({required this.articles, required this.itemKeys});

  final List<LegalArticle> articles;
  final List<GlobalKey> itemKeys;

  @override
  Widget build(BuildContext context) {
    final reading = _articleReadingStyle(context);
    final children = <Widget>[];
    var previousPath = const <String>[];

    for (var i = 0; i < articles.length; i++) {
      final divisions = _newDivisions(previousPath, articles[i].path);
      for (var d = 0; d < divisions.length; d++) {
        children.add(_DivisionHeading(divisions[d], isFirst: i == 0 && d == 0));
      }
      children.add(
        KeyedSubtree(
          key: itemKeys[i],
          child: Padding(
            padding: EdgeInsets.only(top: i == 0 && divisions.isEmpty ? 0 : AppSpacing.xl),
            child: _ArticleBlock(article: articles[i], readingStyle: reading),
          ),
        ),
      );
      previousPath = articles[i].path;
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}

class _DivisionHeading extends StatelessWidget {
  const _DivisionHeading(this.text, {this.isFirst = false});

  final String text;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 0 : AppSpacing.xxl, bottom: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  height: 1.3,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 52,
            height: 1.5,
            decoration: BoxDecoration(
              gradient: AppGradients.goldSheen,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleBlock extends StatelessWidget {
  const _ArticleBlock({required this.article, required this.readingStyle});

  final LegalArticle article;
  final TextStyle? readingStyle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.small),
                color: AppColors.gold.withValues(alpha: 0.13),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.45), width: 0.7),
              ),
              child: Text(
                'Art. ${article.number}',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (article.heading.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    article.heading,
                    style: textTheme.titleSmall?.copyWith(
                      fontFamily: 'Libre Caslon Display',
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SelectableText(article.text, textAlign: TextAlign.justify, style: readingStyle),
      ],
    );
  }
}

/// Sommaire en rail latéral (desktop large) avec surlignage de l'article
/// courant.
class _SommaireRail extends StatelessWidget {
  const _SommaireRail({required this.articles, required this.active, required this.onTap});

  final List<LegalArticle> articles;
  final int active;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.sm, AppSpacing.xxl),
      child: _SommaireBody(articles: articles, active: active, onTap: onTap),
    );
  }
}

/// Sommaire replié en panneau, en tête de colonne (desktop étroit).
class _SommairePanel extends StatelessWidget {
  const _SommairePanel({required this.articles, required this.active, required this.onTap});

  final List<LegalArticle> articles;
  final int active;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: _SommaireBody(articles: articles, active: active, onTap: onTap),
    );
  }
}

class _SommaireBody extends StatelessWidget {
  const _SommaireBody({required this.articles, required this.active, required this.onTap});

  final List<LegalArticle> articles;
  final int active;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final children = <Widget>[
      const _MiniLabel('Sommaire'),
      const SizedBox(height: AppSpacing.sm),
    ];
    var previousPath = const <String>[];

    for (var i = 0; i < articles.length; i++) {
      for (final division in _newDivisions(previousPath, articles[i].path)) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(4, AppSpacing.sm, 4, 4),
            child: Text(
              division.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.textDisabled,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                fontSize: 9.5,
              ),
            ),
          ),
        );
      }
      children.add(
        _SommaireItem(
          number: articles[i].number,
          heading: articles[i].heading,
          active: i == active,
          onTap: () => onTap(i),
        ),
      );
      previousPath = articles[i].path;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

class _SommaireItem extends StatefulWidget {
  const _SommaireItem({
    required this.number,
    required this.heading,
    required this.active,
    required this.onTap,
  });

  final String number;
  final String heading;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_SommaireItem> createState() => _SommaireItemState();
}

class _SommaireItemState extends State<_SommaireItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final active = widget.active;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppRadius.small),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(vertical: 1),
            padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 6, AppSpacing.sm, 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.small),
              color: active
                  ? AppColors.gold.withValues(alpha: 0.14)
                  : _hovered
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: active ? AppColors.gold : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 34,
                  child: Text(
                    'Art. ${widget.number}',
                    style: textTheme.labelSmall?.copyWith(
                      color: active ? AppColors.gold : AppColors.textDisabled,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.heading.isEmpty ? 'Article ${widget.number}' : widget.heading,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: active ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      height: 1.25,
                    ),
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

/// Affiché quand le texte intégral n'est pas encore importé : plan du texte
/// et lien vers la source officielle.
class _OutlineFallback extends StatelessWidget {
  const _OutlineFallback({required this.document, required this.onSource});

  final LegalDocument document;
  final VoidCallback onSource;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.hourglass_top_rounded, size: 16, color: AppColors.goldLight),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      "Le texte intégral, article par article, est en cours d'intégration "
                      'dans JurisIA.',
                      style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary, height: 1.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'En attendant, consultez la version officielle et à jour :',
                style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ActionButton(
                icon: Icons.open_in_new_rounded,
                label: 'Consulter sur ${document.officialSourceName ?? "la source officielle"}',
                filled: true,
                onTap: onSource,
              ),
            ],
          ),
        ),
        if (document.outline.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          const _MiniLabel('Plan du texte'),
          const SizedBox(height: AppSpacing.sm),
          for (final line in document.outline)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 7),
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppGradients.goldSheen,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm + 2),
                  Expanded(
                    child: Text(
                      line,
                      style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
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
    required this.sourceName,
    required this.onToggleFavorite,
    required this.onCopy,
    required this.onDownload,
  });

  final bool isFavorite;
  final String? sourceUrl;
  final String? sourceName;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onCopy;
  final VoidCallback? onDownload;

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
        if (onCopy != null) ...[
          const SizedBox(height: 8),
          _ActionButton(icon: Icons.copy_rounded, label: 'Copier le texte', onTap: onCopy!),
        ],
        if (onDownload != null) ...[
          const SizedBox(height: 8),
          _ActionButton(icon: Icons.download_rounded, label: 'Télécharger', onTap: onDownload!),
        ],
        if (sourceUrl != null && sourceUrl!.isNotEmpty) ...[
          const SizedBox(height: 8),
          _ActionButton(
            icon: Icons.open_in_new_rounded,
            label: 'Consulter sur ${sourceName ?? "la source officielle"}',
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
                  if (document.awaitingFullText) ...[
                    const SizedBox(height: AppSpacing.md),
                    const SummaryOnlyBadge(),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  if (document.isStructured)
                    GlassContainer(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: _ArticleList(
                        articles: document.articles,
                        itemKeys: List.generate(document.articles.length, (_) => GlobalKey()),
                      ),
                    )
                  else if (document.fullContent.trim().isNotEmpty)
                    GlassContainer(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: SelectableText(document.fullContent, style: readingStyle),
                    )
                  else
                    GlassContainer(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Le texte intégral, article par article, est en cours d'intégration.",
                            style: readingStyle?.copyWith(fontSize: 14.5),
                          ),
                          if (document.sourceUrl != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            TextButton.icon(
                              onPressed: () => launchUrl(
                                Uri.parse(document.sourceUrl!),
                                webOnlyWindowName: '_blank',
                              ),
                              icon: const Icon(Icons.open_in_new_rounded, size: 16),
                              label: Text('Consulter sur ${document.officialSourceName ?? "la source"}'),
                            ),
                          ],
                          for (final line in document.outline)
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.sm),
                              child: Text('•  $line', style: Theme.of(context).textTheme.bodyMedium),
                            ),
                        ],
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
