import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/ai/groq_providers.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/widgets/entrance_fade.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/gradient_icon_badge.dart';
import '../../../core/widgets/luxury_scaffold_background.dart';
import '../../../core/widgets/premium_surface.dart';
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

/// Salle de revue : file unique des contenus qui attendent une décision.
/// Les contrôleurs et RPC restent inchangés ; cet écran donne au relecteur
/// une surface plus lisible pour comprendre, vérifier et décider.
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

enum _ReviewLane { all, documents, prompts }

class _QueueEntry {
  const _QueueEntry({required this.when, required this.lane, required this.card});

  final DateTime when;
  final _ReviewLane lane;
  final Widget card;
}

class _View extends StatefulWidget {
  const _View({required this.identity});

  final StaffIdentity identity;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  _ReviewLane _lane = _ReviewLane.all;

  @override
  Widget build(BuildContext context) {
    final docController = context.watch<AdminDocumentDraftController>();
    final promptController = context.watch<AdminPromptController>();
    final busy = docController.isMutating || promptController.isMutating;
    final pendingDocs = widget.identity.canReviewDocuments
        ? docController.drafts.where((d) => d.status == DocumentDraftStatus.inReview).length
        : 0;
    final pendingPrompts = widget.identity.canPublishPrompts
        ? promptController.prompts.where((p) => p.status == AiPromptStatus.tested).length
        : 0;
    final total = pendingDocs + pendingPrompts;
    final entries = _buildEntries(
      context,
      docController: docController,
      promptController: promptController,
      busy: busy,
    );
    final visibleEntries = entries
        .where((entry) => _lane == _ReviewLane.all || entry.lane == _lane)
        .toList();
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
                subtitle: 'Le cockpit des décisions éditoriales de JurisIA.',
                actions: [
                  _HeaderStatus(count: total),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    tooltip: 'Rafraîchir la file',
                    onPressed: loading
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
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 1080;
                        final content = _ReviewContent(
                          identity: widget.identity,
                          total: total,
                          pendingDocs: pendingDocs,
                          pendingPrompts: pendingPrompts,
                          lane: _lane,
                          onLaneChanged: (lane) => setState(() => _lane = lane),
                          entries: visibleEntries,
                          loading: loading,
                          busy: busy,
                        );

                        if (!wide) return content;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: content),
                            const SizedBox(width: AppSpacing.md),
                            const SizedBox(width: 300, child: _ReviewGuide()),
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

  List<_QueueEntry> _buildEntries(
    BuildContext context, {
    required AdminDocumentDraftController docController,
    required AdminPromptController promptController,
    required bool busy,
  }) {
    final entries = <_QueueEntry>[];
    if (widget.identity.canReviewDocuments) {
      for (final draft in docController.drafts) {
        if (draft.status != DocumentDraftStatus.inReview) continue;
        entries.add(
          _QueueEntry(
            when: draft.updatedAt,
            lane: _ReviewLane.documents,
            card: _DocQueueCard(
              draft: draft,
              busy: busy,
              onApprove: () => docController.approve(draft.id),
              onRequestChanges: () => _promptReason(
                context,
                title: 'Renvoyer en correction',
                label: 'Motif obligatoire',
                onConfirm: (reason) => docController.requestChanges(draft.id, reason),
              ),
            ),
          ),
        );
      }
    }
    if (widget.identity.canPublishPrompts) {
      for (final prompt in promptController.prompts) {
        if (prompt.status != AiPromptStatus.tested) continue;
        entries.add(
          _QueueEntry(
            when: prompt.updatedAt,
            lane: _ReviewLane.prompts,
            card: _PromptQueueCard(
              prompt: prompt,
              busy: busy,
              onPublish: () => promptController.publish(prompt.id),
            ),
          ),
        );
      }
    }
    entries.sort((a, b) => b.when.compareTo(a.when));
    return entries;
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
          maxLines: 4,
          autofocus: true,
          decoration: InputDecoration(labelText: label, hintText: 'Expliquez ce qui doit être repris…'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirmer')),
        ],
      ),
    );
    final reason = controller.text.trim();
    controller.dispose();
    if (confirmed != true || reason.isEmpty) return;
    await onConfirm(reason);
  }
}

class _ReviewContent extends StatelessWidget {
  const _ReviewContent({
    required this.identity,
    required this.total,
    required this.pendingDocs,
    required this.pendingPrompts,
    required this.lane,
    required this.onLaneChanged,
    required this.entries,
    required this.loading,
    required this.busy,
  });

