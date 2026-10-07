import 'package:flutter/material.dart';

import '../../../../core/widgets/app_shell_menu_button.dart';
import '../../../../core/widgets/entrance_fade.dart';
import '../../../../core/widgets/luxury_scaffold_background.dart';
import '../../../../theme/app_theme.dart';

enum _OpportunityKind { internship, employment }

/// Hub des opportunités professionnelles : la personne choisit le type
/// d’annonce avant d’accéder à sa liste.
class CareerOpportunitiesScreen extends StatefulWidget {
  const CareerOpportunitiesScreen({super.key});

  @override
  State<CareerOpportunitiesScreen> createState() =>
      _CareerOpportunitiesScreenState();
}

class _CareerOpportunitiesScreenState extends State<CareerOpportunitiesScreen> {
  _OpportunityKind? _selection;

  @override
  Widget build(BuildContext context) {
    final selected = _selection;
    final title = switch (selected) {
      _OpportunityKind.internship => 'Offre de stage',
      _OpportunityKind.employment => 'Offre d’emploi',
      null => 'Stages et emploi',
    };

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: selected == null
              ? const AppShellMenuButton()
              : IconButton(
                  tooltip: 'Revenir aux choix',
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => setState(() => _selection = null),
                ),
          title: Text(title),
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
                child: AnimatedSwitcher(
                  duration: AppMotion.standard,
                  switchInCurve: AppMotion.premium,
                  child: selected == null
                      ? _OpportunityChooser(
                          key: const ValueKey('chooser'),
                          onSelect: (kind) => setState(() => _selection = kind),
                        )
                      : _OpportunityListing(
                          key: ValueKey(selected),
                          kind: selected,
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

class _OpportunityChooser extends StatelessWidget {
  const _OpportunityChooser({super.key, required this.onSelect});

  final ValueChanged<_OpportunityKind> onSelect;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EntranceFadeSlide(
          index: 0,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.large + 4),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.cobalt, AppColors.cobaltDeep, AppColors.deepSlate],
              ),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.32)),
              boxShadow: AppShadows.floating,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _GoldLabel('CARRIÈRES · JURISIA'),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'La prochaine étape\nde votre parcours.',
                  style: textTheme.displaySmall?.copyWith(
                    fontFamily: 'Libre Caslon Display',
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Text(
                    'Explorez les opportunités professionnelles et choisissez le type d’annonce qui correspond à votre projet.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const _GoldLabel('CHOISIR UN PARCOURS'),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Que recherchez-vous ?',
          style: textTheme.headlineMedium?.copyWith(
            fontFamily: 'Libre Caslon Display',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 700;
            final internship = _OpportunityCard(
              index: 1,
              icon: Icons.school_rounded,
              eyebrow: 'APPRENDRE SUR LE TERRAIN',
              title: 'Offre de stage',
              description:
                  'Découvrez des stages pour développer votre expérience et mettre vos compétences en pratique.',
              onTap: () => onSelect(_OpportunityKind.internship),
            );
            final employment = _OpportunityCard(
              index: 2,
              icon: Icons.work_rounded,
              eyebrow: 'FAIRE ÉVOLUER SA CARRIÈRE',
              title: 'Offre d’emploi',
              description:
                  'Consultez les opportunités de poste et trouvez un environnement où faire grandir votre parcours.',
              onTap: () => onSelect(_OpportunityKind.employment),
            );
            if (narrow) {
              return Column(
                children: [
                  internship,
                  const SizedBox(height: AppSpacing.md),
                  employment,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: internship),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: employment),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({
    required this.index,
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final int index;
  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return EntranceFadeSlide(
      index: index,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.large),
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.large),
              gradient: AppGradients.glassCard,
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: AppGradients.goldMetallic,
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: AppShadows.goldGlow,
                  ),
                  child: Icon(icon, color: AppColors.deepSlate),
                ),
                const SizedBox(height: AppSpacing.lg),
                _GoldLabel(eyebrow),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  title,
                  style: textTheme.headlineSmall?.copyWith(
                    fontFamily: 'Libre Caslon Display',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Text(
                      'Explorer les annonces',
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.goldLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(Icons.arrow_forward_rounded, color: AppColors.gold),
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

class _OpportunityListing extends StatelessWidget {
  const _OpportunityListing({super.key, required this.kind});

  final _OpportunityKind kind;

  @override
  Widget build(BuildContext context) {
    final isInternship = kind == _OpportunityKind.internship;
    final title = isInternship ? 'Offre de stage' : 'Offre d’emploi';
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _GoldLabel('OPPORTUNITÉS PROFESSIONNELLES'),
        const SizedBox(height: AppSpacing.sm),
        Text(
          title,
          style: textTheme.displaySmall?.copyWith(
            fontFamily: 'Libre Caslon Display',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: AppColors.deepSlateElevated.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.cobalt.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                ),
                child: Icon(
                  isInternship ? Icons.school_rounded : Icons.work_rounded,
                  color: AppColors.goldLight,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Aucune annonce publiée pour le moment',
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontFamily: 'Libre Caslon Display',
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  'Les nouvelles offres ${isInternship ? 'de stage' : 'd’emploi'} apparaîtront ici dès leur publication.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoldLabel extends StatelessWidget {
  const _GoldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: AppColors.goldLight,
      letterSpacing: 2.0,
      fontWeight: FontWeight.w800,
    ),
  );
}
