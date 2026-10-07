import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../core/widgets/entrance_fade.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/luxury_scaffold_background.dart';
import '../../../models/legal_document/legal_document_model.dart';
import '../../../models/legal_document/legal_domain.dart';
import '../../../theme/app_theme.dart';
import '../../auth/staff_role.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_ambience.dart';
import '../../widgets/admin_empty_state.dart';
import '../../widgets/admin_filter_chip.dart';
import '../../widgets/admin_page_header.dart';
import '../../widgets/admin_section_card.dart';
import '../../widgets/admin_status_chip.dart';
import 'admin_document_draft.dart';
import 'admin_document_draft_controller.dart';
import 'admin_document_draft_repository.dart';

/// Console — CMS Bibliothèque : la file des brouillons de textes et leur
/// circuit de relecture (voir migration_012_legal_document_review.sql).
/// L'éditeur d'articles est structuré (numéro, intitulé, fil hiérarchique,
/// corps, réordonnancement) — voir `_ArticleEditorItem`/`_ArticleEditorCard`
/// — tout en restant compatible avec la sortie de `tools/legal_import`
/// (fetch/parse) via le bouton « Importer un JSON ».
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

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              AdminPageHeader(
                icon: Icons.menu_book_rounded,
                title: 'CMS Bibliothèque',
                subtitle: 'Pilotez les textes, les validations et la publication de la base juridique.',
                actions: [
                  IconButton(
                    tooltip: 'Actualiser le CMS',
                    onPressed: controller.isLoading ? null : controller.load,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                  if (identity.canEditContent)
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.xs),
                      child: FilledButton.icon(
                        onPressed: () => _openEditor(context, controller),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Nouveau texte'),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Stack(
                  children: [
                    const Positioned.fill(child: IgnorePointer(child: AdminAmbience())),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 1180;
                        return ListView(
                          padding: EdgeInsets.fromLTRB(
                            wide ? AppSpacing.xl : AppSpacing.md,
                            AppSpacing.lg,
                            wide ? AppSpacing.xl : AppSpacing.md,
                            AppSpacing.xl,
                          ),
                          children: [
                            _CmsHero(
                              total: controller.totalCount,
                              published: controller.countFor(DocumentDraftStatus.published),
                              inReview: controller.countFor(DocumentDraftStatus.inReview),
                              canCreate: identity.canEditContent,
                              onCreate: () => _openEditor(context, controller),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _CmsStatsStrip(controller: controller),
                            const SizedBox(height: AppSpacing.lg),
                            if (controller.error != null)
                              AdminErrorBanner(message: controller.error!, onDismiss: controller.dismissError),
                            _WorkflowCard(
                              controller: controller,
                              identity: identity,
                              onRefresh: controller.load,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (controller.isLoading && controller.drafts.isEmpty)
                              const SizedBox(
                                height: 260,
                                child: Center(child: CircularProgressIndicator()),
                              )
                            else if (controller.drafts.isEmpty)
                              const SizedBox(
                                height: 280,
                                child: AdminEmptyState(
                                  icon: Icons.description_outlined,
                                  message: 'Aucun texte dans cette vue.',
                                ),
                              )
                            else
                              _DraftWorkspace(
                                drafts: controller.drafts,
                                identity: identity,
                                busy: controller.isMutating,
                                wide: wide,
                                onEdit: (draft) => _openEditor(context, controller, draft: draft),
                                onSubmit: controller.submit,
                                onApprove: controller.approve,
                                onRequestChanges: (draft) => _promptReason(
                                  context,
                                  title: 'Renvoyer en correction',
                                  label: 'Motif (obligatoire)',
                                  onConfirm: (reason) => controller.requestChanges(draft.id, reason),
                                ),
                                onArchive: (draft) => _promptReason(
                                  context,
                                  title: 'Archiver ce texte',
                                  label: 'Motif (facultatif)',
                                  requireReason: false,
                                  onConfirm: (reason) => controller.archiveDocument(
                                    draft.documentId,
                                    reason.isEmpty ? null : reason,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
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

class _CmsHero extends StatelessWidget {
  const _CmsHero({
    required this.total,
    required this.published,
    required this.inReview,
    required this.canCreate,
    required this.onCreate,
  });

  final int total;
  final int published;
  final int inReview;
  final bool canCreate;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.large),
        gradient: LinearGradient(
          colors: [
            AdminTheme.accentDark.withValues(alpha: 0.88),
            AppColors.nightBlue.withValues(alpha: 0.86),
            AppColors.deepSlateDeep.withValues(alpha: 0.94),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AdminTheme.accentLight.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(color: AdminTheme.accent.withValues(alpha: 0.16), blurRadius: 32, spreadRadius: -10),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          final intro = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.42)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome_rounded, size: 15, color: AppColors.gold),
                        const SizedBox(width: 7),
                        Text(
                          'ATELIER ÉDITORIAL',
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.gold,
                            letterSpacing: AppLetterSpacing.caps,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      'SOURCE JURIDIQUE',
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: AppLetterSpacing.caps,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'La bibliothèque,\navec une ligne éditoriale.',
                style: (compact ? textTheme.headlineSmall : textTheme.headlineMedium)?.copyWith(
                  fontFamily: 'Libre Caslon Display',
                  color: AppColors.textPrimary,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 590),
                child: Text(
                  'Préparez des contenus fiables, orchestrez la relecture et publiez chaque référence avec une traçabilité claire.',
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.45),
                ),
              ),
              if (compact) ...[
                const SizedBox(height: AppSpacing.md),
                if (canCreate)
                  FilledButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Créer un brouillon'),
                  ),
              ],
            ],
          );
          final signal = Container(
            constraints: BoxConstraints(minWidth: compact ? 0 : 235, maxWidth: 290),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.055),
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SIGNAL DE PUBLICATION', style: textTheme.labelSmall?.copyWith(color: AdminTheme.accentLight, letterSpacing: AppLetterSpacing.caps, fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.sm),
                _HeroMetric(label: 'Textes suivis', value: '$total', icon: Icons.library_books_rounded),
                const SizedBox(height: AppSpacing.sm),
                _HeroMetric(label: 'En ligne', value: '$published', icon: Icons.public_rounded, color: AppColors.success),
                const SizedBox(height: AppSpacing.sm),
                _HeroMetric(label: 'À relire', value: '$inReview', icon: Icons.rate_review_rounded, color: AppColors.warning),
              ],
            ),
          );
          return compact ? intro : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: intro), const SizedBox(width: AppSpacing.lg), signal]);
        },
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value, required this.icon, this.color = AdminTheme.accentLight});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 9),
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary))),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _CmsStatsStrip extends StatelessWidget {
  const _CmsStatsStrip({required this.controller});
  final AdminDocumentDraftController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 680;
        final cards = [
          _CmsStat(label: 'Total', value: controller.totalCount, icon: Icons.layers_rounded, color: AdminTheme.accentLight, hint: 'textes suivis'),
          _CmsStat(label: 'Brouillons', value: controller.countFor(DocumentDraftStatus.draft), icon: Icons.edit_note_rounded, color: AppColors.textSecondary, hint: 'à préparer'),
          _CmsStat(label: 'En relecture', value: controller.countFor(DocumentDraftStatus.inReview), icon: Icons.rate_review_rounded, color: AppColors.warning, hint: 'à arbitrer'),
          _CmsStat(label: 'Publié', value: controller.countFor(DocumentDraftStatus.published), icon: Icons.verified_rounded, color: AppColors.success, hint: 'visible au public'),
        ];
        return compact
            ? Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [for (final card in cards) SizedBox(width: (constraints.maxWidth - AppSpacing.sm) / 2, child: card)])
            : Row(children: [for (var i = 0; i < cards.length; i++) Expanded(child: Padding(padding: EdgeInsets.only(right: i == cards.length - 1 ? 0 : AppSpacing.sm), child: cards[i]))]);
      },
    );
  }
}

