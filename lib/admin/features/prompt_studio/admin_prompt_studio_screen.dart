import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/ai/groq_providers.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/luxury_scaffold_background.dart';
import '../../../theme/app_theme.dart';
import '../../auth/staff_role.dart';
import '../../theme/admin_theme.dart';
import 'admin_ai_prompt.dart';
import 'admin_prompt_controller.dart';
import 'admin_prompt_repository.dart';

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
    final textTheme = Theme.of(context).textTheme;

    final byKey = <String, List<AdminAiPrompt>>{};
    for (final prompt in controller.prompts) {
      byKey.putIfAbsent(prompt.key, () => []).add(prompt);
    }
    final keys = {...PromptKey.all, ...byKey.keys}.toList();

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Studio de prompts'),
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
          child: controller.isLoading && controller.prompts.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    if (controller.error != null) ...[
                      _ErrorBanner(message: controller.error!, onDismiss: controller.dismissError),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    for (final key in keys) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Text(PromptKey.label(key), style: textTheme.titleSmall),
                      ),
                      if ((byKey[key] ?? const []).isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                          child: Text(
                            'Aucun prompt enregistré — utilise la constante codée en dur.',
                            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                          child: Column(
                            children: [
                              for (final prompt in byKey[key]!)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                  child: _PromptCard(
                                    prompt: prompt,
                                    identity: identity,
                                    busy: controller.isMutating,
                                    onEdit: () => _openEditor(context, controller, prompt: prompt),
                                    onTest: () => _openTestDialog(context, controller, prompt),
                                    onPublish: () => controller.publish(prompt.id),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
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

  Color _statusColor() {
    switch (prompt.status) {
      case AiPromptStatus.published:
        return AppColors.success;
      case AiPromptStatus.tested:
        return AdminTheme.accentLight;
      case AiPromptStatus.archived:
        return AppColors.textDisabled;
      case AiPromptStatus.draft:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = _statusColor();

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: prompt.status == AiPromptStatus.published
          ? AppColors.success.withValues(alpha: 0.4)
          : AppColors.glassBorder,
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
                  prompt.status.label,
                  style: textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
                ),
              ),
              const Spacer(),
              Text(
                'Maj ${prompt.updatedAt.day}/${prompt.updatedAt.month}/${prompt.updatedAt.year}',
                style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            prompt.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall,
          ),
          if (prompt.testedAt != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Dernier test le ${prompt.testedAt!.day}/${prompt.testedAt!.month}/${prompt.testedAt!.year}',
              style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
