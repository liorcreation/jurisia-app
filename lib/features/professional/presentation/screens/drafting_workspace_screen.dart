import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/ai/groq_providers.dart';
import '../../../../core/platform/app_platform_style.dart';
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
  const DraftingWorkspaceScreen({super.key, required this.request, this.controllerOverride});

  final DraftingRequest request;

  /// Contrôleur injecté (aperçus / tests). En production l'écran construit
  /// le sien.
  final DraftingWorkspaceController? controllerOverride;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DraftingWorkspaceController>(
      create: (_) => controllerOverride ?? _buildController(request),
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

    if (AppPlatformStyle.of(context) == AppPlatformStyle.desktop) {
      return _DesktopWorkspace(controller: controller);
    }

    final chrome = _modeChrome(controller.request.mode);

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          titleSpacing: 0,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chrome.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.goldLight,
                      letterSpacing: AppLetterSpacing.label,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 1),
              Text(
                result?.title ?? _loadingLabel(controller.request.mode),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontFamily: 'Libre Caslon Display'),
              ),
            ],
          ),
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
        body: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(child: IgnorePointer(child: _WsAmbience())),
              _buildBody(context, controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DraftingWorkspaceController controller) {
    if (controller.status == DraftingStatus.error && controller.result == null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: _DesktopWsError(
          message: controller.errorMessage ?? 'Une erreur est survenue.',
          onRetry: controller.regenerate,
        ),
      );
    }

    if (controller.status == DraftingStatus.generating && controller.streamingText.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: _DesktopWsGenerating(mode: controller.request.mode),
      );
    }

    return _DocumentView(controller: controller);
  }
}

class _DocumentView extends StatelessWidget {
  const _DocumentView({required this.controller});

  final DraftingWorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final result = controller.result;
    final text = result?.content ?? controller.streamingText;
    final generating = controller.isGenerating;
    final readingStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontFamily: 'Lora',
      color: AppColors.textPrimary,
      height: 1.85,
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
                  if (generating && result != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(strokeWidth: 1.8, color: AppColors.goldLight),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Application de l\'ajustement…',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: AppColors.goldLight),
                          ),
                        ],
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
    final enabled = !controller.isGenerating;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: QuickAdjustment.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final adjustment = QuickAdjustment.values[index];
          return TapScale(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: enabled ? () => controller.applyAdjustment(adjustment) : null,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Opacity(
                  opacity: enabled ? 1 : 0.45,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.legalBlueDark.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.28), width: 0.7),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_fix_high_rounded, size: 13, color: AppColors.goldLight),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          adjustment.label,
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
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

void _copyResult(BuildContext context, LegalDraftingResult result) {
  Clipboard.setData(ClipboardData(text: result.content));
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Texte copié dans le presse-papiers.')),
  );
}

void _exportResult(BuildContext context, LegalDraftingResult result) {
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

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.result});

  final LegalDraftingResult result;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _copyResult(context, result),
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copier'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _exportResult(context, result),
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: const Text('Exporter'),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
//  DESKTOP — « L'atelier de rédaction »
// ===========================================================================

({IconData icon, Color tint, String label}) _modeChrome(DraftingMode mode) {
  switch (mode) {
    case DraftingMode.redaction:
      return (icon: Icons.draw_rounded, tint: AppColors.metalDeepGold, label: 'RÉDACTION D\'ACTE');
    case DraftingMode.audit:
      return (icon: Icons.rule_rounded, tint: AppColors.metalCobalt, label: 'AUDIT DE CONTRAT');
    case DraftingMode.consultation:
      return (icon: Icons.balance_rounded, tint: AppColors.metalEmerald, label: 'NOTE DE SYNTHÈSE');
  }
}

class _DesktopWorkspace extends StatefulWidget {
  const _DesktopWorkspace({required this.controller});

  final DraftingWorkspaceController controller;

