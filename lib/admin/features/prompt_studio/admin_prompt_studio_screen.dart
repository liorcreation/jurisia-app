import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/ai/groq_providers.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/widgets/entrance_fade.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/luxury_scaffold_background.dart';
import '../../../theme/app_theme.dart';
import '../../auth/staff_role.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_ambience.dart';
import '../../widgets/admin_empty_state.dart';
import '../../widgets/admin_page_header.dart';
import '../../widgets/admin_section_card.dart';
import '../../widgets/admin_status_chip.dart';
import 'admin_ai_prompt.dart';
import 'admin_prompt_controller.dart';
import 'admin_prompt_repository.dart';

IconData _promptKeyIcon(String key) => switch (key) {
      PromptKey.litige => Icons.gavel_rounded,
      PromptKey.tuteur => Icons.school_rounded,
      PromptKey.redaction => Icons.edit_note_rounded,
      PromptKey.audit => Icons.fact_check_rounded,
      PromptKey.consultation => Icons.forum_rounded,
      _ => Icons.auto_awesome_rounded,
    };

/// Console — Studio de prompts : rédiger, tester et publier les
/// instructions système de l'IA sans déploiement de code (voir
/// migration_013_ai_prompts.sql). Publier reste réservé à super_admin — le
/// risque touche tous les utilisateurs d'un coup, contrairement à un texte
/// de la bibliothèque qui reste contenu à lui-même.
class AdminPromptStudioScreen extends StatelessWidget {
  const AdminPromptStudioScreen({super.key, required this.identity});

