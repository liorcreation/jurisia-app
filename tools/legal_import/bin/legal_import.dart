import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:legal_import/adapters/droit_afrique_adapter.dart';
import 'package:legal_import/adapters/legiburkina_adapter.dart';
import 'package:legal_import/adapters/ohada_adapter.dart';
import 'package:legal_import/adapters/source_adapter.dart';
import 'package:legal_import/article_parser.dart';
import 'package:legal_import/imported_document.dart';
import 'package:legal_import/supabase_writer.dart';

final _adapters = <String, SourceAdapter>{
  'ohada': const OhadaAdapter(),
  'droit-afrique': const DroitAfriqueAdapter(),
  'legiburkina': const LegiburkinaAdapter(),
};

Future<void> main(List<String> args) async {
  final runner = CommandRunner<void>(
    'legal_import',
    "Pipeline d'import du corpus juridique de JurisIA (voir RUNBOOK.md).",
  )
    ..addCommand(_FetchCommand())
    ..addCommand(_ParseCommand())
    ..addCommand(_ValidateCommand())
    ..addCommand(_PushCommand());

  try {
    await runner.run(args);
  } on UsageException catch (e) {
    stderr.writeln(e);
    exit(64);
  }
}

/// `fetch <source> <url> [-o out.json] [--set key=value ...]`
class _FetchCommand extends Command<void> {
  _FetchCommand() {
    argParser
      ..addOption('out', abbr: 'o', help: 'Fichier JSON de sortie (défaut : stdout).')
      ..addMultiOption('set',
          help: 'Surcharge de métadonnée, ex. --set type=code --set domain=travail.');
  }

  @override
  final name = 'fetch';
  @override
  final description = 'Récupère et normalise un texte depuis une source (ohada|droit-afrique|legiburkina).';

  @override
  Future<void> run() async {
    final rest = argResults!.rest;
    if (rest.length < 2) usageException('Usage : fetch <source> <url> [-o out.json]');
    final source = rest[0];
    final url = rest[1];
    final adapter = _adapters[source];
    if (adapter == null) usageException('Source inconnue : $source (${_adapters.keys.join(", ")})');

    final overrides = <String, dynamic>{};
    for (final kv in argResults!['set'] as List<String>) {
      final i = kv.indexOf('=');
      if (i < 0) usageException('--set attend key=value, reçu « $kv »');
      overrides[kv.substring(0, i)] = _coerce(kv.substring(i + 1));
    }

    stderr.writeln('→ $source : $url');
    final doc = await adapter.fetch(url, overrides: overrides);
    stderr.writeln('  ${doc.articles.length} articles, ${doc.outline.length} divisions.');

    final json = const JsonEncoder.withIndent('  ').convert(doc.toJson());
    final out = argResults!['out'] as String?;
    if (out == null) {
      stdout.writeln(json);
    } else {
      File(out).writeAsStringSync(json);
      stderr.writeln('  écrit dans $out');
    }
  }
}

/// `parse <fichier.txt>` — découpe un texte déjà extrait (ex. depuis un PDF
/// via `pdftotext -layout`) en articles JSON, sans réseau.
class _ParseCommand extends Command<void> {
  _ParseCommand() {
    argParser
      ..addOption('out', abbr: 'o')
      ..addMultiOption('set');
  }

  @override
  final name = 'parse';
  @override
  final description = "Découpe un fichier texte local en articles (utile pour les sources PDF).";

  @override
  Future<void> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) usageException('Usage : parse <fichier.txt> [-o out.json]');
    final text = File(rest[0]).readAsStringSync();

    final overrides = <String, dynamic>{};
    for (final kv in argResults!['set'] as List<String>) {
      final i = kv.indexOf('=');
      overrides[kv.substring(0, i)] = _coerce(kv.substring(i + 1));
    }

    final base = ImportedDocument(
      id: overrides['id'] as String? ?? 'doc-a-renommer',
      title: overrides['title'] as String? ?? 'Titre à renseigner',
      type: overrides['type'] as String? ?? 'code',
      domain: overrides['domain'] as String? ?? 'autre',
      articles: parseArticles(text),
      outline: parseOutline(text),
    );
    final doc = withOverrides(base, overrides);

    stderr.writeln('${doc.articles.length} articles détectés.');
    final json = const JsonEncoder.withIndent('  ').convert(doc.toJson());
    final out = argResults!['out'] as String?;
    if (out == null) {
      stdout.writeln(json);
    } else {
      File(out).writeAsStringSync(json);
    }
  }
}

