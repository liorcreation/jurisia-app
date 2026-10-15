import 'package:flutter/material.dart';

import '../../../../core/widgets/app_shell_menu_button.dart';
import '../../../../core/widgets/entrance_fade.dart';
import '../../../../core/widgets/luxury_scaffold_background.dart';
import '../../../../theme/app_theme.dart';

enum _OpportunityKind { internship, employment }

abstract final class _CareerPalette {
  static const canvas = Color(0xFFF3F6FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFF8FAFD);
  static const ink = Color(0xFF10233F);
  static const muted = Color(0xFF52647C);
  static const subtle = Color(0xFF718198);
  static const border = Color(0xFFDCE4EE);
  static const goldInk = Color(0xFF8A6815);
  static const cobaltInk = Color(0xFF28558D);

  static const surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface, surfaceSoft],
  );
}

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
        backgroundColor: _CareerPalette.canvas,
        appBar: AppBar(
          leading: selected == null
              ? const AppShellMenuButton()
              : IconButton(
                  tooltip: 'Revenir aux choix',
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => setState(() => _selection = null),
                ),
          title: Text(title),
          backgroundColor: Colors.white,
          foregroundColor: _CareerPalette.ink,
          surfaceTintColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(
              height: 1,
              thickness: 1,
              color: _CareerPalette.border,
            ),
          ),
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
                          onSwitchKind: () => setState(() {
                            _selection = selected == _OpportunityKind.internship
                                ? _OpportunityKind.employment
                                : _OpportunityKind.internship;
                          }),
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
                colors: [
                  AppColors.cobalt,
                  AppColors.cobaltDeep,
                  AppColors.deepSlate,
                ],
              ),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.32)),
              boxShadow: AppShadows.floating,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _GoldLabel('CARRIÈRES · JURISIA', onDark: true),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'La prochaine étape\nde votre parcours.',
                  style: textTheme.displaySmall?.copyWith(
                    color: AppColors.textPrimary,
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
            color: _CareerPalette.ink,
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
              gradient: _CareerPalette.surfaceGradient,
              border: Border.all(color: _CareerPalette.border),
              boxShadow: [
                BoxShadow(
                  color: _CareerPalette.ink.withValues(alpha: 0.06),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
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
                    color: _CareerPalette.ink,
                    fontFamily: 'Libre Caslon Display',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: _CareerPalette.muted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Text(
                      'Explorer les annonces',
                      style: textTheme.labelLarge?.copyWith(
                        color: _CareerPalette.goldInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: _CareerPalette.goldInk,
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

class _OpportunityListing extends StatelessWidget {
  const _OpportunityListing({
    super.key,
    required this.kind,
    required this.onSwitchKind,
  });

  final _OpportunityKind kind;
  final VoidCallback onSwitchKind;

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
            color: _CareerPalette.ink,
            fontFamily: 'Libre Caslon Display',
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          isInternship
              ? 'Les opportunités de stage publiées par le réseau JurisIA.'
              : 'Les opportunités d’emploi publiées par le réseau JurisIA.',
          style: textTheme.bodyMedium?.copyWith(
            color: _CareerPalette.muted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: _CareerPalette.surfaceGradient,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: _CareerPalette.border),
            boxShadow: [
              BoxShadow(
                color: _CareerPalette.ink.withValues(alpha: 0.06),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F5FA),
                  shape: BoxShape.circle,
                  border: Border.all(color: _CareerPalette.border),
                ),
                child: Icon(
                  isInternship ? Icons.school_rounded : Icons.work_rounded,
                  color: _CareerPalette.goldInk,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Aucune annonce publiée pour le moment',
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  color: _CareerPalette.ink,
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
                    color: _CareerPalette.muted,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: onSwitchKind,
                icon: Icon(
                  isInternship
                      ? Icons.work_outline_rounded
                      : Icons.school_rounded,
                ),
                label: Text(
                  isInternship
                      ? 'Voir les offres d’emploi'
                      : 'Voir les offres de stage',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _CareerPalette.cobaltInk,
                  side: const BorderSide(color: _CareerPalette.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
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
  const _GoldLabel(this.text, {this.onDark = false});

  final String text;
  final bool onDark;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: onDark ? AppColors.goldLight : _CareerPalette.goldInk,
      letterSpacing: 2.0,
      fontWeight: FontWeight.w800,
    ),
  );
}
