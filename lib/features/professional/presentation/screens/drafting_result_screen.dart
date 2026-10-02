import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/luxury_scaffold_background.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/entities/drafting_request.dart';
import '../../domain/entities/legal_drafting_result.dart';

/// Visionneuse en **lecture seule** d'un document professionnel déjà généré,
/// ouverte depuis la section « Documents récents » de la sidebar. Pas de
/// régénération ni d'ajustement ici — l'espace de rédaction interactif
/// ([DraftingWorkspaceScreen]) reste le point d'entrée pour produire un
/// nouveau document.
class DraftingResultScreen extends StatelessWidget {
  const DraftingResultScreen({super.key, required this.result});

  final LegalDraftingResult result;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final readingStyle = textTheme.bodyLarge?.copyWith(
      fontFamily: 'Lora',
      color: AppColors.textPrimary,
      height: 1.8,
      fontSize: 16,
    );

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(result.title),
          actions: [
            IconButton(
              tooltip: 'Copier',
              icon: const Icon(Icons.copy_rounded),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: result.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Texte copié dans le presse-papiers.'),
                  ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _ResultHero(result: result),
                  const SizedBox(height: AppSpacing.md),
                  GlassContainer(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: SelectableText(result.content, style: readingStyle),
                  ),
                  if (result.citedSources.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    GlassContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.local_library_rounded,
                                size: 18,
                                color: AppColors.gold,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Sources consultées',
                                style: textTheme.titleSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          for (final source in result.citedSources)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '• ${source.title} (${source.reference})',
                                style: textTheme.bodySmall,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (result.risks.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Clauses à risque identifiées',
                      style: textTheme.titleMedium,
                    ),
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
        ),
      ),
    );
  }
}

class _ResultHero extends StatelessWidget {
  const _ResultHero({required this.result});

  final LegalDraftingResult result;

  String get _date {
    final d = result.generatedAt;
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (icon, tint, label) = switch (result.mode) {
      DraftingMode.redaction => (
        Icons.draw_rounded,
        AppColors.metalDeepGold,
        'ACTE RÉDIGÉ',
      ),
      DraftingMode.audit => (
        Icons.rule_rounded,
        AppColors.metalCobalt,
        'AUDIT FINALISÉ',
      ),
      DraftingMode.consultation => (
        Icons.balance_rounded,
        AppColors.metalEmerald,
        'NOTE PRÉPARÉE',
      ),
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.large),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint.withValues(alpha: 0.2), const Color(0x10101B29)],
        ),
        border: Border.all(color: tint.withValues(alpha: 0.42)),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: Border.all(color: tint.withValues(alpha: 0.42)),
            ),
            child: Icon(icon, color: tint, size: 23),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: tint,
                    letterSpacing: AppLetterSpacing.caps,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Document prêt à l’emploi',
                  style: textTheme.titleLarge?.copyWith(
                    fontFamily: 'Libre Caslon Display',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Généré le $_date · relisez et personnalisez avant utilisation.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (result.isFavorite)
            const Icon(Icons.star_rounded, color: AppColors.gold, size: 20),
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              risk.riskLevel.label,
              style: textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            risk.clauseExcerpt,
            style: textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(risk.explanation, style: textTheme.bodyMedium),
          if (risk.suggestedRewrite.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Reformulation proposée :',
              style: textTheme.labelMedium?.copyWith(color: AppColors.gold),
            ),
            const SizedBox(height: 4),
            Text(risk.suggestedRewrite, style: textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