class _CmsStat extends StatelessWidget {
  const _CmsStat({required this.label, required this.value, required this.icon, required this.color, required this.hint});
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textDisabled, letterSpacing: AppLetterSpacing.caps, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('$value', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontFamily: 'Libre Caslon Display', color: AppColors.textPrimary)),
              Text(hint, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _WorkflowCard extends StatelessWidget {
  const _WorkflowCard({required this.controller, required this.identity, required this.onRefresh});
  final AdminDocumentDraftController controller;
  final StaffIdentity identity;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      title: 'File éditoriale',
      icon: Icons.tune_rounded,
      trailing: IconButton(tooltip: 'Actualiser la file', onPressed: controller.isLoading ? null : onRefresh, icon: const Icon(Icons.sync_rounded, size: 19)),
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Organisez votre prochain geste éditorial.', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
              if (identity.canReviewDocuments)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(AppRadius.pill)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.verified_user_outlined, size: 14, color: AppColors.success), const SizedBox(width: 6), Text('Droits de revue actifs', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.success, fontWeight: FontWeight.w700))]),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Chaque filtre conserve le circuit de validation et les actions autorisées par votre rôle.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          _FilterBar(controller: controller),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.controller});
  final AdminDocumentDraftController controller;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, DocumentDraftStatus? status, IconData icon) {
      final count = status == null ? controller.totalCount : controller.countFor(status);
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: AdminFilterChip(label: label, count: count, selected: controller.filter == status, onTap: () => controller.setFilter(status)),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        chip('Toutes les vues', null, Icons.layers_rounded),
        for (final status in DocumentDraftStatus.values) chip(status.label, status, Icons.circle_rounded),
      ]),
    );
  }
}

