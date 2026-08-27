import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/student/presentation/controllers/student_controller.dart';
import '../../../features/student/presentation/screens/module_detail_screen.dart';
import '../../../models/student/course_module.dart';
import '../../../models/student/student_level.dart';
import '../../widgets/glass_container.dart';
import '../../../theme/app_theme.dart';
import '../app_shell.dart';
import 'sidebar_section_scaffold.dart';

/// Section contextuelle « Votre progression » — niveau courant, avancement,
/// et le prochain module à travailler.
class StudentProgressSection extends StatelessWidget {
  const StudentProgressSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StudentController>();
    final level = controller.selectedLevel;

    if (level == null) {
      return const SidebarSection(
        title: 'Votre progression',
        children: [
          SidebarSectionEmpty('Choisissez votre niveau pour démarrer votre parcours.'),
        ],
      );
    }

    final modules = controller.modulesForSelectedLevel;
    final progress = controller.progressForSelectedLevel;
    final done = modules.where((m) => m.isCompleted).length;
    final total = modules.length;
    final percent = total == 0 ? 0.0 : done / total;
    final average = progress?.overallAverage ?? 0;

    final CourseModule? next = modules.cast<CourseModule?>().firstWhere(
          (m) => m != null && m.isUnlocked && !m.isCompleted,
          orElse: () => null,
        );

    return SidebarSection(
      title: 'Votre progression',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 3),
          child: GlassContainer(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(level.shortLabel, style: Theme.of(context).textTheme.titleSmall),
                    const Spacer(),
                    Text(
                      '$done/$total modules',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 5,
                    backgroundColor: AppColors.legalBlueDark,
                  ),
                ),
                if (average > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Moyenne générale : ${average.toStringAsFixed(1)}/20',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (next != null)
          SidebarSectionTile(
            icon: Icons.play_circle_outline_rounded,
            title: next.title,
            subtitle: 'Prochain module',
            onTap: () {
              AppShellScope.of(context).selectModule(2);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider<StudentController>.value(
                    value: controller,
                    child: ModuleDetailScreen(moduleId: next.id),
                  ),
                ),
              ).then((_) => controller.refresh());
            },
          )
        else
          const SidebarSectionEmpty('Tous les modules débloqués sont validés. Bravo !'),
      ],
    );
  }
}
