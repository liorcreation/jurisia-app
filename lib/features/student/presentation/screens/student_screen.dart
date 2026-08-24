import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/ai/claude_api_datasource.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../models/student/course_module.dart';
import '../../../../models/student/student_level.dart';
import '../../../../models/student/student_progress_model.dart';
import '../../../../core/widgets/luxury_scaffold_background.dart';
import '../../../../theme/app_theme.dart';
import '../../data/datasources/ai_evaluation_generator.dart';
import '../../data/datasources/evaluation_question_bank.dart';
import '../../data/datasources/student_curriculum_local_datasource.dart';
import '../../data/repositories/student_repository_impl.dart';
import '../../domain/repositories/student_repository.dart';
import '../../domain/usecases/generate_evaluation_usecase.dart';
import '../../domain/usecases/get_student_modules_usecase.dart';
import '../../domain/usecases/validate_module_usecase.dart';
import '../controllers/student_controller.dart';
import '../widgets/module_status_badge.dart';
import 'module_detail_screen.dart';

StudentController _buildStudentController() {
  final StudentRepository repository = StudentRepositoryImpl(
    curriculumDataSource: const LocalStudentCurriculumDataSource(),
    questionBank: const LocalEvaluationQuestionBank(),
    aiGenerator: AiEvaluationGenerator(dataSource: AnthropicClaudeDataSource()),
  );

  return StudentController(
    repository: repository,
    getModulesUseCase: GetStudentModulesUseCase(repository: repository),
    validateModuleUseCase: ValidateModuleUseCase(repository: repository),
    generateEvaluationUseCase: GenerateEvaluationUseCase(repository: repository),
  );
}

/// Section 3 — Espace étudiant : sélection du niveau à la première
/// connexion, puis parcours universitaire officiel et séquentiel. Seul le
/// premier module d'un niveau est débloqué au départ ; les suivants se
/// débloquent après réussite (moyenne ≥ 10/20) de l'évaluation précédente,
/// et le niveau supérieur se débloque lorsque tous les modules du niveau
/// courant sont validés.
class StudentScreen extends StatelessWidget {
  const StudentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StudentController>(
      create: (_) => _buildStudentController(),
      child: const _StudentView(),
    );
  }
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
    final selectedLevel = controller.selectedLevel;

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Espace étudiant'),
          leading: selectedLevel == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: controller.backToLevelSelection,
                ),
        ),
        body: SafeArea(
          child: selectedLevel == null
              ? _LevelSelector(controller: controller)
              : _ModulePath(
                  level: selectedLevel,
                  modules: controller.modulesForSelectedLevel,
                  progress: controller.progressForSelectedLevel,
                  onOpenModule: (moduleId) => _openModule(context, controller, moduleId),
                ),
        ),
      ),
    );
  }
}

class _LevelSelector extends StatelessWidget {
  const _LevelSelector({required this.controller});

  final StudentController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quel est votre niveau ?', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            "Sélectionnez votre niveau universitaire pour accéder à votre parcours dédié.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.3,
              children: [
                for (final level in AcademicLevel.values)
                  _LevelTile(
                    level: level,
                    unlocked: controller.isLevelUnlocked(level),
                    onTap: () {
                      if (controller.isLevelUnlocked(level)) {
                        controller.selectLevel(level);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Terminez le niveau précédent pour débloquer celui-ci.'),
                          ),
                        );
                      }
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({required this.level, required this.unlocked, required this.onTap});

  final AcademicLevel level;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: unlocked ? 1 : 0.6,
      child: GlassContainer(
        onTap: onTap,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => AppGradients.goldMetallic.createShader(bounds),
                    child: Text(
                      level.shortLabel,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    level.fullLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (!unlocked)
              const Positioned(
                top: 0,
                right: 0,
                child: Icon(Icons.lock_rounded, color: AppColors.gold, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}

class _ModulePath extends StatelessWidget {
  const _ModulePath({
    required this.level,
    required this.modules,
    required this.progress,
    required this.onOpenModule,
  });

  final AcademicLevel level;
  final List<CourseModule> modules;
  final StudentProgress? progress;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total = modules.length;
    final validated = modules.where((m) => m.isCompleted).length;
    final average = progress?.overallAverage ?? 0;
    final percentage = total == 0 ? 0.0 : validated / total;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(level.fullLabel, style: textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Progressez module par module. La moyenne de 10/20 débloque le module suivant.',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Progression du niveau', style: textTheme.titleSmall),
                  Text('$validated / $total modules', style: textTheme.labelMedium),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 8,
                  backgroundColor: AppColors.legalBlueDark,
                  valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                ),
              ),
              if (average > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Moyenne actuelle : ${average.toStringAsFixed(1)}/20',
                  style: textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < modules.length; i++) ...[
          _ModuleCard(module: modules[i], onTap: () => onOpenModule(modules[i].id)),
          if (i != modules.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Center(
                child: Icon(
                  Icons.arrow_downward_rounded,
                  color: modules[i].isCompleted ? AppColors.gold : AppColors.textDisabled,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module, required this.onTap});

  final CourseModule module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final locked = !module.isUnlocked;
    final status = locked
        ? ModuleStatus.locked
        : module.isCompleted
            ? ModuleStatus.completed
            : ModuleStatus.inProgress;

    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: GlassContainer(
        borderColor: module.isCompleted ? AppColors.gold : AppColors.glassBorder,
        onTap: locked ? null : onTap,
        child: Row(
          children: [
            ModuleStatusBadge(status: status),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Module ${module.order} — ${module.title}', style: textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(module.description, style: textTheme.bodyMedium),
                  if (module.lastScore != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Dernière note : ${module.lastScore!.toStringAsFixed(1)}/20',
                      style: textTheme.labelMedium?.copyWith(color: AppColors.gold),
                    ),
                  ] else if (!locked) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text('En cours', style: textTheme.labelMedium?.copyWith(color: AppColors.textSecondary)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
