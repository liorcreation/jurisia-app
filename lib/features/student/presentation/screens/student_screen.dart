import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/platform/app_platform_style.dart';
import '../../../../core/widgets/app_shell_menu_button.dart';
import '../../../../core/widgets/entrance_fade.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/shimmer_sweep.dart';
import '../../../../models/legal_document/legal_domain.dart';
import '../../../../models/student/course_module.dart';
import '../../../../models/student/student_level.dart';
import '../../../../models/student/student_progress_model.dart';
import '../../../../core/widgets/luxury_scaffold_background.dart';
import '../../../../theme/app_theme.dart';
import '../controllers/student_controller.dart';
import '../widgets/module_status_badge.dart';
import 'module_detail_screen.dart';

/// Section 3 — Espace étudiant : sélection du niveau à la première
/// connexion, puis parcours universitaire officiel et séquentiel. Seul le
/// premier module d'un niveau est débloqué au départ ; les suivants se
/// débloquent après réussite (moyenne ≥ 10/20) de l'évaluation précédente,
/// et le niveau supérieur se débloque lorsque tous les modules du niveau
/// courant sont validés.
class StudentScreen extends StatelessWidget {
  const StudentScreen({super.key});

  @override
  Widget build(BuildContext context) => const _StudentView();
}

class _StudentView extends StatelessWidget {
  const _StudentView();