class _DraftWorkspace extends StatelessWidget {
  const _DraftWorkspace({
    required this.drafts,
    required this.identity,
    required this.busy,
    required this.wide,
    required this.onEdit,
    required this.onSubmit,
    required this.onApprove,
    required this.onRequestChanges,
    required this.onArchive,
  });

  final List<AdminDocumentDraft> drafts;
  final StaffIdentity identity;
  final bool busy;
  final bool wide;
  final ValueChanged<AdminDocumentDraft> onEdit;
  final Future<bool> Function(String id) onSubmit;
  final Future<bool> Function(String id) onApprove;
  final ValueChanged<AdminDocumentDraft> onRequestChanges;
  final ValueChanged<AdminDocumentDraft> onArchive;

  @override
  Widget build(BuildContext context) {
    final cards = [
      for (var i = 0; i < drafts.length; i++)
        EntranceFadeSlide(
          index: i,
          child: _DraftCard(
            draft: drafts[i],
            identity: identity,
            busy: busy,
            onEdit: () => onEdit(drafts[i]),
            onSubmit: () => onSubmit(drafts[i].id),
            onApprove: () => onApprove(drafts[i].id),
            onRequestChanges: () => onRequestChanges(drafts[i]),
            onArchive: () => onArchive(drafts[i]),
          ),
        ),
    ];
    final content = wide
        ? Wrap(spacing: AppSpacing.md, runSpacing: AppSpacing.md, children: [for (final card in cards) SizedBox(width: 420, child: card)])
        : Column(children: [for (var i = 0; i < cards.length; i++) Padding(padding: EdgeInsets.only(bottom: i == cards.length - 1 ? 0 : AppSpacing.md), child: cards[i])]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Expanded(child: Text('Textes à piloter', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontFamily: 'Libre Caslon Display'))), Text('${drafts.length} résultat${drafts.length > 1 ? 's' : ''}', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary))]),
        const SizedBox(height: AppSpacing.sm),
        content,
      ],
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({required this.draft, required this.identity, required this.busy, required this.onEdit, required this.onSubmit, required this.onApprove, required this.onRequestChanges, required this.onArchive});
  final AdminDocumentDraft draft;
  final StaffIdentity identity;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onSubmit;
  final VoidCallback onApprove;
  final VoidCallback onRequestChanges;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final statusColor = draftStatusColor(draft.status);
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.medium)), child: Icon(_draftIcon(draft.status), color: statusColor, size: 21)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [AdminStatusChip(label: draft.status.label, color: statusColor), const Spacer(), Text(_formatCmsDate(draft.updatedAt), style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled))]),
            const SizedBox(height: 7),
            Text(draft.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ])),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Wrap(spacing: 6, runSpacing: 6, children: [_MiniTag(draft.type), _MiniTag(draft.domain), if (draft.articleCount > 0) _MiniTag('${draft.articleCount} article${draft.articleCount > 1 ? 's' : ''}')]),
        if (draft.reference.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.bookmark_border_rounded, size: 15, color: AdminTheme.accentLight), const SizedBox(width: 6), Expanded(child: Text(draft.reference, maxLines: 2, overflow: TextOverflow.ellipsis, style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)))])
        ],
        if (draft.summary.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(draft.summary, maxLines: 3, overflow: TextOverflow.ellipsis, style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.35)),
        ],
        if (draft.status == DocumentDraftStatus.changesRequested && draft.reviewReason != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(width: double.infinity, padding: const EdgeInsets.all(AppSpacing.sm), decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(AppRadius.small), border: Border.all(color: AppColors.warning.withValues(alpha: 0.18))), child: Text('Correction demandée · ${draft.reviewReason}', style: textTheme.bodySmall?.copyWith(color: AppColors.warning, height: 1.3))),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(children: [Icon(Icons.person_outline_rounded, size: 15, color: AppColors.textDisabled), const SizedBox(width: 6), Expanded(child: Text(_draftOwnerLabel(draft), maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled)))]),
        const SizedBox(height: AppSpacing.md),
        Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
          if (draft.canEdit && identity.canEditContent) ...[
            OutlinedButton.icon(onPressed: busy ? null : onEdit, icon: const Icon(Icons.edit_rounded, size: 15), label: const Text('Modifier')),
            FilledButton.icon(onPressed: busy ? null : onSubmit, style: FilledButton.styleFrom(backgroundColor: AdminTheme.accent), icon: const Icon(Icons.send_rounded, size: 15), label: const Text('Soumettre')),
          ],
          if (draft.status == DocumentDraftStatus.inReview && identity.canReviewDocuments) ...[
            OutlinedButton.icon(onPressed: busy ? null : onRequestChanges, icon: const Icon(Icons.undo_rounded, size: 15), label: const Text('Corrections')),
            FilledButton.icon(onPressed: busy ? null : onApprove, style: FilledButton.styleFrom(backgroundColor: AppColors.success), icon: const Icon(Icons.check_rounded, size: 15), label: const Text('Approuver')),
          ],
          if (draft.status == DocumentDraftStatus.published && identity.canReviewDocuments) OutlinedButton.icon(onPressed: busy ? null : onArchive, icon: const Icon(Icons.archive_outlined, size: 15), label: const Text('Archiver')),
        ]),
      ]),
    );
  }
}

