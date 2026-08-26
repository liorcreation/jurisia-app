import 'package:flutter/material.dart';

import '../../../../core/platform/app_platform_style.dart';
import '../../../../core/widgets/entrance_fade.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/gradient_icon_badge.dart';
import '../../../../core/widgets/luxury_scaffold_background.dart';
import '../../../../theme/app_theme.dart';
import '../../data/datasources/professional_template_local_datasource.dart';
import '../../domain/entities/drafting_request.dart';
import '../widgets/drafting_intake_sheet.dart';
import 'drafting_workspace_screen.dart';

const _templateDataSource = LocalProfessionalTemplateDataSource();

/// Section 4 — Espace professionnel : tableau de bord avec trois actions
/// rapides (rédaction d'actes, audit de contrat, consultation approfondie),
/// menant à l'espace de rédaction interactif.
class ProfessionalScreen extends StatelessWidget {
  const ProfessionalScreen({super.key});

  void _openIntake(BuildContext context, DraftingMode mode) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraftingIntakeSheet(
        mode: mode,
        templates: _templateDataSource.getAll(),
        onSubmit: (request) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => DraftingWorkspaceScreen(request: request)),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Espace professionnel')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                'Ingénierie juridique assistée par IA',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                "Rédigez des actes sur mesure, auditez un contrat ou obtenez une note de synthèse "
                "approfondie, enrichis par les textes de la bibliothèque juridique.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (AppPlatformStyle.of(context) == AppPlatformStyle.desktop) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: AppColors.textSecondary.withValues(alpha: 0.12),
                      ),
                      child: Text(
                        '⌘K',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text('Palette de commandes', style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              EntranceFadeSlide(
                index: 0,
                child: _ActionCard(
                  icon: Icons.edit_document,
                  emoji: '✍️',
                  title: 'Rédaction d\'Actes & Contrats',
                  subtitle: 'Bail commercial, contrat de prestation, statuts SARL/SAS, contrat de travail…',
                  onTap: () => _openIntake(context, DraftingMode.redaction),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              EntranceFadeSlide(
                index: 1,
                child: _ActionCard(
                  icon: Icons.fact_check_rounded,
                  emoji: '🔍',
                  title: 'Audit & Analyse de Clauses',
                  subtitle: 'Détection de clauses abusives ou à risque et propositions de reformulation.',
                  onTap: () => _openIntake(context, DraftingMode.audit),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              EntranceFadeSlide(
                index: 2,
                child: _ActionCard(
                  icon: Icons.balance_rounded,
                  emoji: '⚖️',
                  title: 'Consultation Approfondie & Note de Synthèse',
                  subtitle:
                      'Analyse argumentée d\'une question de droit complexe, textes et jurisprudence à l\'appui.',
                  onTap: () => _openIntake(context, DraftingMode.consultation),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassContainer(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientIconBadge(icon: icon, size: 48),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$emoji $title', style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle, style: textTheme.bodyMedium),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
