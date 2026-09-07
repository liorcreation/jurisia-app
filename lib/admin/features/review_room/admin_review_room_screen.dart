import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/ai/groq_providers.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/widgets/entrance_fade.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/gradient_icon_badge.dart';
import '../../../core/widgets/luxury_scaffold_background.dart';
import '../../../theme/app_theme.dart';
import '../../auth/staff_role.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_ambience.dart';
import '../../widgets/admin_empty_state.dart';
import '../../widgets/admin_page_header.dart';
import '../../widgets/admin_stat_card.dart';
import '../library_cms/admin_document_draft.dart';
import '../library_cms/admin_document_draft_controller.dart';
import '../library_cms/admin_document_draft_repository.dart';
import '../prompt_studio/admin_ai_prompt.dart';
import '../prompt_studio/admin_prompt_controller.dart';
import '../prompt_studio/admin_prompt_repository.dart';

/// Console — Salle de revue : la file d'attente unique de tout ce qui
/// attend une décision d'un relecteur, tous types de contenu confondus
/// (brouillons de textes en relecture, prompts testés en attente de
/// publication). N'ajoute aucune donnée ni RPC : réutilise tel quel ce que
/// vendent déjà `jurisia_admin_list_document_drafts` et
/// `jurisia_admin_list_prompts`, juste réuni en une seule file triée par
/// ancienneté — pour ne pas avoir à faire le tour de chaque écran de la
/// console à mesure que le nombre de types de contenu relus grandit.
class AdminReviewRoomScreen extends StatelessWidget {
  const AdminReviewRoomScreen({super.key, required this.identity});

  final StaffIdentity identity;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AdminDocumentDraftController>(
          create: (_) => AdminDocumentDraftController(
            repository: SupabaseAdminDocumentDraftRepository(client: SupabaseConfig.client),
          ),
        ),
        ChangeNotifierProvider<AdminPromptController>(
          create: (_) => AdminPromptController(
            repository: SupabaseAdminPromptRepository(
              client: SupabaseConfig.client,
              llm: buildGroqDataSource(),
            ),
          ),
        ),
      ],
      child: _View(identity: identity),
    );
  }
}

class _QueueEntry {
  const _QueueEntry({required this.when, required this.card});
  final DateTime when;
  final Widget card;
}

class _View extends StatelessWidget {
  const _View({required this.identity});

  final StaffIdentity identity;

