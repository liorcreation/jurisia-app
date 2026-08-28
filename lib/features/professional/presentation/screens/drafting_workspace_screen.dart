import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/ai/groq_providers.dart';
import '../../../../core/supabase/supabase_config.dart';
import '../../../../core/widgets/ai_thinking_indicator.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/luxury_scaffold_background.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../theme/app_theme.dart';
import '../../../library/data/datasources/legal_document_local_datasource.dart';
import '../../../library/data/repositories/library_repository_impl.dart';
import '../../data/datasources/professional_template_local_datasource.dart';
import '../../data/repositories/professional_repository_impl.dart';
import '../../domain/entities/drafting_request.dart';
import '../../domain/entities/legal_drafting_result.dart';
import '../../domain/entities/quick_adjustment.dart';
import '../../domain/usecases/analyze_contract_usecase.dart';
import '../../domain/usecases/draft_legal_document_usecase.dart';
import '../controllers/drafting_workspace_controller.dart';

DraftingWorkspaceController _buildController(DraftingRequest request) {
  final dataSource = buildGroqDataSource();
  final libraryRepository = LibraryRepositoryImpl(dataSource: const LocalLegalDocumentDataSource());
  final professionalRepository = ProfessionalRepositoryImpl(
    dataSource: dataSource,
    libraryRepository: libraryRepository,
    templateDataSource: const LocalProfessionalTemplateDataSource(),
    supabaseClient: SupabaseConfig.isReady ? SupabaseConfig.client : null,
    userId: SupabaseConfig.isReady ? SupabaseConfig.client.auth.currentUser?.id : null,
  );

  return DraftingWorkspaceController(
    request: request,
    draftUseCase: DraftLegalDocumentUseCase(repository: professionalRepository),
    analyzeUseCase: AnalyzeContractUseCase(repository: professionalRepository),
    repository: professionalRepository,
  );
}

String _loadingLabel(DraftingMode mode) {
  switch (mode) {
    case DraftingMode.redaction:
      return 'Rédaction du document en cours…';
    case DraftingMode.audit:
      return 'Audit du contrat en cours…';
    case DraftingMode.consultation:
      return 'Préparation de la note de synthèse…';
  }
}

/// Espace de rédaction interactif : génération au fil de l'eau, ajustements
/// rapides, copie, export et mise en favori du document produit.
class DraftingWorkspaceScreen extends StatelessWidget {
  const DraftingWorkspaceScreen({super.key, required this.request});

  final DraftingRequest request;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DraftingWorkspaceController>(
      create: (_) => _buildController(request),
      child: const _WorkspaceView(),
    );
  }
}

class _WorkspaceView extends StatelessWidget {
  const _WorkspaceView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DraftingWorkspaceController>();
    final result = controller.result;

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(result?.title ?? _loadingLabel(controller.request.mode)),
          actions: [
            if (result != null)
              TapScale(
                child: IconButton(
                  tooltip: result.isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                  icon: Icon(
                    result.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                    color: AppColors.gold,
                  ),
                  onPressed: controller.toggleFavorite,
                ),
              ),
          ],
        ),
        body: SafeArea(child: _buildBody(context, controller)),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DraftingWorkspaceController controller) {
    if (controller.status == DraftingStatus.error && controller.result == null) {
      return _ErrorState(
        message: controller.errorMessage ?? 'Une erreur est survenue.',
        onRetry: controller.regenerate,
      );
    }

    if (controller.status == DraftingStatus.generating && controller.streamingText.isEmpty) {
      return Center(
        child: AiThinkingIndicator(label: _loadingLabel(controller.request.mode)),
      );
    }

    return _DocumentView(controller: controller);
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}

class _DocumentView extends StatelessWidget {
  const _DocumentView({required this.controller});

  final DraftingWorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final result = controller.result;
    final text = result?.content ?? controller.streamingText;
    final readingStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontFamily: 'Lora',
      color: AppColors.textPrimary,
      height: 1.8,
      fontSize: 16,
    );

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          children: [
            if (result != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                child: _AdjustmentToolbar(controller: controller),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  if (controller.status == DraftingStatus.error)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: GlassContainer(
                        borderColor: AppColors.error.withValues(alpha: 0.6),
                        child: Text(
                          controller.errorMessage ?? 'Une erreur est survenue lors de l\'ajustement.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textPrimary),
                        ),
                      ),
                    ),
                  GlassContainer(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: text.isEmpty
                        ? const AiThinkingIndicator()
                        : SelectableText(text, style: readingStyle),
                  ),
                  if (result != null && result.citedSources.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _CitedSourcesCard(sources: result.citedSources),
                  ],
                  if (result != null && result.risks.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text('Clauses à risque identifiées', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    for (final risk in result.risks)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _RiskCard(risk: risk),
                      ),
                  ],
                ],
              ),
            ),
            if (result != null) _ActionBar(result: result),
          ],
        ),
      ),
    );
  }
}

class _AdjustmentToolbar extends StatelessWidget {
  const _AdjustmentToolbar({required this.controller});

  final DraftingWorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: QuickAdjustment.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final adjustment = QuickAdjustment.values[index];
          return ActionChip(
            label: Text(adjustment.label),
            onPressed: controller.isGenerating ? null : () => controller.applyAdjustment(adjustment),
            backgroundColor: AppColors.legalBlueDark.withValues(alpha: 0.6),
            side: const BorderSide(color: AppColors.glassBorder),
            labelStyle: Theme.of(context).textTheme.labelMedium,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
          );
        },
      ),
    );
  }
}

class _CitedSourcesCard extends StatelessWidget {
  const _CitedSourcesCard({required this.sources});

  final List<CitedLegalSource> sources;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_library_rounded, size: 18, color: AppColors.gold),
              const SizedBox(width: AppSpacing.sm),
              Text('Sources consultées dans la bibliothèque', style: textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final source in sources)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• ${source.title} (${source.reference})', style: textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}

class _RiskCard extends StatelessWidget {
  const _RiskCard({required this.risk});

  final ClauseRisk risk;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = switch (risk.riskLevel) {
      RiskLevel.faible => AppColors.success,
      RiskLevel.moyen => AppColors.warning,
      RiskLevel.eleve => AppColors.error,
    };

    return GlassContainer(
      borderColor: color.withValues(alpha: 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              risk.riskLevel.label,
              style: textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(risk.clauseExcerpt, style: textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
          const SizedBox(height: AppSpacing.sm),
          Text(risk.explanation, style: textTheme.bodyMedium),
          if (risk.suggestedRewrite.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Reformulation proposée :', style: textTheme.labelMedium?.copyWith(color: AppColors.gold)),
            const SizedBox(height: 4),
            Text(risk.suggestedRewrite, style: textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.result});

  final LegalDraftingResult result;

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: result.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Texte copié dans le presse-papiers.')),
    );
  }

  void _export(BuildContext context) {
    final title = result.title;
    final formatted =
        '$title\n${'=' * title.length}\n\n${result.content}\n\n---\n'
        'Document généré par JurisIA. À faire relire par un professionnel du droit avant toute '
        'utilisation.';
    Clipboard.setData(ClipboardData(text: formatted));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document exporté (copié) avec mise en forme, prêt à coller dans un fichier.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _copy(context),
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copier'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _export(context),
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: const Text('Exporter'),
            ),
          ),
        ],
      ),
    );
  }
}
