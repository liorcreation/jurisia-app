import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/platform/app_platform_style.dart';
import '../../../../core/widgets/app_shell_menu_button.dart';
import '../../../../core/widgets/entrance_fade.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/gradient_icon_badge.dart';
import '../../../../core/widgets/luxury_scaffold_background.dart';
import '../../../../core/widgets/shimmer_sweep.dart';
import '../../../../models/legal_document/legal_domain.dart';
import '../../../../theme/app_theme.dart';
import '../../data/datasources/professional_template_local_datasource.dart';
import '../../domain/entities/drafting_request.dart';
import '../../domain/entities/legal_drafting_result.dart';
import '../../domain/entities/professional_template.dart';
import '../controllers/professional_documents_controller.dart';
import '../widgets/drafting_intake_sheet.dart';
import 'drafting_result_screen.dart';
import 'drafting_workspace_screen.dart';

const _templateDataSource = LocalProfessionalTemplateDataSource();

/// Section 4 — Espace professionnel : tableau de bord avec trois actions
/// rapides (rédaction d'actes, audit de contrat, consultation approfondie),
/// menant à l'espace de rédaction interactif.
class ProfessionalScreen extends StatelessWidget {
  const ProfessionalScreen({super.key});

  void _openIntake(BuildContext context, DraftingMode mode, {ProfessionalTemplate? template}) {
    final sheet = DraftingIntakeSheet(
      mode: mode,
      templates: _templateDataSource.getAll(),
      initialTemplate: template,
      onSubmit: (request) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DraftingWorkspaceScreen(request: request)),
        );
      },
    );

    if (AppPlatformStyle.of(context) == AppPlatformStyle.desktop) {
      showDialog<void>(
        context: context,
        barrierColor: AppColors.nightBlueDeep.withValues(alpha: 0.55),
        builder: (_) => sheet,
      );
    } else {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => sheet,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (AppPlatformStyle.of(context) == AppPlatformStyle.desktop) {
      return _DesktopProfessionalView(
        onOpenIntake: (mode, {template}) => _openIntake(context, mode, template: template),
      );
    }

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Espace professionnel'),
          leading: const AppShellMenuButton(),
        ),
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

// ===========================================================================
//  DESKTOP — « L'atelier » : ingénierie juridique assistée par IA
// ===========================================================================

typedef _OpenIntake = void Function(DraftingMode mode, {ProfessionalTemplate? template});

/// Palette métallique propre à chaque instrument de travail.
({Color tint, Gradient gradient}) _modeStyle(DraftingMode mode) {
  switch (mode) {
    case DraftingMode.redaction:
      return (tint: AppColors.metalDeepGold, gradient: AppGradients.goldMetallic);
    case DraftingMode.audit:
      return (
        tint: AppColors.metalCobalt,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8FB4EC), AppColors.metalCobalt, Color(0xFF3A5C86)],
        ),
      );
    case DraftingMode.consultation:
      return (
        tint: AppColors.metalEmerald,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8FCBB2), AppColors.metalEmerald, Color(0xFF3C7C64)],
        ),
      );
  }
}

IconData _modeIcon(DraftingMode mode) {
  switch (mode) {
    case DraftingMode.redaction:
      return Icons.draw_rounded;
    case DraftingMode.audit:
      return Icons.rule_rounded;
    case DraftingMode.consultation:
      return Icons.balance_rounded;
  }
}

String _modeTitle(DraftingMode mode) {
  switch (mode) {
    case DraftingMode.redaction:
      return 'Rédaction d\'actes & contrats';
    case DraftingMode.audit:
      return 'Audit & analyse de clauses';
    case DraftingMode.consultation:
      return 'Consultation approfondie';
  }
}

String _modeShort(DraftingMode mode) {
  switch (mode) {
    case DraftingMode.redaction:
      return 'Acte rédigé';
    case DraftingMode.audit:
      return 'Audit de contrat';
    case DraftingMode.consultation:
      return 'Note de synthèse';
  }
}

String _modeDescription(DraftingMode mode) {
  switch (mode) {
    case DraftingMode.redaction:
      return 'Un acte complet généré à partir d\'un modèle et du contexte que vous renseignez.';
    case DraftingMode.audit:
      return 'Collez un contrat existant : l\'IA en isole les clauses fragiles et les réécrit.';
    case DraftingMode.consultation:
      return 'Une question de droit complexe traitée en note de synthèse argumentée.';
  }
}

List<String> _modeDeliverables(DraftingMode mode) {
  switch (mode) {
    case DraftingMode.redaction:
      return const [
        'Acte structuré, prêt à personnaliser',
        'Clauses calées sur le droit burkinabè & OHADA',
        'Ajustements rapides en un clic',
      ];
    case DraftingMode.audit:
      return const [
        'Clauses abusives ou à risque signalées',
        'Un niveau de risque par clause',
        'Une reformulation proposée pour chacune',
      ];
    case DraftingMode.consultation:
      return const [
        'Analyse argumentée, au plan structuré',
        'Textes et jurisprudence cités à l\'appui',
        'Note de synthèse exportable',
      ];
  }
}