  final StaffIdentity identity;
  final int total;
  final int pendingDocs;
  final int pendingPrompts;
  final _ReviewLane lane;
  final ValueChanged<_ReviewLane> onLaneChanged;
  final List<_QueueEntry> entries;
  final bool loading;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
      children: [
        const _ReviewHero(),
        const SizedBox(height: AppSpacing.md),
        _StatsRow(pendingDocs: pendingDocs, pendingPrompts: pendingPrompts, total: total),
        const SizedBox(height: AppSpacing.xl),
        PremiumSectionHeader(
          eyebrow: 'FILE ACTIVE',
          title: 'À décider',
          subtitle: total == 0
              ? 'Aucun contenu ne nécessite votre arbitrage pour le moment.'
              : '$total élément${total == 1 ? '' : 's'} prêt${total == 1 ? '' : 's'} pour une décision.',
          action: _LaneFilters(selected: lane, onChanged: onLaneChanged),
        ),
        const SizedBox(height: AppSpacing.md),
        loading && entries.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: Center(child: CircularProgressIndicator()),
              )
            : entries.isEmpty
                ? const AdminEmptyState(
                    icon: Icons.spa_rounded,
                    message: 'La file est claire.',
                    detail: 'Les nouveaux contenus apparaîtront ici dès qu’ils seront prêts à relire.',
                  )
                : Column(
                    children: [
                      for (var i = 0; i < entries.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: EntranceFadeSlide(index: i, child: entries[i].card),
                        ),
                    ],
                  ),
        if (busy) ...[
          const SizedBox(height: AppSpacing.sm),
          const LinearProgressIndicator(minHeight: 2),
        ],
        const SizedBox(height: AppSpacing.md),
        _PermissionsStrip(identity: identity),
      ],
    );
  }
}

class _ReviewHero extends StatelessWidget {
  const _ReviewHero();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return PremiumSurface(
      tone: PremiumSurfaceTone.cobalt,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 580;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const GradientIconBadge(
                    icon: Icons.shield_moon_rounded,
                    size: 48,
                    gradient: AdminGradients.cobaltMetallic,
                    iconColor: AppColors.textPrimary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.32)),
                    ),
                    child: Text(
                      'ESPACE OPÉRATIONNEL',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                        letterSpacing: AppLetterSpacing.label,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Chaque décision renforce la qualité de JurisIA.',
                style: textTheme.headlineSmall?.copyWith(
                  fontFamily: 'Libre Caslon Display',
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Relisez les textes et les prompts avec le même niveau d’exigence : contexte, cohérence, puis décision traçable.',
                style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.45),
              ),
            ],
          );
          final signal = Container(
            width: compact ? double.infinity : 172,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.deepSlateDeep.withValues(alpha: 0.48),
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_graph_rounded, color: AppColors.goldLight, size: 20),
                const SizedBox(height: AppSpacing.sm),
                Text('RITUEL DE QUALITÉ', style: textTheme.labelSmall?.copyWith(color: AppColors.goldLight, letterSpacing: AppLetterSpacing.label)),
                const SizedBox(height: AppSpacing.xs),
                Text('Lire · Vérifier · Décider', style: textTheme.titleSmall?.copyWith(color: AppColors.textPrimary)),
              ],
            ),
          );
          if (compact) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [copy, const SizedBox(height: AppSpacing.md), signal]);
          }
          return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Expanded(child: copy), const SizedBox(width: AppSpacing.lg), signal]);
        },
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.pendingDocs, required this.pendingPrompts, required this.total});

  final int pendingDocs;
  final int pendingPrompts;
  final int total;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 610;
        final cards = [
          AdminStatCard(icon: Icons.inbox_rounded, label: 'À décider', value: '$total', hint: total == 0 ? 'File claire' : 'Priorité du moment', accentColor: AdminTheme.accentLight),
          AdminStatCard(icon: Icons.menu_book_rounded, label: 'Textes', value: '$pendingDocs', hint: 'CMS bibliothèque', accentColor: AppColors.metalCobalt),
          AdminStatCard(icon: Icons.auto_awesome_rounded, label: 'Prompts', value: '$pendingPrompts', hint: 'Studio IA', accentColor: AppColors.gold),
        ];
        if (compact) {
          return Column(children: [for (var i = 0; i < cards.length; i++) ...[cards[i], if (i != cards.length - 1) const SizedBox(height: AppSpacing.sm)]]);
        }
        return Row(children: [for (var i = 0; i < cards.length; i++) ...[Expanded(child: cards[i]), if (i != cards.length - 1) const SizedBox(width: AppSpacing.sm)]]);
      },
    );
  }
}

