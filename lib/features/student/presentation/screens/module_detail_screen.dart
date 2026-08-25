import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/ai/groq_api_datasource.dart';
import '../../../../core/widgets/ai_thinking_indicator.dart';
import '../../../../core/widgets/chat_bubble.dart';
import '../../../../core/widgets/chat_composer.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/luxury_scaffold_background.dart';
import '../../../../core/widgets/markdown_text.dart';
import '../../../../models/chat/message_model.dart';
import '../../../../models/student/course_module.dart';
import '../../../../theme/app_theme.dart';
import '../../data/repositories/module_tutor_repository_impl.dart';
import '../../domain/usecases/ask_module_tutor_usecase.dart';
import '../controllers/module_tutor_controller.dart';
import '../controllers/student_controller.dart';
import 'evaluation_screen.dart';

/// Vue détaillée d'un module : cours complet, fiches de révision et
/// exercices, et assistant IA restreint au contexte du module.
class ModuleDetailScreen extends StatelessWidget {
  const ModuleDetailScreen({super.key, required this.moduleId});

  final String moduleId;

  @override
  Widget build(BuildContext context) {
    final studentController = context.watch<StudentController>();
    final module = studentController.repository.findModule(moduleId);

    if (module == null) {
      return LuxuryScaffoldBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(),
          body: Center(
            child: Text('Module introuvable.', style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      );
    }

    return LuxuryScaffoldBackground(
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(module.title),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Cours'),
                Tab(text: 'Révisions'),
                Tab(text: 'Assistant IA'),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.nightBlueDeep,
            icon: const Icon(Icons.fact_check_rounded),
            label: const Text('Passer l\'évaluation'),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider<StudentController>.value(
                    value: studentController,
                    child: EvaluationScreen(moduleId: module.id),
                  ),
                ),
              );
            },
          ),
          body: SafeArea(
            child: TabBarView(
              children: [
                _CourseTab(module: module),
                _RevisionTab(module: module),
                _TutorTab(module: module),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CourseTab extends StatelessWidget {
  const _CourseTab({required this.module});

  final CourseModule module;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (module.lessons.isEmpty) {
      return Center(
        child: Text('Aucun contenu de cours pour ce module.', style: textTheme.bodyMedium),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: module.lessons.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final lesson = module.lessons[index];
        return GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(lesson.title, style: textTheme.titleMedium)),
                  Icon(Icons.schedule_rounded, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('${lesson.estimatedMinutes} min', style: textTheme.labelSmall),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(lesson.content, style: textTheme.bodyLarge?.copyWith(height: 1.5)),
            ],
          ),
        );
      },
    );
  }
}

class _RevisionTab extends StatelessWidget {
  const _RevisionTab({required this.module});

  final CourseModule module;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (module.revisionSheets.isNotEmpty) ...[
          Text('Fiches de révision', style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          for (final sheet in module.revisionSheets)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sheet.title, style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    for (final point in sheet.keyPoints)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.circle, size: 6, color: AppColors.gold),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: Text(point, style: textTheme.bodyMedium)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
        if (module.exercises.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('Exercices d\'entraînement', style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          for (final exercise in module.exercises)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: GlassContainer(
                child: _ExerciseTile(statement: exercise.statement, correction: exercise.correctionGuideline),
              ),
            ),
        ],
      ],
    );
  }
}

class _ExerciseTile extends StatefulWidget {
  const _ExerciseTile({required this.statement, required this.correction});

  final String statement;
  final String correction;

  @override
  State<_ExerciseTile> createState() => _ExerciseTileState();
}

class _ExerciseTileState extends State<_ExerciseTile> {
  bool _showCorrection = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.statement, style: textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.sm),
        if (_showCorrection)
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.legalBlueDark.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Text(widget.correction, style: textTheme.bodyMedium),
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _showCorrection = true),
              child: const Text('Voir la correction'),
            ),
          ),
      ],
    );
  }
}

class _TutorTab extends StatefulWidget {
  const _TutorTab({required this.module});

  final CourseModule module;

  @override
  State<_TutorTab> createState() => _TutorTabState();
}

class _TutorTabState extends State<_TutorTab> {
  late final ModuleTutorController _controller;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = ModuleTutorController(
      module: widget.module,
      useCase: AskModuleTutorUseCase(
        repository: ModuleTutorRepositoryImpl(dataSource: GroqDataSource()),
      ),
    );
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _inputController.text;
    if (text.trim().isEmpty || _controller.isSending) return;
    _inputController.clear();
    _controller.sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final messages = _controller.messages;
    final itemCount =
        messages.length + (_controller.isSending ? 1 : 0) + (_controller.errorMessage != null ? 1 : 0);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: GlassContainer(
            borderRadius: AppRadius.medium,
            child: Row(
              children: [
                const Icon(Icons.school_rounded, color: AppColors.gold),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Posez vos questions sur le module « ${widget.module.title} ».',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      "Aucune question pour l'instant. Demandez une explication, un exemple, ou de "
                      "l'aide sur un exercice de ce module.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    if (index < messages.length) {
                      return _TutorBubble(message: messages[index]);
                    }
                    var remaining = index - messages.length;
                    if (_controller.isSending) {
                      if (remaining == 0) {
                        return _TutorThinkingBubble(streamingText: _controller.streamingText);
                      }
                      remaining -= 1;
                    }
                    return ChatErrorBubble(
                      message: _controller.errorMessage ?? '',
                      onRetry: _controller.canRetry ? _controller.retry : null,
                      onDismiss: _controller.dismissError,
                    );
                  },
                ),
        ),
        ChatComposer(
          controller: _inputController,
          enabled: !_controller.isSending,
          onSend: _send,
          hintText: 'Votre question sur ce module…',
        ),
      ],
    );
  }
}

class _TutorBubble extends StatelessWidget {
  const _TutorBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;

    return ChatBubble(
      isUser: isUser,
      child: isUser
          ? Text(
              message.content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
            )
          : MarkdownText(message.content),
    );
  }
}

class _TutorThinkingBubble extends StatelessWidget {
  const _TutorThinkingBubble({required this.streamingText});

  final String streamingText;

  @override
  Widget build(BuildContext context) {
    return ChatBubble(
      isUser: false,
      child: streamingText.isEmpty
          ? const AiThinkingIndicator(label: 'Le tuteur réfléchit…')
          : MarkdownText(streamingText),
    );
  }
}