  final StaffIdentity identity;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminPromptController>(
      create: (_) => AdminPromptController(
        repository: SupabaseAdminPromptRepository(
          client: SupabaseConfig.client,
          llm: buildGroqDataSource(),
        ),
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
    final controller = context.watch<AdminPromptController>();
    final byKey = <String, List<AdminAiPrompt>>{};
    for (final prompt in controller.prompts) {
      byKey.putIfAbsent(prompt.key, () => []).add(prompt);
    }
    final keys = {...PromptKey.all, ...byKey.keys}.toList();

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              AdminPageHeader(
                icon: Icons.auto_awesome_rounded,
                title: 'Studio de prompts',
                subtitle: 'Calibrer la voix de JurisIA, tester chaque intention et publier avec maîtrise.',
                actions: [
                  IconButton(
                    tooltip: 'Actualiser le studio',
                    onPressed: controller.isLoading ? null : controller.load,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                  if (identity.canEditContent)
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.xs),
                      child: FilledButton.icon(
                      onPressed: () => _openEditor(context, controller),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Nouveau prompt'),
                    ),
                    ),
                ],
              ),
              Expanded(
                child: Stack(
                  children: [
                    const Positioned.fill(child: IgnorePointer(child: AdminAmbience())),
                    controller.isLoading && controller.prompts.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final wide = constraints.maxWidth >= 1180;
                              final padding = EdgeInsets.fromLTRB(
                                wide ? AppSpacing.xl : AppSpacing.md,
                                AppSpacing.lg,
                                wide ? AppSpacing.xl : AppSpacing.md,
                                AppSpacing.xl,
                              );
                              return ListView(
                                padding: padding,
                                children: [
                                  if (controller.error != null) ...[
                                    AdminErrorBanner(message: controller.error!, onDismiss: controller.dismissError),
                                    const SizedBox(height: AppSpacing.md),
                                  ],
                                  _PromptHero(
                                    total: controller.prompts.length,
                                    published: controller.prompts.where((p) => p.status == AiPromptStatus.published).length,
                                    tested: controller.prompts.where((p) => p.testedAt != null).length,
                                    canPublish: identity.canPublishPrompts,
                                    onCreate: identity.canEditContent ? () => _openEditor(context, controller) : null,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  _PromptStats(prompts: controller.prompts),
                                  const SizedBox(height: AppSpacing.lg),
                                  AdminSectionCard(
                                    title: 'Bibliothèque d\'intentions',
                                    icon: Icons.hub_rounded,
                                    trailing: Text('${keys.length} contextes', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Chaque contexte possède sa propre voix. Les versions publiées restent séparées des brouillons pour garder les tests réversibles.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.4)),
                                        const SizedBox(height: AppSpacing.md),
                                        for (var i = 0; i < keys.length; i++)
                                          Padding(
                                            padding: EdgeInsets.only(bottom: i == keys.length - 1 ? 0 : AppSpacing.lg),
                                            child: EntranceFadeSlide(
                                              index: i,
                                              child: _PromptContextSection(
                                                keyName: keys[i],
                                                prompts: byKey[keys[i]] ?? const [],
                                                identity: identity,
                                                busy: controller.isMutating,
                                                onEdit: (prompt) => _openEditor(context, controller, prompt: prompt),
                                                onTest: (prompt) => _openTestDialog(context, controller, prompt),
                                                onPublish: controller.publish,
                                              ),
                                            ),
                                          ),
                                      ],
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
    AdminPromptController controller, {
    AdminAiPrompt? prompt,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: controller,
        child: _PromptEditorDialog(prompt: prompt),
      ),
    );
  }

  Future<void> _openTestDialog(
    BuildContext context,
    AdminPromptController controller,
    AdminAiPrompt prompt,
  ) {
    return showDialog<void>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: controller,
        child: _PromptTestDialog(prompt: prompt),
      ),
    );
  }
}

class _PromptHero extends StatelessWidget {
  const _PromptHero({required this.total, required this.published, required this.tested, required this.canPublish, required this.onCreate});
  final int total;
  final int published;
  final int tested;
  final bool canPublish;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.large),
        gradient: LinearGradient(
          colors: [AdminTheme.accentDark.withValues(alpha: 0.92), AppColors.deepSlate.withValues(alpha: 0.90), AppColors.deepSlateDeep.withValues(alpha: 0.96)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AdminTheme.accentLight.withValues(alpha: 0.30)),
        boxShadow: [BoxShadow(color: AdminTheme.accent.withValues(alpha: 0.16), blurRadius: 32, spreadRadius: -10)],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;
          final intro = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.gold.withValues(alpha: 0.42))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.auto_awesome_rounded, size: 15, color: AppColors.gold), const SizedBox(width: 7), Text('PROMPT OPS', style: textTheme.labelSmall?.copyWith(color: AppColors.gold, letterSpacing: AppLetterSpacing.caps, fontWeight: FontWeight.w800))]),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(child: Text(canPublish ? 'PUBLICATION SOUS CONTRÔLE' : 'MODE ÉDITION', overflow: TextOverflow.ellipsis, style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary, letterSpacing: AppLetterSpacing.caps))),
              ]),
              const SizedBox(height: AppSpacing.md),
              Text('Calibrez la voix\nde JurisIA.', style: (compact ? textTheme.headlineSmall : textTheme.headlineMedium)?.copyWith(fontFamily: 'Libre Caslon Display', height: 1.04, color: AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.sm),
              ConstrainedBox(constraints: const BoxConstraints(maxWidth: 620), child: Text('Concevez des instructions précises, observez leur comportement et gardez la publication sous contrôle éditorial.', style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.45))),
              if (compact && onCreate != null) ...[
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Créer un prompt')),
              ],
            ],
          );
          final signal = Container(
            constraints: BoxConstraints(minWidth: compact ? 0 : 245, maxWidth: 300),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.055), borderRadius: BorderRadius.circular(AppRadius.medium), border: Border.all(color: Colors.white.withValues(alpha: 0.10))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SIGNAL DU STUDIO', style: textTheme.labelSmall?.copyWith(color: AdminTheme.accentLight, letterSpacing: AppLetterSpacing.caps, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.sm),
              _PromptHeroMetric(label: 'Contextes suivis', value: '$total', icon: Icons.hub_rounded),
              const SizedBox(height: AppSpacing.sm),
              _PromptHeroMetric(label: 'Testés', value: '$tested', icon: Icons.science_outlined, color: AppColors.warning),
              const SizedBox(height: AppSpacing.sm),
              _PromptHeroMetric(label: 'En production', value: '$published', icon: Icons.rocket_launch_rounded, color: AppColors.success),
            ]),
          );
          return compact ? intro : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: intro), const SizedBox(width: AppSpacing.lg), signal]);
        },
      ),
    );
  }
}

class _PromptHeroMetric extends StatelessWidget {
  const _PromptHeroMetric({required this.label, required this.value, required this.icon, this.color = AdminTheme.accentLight});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(children: [Icon(icon, size: 17, color: color), const SizedBox(width: 9), Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary))), Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary))]);
}