class _LaneFilters extends StatelessWidget {
  const _LaneFilters({required this.selected, required this.onChanged});

  final _ReviewLane selected;
  final ValueChanged<_ReviewLane> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        _FilterPill(label: 'Tout', icon: Icons.all_inbox_rounded, selected: selected == _ReviewLane.all, onTap: () => onChanged(_ReviewLane.all)),
        _FilterPill(label: 'Textes', icon: Icons.menu_book_rounded, selected: selected == _ReviewLane.documents, onTap: () => onChanged(_ReviewLane.documents)),
        _FilterPill(label: 'Prompts', icon: Icons.auto_awesome_rounded, selected: selected == _ReviewLane.prompts, onTap: () => onChanged(_ReviewLane.prompts)),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.icon, required this.selected, required this.onTap});

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AdminTheme.accentLight : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: AnimatedContainer(
        duration: AppMotion.quick,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: selected ? AdminTheme.accent.withValues(alpha: 0.22) : AppColors.textPrimary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: color.withValues(alpha: selected ? 0.50 : 0.18)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 15, color: color), const SizedBox(width: 5), Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700))]),
      ),
    );
  }
}

class _HeaderStatus extends StatelessWidget {
  const _HeaderStatus({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final color = count == 0 ? AppColors.success : AppColors.goldLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: color.withValues(alpha: 0.28))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(count == 0 ? Icons.check_circle_outline_rounded : Icons.pending_actions_rounded, size: 16, color: color), const SizedBox(width: 5), Text('$count en attente', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700))]),
    );
  }
}

class _PermissionsStrip extends StatelessWidget {
  const _PermissionsStrip({required this.identity});

  final StaffIdentity identity;

  @override
  Widget build(BuildContext context) {
    final permissions = <String>[
      if (identity.canReviewDocuments) 'Relecture des textes',
      if (identity.canPublishPrompts) 'Publication des prompts',
    ];
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      borderColor: AdminTheme.accent.withValues(alpha: 0.22),
      child: Row(children: [const Icon(Icons.verified_user_outlined, size: 18, color: AdminTheme.accentLight), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('Droits actifs : ${permissions.isEmpty ? 'lecture seule' : permissions.join(' · ')}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)))]),
    );
  }
}

class _ReviewGuide extends StatelessWidget {
  const _ReviewGuide();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, right: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CADRE DE DÉCISION', style: textTheme.labelSmall?.copyWith(color: AppColors.goldLight, fontWeight: FontWeight.w700, letterSpacing: AppLetterSpacing.caps)),
          const SizedBox(height: AppSpacing.sm),
          Text('Une relecture nette, une trace claire.', style: textTheme.titleLarge?.copyWith(fontFamily: 'Libre Caslon Display')),
          const SizedBox(height: AppSpacing.md),
          PremiumSurface(
            padding: const EdgeInsets.all(AppSpacing.md),
            tone: PremiumSurfaceTone.elevated,
            child: Column(children: const [_GuideStep(number: '01', title: 'Lire le contexte', icon: Icons.visibility_rounded), _GuideDivider(), _GuideStep(number: '02', title: 'Vérifier le fond', icon: Icons.fact_check_outlined), _GuideDivider(), _GuideStep(number: '03', title: 'Décider et tracer', icon: Icons.task_alt_rounded)]),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Les décisions sont enregistrées par les procédures d’administration existantes. Aucun contenu n’est publié sans action explicite.', style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.45)),
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({required this.number, required this.title, required this.icon});

  final String number;
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(children: [Text(number, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.goldLight, fontWeight: FontWeight.w700)), const SizedBox(width: AppSpacing.sm), Icon(icon, size: 18, color: AdminTheme.accentLight), const SizedBox(width: AppSpacing.sm), Expanded(child: Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)))]);
}

class _GuideDivider extends StatelessWidget {
  const _GuideDivider();

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(left: 33, top: AppSpacing.xs, bottom: AppSpacing.xs), child: Divider(color: AppColors.textPrimary.withValues(alpha: 0.08), height: 1));
}

