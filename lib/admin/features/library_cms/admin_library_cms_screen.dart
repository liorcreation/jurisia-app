import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/luxury_scaffold_background.dart';
import '../../../models/legal_document/legal_document_model.dart';
import '../../../models/legal_document/legal_domain.dart';
import '../../../theme/app_theme.dart';
import '../../auth/staff_role.dart';
import '../../theme/admin_theme.dart';
import 'admin_document_draft.dart';
import 'admin_document_draft_controller.dart';
import 'admin_document_draft_repository.dart';

/// Console — CMS Bibliothèque : la file des brouillons de textes et leur
/// circuit de relecture (voir migration_012_legal_document_review.sql).
/// L'édition riche d'un article reste hors scope de cette première version
/// (cadrage, phase 3) — le formulaire accepte les articles au format JSON,
/// identique à la sortie de `tools/legal_import` (fetch/parse), pour rester
/// utilisable dès aujourd'hui sans éditeur structuré dédié.
class AdminLibraryCmsScreen extends StatelessWidget {
  const AdminLibraryCmsScreen({super.key, required this.identity});

  final StaffIdentity identity;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminDocumentDraftController>(
      create: (_) => AdminDocumentDraftController(
        repository: SupabaseAdminDocumentDraftRepository(client: SupabaseConfig.client),
      ),
      child: _View(identity: identity),
    );
  }
}

class _View extends StatelessWidget {
  const _View({required this.identity});

