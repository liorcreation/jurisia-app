import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../platform/app_platform_style.dart';
import '../widgets/jurisia_mark.dart';
import '../widgets/luxury_scaffold_background.dart';
import '../../theme/app_theme.dart';

/// Affiche un des documents juridiques « maison » de l'application (CGU,
/// politique de confidentialité) en lecture soignée : sommaire numéroté à
/// gauche avec suivi de lecture, corps en serif justifié à droite. Le
/// contenu markdown de [LegalDocuments] est découpé à la volée en sections.
class LegalDocumentScreen extends StatefulWidget {
  const LegalDocumentScreen({super.key, required this.title, required this.content});

  final String title;
  final String content;

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  final ScrollController _scroll = ScrollController();
  late final _LegalDoc _doc;
  late final List<GlobalKey> _sectionKeys;
  int _active = 0;

  @override
  void initState() {
    super.initState();
    _doc = _parseLegalDoc(widget.content);
    _sectionKeys = List.generate(_doc.sections.length, (_) => GlobalKey());
    _scroll.addListener(_trackActive);
  }

  @override
  void dispose() {
    _scroll.removeListener(_trackActive);
    _scroll.dispose();
    super.dispose();
  }

  void _trackActive() {
    if (!_scroll.hasClients) return;
    var current = 0;
    for (var i = 0; i < _sectionKeys.length; i++) {
      final box = _sectionKeys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box == null) continue;
      if (box.localToGlobal(Offset.zero).dy <= 180) current = i;
    }
    if (current != _active) setState(() => _active = current);
  }

  void _scrollToSection(int index) {
    final ctx = _sectionKeys[index].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 340),
      curve: Curves.fastOutSlowIn,
      alignment: 0.05,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppPlatformStyle.of(context) == AppPlatformStyle.desktop;

    final article = _LegalArticle(
      doc: _doc,
      headerTitle: widget.title,
      sectionKeys: _sectionKeys,
      isDesktop: isDesktop,
    );

    final scroller = SingleChildScrollView(
      controller: _scroll,
      padding: EdgeInsets.fromLTRB(
        isDesktop ? AppSpacing.xxl : AppSpacing.lg,
        isDesktop ? AppSpacing.xl : AppSpacing.lg,
        isDesktop ? AppSpacing.xl : AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: Align(
        alignment: isDesktop ? Alignment.topLeft : Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 720 : 640),
          child: article,
        ),
      ),
    );

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: isDesktop ? null : AppBar(title: Text(widget.title)),
        body: SafeArea(
          child: Stack(
            children: [
              if (isDesktop)
                const Positioned.fill(child: IgnorePointer(child: _LegalAmbience())),
              Column(
                children: [
                  if (isDesktop) ...[
                    _LegalHeader(title: widget.title, updated: _doc.updated),
                    _ReadingProgress(controller: _scroll),
                  ],
                  Expanded(
                    child: isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 288,
                                child: _TocRail(
                                  sections: _doc.sections,
                                  active: _active,
                                  onTap: _scrollToSection,
                                ),
                              ),
                              Expanded(child: scroller),
                            ],
                          )
                        : scroller,
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

// ---------------------------------------------------------------------------
//  En-tête desktop + suivi de lecture
// ---------------------------------------------------------------------------

class _LegalHeader extends StatelessWidget {
  const _LegalHeader({required this.title, required this.updated});

  final String title;
  final String? updated;

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
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Retour',
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(Icons.description_outlined, size: 18, color: AppColors.gold),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(title, style: textTheme.headlineSmall)),
          if (updated != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.28), width: 0.7),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.update_rounded, size: 12, color: AppColors.goldLight),
                  const SizedBox(width: 5),
                  Text(
                    'à jour au $updated',
                    style: textTheme.labelSmall?.copyWith(color: AppColors.goldLight),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

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

// ---------------------------------------------------------------------------
//  Sommaire (rail gauche desktop)
// ---------------------------------------------------------------------------

class _TocRail extends StatelessWidget {
  const _TocRail({required this.sections, required this.active, required this.onTap});

  final List<_LegalSection> sections;
  final int active;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.sm, AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 14, height: 1, color: AppColors.gold.withValues(alpha: 0.6)),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'SOMMAIRE',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.goldLight,
                  letterSpacing: AppLetterSpacing.caps,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < sections.length; i++)
            _TocItem(
              number: sections[i].number,
              heading: sections[i].heading,
              active: i == active,
              onTap: () => onTap(i),
            ),
        ],
      ),
    );
  }
}