  @override
  Widget build(BuildContext context) {
    final docController = context.watch<AdminDocumentDraftController>();
    final promptController = context.watch<AdminPromptController>();
    final busy = docController.isMutating || promptController.isMutating;

    final pendingDocs = identity.canReviewDocuments
        ? docController.drafts.where((d) => d.status == DocumentDraftStatus.inReview).length
        : 0;
    final pendingPrompts = identity.canPublishPrompts
        ? promptController.prompts.where((p) => p.status == AiPromptStatus.tested).length
        : 0;

    final entries = <_QueueEntry>[
      if (identity.canReviewDocuments)
        for (final d in docController.drafts)
          if (d.status == DocumentDraftStatus.inReview)
            _QueueEntry(
              when: d.updatedAt,
              card: _DocQueueCard(
                draft: d,
                busy: busy,
                onApprove: () => docController.approve(d.id),
                onRequestChanges: () => _promptReason(
                  context,
                  title: 'Renvoyer en correction',
                  label: 'Motif (obligatoire)',
                  onConfirm: (reason) => docController.requestChanges(d.id, reason),
                ),
              ),
            ),
      if (identity.canPublishPrompts)
        for (final p in promptController.prompts)
          if (p.status == AiPromptStatus.tested)
            _QueueEntry(
              when: p.updatedAt,
              card: _PromptQueueCard(
                prompt: p,
                busy: busy,
                onPublish: () => promptController.publish(p.id),
              ),
            ),
    ]..sort((a, b) => b.when.compareTo(a.when));

    final loading = docController.isLoading || promptController.isLoading;
    final error = docController.error ?? promptController.error;

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              AdminPageHeader(
                icon: Icons.fact_check_rounded,
                title: 'Salle de revue',
                subtitle: 'Tout ce qui attend une décision d\'un relecteur, triés par ancienneté.',
                actions: [
                  IconButton(
                    tooltip: 'Rafraîchir',
                    onPressed: (docController.isLoading || promptController.isLoading)
                        ? null
                        : () {
                            docController.load();
                            promptController.load();
                          },
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              if (error != null)
                AdminErrorBanner(
                  message: error,
                  onDismiss: () {
                    docController.dismissError();
                    promptController.dismissError();
                  },
                ),
              Expanded(
                child: Stack(
                  children: [
                    const Positioned.fill(child: IgnorePointer(child: AdminAmbience())),
                    loading && entries.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : entries.isEmpty
                            ? const AdminEmptyState(
                                icon: Icons.spa_rounded,
                                message: 'Rien à relire pour le moment.',
                                detail: 'La file se vide au fil des décisions — reviens plus tard.',
                              )
                            : Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 760),
                                  child: ListView(
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    children: [
                                      IntrinsicHeight(
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Expanded(
                                              child: AdminStatCard(
                                                icon: Icons.menu_book_rounded,
                                                label: 'Textes en relecture',
                                                value: '$pendingDocs',
                                                accentColor: AdminTheme.accentLight,
                                              ),
                                            ),
                                            const SizedBox(width: AppSpacing.md),
                                            Expanded(
                                              child: AdminStatCard(
                                                icon: Icons.auto_awesome_rounded,
                                                label: 'Prompts testés',
                                                value: '$pendingPrompts',
                                                accentColor: AppColors.gold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      for (var i = 0; i < entries.length; i++)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                          child: EntranceFadeSlide(index: i, child: entries[i].card),
                                        ),
                                    ],
                                  ),
                                ),
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

  Future<void> _promptReason(
    BuildContext context, {
    required String title,
    required String label,
    required Future<bool> Function(String reason) onConfirm,
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
    if (confirmed != true || controller.text.trim().isEmpty) return;
    await onConfirm(controller.text.trim());
  }
}

class _DocQueueCard extends StatelessWidget {
  const _DocQueueCard({
    required this.draft,
    required this.busy,
    required this.onApprove,
    required this.onRequestChanges,
  });

  final AdminDocumentDraft draft;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onRequestChanges;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: AdminTheme.accentLight.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GradientIconBadge(
                icon: Icons.menu_book_rounded,
                size: 38,
                gradient: AdminGradients.cobaltMetallic,
                iconColor: AppColors.textPrimary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'CMS Bibliothèque',
                      style: textTheme.labelSmall?.copyWith(
                        color: AdminTheme.accentLight,
                        fontWeight: FontWeight.w700,
                        letterSpacing: AppLetterSpacing.caps,
                      ),
                    ),
                    Text(
                      draft.documentId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(draft.title, style: textTheme.titleSmall),
          if (draft.summary.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              draft.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          if (draft.createdByEmail != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Soumis par ${draft.createdByEmail}',
              style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
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
          ),
        ],
      ),
    );
  }
}

class _PromptQueueCard extends StatelessWidget {
  const _PromptQueueCard({required this.prompt, required this.busy, required this.onPublish});

  final AdminAiPrompt prompt;
  final bool busy;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: AppColors.gold.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GradientIconBadge(
                icon: Icons.auto_awesome_rounded,
                size: 38,
                gradient: AppGradients.goldMetallic,
                iconColor: AppColors.nightBlueDeep,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Studio de prompts',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.goldLight,
                        fontWeight: FontWeight.w700,
                        letterSpacing: AppLetterSpacing.caps,
                      ),
                    ),
                    Text(PromptKey.label(prompt.key), style: textTheme.titleSmall),
                  ],
                ),
              ),
            ],
          ),
          if (prompt.testMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              'Testé avec : « ${prompt.testMessage} »',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          if (prompt.createdByEmail != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Rédigé par ${prompt.createdByEmail}',
              style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            onPressed: busy ? null : onPublish,
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            icon: const Icon(Icons.publish_rounded, size: 15),
            label: const Text('Publier'),
          ),
        ],
      ),
    );
  }
}
