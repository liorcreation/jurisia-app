import 'imported_document.dart';

/// Découpe un texte brut de loi / code / acte uniforme en articles, en
/// suivant la hiérarchie éditoriale (LIVRE / TITRE / CHAPITRE / SECTION /
/// SOUS-SECTION). Robuste aux variantes courantes de mise en forme des
/// sources francophones.
///
/// Ce parseur est **volontairement générique** : chaque adaptateur de source
/// nettoie d'abord le HTML en texte plat (une ligne par paragraphe) avant de
/// l'appeler.
List<ImportedArticle> parseArticles(String plainText) {
  final lines = plainText
      .replaceAll('\r\n', '\n')
      .split('\n')
      .map((l) => l.trim())
      .toList();

  final articles = <ImportedArticle>[];
  final path = <String>[];

  final divisionRe = RegExp(
    r'^(LIVRE|TITRE|CHAPITRE|SECTION|SOUS-SECTION|PARTIE|PARAGRAPHE)\s+'
    r'([IVXLCDM0-9]+(?:\s*(?:er|ère|bis|ter))?)\s*[:\.—\-–]?\s*(.*)$',
    caseSensitive: false,
  );
  // « Article 12 », « Art. 12 », « ARTICLE 12 bis », « Article L. 122-4 »
  final articleRe = RegExp(
    r'^(?:ARTICLE|Article|Art\.?)\s+([LRD]?\.?\s?[0-9]+(?:[-.–][0-9]+)*(?:\s*(?:bis|ter|quater))?)\s*[:\.—\-–]?\s*(.*)$',
  );

  ImportedArticle? current;
  final buffer = StringBuffer();

  void flush() {
    if (current == null) return;
    articles.add(ImportedArticle(
      number: current!.number,
      heading: current!.heading,
      body: buffer.toString().trim(),
      path: List.of(current!.path),
    ));
    buffer.clear();
    current = null;
  }

  for (final line in lines) {
    if (line.isEmpty) {
      if (buffer.isNotEmpty) buffer.write('\n\n');
      continue;
    }

    final div = divisionRe.firstMatch(line);
    if (div != null) {
      flush();
      final kind = div.group(1)!.toUpperCase();
      final num = div.group(2)!.trim();
      final label = div.group(3)!.trim();
      final depth = _divisionDepth(kind);
      while (path.length > depth) {
        path.removeLast();
      }
      final text = label.isEmpty ? '$kind $num' : '$kind $num — $label';
      if (path.length == depth) {
        path[depth - 1] = text;
      } else {
        path.add(text);
      }
      continue;
    }

    final art = articleRe.firstMatch(line);
    if (art != null) {
      flush();
      final number = art.group(1)!.replaceAll(RegExp(r'\s+'), ' ').trim();
      final rest = art.group(2)!.trim();
      // Un intitulé court en tête d'article (« Objet. ») est repris comme
      // heading ; sinon tout va dans le corps.
      String heading = '';
      String body = rest;
      final headingRe = RegExp(r'^([A-ZÀ-Ÿ][^.]{2,60})\.\s+(.*)$');
      final m = headingRe.firstMatch(rest);
      if (m != null && m.group(1)!.split(' ').length <= 8) {
        heading = m.group(1)!.trim();
        body = m.group(2)!.trim();
      }
      current = ImportedArticle(number: number, heading: heading, body: '', path: List.of(path));
      if (body.isNotEmpty) buffer.write(body);
      continue;
    }

    if (current != null) {
      if (buffer.isNotEmpty && !buffer.toString().endsWith('\n')) buffer.write(' ');
      buffer.write(line);
    }
  }
  flush();

  return articles;
}

int _divisionDepth(String kind) {
  switch (kind) {
    case 'LIVRE':
    case 'PARTIE':
      return 1;
    case 'TITRE':
      return 2;
    case 'CHAPITRE':
      return 3;
    case 'SECTION':
      return 4;
    case 'SOUS-SECTION':
    case 'PARAGRAPHE':
      return 5;
    default:
      return 1;
  }
}

/// Extrait un plan (`outline`) à partir des titres de division rencontrés
/// dans le texte — utile même quand le texte intégral n'est pas conservé.
List<String> parseOutline(String plainText) {
  final re = RegExp(
    r'^(LIVRE|TITRE|PARTIE)\s+([IVXLCDM0-9]+(?:\s*(?:er|ère))?)\s*[:\.—\-–]?\s*(.*)$',
    multiLine: true,
    caseSensitive: false,
  );
  return [
    for (final m in re.allMatches(plainText))
      '${m.group(1)!.toUpperCase()} ${m.group(2)!.trim()}'
          '${(m.group(3) ?? '').trim().isEmpty ? '' : ' — ${m.group(3)!.trim()}'}',
  ];
}