class _TocItem extends StatefulWidget {
  const _TocItem({
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
  State<_TocItem> createState() => _TocItemState();
}

class _TocItemState extends State<_TocItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final lit = widget.active || _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.small),
            color: widget.active ? AppColors.gold.withValues(alpha: 0.10) : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: widget.active ? AppColors.gold : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                child: Text(
                  widget.number.isEmpty ? '—' : widget.number.padLeft(2, '0'),
                  style: textTheme.labelSmall?.copyWith(
                    fontFamily: 'Libre Caslon Display',
                    color: lit ? AppColors.goldLight : AppColors.textDisabled,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.heading,
                  style: textTheme.labelMedium?.copyWith(
                    color: lit ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: widget.active ? FontWeight.w700 : FontWeight.w500,
                    height: 1.3,
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

// ---------------------------------------------------------------------------
//  Corps de l'article
// ---------------------------------------------------------------------------

class _LegalArticle extends StatelessWidget {
  const _LegalArticle({
    required this.doc,
    required this.headerTitle,
    required this.sectionKeys,
    required this.isDesktop,
  });

  final _LegalDoc doc;
  final String headerTitle;
  final List<GlobalKey> sectionKeys;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            JurisIAMark(size: isDesktop ? 28 : 24),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'DOCUMENT JURIDIQUE',
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.goldLight,
                letterSpacing: AppLetterSpacing.caps,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: isDesktop ? AppSpacing.md : AppSpacing.sm),
        Text(
          doc.title,
          softWrap: true,
          style: (isDesktop ? textTheme.displaySmall : textTheme.headlineSmall)?.copyWith(
            fontFamily: 'Libre Caslon Display',
            height: 1.12,
          ),
        ),
        if (doc.updated != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Dernière mise à jour : ${doc.updated}',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Container(width: 54, height: 2, color: AppColors.gold.withValues(alpha: 0.7)),
        SizedBox(height: isDesktop ? AppSpacing.xl : AppSpacing.lg),
        for (var i = 0; i < doc.sections.length; i++)
          KeyedSubtree(
            key: sectionKeys[i],
            child: Padding(
              padding: EdgeInsets.only(
                bottom: i == doc.sections.length - 1 ? 0 : (isDesktop ? AppSpacing.xl : AppSpacing.lg),
              ),
              child: _SectionBlock(section: doc.sections[i], isDesktop: isDesktop),
            ),
          ),
      ],
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.section, required this.isDesktop});

  final _LegalSection section;
  final bool isDesktop;

  TextStyle _readingStyle(BuildContext context) {
    return (Theme.of(context).textTheme.bodyMedium ?? const TextStyle()).copyWith(
      fontFamily: 'Lora',
      color: AppColors.textPrimary,
      height: 1.75,
      fontSize: isDesktop ? 15.5 : 15,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final reading = _readingStyle(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            if (section.number.isNotEmpty) ...[
              Text(
                section.number.padLeft(2, '0'),
                style: (isDesktop ? textTheme.titleLarge : textTheme.titleMedium)?.copyWith(
                  fontFamily: 'Libre Caslon Display',
                  color: AppColors.gold.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Text(
                section.heading,
                style: (isDesktop ? textTheme.titleLarge : textTheme.titleMedium)?.copyWith(
                  fontFamily: 'Libre Caslon Display',
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: 32,
          height: 1,
          color: AppColors.gold.withValues(alpha: 0.35),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final block in section.blocks) ...[
          if (block is _Para)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(block.text, textAlign: TextAlign.justify, style: reading),
            )
          else if (block is _Bullets)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm, top: 2),
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.gold.withValues(alpha: 0.4), width: 2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in block.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: AppColors.gold,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              item,
                              style: reading.copyWith(
                                fontSize: (reading.fontSize ?? 15) - 0.5,
                                color: AppColors.textSecondary,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
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

/// Fines poussières d'or en suspension — la respiration « vivante » du
/// registre desktop.
class _LegalAmbience extends StatefulWidget {
  const _LegalAmbience();

  @override
  State<_LegalAmbience> createState() => _LegalAmbienceState();
}

class _LegalAmbienceState extends State<_LegalAmbience> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(painter: _LegalAmbiencePainter(_controller.value)),
    );
  }
}

class _LegalAmbiencePainter extends CustomPainter {
  const _LegalAmbiencePainter(this.t);

  final double t;
  static const int _count = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < _count; i++) {
      final seed = i * 61.0;
      final baseX = seed % size.width;
      final drift = math.sin((t * 2 * math.pi) + seed) * 18;
      final x = (baseX + drift) % size.width;
      final y = (size.height * ((i / _count) + t) % 1.0);
      final radius = 0.7 + (i % 3) * 0.6;
      final opacity = 0.04 + 0.07 * (0.5 + 0.5 * math.sin((t * 2 * math.pi) + seed * 1.7));
      paint.color = AppColors.goldLight.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LegalAmbiencePainter oldDelegate) => oldDelegate.t != t;
}

// ---------------------------------------------------------------------------
//  Modèle + parseur markdown minimal
// ---------------------------------------------------------------------------

class _LegalDoc {
  const _LegalDoc({required this.title, required this.updated, required this.sections});

  final String title;
  final String? updated;
  final List<_LegalSection> sections;
}

class _LegalSection {
  _LegalSection({required this.number, required this.heading, required this.blocks});

  final String number;
  final String heading;
  final List<_Block> blocks;
}

sealed class _Block {
  const _Block();
}

class _Para extends _Block {
  const _Para(this.text);
  final String text;
}

class _Bullets extends _Block {
  const _Bullets(this.items);
  final List<String> items;
}

final _headingRe = RegExp(r'^##\s+(?:(\d+)\.\s+)?(.+)$');

/// Découpe le markdown des CGU / politique de confidentialité (format
/// stable : `# titre`, ligne « Dernière mise à jour », puis des sections
/// `## N. Intitulé` avec paragraphes et listes `- item`).
_LegalDoc _parseLegalDoc(String content) {
  final lines = content.trim().split('\n');
  var title = '';
  String? updated;
  final sections = <_LegalSection>[];

  _LegalSection? current;
  final paragraph = StringBuffer();
  List<String>? bullets;

  void flushParagraph() {
    final text = paragraph.toString().trim();
    if (text.isNotEmpty) current?.blocks.add(_Para(_inline(text)));
    paragraph.clear();
  }

  void flushBullets() {
    if (bullets != null && bullets!.isNotEmpty) current?.blocks.add(_Bullets(List.of(bullets!)));
    bullets = null;
  }

  void ensureSection() {
    current ??= _LegalSection(number: '', heading: 'Préambule', blocks: []);
    if (!sections.contains(current)) sections.add(current!);
  }

  for (final raw in lines) {
    final line = raw.trimRight();

    if (line.startsWith('# ')) {
      title = line.substring(2).trim();
      continue;
    }
    if (line.toLowerCase().startsWith('dernière mise à jour')) {
      final idx = line.indexOf(':');
      updated = idx == -1 ? null : line.substring(idx + 1).trim();
      continue;
    }

    final headingMatch = _headingRe.firstMatch(line);
    if (headingMatch != null) {
      flushParagraph();
      flushBullets();
      current = _LegalSection(
        number: headingMatch.group(1) ?? '',
        heading: headingMatch.group(2)!.trim(),
        blocks: [],
      );
      sections.add(current!);
      continue;
    }

    if (line.isEmpty) {
      flushParagraph();
      flushBullets();
      continue;
    }

    if (line.startsWith('- ')) {
      flushParagraph();
      ensureSection();
      (bullets ??= <String>[]).add(_inline(line.substring(2).trim()));
      continue;
    }

    // paragraphe : ligne de texte
    flushBullets();
    ensureSection();
    if (paragraph.isNotEmpty) paragraph.write(' ');
    paragraph.write(line);
  }

  flushParagraph();
  flushBullets();

  return _LegalDoc(title: title, updated: updated, sections: sections);
}

/// Nettoie le markdown inline résiduel (gras) — le contenu maison n'utilise
/// que `**…**`.
String _inline(String text) => text.replaceAll('**', '');
