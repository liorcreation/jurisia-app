import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Rendu léger d'un sous-ensemble de Markdown (gras, italique, listes à
/// puces et listes numérotées, paragraphes) suffisant pour les réponses de
/// l'IA, sans dépendance externe.
class MarkdownText extends StatelessWidget {
  const MarkdownText(this.data, {super.key, this.style});

  final String data;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final baseStyle =
        style ?? Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary, height: 1.45);
    final blocks = _parseBlocks(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          blocks[i].build(baseStyle),
        ],
      ],
    );
  }

  static final _bulletRegex = RegExp(r'^\s*[-•]\s+(.*)$');
  static final _orderedRegex = RegExp(r'^\s*\d+[.)]\s+(.*)$');
  static final _headingRegex = RegExp(r'^(#{1,3})\s+(.*)$');

  List<_MdBlock> _parseBlocks(String text) {
    final lines = text.split('\n');
    final blocks = <_MdBlock>[];
    final paragraphBuffer = <String>[];
    List<String>? listBuffer;
    var ordered = false;

    void flushParagraph() {
      if (paragraphBuffer.isNotEmpty) {
        blocks.add(_ParagraphBlock(paragraphBuffer.join(' ')));
        paragraphBuffer.clear();
      }
    }

    void flushList() {
      final items = listBuffer;
      if (items != null && items.isNotEmpty) {
        blocks.add(_ListBlock(items, ordered: ordered));
      }
      listBuffer = null;
    }

    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      if (line.trim().isEmpty) {
        flushParagraph();
        flushList();
        continue;
      }

      final headingMatch = _headingRegex.firstMatch(line);
      if (headingMatch != null) {
        flushParagraph();
        flushList();
        blocks.add(_HeadingBlock(headingMatch.group(2)!.trim(), level: headingMatch.group(1)!.length));
        continue;
      }

      final bulletMatch = _bulletRegex.firstMatch(line);
      final orderedMatch = _orderedRegex.firstMatch(line);

      if (bulletMatch != null || orderedMatch != null) {
        flushParagraph();
        final isOrdered = orderedMatch != null;
        final content = (bulletMatch ?? orderedMatch)!.group(1)!.trim();
        if (listBuffer == null || ordered != isOrdered) {
          flushList();
          listBuffer = [];
          ordered = isOrdered;
        }
        listBuffer!.add(content);
      } else {
        flushList();
        paragraphBuffer.add(line.trim());
      }
    }
    flushParagraph();
    flushList();

    return blocks;
  }
}

abstract class _MdBlock {
  const _MdBlock();

  Widget build(TextStyle? baseStyle);
}

class _HeadingBlock extends _MdBlock {
  const _HeadingBlock(this.text, {required this.level});

  final String text;
  final int level;

  @override
  Widget build(TextStyle? baseStyle) {
    final fontSize = switch (level) {
      1 => 22.0,
      2 => 18.0,
      _ => 15.0,
    };
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text(
        text,
        style: baseStyle?.copyWith(
          color: AppColors.gold,
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
          height: 1.3,
        ),
      ),
    );
  }
}

class _ParagraphBlock extends _MdBlock {
  const _ParagraphBlock(this.text);

  final String text;

  @override
  Widget build(TextStyle? baseStyle) => Text.rich(_parseInline(text, baseStyle));
}

class _ListBlock extends _MdBlock {
  const _ListBlock(this.items, {required this.ordered});

  final List<String> items;
  final bool ordered;

  @override
  Widget build(TextStyle? baseStyle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 22,
                  child: Text(
                    ordered ? '${i + 1}.' : '•',
                    style: baseStyle?.copyWith(color: AppColors.gold, fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(child: Text.rich(_parseInline(items[i], baseStyle))),
              ],
            ),
          ),
      ],
    );
  }
}

final _inlineRegex = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*');

InlineSpan _parseInline(String text, TextStyle? baseStyle) {
  final spans = <InlineSpan>[];
  var lastEnd = 0;

  for (final match in _inlineRegex.allMatches(text)) {
    if (match.start > lastEnd) {
      spans.add(TextSpan(text: text.substring(lastEnd, match.start), style: baseStyle));
    }
    final bold = match.group(1);
    final italic = match.group(2);
    if (bold != null) {
      spans.add(
        TextSpan(
          text: bold,
          style: baseStyle?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
      );
    } else if (italic != null) {
      spans.add(TextSpan(text: italic, style: baseStyle?.copyWith(fontStyle: FontStyle.italic)));
    }
    lastEnd = match.end;
  }
  if (lastEnd < text.length) {
    spans.add(TextSpan(text: text.substring(lastEnd), style: baseStyle));
  }
  return TextSpan(children: spans, style: baseStyle);
}