  final StaffIdentity identity;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminDocumentDraftController>();
    final textTheme = Theme.of(context).textTheme;

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('CMS Bibliothèque'),
          actions: [
            IconButton(
              tooltip: 'Rafraîchir',
              onPressed: controller.isLoading ? null : controller.load,
              icon: const Icon(Icons.refresh_rounded),
            ),
            if (identity.canEditContent)
              IconButton(
                tooltip: 'Nouveau brouillon',
                onPressed: () => _openEditor(context, controller),
                icon: const Icon(Icons.add_rounded),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _FilterBar(controller: controller),
              if (controller.error != null)
                _ErrorBanner(message: controller.error!, onDismiss: controller.dismissError),
              Expanded(
                child: controller.isLoading && controller.drafts.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : controller.drafts.isEmpty
                        ? Center(
                            child: Text('Aucun brouillon.', style: textTheme.bodyMedium),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            itemCount: controller.drafts.length,
                            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) => _DraftCard(
                              draft: controller.drafts[index],
                              identity: identity,
                              busy: controller.isMutating,
                              onEdit: () => _openEditor(context, controller, draft: controller.drafts[index]),
                              onSubmit: () => controller.submit(controller.drafts[index].id),
                              onApprove: () => controller.approve(controller.drafts[index].id),
                              onRequestChanges: () => _promptReason(
                                context,
                                title: 'Renvoyer en correction',
                                label: 'Motif (obligatoire)',
                                onConfirm: (reason) =>
                                    controller.requestChanges(controller.drafts[index].id, reason),
                              ),
                              onArchive: () => _promptReason(
                                context,
                                title: 'Archiver ce texte',
                                label: 'Motif (facultatif)',
                                requireReason: false,
                                onConfirm: (reason) => controller.archiveDocument(
                                  controller.drafts[index].documentId,
                                  reason.isEmpty ? null : reason,
                                ),
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

  Future<void> _openEditor(
    BuildContext context,
    AdminDocumentDraftController controller, {
    AdminDocumentDraft? draft,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: controller,
        child: _DraftEditorDialog(draft: draft),
      ),
    );
  }

  Future<void> _promptReason(
    BuildContext context, {
    required String title,
    required String label,
    required Future<bool> Function(String reason) onConfirm,
    bool requireReason = true,
  }) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirmer')),
        ],
      ),
    );
    if (confirmed != true) return;
    if (requireReason && controller.text.trim().isEmpty) return;
    await onConfirm(controller.text.trim());
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.controller});

  final AdminDocumentDraftController controller;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, DocumentDraftStatus? status) {
      final count = status == null ? controller.totalCount : controller.countFor(status);
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: ChoiceChip(
          label: Text(status == null ? label : '$label · $count'),
          selected: controller.filter == status,
          onSelected: (_) => controller.setFilter(status),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            chip('Tous', null),
            for (final status in DocumentDraftStatus.values) chip(status.label, status),
          ],
        ),
      ),
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.draft,
    required this.identity,
    required this.busy,
    required this.onEdit,
    required this.onSubmit,
    required this.onApprove,
    required this.onRequestChanges,
    required this.onArchive,
  });

  final AdminDocumentDraft draft;
  final StaffIdentity identity;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onSubmit;
  final VoidCallback onApprove;
  final VoidCallback onRequestChanges;
  final VoidCallback onArchive;

  Color _statusColor(BuildContext context) {
    switch (draft.status) {
      case DocumentDraftStatus.published:
        return AppColors.success;
      case DocumentDraftStatus.changesRequested:
        return AppColors.warning;
      case DocumentDraftStatus.archived:
        return AppColors.textDisabled;
      case DocumentDraftStatus.inReview:
        return AdminTheme.accentLight;
      case DocumentDraftStatus.draft:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = _statusColor(context);

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
                ),
                child: Text(
                  draft.status.label,
                  style: textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  draft.documentId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(draft.title, style: textTheme.titleSmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _MiniTag(draft.type),
              _MiniTag(draft.domain),
              if (draft.articleCount > 0)
                _MiniTag('${draft.articleCount} article${draft.articleCount > 1 ? "s" : ""}'),
            ],
          ),
          if (draft.summary.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              draft.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          if (draft.status == DocumentDraftStatus.changesRequested && draft.reviewReason != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Text(
                'Motif : ${draft.reviewReason}',
                style: textTheme.bodySmall?.copyWith(color: AppColors.warning),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            [
              if (draft.createdByEmail != null) 'Créé par ${draft.createdByEmail}',
              if (draft.reviewedByEmail != null) 'relu par ${draft.reviewedByEmail}',
            ].join(' · '),
            style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              if (draft.canEdit && identity.canEditContent) ...[
                OutlinedButton.icon(
                  onPressed: busy ? null : onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 15),
                  label: const Text('Modifier'),
                ),
                FilledButton.icon(
                  onPressed: busy ? null : onSubmit,
                  style: FilledButton.styleFrom(backgroundColor: AdminTheme.accent),
                  icon: const Icon(Icons.send_rounded, size: 15),
                  label: const Text('Soumettre à la relecture'),
                ),
              ],
              if (draft.status == DocumentDraftStatus.inReview && identity.canReviewDocuments) ...[
                OutlinedButton.icon(
                  onPressed: busy ? null : onRequestChanges,
                  icon: const Icon(Icons.undo_rounded, size: 15),
                  label: const Text('Demander des corrections'),
                ),
                FilledButton.icon(
                  onPressed: busy ? null : onApprove,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                  icon: const Icon(Icons.check_rounded, size: 15),
                  label: const Text('Approuver'),
                ),
              ],
              if (draft.status == DocumentDraftStatus.published && identity.canReviewDocuments)
                OutlinedButton.icon(
                  onPressed: busy ? null : onArchive,
                  icon: const Icon(Icons.archive_outlined, size: 15),
                  label: const Text('Archiver ce texte'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.legalBlueDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

/// Formulaire de brouillon — les champs de `ImportedDocument.toJson()`
/// (voir tools/legal_import), plus un champ JSON libre pour les articles
/// tant qu'il n'y a pas d'éditeur structuré dédié.
class _DraftEditorDialog extends StatefulWidget {
  const _DraftEditorDialog({this.draft});

  final AdminDocumentDraft? draft;

  @override
  State<_DraftEditorDialog> createState() => _DraftEditorDialogState();
}

class _DraftEditorDialogState extends State<_DraftEditorDialog> {
  late final _documentId = TextEditingController(text: widget.draft?.documentId ?? '');
  late final _title = TextEditingController(text: widget.draft?.payload['title'] as String? ?? '');
  late final _reference = TextEditingController(text: widget.draft?.payload['reference'] as String? ?? '');
  late final _summary = TextEditingController(text: widget.draft?.payload['summary'] as String? ?? '');
  late final _fullContent =
      TextEditingController(text: widget.draft?.payload['full_content'] as String? ?? '');
  late final _sourceUrl = TextEditingController(text: widget.draft?.payload['source_url'] as String? ?? '');
  late final _officialSource =
      TextEditingController(text: widget.draft?.payload['official_source_name'] as String? ?? '');
  late final _tags = TextEditingController(
    text: ((widget.draft?.payload['tags'] as List?)?.cast<String>() ?? const <String>[]).join(', '),
  );
  late final _articlesJson = TextEditingController(
    text: widget.draft?.payload['articles'] != null
        ? const JsonEncoder.withIndent('  ').convert(widget.draft!.payload['articles'])
        : '',
  );

  late LegalDocumentType _type = LegalDocumentType.values.firstWhere(
    (t) => t.name == widget.draft?.payload['type'],
    orElse: () => LegalDocumentType.loi,
  );
  late LegalDomain _domain = LegalDomain.values.firstWhere(
    (d) => d.name == widget.draft?.payload['domain'],
    orElse: () => LegalDomain.autre,
  );
  late LegalDocumentStatus _status = LegalDocumentStatus.values.firstWhere(
    (s) => s.name == widget.draft?.payload['status'],
    orElse: () => LegalDocumentStatus.enVigueur,
  );

  String? _articlesError;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _documentId, _title, _reference, _summary, _fullContent,
      _sourceUrl, _officialSource, _tags, _articlesJson,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  List<dynamic>? _parseArticles() {
    final raw = _articlesJson.text.trim();
    if (raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) throw const FormatException('doit être un tableau JSON');
      return decoded;
    } catch (error) {
      setState(() => _articlesError = 'JSON invalide : $error');
      return null;
    }
  }

  Future<void> _save({required bool andSubmit}) async {
    if (_documentId.text.trim().isEmpty || _title.text.trim().isEmpty) return;
    final articles = _parseArticles();
    if (articles == null) return;
    setState(() {
      _articlesError = null;
      _saving = true;
    });

    final payload = <String, dynamic>{
      'id': _documentId.text.trim(),
      'title': _title.text.trim(),
      'type': _type.name,
      'domain': _domain.name,
      'reference': _reference.text.trim(),
      'status': _status.name,
      'summary': _summary.text.trim(),
      'full_content': _fullContent.text.trim(),
      'summary_only': _fullContent.text.trim().isEmpty && articles.isEmpty,
      'official_source_name': _officialSource.text.trim().isEmpty ? null : _officialSource.text.trim(),
      'source_url': _sourceUrl.text.trim().isEmpty ? null : _sourceUrl.text.trim(),
      'tags': _tags.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList(),
      'related_ids': (widget.draft?.payload['related_ids'] as List?)?.cast<String>() ?? const [],
      'outline': (widget.draft?.payload['outline'] as List?)?.cast<String>() ?? const [],
      'articles': articles,
    };

    final controller = context.read<AdminDocumentDraftController>();
    final draft = widget.draft;
    final ok = draft == null
        ? await controller.createDraft(documentId: payload['id'] as String, payload: payload)
        : await controller.updateDraft(draft, payload);

    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) return;

    if (andSubmit) {
      // Le brouillon vient d'être (re)créé ; on retrouve son id à jour dans
      // le contrôleur pour le soumettre dans la foulée.
      final saved = controller.drafts.firstWhere(
        (d) => d.documentId == payload['id'],
        orElse: () => draft ?? controller.drafts.first,
      );
      await controller.submit(saved.id);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.draft == null;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isNew ? 'Nouveau brouillon' : 'Modifier le brouillon',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _documentId,
                        enabled: isNew,
                        decoration: const InputDecoration(labelText: 'Identifiant (ex. doc-code-travail)'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(controller: _title, decoration: const InputDecoration(labelText: 'Titre')),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<LegalDocumentType>(
                              initialValue: _type,
                              decoration: const InputDecoration(labelText: 'Type'),
                              items: [
                                for (final t in LegalDocumentType.values)
                                  DropdownMenuItem(value: t, child: Text(t.name)),
                              ],
                              onChanged: (v) => setState(() => _type = v ?? _type),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: DropdownButtonFormField<LegalDomain>(
                              initialValue: _domain,
                              decoration: const InputDecoration(labelText: 'Branche'),
                              items: [
                                for (final d in LegalDomain.values)
                                  DropdownMenuItem(value: d, child: Text(d.label)),
                              ],
                              onChanged: (v) => setState(() => _domain = v ?? _domain),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _reference,
                              decoration: const InputDecoration(labelText: 'Référence'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: DropdownButtonFormField<LegalDocumentStatus>(
                              initialValue: _status,
                              decoration: const InputDecoration(labelText: 'Statut'),
                              items: [
                                for (final s in LegalDocumentStatus.values)
                                  DropdownMenuItem(value: s, child: Text(s.label)),
                              ],
                              onChanged: (v) => setState(() => _status = v ?? _status),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _summary,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Résumé'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _fullContent,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Texte intégral en prose (laisser vide si structuré en articles)',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _tags,
                        decoration: const InputDecoration(labelText: 'Mots-clés (séparés par des virgules)'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _officialSource,
                              decoration: const InputDecoration(labelText: 'Source officielle'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: TextField(
                              controller: _sourceUrl,
                              decoration: const InputDecoration(labelText: 'URL source'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _articlesJson,
                        maxLines: 6,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
                        decoration: InputDecoration(
                          labelText: 'Articles (JSON — sortie de tools/legal_import fetch/parse)',
                          alignLabelWithHint: true,
                          errorText: _articlesError,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: _saving ? null : () => _save(andSubmit: false),
                    child: const Text('Enregistrer le brouillon'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: _saving ? null : () => _save(andSubmit: true),
                    style: FilledButton.styleFrom(backgroundColor: AdminTheme.accent),
                    child: const Text('Enregistrer et soumettre'),
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16),
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