IconData _domainIconPro(LegalDomain domain) {
  switch (domain) {
    case LegalDomain.commercial:
      return Icons.storefront_rounded;
    case LegalDomain.travail:
      return Icons.badge_rounded;
    case LegalDomain.civil:
      return Icons.handshake_rounded;
    default:
      return Icons.description_rounded;
  }
}

String _relativeDate(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inMinutes < 1) return 'à l\'instant';
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  if (diff.inDays == 1) return 'hier';
  if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _DesktopProfessionalView extends StatelessWidget {
  const _DesktopProfessionalView({required this.onOpenIntake});

  final _OpenIntake onOpenIntake;

  @override
  Widget build(BuildContext context) {
    final recent = context.watch<ProfessionalDocumentsController>().recentResults;

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(child: IgnorePointer(child: _AtelierAmbience())),
              Column(
                children: [
                  const _DesktopProfessionalHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1180),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.xl,
                              AppSpacing.xl,
                              AppSpacing.xl,
                              AppSpacing.xxl,
                            ),
                            child: _AtelierBody(recent: recent, onOpenIntake: onOpenIntake),
                          ),
                        ),
                      ),
                    ),
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

class _DesktopProfessionalHeader extends StatelessWidget {
  const _DesktopProfessionalHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.smokedGlass,
        border: Border(
          bottom: BorderSide(color: AppColors.gold.withValues(alpha: 0.18), width: 0.6),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.design_services_rounded, size: 18, color: AppColors.gold),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Espace professionnel', style: textTheme.headlineSmall),
                const SizedBox(height: 3),
                Text(
                  'Atelier d\'ingénierie juridique — actes, audits et notes de synthèse',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const _CommandHint(),
        ],
      ),
    );
  }
}

class _CommandHint extends StatelessWidget {
  const _CommandHint();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Tooltip(
      message: 'Palette de commandes',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.small),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.25), width: 0.7),
          color: AppColors.legalBlueDark.withValues(alpha: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, size: 13, color: AppColors.goldLight),
            const SizedBox(width: 6),
            Text(
              '⌘K',
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.goldLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AtelierBody extends StatelessWidget {
  const _AtelierBody({required this.recent, required this.onOpenIntake});

  final List<LegalDraftingResult> recent;
  final _OpenIntake onOpenIntake;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final instruments = LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          for (var i = 0; i < DraftingMode.values.length; i++)
            EntranceFadeSlide(
              index: i,
              child: _InstrumentCard(
                mode: DraftingMode.values[i],
                onOpen: () => onOpenIntake(DraftingMode.values[i]),
              ),
            ),
        ];

        if (constraints.maxWidth < 900) {
          return Column(
            children: [
              for (var i = 0; i < cards.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: i == cards.length - 1 ? 0 : AppSpacing.md),
                  child: cards[i],
                ),
            ],
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.md),
                Expanded(child: cards[i]),
              ],
            ],
          ),
        );
      },
    );

    final templatesColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow('Modèles prêts à l\'emploi'),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Renseignez quelques informations, l\'acte est rédigé au fil de l\'eau.',
          style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        _TemplateGrid(onOpenIntake: onOpenIntake),
      ],
    );

    final sideColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RecentPanel(recent: recent),
        const SizedBox(height: AppSpacing.md),
        const _HowItWorks(),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow('Ingénierie juridique assistée par IA'),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Votre atelier de rédaction',
          style: textTheme.displaySmall?.copyWith(fontFamily: 'Libre Caslon Display'),
        ),
        const SizedBox(height: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Text(
            'Trois instruments pour produire un travail abouti — un acte sur mesure, '
            'l\'audit d\'un contrat, ou une note de synthèse — chacun nourri par les '
            'textes de la bibliothèque juridique.',
            style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary, height: 1.5),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        instruments,
        const SizedBox(height: AppSpacing.xxl),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 960) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  templatesColumn,
                  const SizedBox(height: AppSpacing.xl),
                  sideColumn,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: templatesColumn),
                const SizedBox(width: AppSpacing.xl),
                SizedBox(width: 340, child: sideColumn),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _InstrumentCard extends StatefulWidget {
  const _InstrumentCard({required this.mode, required this.onOpen});

  final DraftingMode mode;
  final VoidCallback onOpen;

  @override
  State<_InstrumentCard> createState() => _InstrumentCardState();
}