class _PromptStats extends StatelessWidget {
  const _PromptStats({required this.prompts});
  final List<AdminAiPrompt> prompts;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _PromptStat(label: 'Total', value: prompts.length, hint: 'instructions suivies', icon: Icons.layers_rounded, color: AdminTheme.accentLight),
      _PromptStat(label: 'Brouillons', value: prompts.where((p) => p.status == AiPromptStatus.draft).length, hint: 'à façonner', icon: Icons.edit_note_rounded, color: AppColors.textSecondary),
      _PromptStat(label: 'Testés', value: prompts.where((p) => p.testedAt != null).length, hint: 'avec une preuve de test', icon: Icons.science_outlined, color: AppColors.warning),
      _PromptStat(label: 'Publiés', value: prompts.where((p) => p.status == AiPromptStatus.published).length, hint: 'actifs pour l’IA', icon: Icons.verified_rounded, color: AppColors.success),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 700;
      return compact
          ? Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [for (final card in cards) SizedBox(width: (constraints.maxWidth - AppSpacing.sm) / 2, child: card)])
          : Row(children: [for (var i = 0; i < cards.length; i++) Expanded(child: Padding(padding: EdgeInsets.only(right: i == cards.length - 1 ? 0 : AppSpacing.sm), child: cards[i]))]);
    });
  }
}

class _PromptStat extends StatelessWidget {
  const _PromptStat({required this.label, required this.value, required this.hint, required this.icon, required this.color});
  final String label;
  final int value;
  final String hint;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => GlassContainer(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(children: [Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle), child: Icon(icon, size: 18, color: color)), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textDisabled, letterSpacing: AppLetterSpacing.caps, fontWeight: FontWeight.w700)), const SizedBox(height: 2), Text('$value', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontFamily: 'Libre Caslon Display')), Text(hint, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary))]))]),
      );
}

class _PromptContextSection extends StatelessWidget {
  const _PromptContextSection({required this.keyName, required this.prompts, required this.identity, required this.busy, required this.onEdit, required this.onTest, required this.onPublish});
  final String keyName;
  final List<AdminAiPrompt> prompts;
  final StaffIdentity identity;
  final bool busy;
  final ValueChanged<AdminAiPrompt> onEdit;
  final ValueChanged<AdminAiPrompt> onTest;
  final Future<bool> Function(String id) onPublish;

  @override
  Widget build(BuildContext context) {
    final published = prompts.any((p) => p.status == AiPromptStatus.published);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AdminTheme.accent.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(AppRadius.medium)), child: Icon(_promptKeyIcon(keyName), color: AdminTheme.accentLight, size: 22)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(PromptKey.label(keyName), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text('$keyName · ${prompts.length} version${prompts.length > 1 ? 's' : ''}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textDisabled))])),
        if (published) const AdminStatusChip(label: 'Actif', color: AppColors.success),
      ]),
      const SizedBox(height: AppSpacing.sm),
      if (prompts.isEmpty)
        Container(width: double.infinity, padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(color: AppColors.legalBlueDark.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(AppRadius.medium), border: Border.all(color: AppColors.divider)), child: Row(children: [const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textDisabled), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('Aucun addendum enregistré — le contexte utilise sa configuration système fixe.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)))]))
      else
        Column(children: [for (var i = 0; i < prompts.length; i++) Padding(padding: EdgeInsets.only(top: i == 0 ? 0 : AppSpacing.sm), child: _PromptCard(prompt: prompts[i], identity: identity, busy: busy, onEdit: () => onEdit(prompts[i]), onTest: () => onTest(prompts[i]), onPublish: () => onPublish(prompts[i].id)))])
    ]);
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.prompt,
    required this.identity,
    required this.busy,
    required this.onEdit,
    required this.onTest,
    required this.onPublish,
  });

  final AdminAiPrompt prompt;
  final StaffIdentity identity;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onTest;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: prompt.status == AiPromptStatus.published
          ? AppColors.success.withValues(alpha: 0.4)
          : AppColors.glassBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: promptStatusColor(prompt.status).withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Icon(
                  prompt.status == AiPromptStatus.published ? Icons.rocket_launch_rounded : Icons.code_rounded,
                  size: 18,
                  color: promptStatusColor(prompt.status),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AdminStatusChip(label: prompt.status.label, color: promptStatusColor(prompt.status)),
                        const Spacer(),
                        Text(_formatPromptDate(prompt.updatedAt), style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      prompt.status == AiPromptStatus.published ? 'Version active pour JurisIA' : 'Version éditoriale',
                      style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.deepSlateDeep.withValues(alpha: 0.40),
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.format_quote_rounded, size: 19, color: AdminTheme.accentLight),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    prompt.content,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _PromptSignal(
                icon: prompt.testedAt != null ? Icons.check_circle_outline_rounded : Icons.pending_outlined,
                label: prompt.testedAt != null ? 'Testé le ${_formatPromptDate(prompt.testedAt!)}' : 'Test requis avant publication',
                color: prompt.testedAt != null ? AppColors.success : AppColors.warning,
              ),
              if (prompt.approvedByEmail != null)
                _PromptSignal(icon: Icons.verified_user_outlined, label: 'Validé par ${prompt.approvedByEmail}', color: AppColors.textSecondary),
            ],
          ),
          if (prompt.testResponse != null && prompt.testResponse!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(children: [const Icon(Icons.insights_outlined, size: 15, color: AdminTheme.accentLight), const SizedBox(width: 6), Text('Un résultat de test est disponible', style: textTheme.labelSmall?.copyWith(color: AdminTheme.accentLight))]),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              if (prompt.isEditable && identity.canEditContent)
                OutlinedButton.icon(
                  onPressed: busy ? null : onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 15),
                  label: const Text('Modifier'),
                ),
              if (prompt.isEditable && identity.canEditContent)
                OutlinedButton.icon(
                  onPressed: busy ? null : onTest,
                  icon: const Icon(Icons.play_arrow_rounded, size: 15),
                  label: const Text('Tester'),
                ),
              if (prompt.canPublish && identity.canPublishPrompts && prompt.status != AiPromptStatus.published)
                FilledButton.icon(
                  onPressed: busy ? null : onPublish,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                  icon: const Icon(Icons.rocket_launch_rounded, size: 15),
                  label: const Text('Publier'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromptSignal extends StatelessWidget {
  const _PromptSignal({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 15, color: color), const SizedBox(width: 5), Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color))]);
}

