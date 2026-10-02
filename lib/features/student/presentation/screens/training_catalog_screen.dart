import 'package:flutter/material.dart';

import '../../../../core/widgets/app_shell_menu_button.dart';
import '../../../../core/widgets/entrance_fade.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/luxury_scaffold_background.dart';
import '../../../../models/training/training_category.dart';
import '../../../../theme/app_theme.dart';
import '../../data/datasources/training_catalog_local_datasource.dart';

/// Catalogue thématique des formations certifiantes.
class TrainingCatalogScreen extends StatelessWidget {
  const TrainingCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = const TrainingCatalogLocalDataSource()
        .getAll()
        .where((category) => category.trainingType == TrainingType.certifying)
        .toList();

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Retour à l’espace étudiant',
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          actions: const [AppShellMenuButton()],
          title: const Text('Catalogue certifiant'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CatalogHero(categoryCount: categories.length),
                    const SizedBox(height: AppSpacing.xl),
                    const _LearningRouteRail(),
                    const SizedBox(height: AppSpacing.xl),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 880
                            ? 3
                            : constraints.maxWidth >= 560
                            ? 2
                            : 1;
                        final gap = AppSpacing.md * (columns - 1);
                        final width = (constraints.maxWidth - gap) / columns;
                        return Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.md,
                          children: [
                            for (var i = 0; i < categories.length; i++)
                              SizedBox(
                                width: width,
                                child: EntranceFadeSlide(
                                  index: i,
                                  child: _TrainingCategoryCard(
                                    category: categories[i],
                                    index: i + 1,
                                    onOpen: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            TrainingCategoryDetailScreen(
                                              category: categories[i],
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _CatalogTrustNote(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Deux cartes d'orientation de l'accueil Étudiant.
class TrainingOrientationSection extends StatelessWidget {
  const TrainingOrientationSection({super.key, required this.onOpenCatalog});

  final VoidCallback onOpenCatalog;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StudentWelcomeHero(),
        const SizedBox(height: AppSpacing.xl),
        const _CatalogEyebrow('VOTRE ORIENTATION'),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Choisissez votre parcours',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontFamily: 'Libre Caslon Display',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Text(
            'JurisIA vous accompagne d’abord par des formations certifiantes thématiques. Le parcours universitaire LMD sera activé dans une prochaine phase.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 700;
            final cards = [
              _OrientationCard(
                icon: Icons.workspace_premium_rounded,
                title: 'Formations Certifiantes',
                subtitle: 'Spécialisez-vous à votre rythme',
                description:
                    'Des parcours thématiques guidés, des cas pratiques et une certification JurisIA à la clé.',
                badge: 'Disponible',
                tint: AppColors.gold,
                available: true,
                onTap: onOpenCatalog,
              ),
              const _OrientationCard(
                icon: Icons.school_rounded,
                title: 'Système LMD',
                subtitle: 'Licence, Master 1, Master 2',
                description:
                    'Le cursus universitaire séquentiel sera ouvert après la mise en vigueur du catalogue académique.',
                badge: 'Non encore en vigueur',
                tint: AppColors.cobaltLight,
                available: false,
              ),
            ];
            if (compact) {
              return Column(
                children: [
                  cards[0],
                  const SizedBox(height: AppSpacing.md),
                  cards[1],
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: cards[1]),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        const _LearningRouteRail(),
        const SizedBox(height: AppSpacing.xl),
        const _CatalogTrustNote(),
      ],
    );
  }
}

class _CatalogHero extends StatelessWidget {
  const _CatalogHero({required this.categoryCount});

  final int categoryCount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        return Container(
          clipBehavior: Clip.antiAlias,
          padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.large + 4),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E426A), Color(0xFF111D30), Color(0xFF0A101A)],
              stops: [0, 0.55, 1],
            ),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.32)),
            boxShadow: [
              BoxShadow(
                color: AppColors.cobalt.withValues(alpha: 0.16),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: compact ? -92 : 42,
                top: compact ? -116 : -150,
                child: IgnorePointer(
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    size: compact ? 240 : 320,
                    color: AppColors.gold.withValues(alpha: 0.055),
                  ),
                ),
              ),
              if (compact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _CatalogEyebrow('FORMATIONS CERTIFIANTES'),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Choisissez votre spécialité.',
                      style: textTheme.headlineMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontFamily: 'Libre Caslon Display',
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Des parcours courts et évalués pour transformer une matière juridique en compétence mobilisable.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _CatalogHeroMeta(categoryCount: categoryCount),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _CatalogEyebrow('FORMATIONS CERTIFIANTES'),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Choisissez votre spécialité.',
                            style: textTheme.displaySmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontFamily: 'Libre Caslon Display',
                              height: 1.04,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 720),
                            child: Text(
                              'Des parcours courts, ciblés et évalués par JurisIA pour transformer une matière juridique en compétence directement mobilisable.',
                              style: textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.55,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    _CatalogHeroMeta(categoryCount: categoryCount),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CatalogHeroMeta extends StatelessWidget {
  const _CatalogHeroMeta({required this.categoryCount});

  final int categoryCount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _StudentStat(
          icon: Icons.grid_view_rounded,
          value: '$categoryCount',
          label: 'spécialités',
        ),
        const _StudentStat(
          icon: Icons.verified_rounded,
          value: '100%',
          label: 'parcours guidés',
        ),
        const _StudentStat(
          icon: Icons.auto_awesome_rounded,
          value: '01',
          label: 'certificat JurisIA',
        ),
      ],
    );
  }
}

class _LearningRouteRail extends StatelessWidget {
  const _LearningRouteRail();