class _InstrumentCardState extends State<_InstrumentCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = _modeStyle(widget.mode);

    Widget badge = GradientIconBadge(
      icon: _modeIcon(widget.mode),
      size: 52,
      gradient: style.gradient,
    );
    if (_hovered) {
      badge = ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: ShimmerSweep(duration: const Duration(milliseconds: 1600), child: badge),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedSlide(
        offset: _hovered ? const Offset(0, -0.012) : Offset.zero,
        duration: const Duration(milliseconds: 160),
        child: GlassContainer(
          onTap: widget.onOpen,
          padding: const EdgeInsets.all(AppSpacing.lg),
          borderColor: _hovered
              ? style.tint.withValues(alpha: 0.6)
              : style.tint.withValues(alpha: 0.28),
          borderWidth: _hovered ? 1 : 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              badge,
              const SizedBox(height: AppSpacing.md),
              Text(
                _modeTitle(widget.mode),
                style: textTheme.titleLarge?.copyWith(fontFamily: 'Libre Caslon Display', height: 1.15),
              ),
              const SizedBox(height: 6),
              Text(
                _modeDescription(widget.mode),
                style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final line in _modeDeliverables(widget.mode))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Icon(Icons.check_rounded, size: 13, color: style.tint),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          line,
                          style: textTheme.bodySmall?.copyWith(height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              const Spacer(),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Ouvrir l\'atelier',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.goldLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.goldLight),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateGrid extends StatelessWidget {
  const _TemplateGrid({required this.onOpenIntake});

  final _OpenIntake onOpenIntake;

  @override
  Widget build(BuildContext context) {
    final templates = _templateDataSource.getAll();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 2 : 1;
        final gap = AppSpacing.md * (columns - 1);
        final width = (constraints.maxWidth - gap) / columns;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (var i = 0; i < templates.length; i++)
              SizedBox(
                width: width,
                child: EntranceFadeSlide(
                  index: i,
                  child: _TemplateCard(
                    template: templates[i],
                    onOpen: () => onOpenIntake(DraftingMode.redaction, template: templates[i]),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.onOpen});

  final ProfessionalTemplate template;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassContainer(
      onTap: onOpen,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientIconBadge(icon: _domainIconPro(template.domain), size: 40),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.title,
                      style: textTheme.titleSmall?.copyWith(
                        fontFamily: 'Libre Caslon Display',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      template.domain.label,
                      style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            template.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.35),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '${template.requiredFields.length} informations',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Rédiger',
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.goldLight),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentPanel extends StatelessWidget {
  const _RecentPanel({required this.recent});

  final List<LegalDraftingResult> recent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Eyebrow('Travaux récents'),
          const SizedBox(height: AppSpacing.md),
          if (recent.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.folder_open_rounded, size: 22, color: AppColors.gold.withValues(alpha: 0.6)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Vos actes, audits et notes générés apparaîtront ici, prêts à rouvrir.',
                  style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            )
          else
            for (var i = 0; i < recent.length && i < 6; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i == recent.length - 1 || i == 5 ? 0 : AppSpacing.sm),
                child: _RecentTile(result: recent[i]),
              ),
        ],
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.result});

  final LegalDraftingResult result;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = _modeStyle(result.mode);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.small),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DraftingResultScreen(result: result)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(_modeIcon(result.mode), size: 15, color: style.tint),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${_modeShort(result.mode)} · ${_relativeDate(result.generatedAt)}',
                      style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (result.isFavorite)
                const Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
            ],
          ),
        ),
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  static const _steps = <(IconData, String)>[
    (Icons.tune_rounded, 'Choisissez un instrument et renseignez le contexte'),
    (Icons.auto_awesome_rounded, 'L\'IA rédige au fil de l\'eau, sources à l\'appui'),
    (Icons.done_all_rounded, 'Ajustez en un clic, copiez ou exportez'),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Eyebrow('L\'atelier en bref'),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < _steps.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == _steps.length - 1 ? 0 : AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '0${i + 1}',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(_steps[i].$1, size: 14, color: AppColors.goldLight),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _steps[i].$2,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
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

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 1, color: AppColors.gold.withValues(alpha: 0.6)),
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

/// Fines poussières d'or en suspension — la même respiration « vivante »
/// que les autres écrans du registre desktop.
class _AtelierAmbience extends StatefulWidget {
  const _AtelierAmbience();

  @override
  State<_AtelierAmbience> createState() => _AtelierAmbienceState();
}

class _AtelierAmbienceState extends State<_AtelierAmbience> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 36))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(painter: _AtelierAmbiencePainter(_controller.value)),
    );
  }
}

class _AtelierAmbiencePainter extends CustomPainter {
  const _AtelierAmbiencePainter(this.t);

  final double t;
  static const int _count = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < _count; i++) {
      final seed = i * 53.0;
      final baseX = seed % size.width;
      final drift = math.sin((t * 2 * math.pi) + seed) * 24;
      final x = (baseX + drift) % size.width;
      final y = (size.height * ((i / _count) + t) % 1.0);
      final radius = 0.8 + (i % 3) * 0.7;
      final opacity = 0.05 + 0.09 * (0.5 + 0.5 * math.sin((t * 2 * math.pi) + seed * 1.7));
      paint.color = AppColors.goldLight.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AtelierAmbiencePainter oldDelegate) => oldDelegate.t != t;
}