String _formatPromptDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

class _PromptEditorDialog extends StatefulWidget {
  const _PromptEditorDialog({this.prompt});

  final AdminAiPrompt? prompt;

  @override
  State<_PromptEditorDialog> createState() => _PromptEditorDialogState();
}

class _PromptEditorDialogState extends State<_PromptEditorDialog> {
  late String _key = widget.prompt?.key ?? PromptKey.litige;
  late final _content = TextEditingController(text: widget.prompt?.content ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_content.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final controller = context.read<AdminPromptController>();
    final ok = await controller.saveDraft(
      draftId: widget.prompt?.id,
      key: _key,
      content: _content.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.prompt == null;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isNew ? 'Nouveau brouillon de prompt' : 'Modifier le prompt',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Ce texte s\'AJOUTE à la fin du prompt système fixe du module — il ne le '
                'remplace jamais. Le protocole de sortie (mise en forme, blocs de données '
                'internes) reste toujours celui codé en dur ; n\'essaie pas de le redéfinir ici.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _key,
                decoration: const InputDecoration(labelText: 'Contexte'),
                items: [
                  for (final key in PromptKey.all)
                    DropdownMenuItem(value: key, child: Text(PromptKey.label(key))),
                ],
                onChanged: isNew ? (v) => setState(() => _key = v ?? _key) : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _content,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    labelText: 'Consignes éditoriales complémentaires',
                    alignLabelWithHint: true,
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
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(backgroundColor: AdminTheme.accent),
                    child: const Text('Enregistrer le brouillon'),
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

/// Zone de test : un message d'exemple, la réponse obtenue avec CE
/// brouillon comme instruction système — sans jamais toucher au prompt
/// actif tant que « Publier » n'a pas été cliqué séparément.
class _PromptTestDialog extends StatefulWidget {
  const _PromptTestDialog({required this.prompt});

  final AdminAiPrompt prompt;

  @override
  State<_PromptTestDialog> createState() => _PromptTestDialogState();
}

class _PromptTestDialogState extends State<_PromptTestDialog> {
  final _message = TextEditingController();
  String? _response;
  bool _running = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (_message.text.trim().isEmpty) return;
    setState(() {
      _running = true;
      _response = null;
    });
    final controller = context.read<AdminPromptController>();
    final response = await controller.testDraft(
      draftId: widget.prompt.id,
      draftContent: widget.prompt.content,
      testMessage: _message.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _running = false;
      _response = response;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tester — ${PromptKey.label(widget.prompt.key)}', style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Ce test envoie UNIQUEMENT cet addendum comme instruction système, sans le '
                'prompt de base réel du module (persona, protocole de sortie) — utile pour juger '
                'du ton et du contenu ajoutés, pas du comportement exact une fois publié. Le '
                'prompt actif n\'est jamais touché ici.',
                style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _message,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Message d\'exemple'),
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _running ? null : _run,
                  style: FilledButton.styleFrom(backgroundColor: AdminTheme.accent),
                  icon: _running
                      ? const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text('Lancer le test'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_response != null)
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.legalBlueDark.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                      child: Text(_response!.isEmpty ? '(réponse vide)' : _response!, style: textTheme.bodyMedium),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