/// `validate <fichier.json | dossier>` — contrôles de cohérence avant push.
class _ValidateCommand extends Command<void> {
  @override
  final name = 'validate';
  @override
  final description = 'Vérifie un ou plusieurs fichiers JSON de documents.';

  static const _types = {
    'constitution', 'code', 'loi', 'decret', 'arrete', 'jurisprudence', 'traite', 'modeleActe',
  };
  static const _domains = {
    'civil', 'penal', 'commercial', 'travail', 'famille', 'administratif', 'fiscal',
    'constitutionnel', 'foncier', 'ohada', 'procedureCivile', 'procedurePenale', 'autre',
  };

  @override
  Future<void> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) usageException('Usage : validate <fichier.json | dossier>');

    var errors = 0;
    for (final doc in _load(rest[0])) {
      final where = doc.id;
      void bad(String msg) {
        stderr.writeln('✗ $where : $msg');
        errors++;
      }

      if (!doc.id.startsWith('doc-')) bad('id doit commencer par « doc- »');
      if (doc.title.trim().isEmpty) bad('titre vide');
      if (!_types.contains(doc.type)) bad('type inconnu : ${doc.type}');
      if (!_domains.contains(doc.domain)) bad('domaine inconnu : ${doc.domain}');
      if (doc.fullContent.trim().isEmpty && doc.articles.isEmpty) {
        stderr.writeln('  ⚠ $where : ni prose ni articles (fiche seule + lien source).');
      }
      final nums = doc.articles.map((a) => a.number).toList();
      if (nums.toSet().length != nums.length) bad('numéros d\'articles en double');
    }

    if (errors > 0) {
      stderr.writeln('$errors erreur(s).');
      exit(1);
    }
    stderr.writeln('OK.');
  }
}

/// `push <fichier.json | dossier>` — upsert dans Supabase.
class _PushCommand extends Command<void> {
  _PushCommand() {
    argParser.addFlag('dry-run', help: 'N\'écrit rien, affiche seulement ce qui serait poussé.');
  }

  @override
  final name = 'push';
  @override
  final description = 'Écrit un ou plusieurs documents dans Supabase (service_role requis).';

  @override
  Future<void> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) usageException('Usage : push <fichier.json | dossier>');
    final docs = _load(rest[0]).toList();
    final dryRun = argResults!['dry-run'] as bool;

    if (dryRun) {
      for (final d in docs) {
        stdout.writeln('${d.id}  «${d.title}»  ${d.articles.length} articles');
      }
      return;
    }

    final writer = SupabaseWriter();
    for (final d in docs) {
      stdout.write('→ ${d.id} … ');
      await writer.push(d);
      stdout.writeln('ok (${d.articles.length} art.)');
    }
    stdout.writeln('${docs.length} document(s) synchronisé(s).');
  }
}

Iterable<ImportedDocument> _load(String path) sync* {
  final entity = FileSystemEntity.typeSync(path);
  if (entity == FileSystemEntityType.directory) {
    for (final f in Directory(path).listSync().whereType<File>()) {
      if (f.path.endsWith('.json')) {
        yield ImportedDocument.fromJson(jsonDecode(f.readAsStringSync()) as Map<String, dynamic>);
      }
    }
  } else {
    final decoded = jsonDecode(File(path).readAsStringSync());
    if (decoded is List) {
      for (final d in decoded) {
        yield ImportedDocument.fromJson(d as Map<String, dynamic>);
      }
    } else {
      yield ImportedDocument.fromJson(decoded as Map<String, dynamic>);
    }
  }
}

Object _coerce(String v) {
  if (v == 'true') return true;
  if (v == 'false') return false;
  final n = num.tryParse(v);
  if (n != null) return n;
  return v;
}