class _DocQueueCard extends StatelessWidget {
  const _DocQueueCard({required this.draft, required this.busy, required this.onApprove, required this.onRequestChanges});

  final AdminDocumentDraft draft;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onRequestChanges;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: AdminTheme.accentLight.withValues(alpha: 0.34),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const GradientIconBadge(icon: Icons.menu_book_rounded, size: 42, gradient: AdminGradients.cobaltMetallic, iconColor: AppColors.textPrimary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_CardEyebrow(label: 'TEXTE · CMS BIBLIOTHÈQUE', color: AdminTheme.accentLight), const SizedBox(height: 2), Text(draft.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))])),
          _FreshnessLabel(date: draft.updatedAt),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [if (draft.domain != '—') _MetaTag(draft.domain), if (draft.type != '—') _MetaTag(draft.type), _MetaTag('${draft.articleCount} article${draft.articleCount == 1 ? '' : 's'}')]),
        if (draft.summary.isNotEmpty) ...[const SizedBox(height: AppSpacing.sm), Text(draft.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.4))],
        const SizedBox(height: AppSpacing.md),
        Row(children: [Expanded(child: Text(draft.createdByEmail == null ? 'Soumission interne' : 'Soumis par ${draft.createdByEmail}', maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled))), const SizedBox(width: AppSpacing.sm), OutlinedButton.icon(onPressed: busy ? null : onRequestChanges, icon: const Icon(Icons.reply_rounded, size: 16), label: const Text('Corriger')), const SizedBox(width: AppSpacing.xs), FilledButton.icon(onPressed: busy ? null : onApprove, style: FilledButton.styleFrom(backgroundColor: AppColors.success), icon: const Icon(Icons.check_rounded, size: 16), label: const Text('Approuver'))]),
      ]),
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
      borderColor: AppColors.gold.withValues(alpha: 0.36),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const GradientIconBadge(icon: Icons.auto_awesome_rounded, size: 42, gradient: AppGradients.goldMetallic, iconColor: AppColors.nightBlueDeep),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_CardEyebrow(label: 'PROMPT · STUDIO IA', color: AppColors.goldLight), const SizedBox(height: 2), Text(PromptKey.label(prompt.key), maxLines: 2, overflow: TextOverflow.ellipsis, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))])),
          _FreshnessLabel(date: prompt.updatedAt),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Row(children: [const _MetaTag('Testé'), if (prompt.testedAt != null) ...[const SizedBox(width: AppSpacing.xs), _MetaTag('Test le ${_shortDate(prompt.testedAt!)}')]]),
        if (prompt.testMessage != null && prompt.testMessage!.trim().isNotEmpty) ...[const SizedBox(height: AppSpacing.sm), Text('Scénario : « ${prompt.testMessage} »', maxLines: 2, overflow: TextOverflow.ellipsis, style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.4))],
        const SizedBox(height: AppSpacing.md),
        Row(children: [Expanded(child: Text(prompt.createdByEmail == null ? 'Soumission interne' : 'Rédigé par ${prompt.createdByEmail}', maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled))), FilledButton.icon(onPressed: busy ? null : onPublish, style: FilledButton.styleFrom(backgroundColor: AppColors.success), icon: const Icon(Icons.publish_rounded, size: 16), label: const Text('Publier'))]),
      ]),
    );
  }
}

class _CardEyebrow extends StatelessWidget {
  const _CardEyebrow({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700, letterSpacing: AppLetterSpacing.label));
}

class _MetaTag extends StatelessWidget {
  const _MetaTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs), decoration: BoxDecoration(color: AppColors.cobalt.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.cobaltLight.withValues(alpha: 0.24))), child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.cobaltLight, fontWeight: FontWeight.w600)));
}

class _FreshnessLabel extends StatelessWidget {
  const _FreshnessLabel({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) => Text(_relativeTime(date), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textDisabled));
}

String _relativeTime(DateTime date) {
  final delta = DateTime.now().difference(date);
  if (delta.inMinutes < 2) return 'À l’instant';
  if (delta.inHours < 1) return 'Il y a ${delta.inMinutes} min';
  if (delta.inDays < 1) return 'Il y a ${delta.inHours} h';
  if (delta.inDays < 7) return 'Il y a ${delta.inDays} j';
  return _shortDate(date);
}

String _shortDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