IconData _draftIcon(DocumentDraftStatus status) {
  switch (status) {
    case DocumentDraftStatus.draft:
      return Icons.edit_note_rounded;
    case DocumentDraftStatus.inReview:
      return Icons.rate_review_rounded;
    case DocumentDraftStatus.changesRequested:
      return Icons.warning_amber_rounded;
    case DocumentDraftStatus.published:
      return Icons.public_rounded;
    case DocumentDraftStatus.archived:
      return Icons.inventory_2_outlined;
  }
}

String _draftOwnerLabel(AdminDocumentDraft draft) {
  if (draft.reviewedByEmail != null) return 'Relu par ${draft.reviewedByEmail}';
  if (draft.createdByEmail != null) return 'Créé par ${draft.createdByEmail}';
  return 'Auteur non renseigné';
}

String _formatCmsDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

class _MiniTag extends StatelessWidget {
  const _MiniTag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.legalBlueDark.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
    );
  }
}

/// Un article en cours d'édition — mêmes champs qu'`ImportedArticle`
/// (tools/legal_import) : `number`, `heading`, `body`, `path` (fil
/// hiérarchique, ex. Livre I › Titre II). L'ordre dans la liste EST l'ordre
/// de publication (`ord`), il n'y a pas de champ dédié.
class _ArticleEditorItem {
  _ArticleEditorItem({String? number, String? heading, String? body, List<String>? path})
      : number = TextEditingController(text: number ?? ''),
        heading = TextEditingController(text: heading ?? ''),
        body = TextEditingController(text: body ?? ''),
        path = TextEditingController(text: (path ?? const []).join(' › '));