  @override
  State<_DesktopWorkspace> createState() => _DesktopWorkspaceState();
}

class _DesktopWorkspaceState extends State<_DesktopWorkspace> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final result = controller.result;
    final chrome = _modeChrome(controller.request.mode);

    final Widget body;
    if (controller.status == DraftingStatus.error && result == null) {
      body = _DesktopWsError(
        message: controller.errorMessage ?? 'Une erreur est survenue.',
        onRetry: controller.regenerate,
      );
    } else if (controller.status == DraftingStatus.generating && controller.streamingText.isEmpty && result == null) {
      body = _DesktopWsGenerating(mode: controller.request.mode);
    } else {
      body = _DesktopWsDocument(controller: controller, scroll: _scroll);
    }

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(child: IgnorePointer(child: _WsAmbience())),
              Column(
                children: [
                  _DesktopWsHeader(
                    controller: controller,
                    title: result?.title ?? _loadingLabel(controller.request.mode),
                    eyebrow: chrome.label,
                  ),
                  Expanded(child: body),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopWsHeader extends StatelessWidget {
  const _DesktopWsHeader({
    required this.controller,
    required this.title,
    required this.eyebrow,
  });

  final DraftingWorkspaceController controller;
  final String title;
  final String eyebrow;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final result = controller.result;

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.smokedGlass,
        border: Border(
          bottom: BorderSide(color: AppColors.gold.withValues(alpha: 0.18), width: 0.6),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Retour à l\'atelier',
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.goldLight,
                    letterSpacing: AppLetterSpacing.label,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.headlineSmall?.copyWith(fontFamily: 'Libre Caslon Display'),
                ),
              ],
            ),
          ),
          if (result != null) ...[
            const SizedBox(width: AppSpacing.md),
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
        ],
      ),
    );
  }
}

class _DesktopWsGenerating extends StatelessWidget {
  const _DesktopWsGenerating({required this.mode});

  final DraftingMode mode;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final chrome = _modeChrome(mode);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _WsPulse(icon: chrome.icon, tint: chrome.tint),
          const SizedBox(height: AppSpacing.xl),
          Text(
            _loadingLabel(mode),
            style: textTheme.headlineSmall?.copyWith(fontFamily: 'Libre Caslon Display'),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'L\'IA compose le document en s\'appuyant sur les textes de la bibliothèque.',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _WsPulse extends StatefulWidget {
  const _WsPulse({required this.icon, required this.tint});

  final IconData icon;
  final Color tint;

  @override
  State<_WsPulse> createState() => _WsPulseState();
}

class _WsPulseState extends State<_WsPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_c.value);
        return Container(
          width: 84,
          height: 84,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(widget.tint, Colors.white, 0.35)!,
                widget.tint,
                Color.lerp(widget.tint, AppColors.nightBlueDeep, 0.35)!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.tint.withValues(alpha: 0.15 + 0.25 * t),
                blurRadius: 22 + 14 * t,
                spreadRadius: 2 + 3 * t,
              ),
            ],
          ),
          child: Icon(widget.icon, size: 34, color: AppColors.nightBlueDeep),
        );
      },
    );
  }
}

class _DesktopWsError extends StatelessWidget {
  const _DesktopWsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.xl),
          borderColor: AppColors.error.withValues(alpha: 0.4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 36),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.nightBlueDeep,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopWsDocument extends StatelessWidget {
  const _DesktopWsDocument({required this.controller, required this.scroll});

  final DraftingWorkspaceController controller;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final result = controller.result;
    final text = result?.content ?? controller.streamingText;
    final generating = controller.isGenerating;
    final readingStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontFamily: 'Lora',
          color: AppColors.textPrimary,
          height: 1.85,
          fontSize: 16,
        );

    final reading = SingleChildScrollView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxl),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (controller.status == DraftingStatus.error && result != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: GlassContainer(
                    borderColor: AppColors.error.withValues(alpha: 0.6),
                    child: Text(
                      controller.errorMessage ?? 'Une erreur est survenue lors de l\'ajustement.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                ),
              if (generating)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(strokeWidth: 1.8, color: AppColors.goldLight),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        result == null ? 'Rédaction en cours…' : 'Application de l\'ajustement…',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: AppColors.goldLight),
                      ),
                    ],
                  ),
                ),
              text.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: AiThinkingIndicator(),
                    )
                  : SelectableText(text, style: readingStyle),
            ],
          ),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1040;
        if (!wide || result == null) {
          return reading;
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: reading),
            SizedBox(
              width: 348,
              child: _WsRail(controller: controller, result: result),
            ),
          ],
        );
      },
    );
  }
}