  static const _steps = [
    (
      icon: Icons.explore_rounded,
      number: '01',
      title: 'Choisir',
      text: 'Une spécialité alignée sur votre projet.',
    ),
    (
      icon: Icons.menu_book_rounded,
      number: '02',
      title: 'Progresser',
      text: 'Des modules courts, des cas et une méthode.',
    ),
    (
      icon: Icons.workspace_premium_rounded,
      number: '03',
      title: 'Certifier',
      text: 'Une évaluation finale pour valider vos acquis.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final steps = [
          for (final step in _steps)
            _LearningRouteStep(
              icon: step.icon,
              number: step.number,
              title: step.title,
              text: step.text,
            ),
        ];
        return GlassContainer(
          padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
          borderColor: AppColors.cobaltLight.withValues(alpha: 0.24),
          gradient: const LinearGradient(
            colors: [Color(0x201A5590), Color(0x0D10243A)],
          ),
          child: compact
              ? Column(
                  children: [
                    for (var i = 0; i < steps.length; i++) ...[
                      steps[i],
                      if (i < steps.length - 1)
                        const Divider(height: AppSpacing.xl),
                    ],
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < steps.length; i++) ...[
                      Expanded(child: steps[i]),
                      if (i < steps.length - 1)
                        const SizedBox(width: AppSpacing.md),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class _LearningRouteStep extends StatelessWidget {
  const _LearningRouteStep({
    required this.icon,
    required this.number,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String number;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppGradients.goldMetallic,
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          child: Icon(icon, size: 19, color: AppColors.nightBlueDeep),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$number  $title',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StudentWelcomeHero extends StatelessWidget {
  const _StudentWelcomeHero();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        return Container(
          clipBehavior: Clip.antiAlias,
          padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.large + 4),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF173B60), Color(0xFF111D30), Color(0xFF0B111C)],
              stops: [0, 0.54, 1],
            ),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: AppColors.nightBlueDeep.withValues(alpha: 0.42),
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: compact ? -84 : 24,
                top: compact ? -110 : -142,
                child: IgnorePointer(
                  child: Container(
                    width: compact ? 260 : 360,
                    height: compact ? 260 : 360,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.09),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: compact ? 184 : 258,
                        height: compact ? 184 : 258,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.cobaltLight.withValues(
                              alpha: 0.12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (compact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _CatalogEyebrow('ESPACE ÉTUDIANT · JURISIA'),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Votre progression\ncommence ici.',
                      style: textTheme.headlineMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontFamily: 'Libre Caslon Display',
                        height: 1.06,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Des spécialités ciblées, des cas concrets et une validation qui transforme vos connaissances en réflexes professionnels.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _StudentStat(
                          icon: Icons.workspace_premium_rounded,
                          value: '01',
                          label: 'objectif certifiant',
                        ),
                        _StudentStat(
                          icon: Icons.auto_graph_rounded,
                          value: '∞',
                          label: 'à votre rythme',
                        ),
                      ],
                    ),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _CatalogEyebrow('ESPACE ÉTUDIANT · JURISIA'),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Votre progression commence ici.',
                            style: textTheme.displaySmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontFamily: 'Libre Caslon Display',
                              height: 1.04,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 650),
                            child: Text(
                              'Des spécialités ciblées, des cas concrets et une validation qui transforme vos connaissances en réflexes professionnels.',
                              style: textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.55,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    const Column(
                      children: [
                        _StudentStat(
                          icon: Icons.workspace_premium_rounded,
                          value: '01',
                          label: 'objectif certifiant',
                        ),
                        SizedBox(height: AppSpacing.sm),
                        _StudentStat(
                          icon: Icons.auto_graph_rounded,
                          value: '∞',
                          label: 'à votre rythme',
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StudentStat extends StatelessWidget {
  const _StudentStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.goldLight),
          const SizedBox(width: 7),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _OrientationCard extends StatefulWidget {
  const _OrientationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.badge,
    required this.tint,
    required this.available,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final String badge;
  final Color tint;
  final bool available;
  final VoidCallback? onTap;

  @override
  State<_OrientationCard> createState() => _OrientationCardState();
}

class _OrientationCardState extends State<_OrientationCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final borderColor = widget.available
        ? widget.tint.withValues(alpha: _hovered ? 0.72 : 0.42)
        : AppColors.glassBorder.withValues(alpha: 0.42);

    return MouseRegion(
      onEnter: widget.available ? (_) => setState(() => _hovered = true) : null,
      onExit: widget.available ? (_) => setState(() => _hovered = false) : null,
      child: AnimatedOpacity(
        duration: AppMotion.standard,
        opacity: widget.available ? 1 : 0.56,
        child: AnimatedSlide(
          duration: AppMotion.standard,
          offset: _hovered ? const Offset(0, -0.012) : Offset.zero,
          child: GlassContainer(
            onTap: widget.available ? widget.onTap : null,
            padding: const EdgeInsets.all(AppSpacing.lg),
            borderColor: borderColor,
            borderWidth: widget.available && _hovered ? 1.1 : 0.7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(widget.icon, color: widget.tint, size: 30),
                    const Spacer(),
                    _OrientationBadge(
                      label: widget.badge,
                      color: widget.tint,
                      icon: widget.available
                          ? Icons.check_circle_rounded
                          : Icons.lock_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  widget.title,
                  style: textTheme.headlineSmall?.copyWith(
                    fontFamily: 'Libre Caslon Display',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  style: textTheme.labelLarge?.copyWith(
                    color: widget.tint,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.available
                            ? 'Explorer le catalogue'
                            : 'Accès prochainement',
                        style: textTheme.labelLarge?.copyWith(
                          color: widget.available
                              ? AppColors.goldLight
                              : AppColors.textDisabled,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      widget.available
                          ? Icons.arrow_forward_rounded
                          : Icons.lock_outline_rounded,
                      size: 18,
                      color: widget.available
                          ? AppColors.goldLight
                          : AppColors.textDisabled,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrainingCategoryCard extends StatefulWidget {
  const _TrainingCategoryCard({
    required this.category,
    required this.index,
    required this.onOpen,
  });

  final TrainingCategory category;
  final int index;
  final VoidCallback onOpen;

  @override
  State<_TrainingCategoryCard> createState() => _TrainingCategoryCardState();
}

class _TrainingCategoryCardState extends State<_TrainingCategoryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final category = widget.category;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedSlide(
        duration: AppMotion.standard,
        offset: _hovered ? const Offset(0, -0.012) : Offset.zero,
        child: GlassContainer(
          onTap: category.isAvailable ? widget.onOpen : null,
          padding: const EdgeInsets.all(AppSpacing.lg),
          borderColor: AppColors.gold.withValues(alpha: _hovered ? 0.66 : 0.34),
          borderWidth: _hovered ? 1 : 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: AppGradients.goldMetallic,
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      _iconFor(category.icon),
                      color: AppColors.nightBlueDeep,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    widget.index.toString().padLeft(2, '0'),
                    style: textTheme.headlineSmall?.copyWith(
                      fontFamily: 'Libre Caslon Display',
                      color: AppColors.gold.withValues(alpha: 0.26),
                      height: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                category.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleLarge?.copyWith(
                  fontFamily: 'Libre Caslon Display',
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                category.subtitle ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                category.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: const [
                  _CatalogChip(
                    icon: Icons.menu_book_rounded,
                    label: 'Parcours guidé',
                  ),
                  _CatalogChip(
                    icon: Icons.verified_rounded,
                    label: 'Validation finale',
                  ),
                  _CatalogChip(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Certificat JurisIA',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      category.isAvailable
                          ? 'Ouvrir la spécialité'
                          : 'Accès prochainement',
                      style: textTheme.labelLarge?.copyWith(
                        color: category.isAvailable
                            ? AppColors.goldLight
                            : AppColors.textDisabled,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    category.isAvailable
                        ? Icons.arrow_outward_rounded
                        : Icons.lock_outline_rounded,
                    size: 18,
                    color: category.isAvailable
                        ? AppColors.goldLight
                        : AppColors.textDisabled,
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

class _CatalogChip extends StatelessWidget {
  const _CatalogChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.legalBlueDark.withValues(alpha: 0.62),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border: Border.all(color: AppColors.glassBorder),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.gold),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class TrainingCategoryDetailScreen extends StatelessWidget {
  const TrainingCategoryDetailScreen({super.key, required this.category});

  final TrainingCategory category;

  @override
  Widget build(BuildContext context) {
    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Spécialité'),
          actions: const [AppShellMenuButton()],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: _CategoryDetailContent(category: category),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryDetailContent extends StatelessWidget {
  const _CategoryDetailContent({required this.category});

  final TrainingCategory category;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CategoryHero(category: category),
        const SizedBox(height: AppSpacing.xl),
        _CategorySnapshot(category: category),
        const SizedBox(height: AppSpacing.xl),
        const _CatalogEyebrow('VOTRE PARCOURS'),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Une spécialité pensée pour la pratique.',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontFamily: 'Libre Caslon Display',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Apprenez à raisonner, qualifier et agir avec une méthode claire, progressive et directement applicable.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 700;
            final items = const [
              _DetailPillar(
                icon: Icons.menu_book_rounded,
                title: 'Comprendre',
                text: 'Les notions essentielles et leur logique juridique.',
              ),
              _DetailPillar(
                icon: Icons.account_tree_rounded,
                title: 'Raisonner',
                text:
                    'Une méthode pour qualifier les faits et construire l’analyse.',
              ),
              _DetailPillar(
                icon: Icons.workspace_premium_rounded,
                title: 'Valider',
                text: 'Une évaluation finale pour attester les acquis.',
              ),
            ];
            if (compact) {
              return Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    items[i],
                    if (i < items.length - 1)
                      const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  Expanded(child: items[i]),
                  if (i < items.length - 1)
                    const SizedBox(width: AppSpacing.md),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.lg),
          borderColor: AppColors.cobaltLight.withValues(alpha: 0.22),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.route_rounded, color: AppColors.cobaltLight),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Architecture du parcours',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Introduction · notions fondamentales · mises en situation · évaluation certifiante',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _CategoryRoadmap(),
      ],
    );
  }
}

class _CategorySnapshot extends StatelessWidget {
  const _CategorySnapshot({required this.category});

  final TrainingCategory category;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final items = [
          const _SnapshotItem(
            icon: Icons.route_rounded,
            value: '03',
            label: 'étapes guidées',
          ),
          const _SnapshotItem(
            icon: Icons.gavel_rounded,
            value: '100%',
            label: 'orienté pratique',
          ),
          _SnapshotItem(
            icon: Icons.verified_rounded,
            value: category.isAvailable ? 'OK' : '—',
            label: 'statut du parcours',
          ),
        ];
        return GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.md),
          borderColor: AppColors.gold.withValues(alpha: 0.24),
          child: compact
              ? Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.md,
                  children: items,
                )
              : Row(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      Expanded(child: items[i]),
                      if (i < items.length - 1)
                        const SizedBox(
                          height: 34,
                          child: VerticalDivider(width: AppSpacing.xl),
                        ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class _SnapshotItem extends StatelessWidget {
  const _SnapshotItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 19, color: AppColors.goldLight),
      const SizedBox(width: AppSpacing.sm),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    ],
  );
}

class _CategoryRoadmap extends StatelessWidget {
  const _CategoryRoadmap();

  @override
  Widget build(BuildContext context) {
    return PremiumLikePanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: AppColors.goldLight),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Votre feuille de route',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Orientation → modules guidés → exercices → évaluation certifiante. Les contenus disponibles apparaîtront dans votre espace étudiant au fil de leur ouverture.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
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

class _CategoryHero extends StatelessWidget {
  const _CategoryHero({required this.category});

  final TrainingCategory category;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.large + 4),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C416A), Color(0xFF121F32), Color(0xFF0A1019)],
        ),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.32)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cobalt.withValues(alpha: 0.16),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: AppGradients.goldMetallic,
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                    child: Icon(
                      _iconFor(category.icon),
                      color: AppColors.nightBlueDeep,
                      size: 28,
                    ),
                  ),
                  const Spacer(),
                  const _OrientationBadge(
                    label: 'Disponible',
                    color: AppColors.success,
                    icon: Icons.check_circle_rounded,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const _CatalogEyebrow('PARCOURS CERTIFIANT'),
              const SizedBox(height: AppSpacing.sm),
              Text(
                category.title,
                style:
                    (compact
                            ? textTheme.headlineMedium
                            : textTheme.displaySmall)
                        ?.copyWith(
                          color: AppColors.textPrimary,
                          fontFamily: 'Libre Caslon Display',
                          height: 1.06,
                        ),
              ),
              const SizedBox(height: 7),
              Text(
                category.subtitle ?? '',
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Text(
                  category.description,
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          );
          return content;
        },
      ),
    );
  }
}

class _DetailPillar extends StatelessWidget {
  const _DetailPillar({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => GlassContainer(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: AppColors.goldLight),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class PremiumLikePanel extends StatelessWidget {
  const PremiumLikePanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.26)),
      ),
      child: child,
    );
  }
}

class _OrientationBadge extends StatelessWidget {
  const _OrientationBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogTrustNote extends StatelessWidget {
  const _CatalogTrustNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.verified_user_outlined,
          color: AppColors.gold,
          size: 18,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Chaque parcours certifiant associe contenus pédagogiques, pratique guidée et validation finale. Les certificats seront vérifiables par code unique.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _CatalogEyebrow extends StatelessWidget {
  const _CatalogEyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.gold,
        fontWeight: FontWeight.w700,
        letterSpacing: AppLetterSpacing.caps,
      ),
    );
  }
}

IconData _iconFor(String icon) => switch (icon) {
  'family' => Icons.family_restroom_rounded,
  'account_balance' => Icons.account_balance_rounded,
  'business_center' => Icons.business_center_rounded,
  'verified_user' => Icons.verified_user_rounded,
  'domain' => Icons.domain_rounded,
  _ => Icons.school_rounded,
};