  factory _ArticleEditorItem.fromJson(Map<String, dynamic> j) => _ArticleEditorItem(
        number: j['number'] as String?,
        heading: j['heading'] as String?,
        body: j['body'] as String?,
        path: (j['path'] as List?)?.cast<String>(),
      );

  final TextEditingController number;
  final TextEditingController heading;
  final TextEditingController body;
  final TextEditingController path;

  bool get isBlank => number.text.trim().isEmpty && body.text.trim().isEmpty;

  Map<String, dynamic> toJson() => {
        'number': number.text.trim(),
        'heading': heading.text.trim(),
        'body': body.text.trim(),
        'path': path.text.split('›').map((p) => p.trim()).where((p) => p.isNotEmpty).toList(),
      };

  void dispose() {
    number.dispose();
    heading.dispose();
    body.dispose();
    path.dispose();
  }
}

/// Formulaire de brouillon — les champs de `ImportedDocument.toJson()`
/// (voir tools/legal_import), avec un éditeur d'articles structuré (numéro,
/// intitulé, fil hiérarchique, corps) plutôt qu'un JSON brut — tout en
/// restant strictement compatible avec la sortie de `tools/legal_import
/// fetch`/`parse` (mêmes champs, on peut toujours coller ce JSON via
/// « Importer un JSON » puis continuer à l'éditer ici article par article).
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
  late final List<_ArticleEditorItem> _articles = [
    for (final a in (widget.draft?.payload['articles'] as List? ?? const []))
      _ArticleEditorItem.fromJson((a as Map).cast<String, dynamic>()),
  ];

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

  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _documentId, _title, _reference, _summary, _fullContent,
      _sourceUrl, _officialSource, _tags,
    ]) {
      c.dispose();
    }
    for (final a in _articles) {
      a.dispose();
    }
    super.dispose();
  }

  Future<void> _importJson() async {
    final pasteController = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importer un JSON'),
        content: SizedBox(
          width: 480,
          child: TextField(
            controller: pasteController,
            maxLines: 12,
            autofocus: true,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
            decoration: const InputDecoration(
              hintText: 'Collez ici la sortie de tools/legal_import fetch/parse '
                  '(ou un export précédent) : { "title": ..., "articles": [...] }',
              alignLabelWithHint: true,
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(pasteController.text),
            child: const Text('Importer'),
          ),
        ],
      ),
    );
    pasteController.dispose();
    if (raw == null || raw.trim().isEmpty || !mounted) return;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      setState(() {
        if (widget.draft == null) {
          // L'identifiant ne se modifie plus une fois le brouillon créé
          // (champ désactivé, voir plus bas) — ne le réécrire qu'à la
          // création.
          _documentId.text = decoded['id'] as String? ?? _documentId.text;
        }
        _title.text = decoded['title'] as String? ?? _title.text;
        _reference.text = decoded['reference'] as String? ?? _reference.text;
        _summary.text = decoded['summary'] as String? ?? _summary.text;
        _fullContent.text = decoded['full_content'] as String? ?? _fullContent.text;
        _sourceUrl.text = decoded['source_url'] as String? ?? _sourceUrl.text;
        _officialSource.text = decoded['official_source_name'] as String? ?? _officialSource.text;
        final tags = (decoded['tags'] as List?)?.cast<String>();
        if (tags != null) _tags.text = tags.join(', ');
        final type = LegalDocumentType.values.where((t) => t.name == decoded['type']).firstOrNull;
        if (type != null) _type = type;
        final domain = LegalDomain.values.where((d) => d.name == decoded['domain']).firstOrNull;
        if (domain != null) _domain = domain;

        for (final a in _articles) {
          a.dispose();
        }
        _articles
          ..clear()
          ..addAll([
            for (final a in (decoded['articles'] as List? ?? const []))
              _ArticleEditorItem.fromJson((a as Map).cast<String, dynamic>()),
          ]);
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('JSON invalide : $error')),
        );
      }
    }
  }

  Future<void> _save({required bool andSubmit}) async {
    if (_documentId.text.trim().isEmpty || _title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Identifiant et titre sont obligatoires.')),
      );
      return;
    }
    final articles = [
      for (final a in _articles)
        if (!a.isBlank) a.toJson(),
    ];
    setState(() => _saving = true);

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
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 840),
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
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Text('Articles', style: Theme.of(context).textTheme.titleSmall),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _importJson,
                            icon: const Icon(Icons.upload_file_rounded, size: 16),
                            label: const Text('Importer un JSON'),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          OutlinedButton.icon(
                            onPressed: () => setState(() => _articles.add(_ArticleEditorItem())),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Ajouter un article'),
                          ),
                        ],
                      ),
                      if (_articles.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          child: Text(
                            'Aucun article — laissez vide pour un texte en prose (« Texte intégral » '
                            'ci-dessus), ou ajoutez les articles un par un.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      for (var i = 0; i < _articles.length; i++)
                        _ArticleEditorCard(
                          key: ObjectKey(_articles[i]),
                          item: _articles[i],
                          index: i,
                          canMoveUp: i > 0,
                          canMoveDown: i < _articles.length - 1,
                          onMoveUp: () => setState(() {
                            final item = _articles.removeAt(i);
                            _articles.insert(i - 1, item);
                          }),
                          onMoveDown: () => setState(() {
                            final item = _articles.removeAt(i);
                            _articles.insert(i + 1, item);
                          }),
                          onDelete: () => setState(() => _articles.removeAt(i).dispose()),
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

/// Une carte d'édition pour un article : numéro, intitulé, fil hiérarchique
/// et corps du texte, avec réordonnancement (monter/descendre) et
/// suppression. L'ordre des cartes dans le formulaire EST l'ordre de
/// publication de l'article.
class _ArticleEditorCard extends StatelessWidget {
  const _ArticleEditorCard({
    super.key,
    required this.item,
    required this.index,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
  });

  final _ArticleEditorItem item;
  final int index;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.legalBlueDark.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Article ${index + 1}',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.textDisabled, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Monter',
                onPressed: canMoveUp ? onMoveUp : null,
                icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
              IconButton(
                tooltip: 'Descendre',
                onPressed: canMoveDown ? onMoveDown : null,
                icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
              IconButton(
                tooltip: 'Supprimer cet article',
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
          Row(
            children: [
              SizedBox(
                width: 100,
                child: TextField(
                  controller: item.number,
                  decoration: const InputDecoration(labelText: 'Numéro', isDense: true),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: item.heading,
                  decoration: const InputDecoration(labelText: 'Intitulé (facultatif)', isDense: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: item.path,
            decoration: const InputDecoration(
              labelText: 'Fil hiérarchique — ex. Livre I › Titre II (séparé par ›)',
              isDense: true,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: item.body,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Corps de l\'article', alignLabelWithHint: true),
          ),
        ],
      ),
    );
  }
}