class _WsRail extends StatelessWidget {
  const _WsRail({required this.controller, required this.result});

  final DraftingWorkspaceController controller;
  final LegalDraftingResult result;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final generating = controller.isGenerating;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.nightBlueDeep.withValues(alpha: 0.3),
        border: Border(
          left: BorderSide(color: AppColors.gold.withValues(alpha: 0.16), width: 1),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _WsRailLabel('Ajustements rapides'),
                  const SizedBox(height: AppSpacing.sm),
                  for (final adjustment in QuickAdjustment.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _AdjustmentButton(
                        label: adjustment.label,
                        enabled: !generating,
                        onTap: () => controller.applyAdjustment(adjustment),
                      ),
                    ),
                  if (result.citedSources.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _WsRailLabel('Sources consultées'),
                    const SizedBox(height: AppSpacing.sm),
                    for (final source in result.citedSources)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Icon(Icons.local_library_rounded, size: 12, color: AppColors.goldLight),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                '${source.title} · ${source.reference}',
                                style: textTheme.labelSmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  if (result.risks.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _WsRailLabel('Clauses à risque · ${result.risks.length}'),
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
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.gold.withValues(alpha: 0.14), width: 0.6),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyResult(context, result),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 11)),
                    icon: const Icon(Icons.copy_rounded, size: 15),
                    label: const Text('Copier'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _exportResult(context, result),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.nightBlueDeep,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    icon: const Icon(Icons.ios_share_rounded, size: 15),
                    label: const Text('Exporter'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WsRailLabel extends StatelessWidget {
  const _WsRailLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 1, color: AppColors.gold.withValues(alpha: 0.6)),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.goldLight,
                  letterSpacing: AppLetterSpacing.caps,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

class _AdjustmentButton extends StatelessWidget {
  const _AdjustmentButton({required this.label, required this.enabled, required this.onTap});

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.small),
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: AppColors.legalBlueDark.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.small),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.28), width: 0.7),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_fix_high_rounded, size: 13, color: AppColors.goldLight),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fines poussières d'or en suspension — la respiration « vivante » du
/// registre desktop.
class _WsAmbience extends StatefulWidget {
  const _WsAmbience();

  @override
  State<_WsAmbience> createState() => _WsAmbienceState();
}

class _WsAmbienceState extends State<_WsAmbience> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(painter: _WsAmbiencePainter(_controller.value)),
    );
  }
}

class _WsAmbiencePainter extends CustomPainter {
  const _WsAmbiencePainter(this.t);

  final double t;
  static const int _count = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < _count; i++) {
      final seed = i * 57.0;
      final baseX = seed % size.width;
      final drift = math.sin((t * 2 * math.pi) + seed) * 18;
      final x = (baseX + drift) % size.width;
      final y = (size.height * ((i / _count) + t) % 1.0);
      final radius = 0.7 + (i % 3) * 0.6;
      final opacity = 0.04 + 0.07 * (0.5 + 0.5 * math.sin((t * 2 * math.pi) + seed * 1.7));
      paint.color = AppColors.goldLight.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WsAmbiencePainter oldDelegate) => oldDelegate.t != t;
}