  Future<void> _openModule(BuildContext context, StudentController controller, String moduleId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<StudentController>.value(
          value: controller,
          child: ModuleDetailScreen(moduleId: moduleId),
        ),
      ),
    );
    controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StudentController>();

    if (AppPlatformStyle.of(context) == AppPlatformStyle.desktop) {
      return _DesktopStudentView(
        controller: controller,
        onOpenModule: (moduleId) => _openModule(context, controller, moduleId),
      );
    }

    final selectedLevel = controller.selectedLevel;

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(selectedLevel == null ? 'Espace étudiant' : selectedLevel.fullLabel),
          leading: selectedLevel == null
              ? const AppShellMenuButton()
              : IconButton(
                  tooltip: 'Tous les niveaux',
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: controller.backToLevelSelection,
                ),
        ),
        body: Stack(
          children: [
            const Positioned.fill(child: IgnorePointer(child: _StudentAmbience())),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.xxl,
                ),
                child: selectedLevel == null
                    ? _LevelGallery(controller: controller)
                    : _LevelWorkspace(
                        level: selectedLevel,
                        controller: controller,
                        onOpenModule: (moduleId) => _openModule(context, controller, moduleId),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ===========================================================================
//  DESKTOP — « Le cursus » : de la Licence au Master
// ===========================================================================

/// Teinte métallique propre à chaque niveau : la palette « se réchauffe »
/// de l'argent (L1) à l'or profond (M2), pour lire la progression au premier
/// coup d'œil sans diluer l'or réservé aux actions.
Color _levelTint(AcademicLevel level) {
  switch (level) {
    case AcademicLevel.l1:
      return AppColors.metalSilver;
    case AcademicLevel.l2:
      return AppColors.metalCobalt;
    case AcademicLevel.l3:
      return AppColors.metalBronze;
    case AcademicLevel.m1:
      return AppColors.metalCopper;
    case AcademicLevel.m2:
      return AppColors.metalDeepGold;
  }
}

IconData _domainIcon(LegalDomain domain) {
  switch (domain) {
    case LegalDomain.civil:
      return Icons.handshake_rounded;
    case LegalDomain.penal:
      return Icons.gavel_rounded;
    case LegalDomain.commercial:
      return Icons.storefront_rounded;
    case LegalDomain.travail:
      return Icons.badge_rounded;
    case LegalDomain.famille:
      return Icons.family_restroom_rounded;
    case LegalDomain.administratif:
      return Icons.account_balance_rounded;
    case LegalDomain.fiscal:
      return Icons.receipt_long_rounded;
    case LegalDomain.constitutionnel:
      return Icons.foundation_rounded;
    case LegalDomain.foncier:
      return Icons.terrain_rounded;
    case LegalDomain.ohada:
      return Icons.public_rounded;
    case LegalDomain.procedureCivile:
      return Icons.balance_rounded;
    case LegalDomain.procedurePenale:
      return Icons.shield_rounded;
    case LegalDomain.autre:
      return Icons.category_rounded;
  }
}

ModuleStatus _statusOf(CourseModule module) {
  if (!module.isUnlocked) return ModuleStatus.locked;
  if (module.isCompleted) return ModuleStatus.completed;
  return ModuleStatus.inProgress;
}

class _DesktopStudentView extends StatelessWidget {
  const _DesktopStudentView({required this.controller, required this.onOpenModule});

  final StudentController controller;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final level = controller.selectedLevel;

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(child: IgnorePointer(child: _StudentAmbience())),
              Column(
                children: [
                  _DesktopStudentHeader(
                    level: level,
                    onBackToLevels: controller.backToLevelSelection,
                  ),
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
                            child: level == null
                                ? _LevelGallery(controller: controller)
                                : _LevelWorkspace(
                                    level: level,
                                    controller: controller,
                                    onOpenModule: onOpenModule,
                                  ),
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

class _DesktopStudentHeader extends StatelessWidget {
  const _DesktopStudentHeader({required this.level, required this.onBackToLevels});

  final AcademicLevel? level;
  final VoidCallback onBackToLevels;

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
          const Icon(Icons.school_rounded, size: 18, color: AppColors.gold),
          const SizedBox(width: AppSpacing.sm),
          Text('Espace étudiant', style: textTheme.headlineSmall),
          if (level != null) ...[
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textDisabled),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                level!.fullLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (level != null)
            Tooltip(
              message: 'Revenir au choix du niveau',
              child: OutlinedButton.icon(
                onPressed: onBackToLevels,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                  textStyle: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                icon: const Icon(Icons.grid_view_rounded, size: 16),
                label: const Text('Tous les niveaux'),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  Choix du niveau — la galerie du cursus
// ---------------------------------------------------------------------------

class _LevelGallery extends StatelessWidget {
  const _LevelGallery({required this.controller});

  final StudentController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final levels = AcademicLevel.values;

    // Le niveau « courant » : le premier débloqué qui n'est pas terminé.
    AcademicLevel? current;
    for (final level in levels) {
      if (controller.isLevelUnlocked(level) && !controller.isLevelCompleted(level)) {
        current = level;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow('Votre cursus'),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'De la Licence au Master',
          style: textTheme.displaySmall?.copyWith(fontFamily: 'Libre Caslon Display'),
        ),
        const SizedBox(height: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Text(
            'Un parcours universitaire officiel, structuré niveau par niveau. '
            'Chaque module réunit un cours complet, une fiche de révision, des '
            'exercices corrigés et un tuteur IA dédié — sanctionné par une '
            'évaluation notée sur 20.',
            style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary, height: 1.5),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _CursusLadder(controller: controller, current: current),
        const SizedBox(height: AppSpacing.xxl),
        const _Eyebrow('Chaque module, cinq temps forts'),
        const SizedBox(height: AppSpacing.md),
        const _ModuleAnatomy(),
        const SizedBox(height: AppSpacing.xl),
        const _RuleNote(),
      ],
    );
  }
}

class _ModuleAnatomy extends StatelessWidget {
  const _ModuleAnatomy();

  static const _steps = <(IconData, String, String)>[
    (Icons.menu_book_rounded, 'Cours', 'Leçons complètes, exemples burkinabè'),
    (Icons.summarize_rounded, 'Fiche de révision', 'Les points-clés à retenir'),
    (Icons.edit_note_rounded, 'Exercices', 'Cas pratiques corrigés'),
    (Icons.school_rounded, 'Tuteur IA', 'Un assistant limité au module'),
    (Icons.fact_check_rounded, 'Évaluation', 'Notée sur 20 — seuil 10'),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final perRow = constraints.maxWidth >= 900 ? 5 : 2;
        final width = (constraints.maxWidth - AppSpacing.md * (perRow - 1)) / perRow;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (var i = 0; i < _steps.length; i++)
              SizedBox(
                width: width,
                child: EntranceFadeSlide(
                  index: i,
                  child: GlassContainer(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(_steps[i].$1, size: 16, color: AppColors.goldLight),
                            const SizedBox(width: 6),
                            Text(
                              '0${i + 1}',
                              style: textTheme.labelSmall?.copyWith(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _steps[i].$2,
                          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _steps[i].$3,
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CursusLadder extends StatelessWidget {
  const _CursusLadder({required this.controller, required this.current});

  final StudentController controller;
  final AcademicLevel? current;

  @override
  Widget build(BuildContext context) {
    final levels = AcademicLevel.values;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;

        final cards = <Widget>[
          for (var i = 0; i < levels.length; i++)
            _LevelCard(
              level: levels[i],
              modules: controller.modulesForLevel(levels[i]),
              unlocked: controller.isLevelUnlocked(levels[i]),
              completed: controller.isLevelCompleted(levels[i]),
              isCurrent: levels[i] == current,
              onTap: () {
                if (controller.isLevelUnlocked(levels[i])) {
                  controller.selectLevel(levels[i]);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Validez le niveau précédent pour débloquer celui-ci.'),
                    ),
                  );
                }
              },
            ),
        ];

        if (!wide) {
          final cols = constraints.maxWidth < 480 ? 1 : 2;
          final cardWidth = cols == 1
              ? constraints.maxWidth
              : (constraints.maxWidth - AppSpacing.md) / 2;
          return Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (var i = 0; i < cards.length; i++)
                SizedBox(
                  width: cardWidth,
                  child: EntranceFadeSlide(index: i, child: cards[i]),
                ),
            ],
          );
        }

        // Escalier : chaque niveau s'élève un peu plus que le précédent.
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: (levels.length - 1 - i) * 18.0),
                  child: EntranceFadeSlide(index: i, child: cards[i]),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.modules,
    required this.unlocked,
    required this.completed,
    required this.isCurrent,
    required this.onTap,
  });

  final AcademicLevel level;
  final List<CourseModule> modules;
  final bool unlocked;
  final bool completed;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tint = _levelTint(level);
    final validated = modules.where((m) => m.isCompleted).length;

    final String stateLabel;
    final Color stateColor;
    if (completed) {
      stateLabel = 'Niveau validé';
      stateColor = AppColors.success;
    } else if (unlocked) {
      stateLabel = validated > 0 ? 'En cours' : 'Ouvert';
      stateColor = AppColors.goldLight;
    } else {
      stateLabel = 'À débloquer';
      stateColor = AppColors.textDisabled;
    }

    Widget accent = Container(
      height: 3,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [tint.withValues(alpha: 0.2), tint]),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );
    if (isCurrent) {
      accent = ShimmerSweep(duration: const Duration(milliseconds: 2600), child: accent);
    }

    return Opacity(
      opacity: unlocked ? 1 : 0.62,
      child: GlassContainer(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
        borderColor: isCurrent
            ? AppColors.gold.withValues(alpha: 0.55)
            : tint.withValues(alpha: unlocked ? 0.45 : 0.22),
        borderWidth: isCurrent ? 1.1 : 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: accent),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  completed
                      ? Icons.verified_rounded
                      : unlocked
                          ? Icons.auto_awesome_rounded
                          : Icons.lock_rounded,
                  size: 15,
                  color: completed
                      ? AppColors.success
                      : unlocked
                          ? AppColors.goldLight
                          : AppColors.textDisabled,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ShaderMask(
              shaderCallback: (bounds) =>
                  (unlocked ? AppGradients.goldMetallic : AppGradients.goldAged).createShader(bounds),
              child: Text(
                level.shortLabel,
                style: textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontFamily: 'Libre Caslon Display',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              level.fullLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(height: 1.25),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              validated > 0
                  ? '${modules.length} modules · $validated validé${validated > 1 ? 's' : ''}'
                  : '${modules.length} modules',
              style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              stateLabel,
              style: textTheme.labelMedium?.copyWith(color: stateColor, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleNote extends StatelessWidget {
  const _RuleNote();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.route_rounded, size: 18, color: AppColors.gold),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Parcours séquentiel : seul le premier module de la Licence 1 est ouvert au départ. '
              'Chaque évaluation réussie (moyenne ≥ 10/20) débloque le module suivant, et valider '
              'tous les modules d\'un niveau ouvre le niveau supérieur.',
              style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  Parcours d'un niveau — la colonne des modules + le tableau de progression
// ---------------------------------------------------------------------------

class _LevelWorkspace extends StatelessWidget {
  const _LevelWorkspace({
    required this.level,
    required this.controller,
    required this.onOpenModule,
  });

  final AcademicLevel level;
  final StudentController controller;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final modules = controller.modulesForSelectedLevel;
    final progress = controller.progressForSelectedLevel;

    final main = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Eyebrow('Espace étudiant — ${level.shortLabel}'),
        const SizedBox(height: AppSpacing.sm),
        Text(
          level.fullLabel,
          style: textTheme.headlineMedium?.copyWith(fontFamily: 'Libre Caslon Display'),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Avancez module par module. Chaque module se conclut par une évaluation ; '
          'la moyenne de 10/20 ouvre le module suivant.',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.45),
        ),
        const SizedBox(height: AppSpacing.xl),
        _ModuleSpine(modules: modules, onOpenModule: onOpenModule),
      ],
    );

    final rail = _ProgressPanel(
      level: level,
      controller: controller,
      modules: modules,
      progress: progress,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              main,
              const SizedBox(height: AppSpacing.xl),
              rail,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: main),
            const SizedBox(width: AppSpacing.xl),
            SizedBox(width: 340, child: rail),
          ],
        );
      },
    );
  }
}

class _ModuleSpine extends StatelessWidget {
  const _ModuleSpine({required this.modules, required this.onOpenModule});

  final List<CourseModule> modules;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    if (modules.isEmpty) {
      return Text(
        'Le programme de ce niveau arrive très bientôt.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Registre replié (téléphone, petite tablette) : la carte n'a pas la
        // largeur pour un pied à deux colonnes ni un gouvernail large.
        final compact = constraints.maxWidth < 560;
        final railGap = compact ? AppSpacing.sm : AppSpacing.md;

        return Column(
          children: [
            for (var i = 0; i < modules.length; i++)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StationRail(
                      status: _statusOf(modules[i]),
                      topActive: i > 0 && modules[i - 1].isCompleted,
                      bottomActive: modules[i].isCompleted,
                      isFirst: i == 0,
                      isLast: i == modules.length - 1,
                      compact: compact,
                    ),
                    SizedBox(width: railGap),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: i == modules.length - 1 ? 0 : AppSpacing.lg,
                        ),
                        child: EntranceFadeSlide(
                          index: i,
                          child: _DesktopModuleCard(
                            module: modules[i],
                            onOpen: () => onOpenModule(modules[i].id),
                            compact: compact,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StationRail extends StatelessWidget {
  const _StationRail({
    required this.status,
    required this.topActive,
    required this.bottomActive,
    required this.isFirst,
    required this.isLast,
    this.compact = false,
  });

  final ModuleStatus status;
  final bool topActive;
  final bool bottomActive;
  final bool isFirst;
  final bool isLast;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final faint = AppColors.gold.withValues(alpha: 0.14);
    // La toile du sceau (avec sa volée de particules) fait 1,9× sa taille :
    // le gouvernail doit rester au moins aussi large pour ne pas la rogner.
    final badgeSize = compact ? 30.0 : 40.0;

    Color line(bool active, bool hidden) =>
        hidden ? Colors.transparent : (active ? AppColors.gold : faint);

    return SizedBox(
      width: compact ? 58 : 76,
      child: Column(
        children: [
          Container(width: 2, height: 14, color: line(topActive, isFirst)),
          ModuleStatusBadge(status: status, size: badgeSize),
          Expanded(child: Container(width: 2, color: line(bottomActive, isLast))),
        ],
      ),
    );
  }
}

class _DesktopModuleCard extends StatefulWidget {
  const _DesktopModuleCard({
    required this.module,
    required this.onOpen,
    this.compact = false,
  });

  final CourseModule module;
  final VoidCallback onOpen;
  final bool compact;

  @override
  State<_DesktopModuleCard> createState() => _DesktopModuleCardState();
}

class _DesktopModuleCardState extends State<_DesktopModuleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final module = widget.module;
    final compact = widget.compact;
    final locked = !module.isUnlocked;
    final minutes = module.lessons.fold<int>(0, (sum, lesson) => sum + lesson.estimatedMinutes);

    final Color border;
    if (module.isCompleted) {
      border = AppColors.gold.withValues(alpha: 0.5);
    } else if (_hovered && !locked) {
      border = AppColors.gold.withValues(alpha: 0.4);
    } else {
      border = AppColors.glassBorder;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Opacity(
        opacity: locked ? 0.6 : 1,
        child: GlassContainer(
          onTap: locked ? null : widget.onOpen,
          padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
          borderColor: border,
          borderWidth: (_hovered && !locked) || module.isCompleted ? 0.9 : 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête : la pastille de statut à gauche, et — en registre
              // replié — le numéro du module en grand chiffre fantôme à
              // droite, comme un folio d'ouvrage. Aucune tension horizontale.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (compact) ...[
                    _ModulePill(status: _statusOf(module)),
                    const Spacer(),
                    Text(
                      module.order.toString().padLeft(2, '0'),
                      style: textTheme.headlineSmall?.copyWith(
                        fontFamily: 'Libre Caslon Display',
                        color: AppColors.gold.withValues(alpha: 0.2),
                        height: 1,
                      ),
                    ),
                  ] else ...[
                    _Eyebrow('Module ${module.order}'),
                    const Spacer(),
                    _ModulePill(status: _statusOf(module)),
                  ],
                ],
              ),
              SizedBox(height: compact ? 6 : AppSpacing.sm),
              Text(
                module.title,
                style: (compact ? textTheme.titleMedium : textTheme.titleLarge)
                    ?.copyWith(fontFamily: 'Libre Caslon Display'),
              ),
              const SizedBox(height: 6),
              Text(
                module.description,
                maxLines: compact ? 3 : null,
                overflow: compact ? TextOverflow.ellipsis : null,
                style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: compact ? AppSpacing.sm : AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: [
                  _MetaBit(icon: _domainIcon(module.domain), label: module.domain.label),
                  _MetaBit(icon: Icons.menu_book_rounded, label: '${module.lessons.length} leçons'),
                  _MetaBit(
                    icon: Icons.edit_note_rounded,
                    label: '${module.exercises.length} exercices',
                  ),
                  if (minutes > 0)
                    _MetaBit(icon: Icons.schedule_rounded, label: '≈ $minutes min'),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.md),
              _ModuleCardFooter(
                module: module,
                onOpen: locked ? null : widget.onOpen,
                compact: compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleCardFooter extends StatelessWidget {
  const _ModuleCardFooter({
    required this.module,
    required this.onOpen,
    this.compact = false,
  });

  final CourseModule module;
  final VoidCallback? onOpen;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final locked = !module.isUnlocked;

    final Widget status;
    if (module.lastScore != null) {
      status = _ScoreTag(score: module.lastScore!);
    } else if (!locked) {
      status = Text(
        module.isCompleted ? 'Validé' : 'Pas encore évalué',
        style: textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
      );
    } else {
      status = const SizedBox.shrink();
    }

    final Widget cta;
    if (locked) {
      cta = Row(
        mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
        children: [
          const Icon(Icons.lock_rounded, size: 14, color: AppColors.textDisabled),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Module précédent à valider',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium?.copyWith(color: AppColors.textDisabled),
            ),
          ),
        ],
      );
    } else if (module.isCompleted) {
      cta = OutlinedButton.icon(
        onPressed: onOpen,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
        ),
        icon: const Icon(Icons.replay_rounded, size: 16),
        label: const Text('Revoir le module'),
      );
    } else {
      cta = FilledButton.icon(
        onPressed: onOpen,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.nightBlueDeep,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        icon: Icon(
          module.lastScore != null ? Icons.refresh_rounded : Icons.play_arrow_rounded,
          size: 18,
        ),
        label: Text(module.lastScore != null ? 'Reprendre' : 'Commencer le module'),
      );
    }

    // Registre replié : tout s'empile, le bouton prend toute la largeur —
    // aucune rangée à deux blocs qui déborde sur les petits écrans.
    if (compact) {
      final hasStatus = module.lastScore != null || !locked;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasStatus) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: status),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          cta,
        ],
      );
    }

    return Row(
      children: [
        status,
        const Spacer(),
        cta,
      ],
    );
  }
}

class _ModulePill extends StatelessWidget {
  const _ModulePill({required this.status});

  final ModuleStatus status;

  @override
  Widget build(BuildContext context) {
    final (String label, Color color, IconData icon) = switch (status) {
      ModuleStatus.completed => ('Validé', AppColors.success, Icons.check_circle_rounded),
      ModuleStatus.inProgress => ('Disponible', AppColors.goldLight, Icons.lock_open_rounded),
      ModuleStatus.locked => ('Verrouillé', AppColors.textDisabled, Icons.lock_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MetaBit extends StatelessWidget {
  const _MetaBit({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ScoreTag extends StatelessWidget {
  const _ScoreTag({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final passed = score >= 10;
    final color = passed ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(passed ? Icons.workspace_premium_rounded : Icons.trending_up_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            'Meilleure note ${score.toStringAsFixed(1)}/20',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({
    required this.level,
    required this.controller,
    required this.modules,
    required this.progress,
  });

  final AcademicLevel level;
  final StudentController controller;
  final List<CourseModule> modules;
  final StudentProgress? progress;

  String _milestone() {
    if (modules.isEmpty) return 'Programme en préparation.';
    final done = modules.where((m) => m.isCompleted).length;
    if (done == modules.length) {
      final levels = AcademicLevel.values;
      final next = levels.indexOf(level) + 1;
      return next < levels.length
          ? 'Niveau validé — ${levels[next].shortLabel} débloqué. Félicitations !'
          : 'Cursus complet. Vous avez tout validé, bravo !';
    }
    final remaining = modules.length - done;
    final target = modules.firstWhere(
      (m) => !m.isCompleted && m.isUnlocked,
      orElse: () => modules.first,
    );
    return 'Encore $remaining module${remaining > 1 ? 's' : ''} pour valider ${level.shortLabel}. '
        'Prochaine étape : Module ${target.order}.';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total = modules.length;
    final validated = modules.where((m) => m.isCompleted).length;
    final average = progress?.overallAverage ?? 0;

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Eyebrow('Progression'),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: _ProgressRing(
              value: total == 0 ? 0 : validated / total,
              headline: '$validated / $total',
              caption: 'modules validés',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (average > 0) ...[
            Text(
              'Moyenne générale',
              style: textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              '${average.toStringAsFixed(1)} / 20',
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.goldLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Stack(
                children: [
                  Container(height: 6, color: AppColors.legalBlueDark),
                  FractionallySizedBox(
                    widthFactor: (average / 20).clamp(0.0, 1.0),
                    child: Container(
                      height: 6,
                      decoration: const BoxDecoration(gradient: AppGradients.goldMetallic),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(AppRadius.small),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.2), width: 0.7),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.flag_rounded, size: 15, color: AppColors.goldLight),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _milestone(),
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.lg),
          const _Eyebrow('Le cursus'),
          const SizedBox(height: AppSpacing.md),
          _LevelStepper(controller: controller, activeLevel: level),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.value, required this.headline, required this.caption});

  final double value;
  final String headline;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: 156,
      height: 156,
      child: CustomPaint(
        painter: _ProgressRingPainter(value.clamp(0.0, 1.0)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => AppGradients.goldMetallic.createShader(bounds),
                child: Text(
                  headline,
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontFamily: 'Libre Caslon Display',
                  ),
                ),
              ),
              Text(
                caption,
                style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 7;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = AppColors.gold.withValues(alpha: 0.14);
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);

    if (value <= 0) return;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.goldLight, AppColors.gold, AppColors.goldDark],
      ).createShader(rect);
    canvas.drawArc(rect, start, 2 * math.pi * value, false, arc);
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) => oldDelegate.value != value;
}

class _LevelStepper extends StatelessWidget {
  const _LevelStepper({required this.controller, required this.activeLevel});

  final StudentController controller;
  final AcademicLevel activeLevel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final levels = AcademicLevel.values;

    return Column(
      children: [
        for (var i = 0; i < levels.length; i++)
          () {
            final level = levels[i];
            final completed = controller.isLevelCompleted(level);
            final unlocked = controller.isLevelUnlocked(level);
            final isActive = level == activeLevel;

            final Color dotColor = completed
                ? AppColors.success
                : unlocked
                    ? AppColors.goldLight
                    : AppColors.textDisabled;

            return Padding(
              padding: EdgeInsets.only(bottom: i == levels.length - 1 ? 0 : AppSpacing.sm),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    child: Column(
                      children: [
                        Icon(
                          completed
                              ? Icons.check_circle_rounded
                              : isActive
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.circle_outlined,
                          size: 15,
                          color: dotColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      level.fullLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium?.copyWith(
                        color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (!unlocked)
                    const Icon(Icons.lock_rounded, size: 12, color: AppColors.textDisabled),
                ],
              ),
            );
          }(),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: controller.backToLevelSelection,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            icon: const Icon(Icons.swap_horiz_rounded, size: 16),
            label: const Text('Changer de niveau'),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
//  Éléments partagés du registre desktop
// ---------------------------------------------------------------------------

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
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.goldLight,
                letterSpacing: AppLetterSpacing.caps,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

/// Fines poussières d'or en suspension sur toute la page — la même
/// respiration « vivante » que la bibliothèque et la visionneuse.
class _StudentAmbience extends StatefulWidget {
  const _StudentAmbience();

  @override
  State<_StudentAmbience> createState() => _StudentAmbienceState();
}

class _StudentAmbienceState extends State<_StudentAmbience> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 34))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(painter: _StudentAmbiencePainter(_controller.value)),
    );
  }
}

class _StudentAmbiencePainter extends CustomPainter {
  const _StudentAmbiencePainter(this.t);

  final double t;
  static const int _count = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < _count; i++) {
      final seed = i * 47.0;
      final baseX = (seed % size.width);
      final drift = math.sin((t * 2 * math.pi) + seed) * 26;
      final x = (baseX + drift) % size.width;
      final y = (size.height * ((i / _count) + t) % 1.0);
      final radius = 0.8 + (i % 3) * 0.7;
      final opacity = 0.05 + 0.09 * (0.5 + 0.5 * math.sin((t * 2 * math.pi) + seed * 1.7));
      paint.color = AppColors.goldLight.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StudentAmbiencePainter oldDelegate) => oldDelegate.t != t;
}
