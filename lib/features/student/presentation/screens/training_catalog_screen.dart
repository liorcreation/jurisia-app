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
          leading: const AppShellMenuButton(),
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
                    const _CatalogEyebrow('FORMATIONS CERTIFIANTES'),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Choisissez votre spécialité',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontFamily: 'Libre Caslon Display',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Text(
                        'Des parcours courts, ciblés et évalués par JurisIA pour transformer une matière juridique en compétence directement mobilisable.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
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
        const _CatalogTrustNote(),
      ],
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

class _TrainingCategoryCard extends StatelessWidget {
  const _TrainingCategoryCard({required this.category, required this.onOpen});

  final TrainingCategory category;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassContainer(
      onTap: category.isAvailable ? onOpen : null,
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: AppColors.gold.withValues(alpha: 0.34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_iconFor(category.icon), color: AppColors.goldLight, size: 28),
          const SizedBox(height: AppSpacing.lg),
          Text(
            category.title,
            style: textTheme.titleLarge?.copyWith(
              fontFamily: 'Libre Caslon Display',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            category.subtitle ?? '',
            style: textTheme.labelMedium?.copyWith(color: AppColors.goldLight),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            category.description,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextButton.icon(
            onPressed: category.isAvailable ? onOpen : null,
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('Ouvrir la formation'),
          ),
        ],
      ),
    );
  }
}

class TrainingCategoryDetailScreen extends StatelessWidget {
  const TrainingCategoryDetailScreen({super.key, required this.category});

  final TrainingCategory category;

  @override
  Widget build(BuildContext context) {
    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(category.title)),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: GlassContainer(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  borderColor: AppColors.gold.withValues(alpha: 0.42),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _iconFor(category.icon),
                        color: AppColors.goldLight,
                        size: 38,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const _CatalogEyebrow('PARCOURS CERTIFIANT'),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        category.title,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(fontFamily: 'Libre Caslon Display'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        category.description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const _ComingSoonPanel(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComingSoonPanel extends StatelessWidget {
  const _ComingSoonPanel();

  @override
  Widget build(BuildContext context) {
    return PremiumLikePanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: AppColors.goldLight),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Le catalogue détaillé, les leçons et les évaluations de cette spécialité sont en cours de finalisation. Votre orientation est bien enregistrée.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
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
