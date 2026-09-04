import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/ai/groq_providers.dart';
import '../../../../core/platform/app_platform_style.dart';
import '../../../../core/widgets/ai_thinking_indicator.dart';
import '../../../../core/widgets/chat_bubble.dart';
import '../../../../core/widgets/chat_composer.dart';
import '../../../../core/widgets/entrance_fade.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/luxury_scaffold_background.dart';
import '../../../../core/widgets/markdown_text.dart';
import '../../../../models/chat/message_model.dart';
import '../../../../models/legal_document/legal_domain.dart';
import '../../../../models/student/course_module.dart';
import '../../../../models/student/student_level.dart';
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

  Future<void> _openEvaluation(
    BuildContext context,
    StudentController studentController,
    String id,
  ) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<StudentController>.value(
          value: studentController,
          child: EvaluationScreen(moduleId: id),
        ),
      ),
    );
  }

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

    if (AppPlatformStyle.of(context) == AppPlatformStyle.desktop) {
      return _DesktopModuleView(
        module: module,
        onEvaluate: () => _openEvaluation(context, studentController, module.id),
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
            onPressed: () => _openEvaluation(context, studentController, module.id),
          ),
          body: SafeArea(
            child: Stack(
              children: [
                const Positioned.fill(child: IgnorePointer(child: _ModuleAmbience())),
                TabBarView(
                  children: [
                    _CourseTab(module: module),
                    _RevisionTab(module: module),
                    _TutorTab(module: module),
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
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.xxl),
      itemCount: module.lessons.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xl),
      itemBuilder: (context, index) => _LessonBlock(
        order: index + 1,
        lesson: module.lessons[index],
      ),
    );
  }
}

class _RevisionTab extends StatelessWidget {
  const _RevisionTab({required this.module});

  final CourseModule module;

  @override
  Widget build(BuildContext context) {
    final hasRevision = module.revisionSheets.isNotEmpty;
    final hasExercises = module.exercises.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.xxl),
      children: [
        if (hasRevision) _RevisionPanel(module: module),
        if (hasRevision && hasExercises) const SizedBox(height: AppSpacing.xl),
        if (hasExercises) _ExercisesSection(module: module),
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
        repository: ModuleTutorRepositoryImpl(dataSource: buildGroqDataSource()),
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
              ? _TutorEmptyState(
                  onPick: (prompt) {
                    if (_controller.isSending) return;
                    _controller.sendMessage(prompt);
                  },
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

class _TutorEmptyState extends StatelessWidget {
  const _TutorEmptyState({required this.onPick});

  final ValueChanged<String> onPick;

  static const _prompts = <String>[
    'Explique-moi ce module autrement',
    'Donne-moi un exemple concret',
    'Aide-moi à réviser les points-clés',
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Aucune question pour l'instant. Demandez une explication, un exemple, ou de "
            "l'aide sur un exercice de ce module.",
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.45),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'POUR DÉMARRER',
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.goldLight,
              letterSpacing: AppLetterSpacing.caps,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final prompt in _prompts)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: () => onPick(prompt),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm + 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.legalBlueDark.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.small),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.28), width: 0.7),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, size: 13, color: AppColors.goldLight),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            prompt,
                            style: textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
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

// ===========================================================================
//  DESKTOP — « La leçon » : cours, révisions, exercices + tuteur permanent
// ===========================================================================

enum _AnchorKind { lesson, revision, exercises }

IconData _moduleDomainIcon(LegalDomain domain) {
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

String _difficultyLabel(int d) {
  if (d <= 1) return 'Facile';
  if (d == 2) return 'Abordable';
  if (d == 3) return 'Intermédiaire';
  if (d == 4) return 'Exigeant';
  return 'Difficile';
}

class _DesktopModuleView extends StatelessWidget {
  const _DesktopModuleView({required this.module, required this.onEvaluate});

  final CourseModule module;
  final VoidCallback onEvaluate;

  @override
  Widget build(BuildContext context) {
    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(child: IgnorePointer(child: _ModuleAmbience())),
              Column(
                children: [
                  _DesktopModuleHeader(module: module, onEvaluate: onEvaluate),
                  Expanded(child: _ModuleWorkspace(module: module)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopModuleHeader extends StatelessWidget {
  const _DesktopModuleHeader({required this.module, required this.onEvaluate});

  final CourseModule module;
  final VoidCallback onEvaluate;

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
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Retour au parcours',
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Espace étudiant · ${module.level.shortLabel} · Module ${module.order}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.goldLight,
                    letterSpacing: AppLetterSpacing.label,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  module.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.headlineSmall?.copyWith(fontFamily: 'Libre Caslon Display'),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          if (module.lastScore != null) ...[
            _HeaderScoreBadge(score: module.lastScore!, completed: module.isCompleted),
            const SizedBox(width: AppSpacing.sm),
          ],
          FilledButton.icon(
            onPressed: onEvaluate,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.nightBlueDeep,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 11),
              textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            icon: const Icon(Icons.fact_check_rounded, size: 17),
            label: Text(module.lastScore != null ? 'Repasser l\'évaluation' : 'Passer l\'évaluation'),
          ),
        ],
      ),
    );
  }
}

class _HeaderScoreBadge extends StatelessWidget {
  const _HeaderScoreBadge({required this.score, required this.completed});

  final double score;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final color = completed ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(completed ? Icons.verified_rounded : Icons.trending_up_rounded, size: 14, color: color),
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

class _ModuleWorkspace extends StatefulWidget {
  const _ModuleWorkspace({required this.module});

  final CourseModule module;

  @override
  State<_ModuleWorkspace> createState() => _ModuleWorkspaceState();
}

class _ModuleWorkspaceState extends State<_ModuleWorkspace> {
  final ScrollController _scroll = ScrollController();
  late final List<({_AnchorKind kind, String label})> _anchors;
  late final List<GlobalKey> _keys;
  int _active = 0;

  @override
  void initState() {
    super.initState();
    final module = widget.module;
    _anchors = [
      for (var i = 0; i < module.lessons.length; i++)
        (kind: _AnchorKind.lesson, label: 'Leçon ${i + 1} — ${module.lessons[i].title}'),
      if (module.revisionSheets.isNotEmpty)
        (kind: _AnchorKind.revision, label: 'Fiche de révision'),
      if (module.exercises.isNotEmpty)
        (kind: _AnchorKind.exercises, label: 'Exercices (${module.exercises.length})'),
    ];
    _keys = List.generate(_anchors.length, (_) => GlobalKey());
    _scroll.addListener(_trackActive);
  }

  @override
  void dispose() {
    _scroll.removeListener(_trackActive);
    _scroll.dispose();
    super.dispose();
  }

  void _trackActive() {
    if (!_scroll.hasClients) return;
    var current = 0;
    for (var i = 0; i < _keys.length; i++) {
      final box = _keys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box == null) continue;
      if (box.localToGlobal(Offset.zero).dy <= 170) current = i;
    }
    if (current != _active) setState(() => _active = current);
  }

  void _scrollTo(int index) {
    final ctx = _keys[index].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 340),
      curve: Curves.fastOutSlowIn,
      alignment: 0.04,
    );
  }

  @override
  Widget build(BuildContext context) {
    final module = widget.module;

    final scroller = SingleChildScrollView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxl),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: _ModuleArticle(module: module, anchors: _anchors, keys: _keys),
        ),
      ),
    );

    final tutor = _TutorRail(module: module);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1200;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (wide)
              SizedBox(
                width: 264,
                child: _ModuleToc(anchors: _anchors, active: _active, onTap: _scrollTo),
              ),
            Expanded(child: scroller),
            SizedBox(width: wide ? 384 : 344, child: tutor),
          ],
        );
      },
    );
  }
}

class _ModuleToc extends StatelessWidget {
  const _ModuleToc({required this.anchors, required this.active, required this.onTap});

  final List<({_AnchorKind kind, String label})> anchors;
  final int active;
  final ValueChanged<int> onTap;

  IconData _iconFor(_AnchorKind kind) {
    switch (kind) {
      case _AnchorKind.lesson:
        return Icons.menu_book_rounded;
      case _AnchorKind.revision:
        return Icons.summarize_rounded;
      case _AnchorKind.exercises:
        return Icons.edit_note_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.sm, AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 14, height: 1, color: AppColors.gold.withValues(alpha: 0.6)),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'DANS CE MODULE',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.goldLight,
                  letterSpacing: AppLetterSpacing.caps,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < anchors.length; i++)
            _TocItem(
              icon: _iconFor(anchors[i].kind),
              label: anchors[i].label,
              active: i == active,
              onTap: () => onTap(i),
            ),
        ],
      ),
    );
  }
}

class _TocItem extends StatefulWidget {
  const _TocItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_TocItem> createState() => _TocItemState();
}

class _TocItemState extends State<_TocItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final lit = widget.active || _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.small),
            color: widget.active ? AppColors.gold.withValues(alpha: 0.10) : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: widget.active ? AppColors.gold : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                  widget.icon,
                  size: 14,
                  color: lit ? AppColors.goldLight : AppColors.textDisabled,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  widget.label,
                  style: textTheme.labelMedium?.copyWith(
                    color: lit ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: widget.active ? FontWeight.w700 : FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleArticle extends StatelessWidget {
  const _ModuleArticle({required this.module, required this.anchors, required this.keys});

  final CourseModule module;
  final List<({_AnchorKind kind, String label})> anchors;
  final List<GlobalKey> keys;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final totalMinutes =
        module.lessons.fold<int>(0, (sum, lesson) => sum + lesson.estimatedMinutes);

    final children = <Widget>[
      // Hero
      Row(
        children: [
          Container(width: 16, height: 1, color: AppColors.gold.withValues(alpha: 0.6)),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'MODULE ${module.order} · ${module.level.shortLabel}',
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.goldLight,
              letterSpacing: AppLetterSpacing.caps,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        module.title,
        style: textTheme.displaySmall?.copyWith(fontFamily: 'Libre Caslon Display', height: 1.12),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        module.description,
        style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary, height: 1.5),
      ),
      const SizedBox(height: AppSpacing.md),
      Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xs,
        children: [
          _MetaBit(icon: _moduleDomainIcon(module.domain), label: module.domain.label),
          _MetaBit(icon: Icons.menu_book_rounded, label: '${module.lessons.length} leçons'),
          _MetaBit(icon: Icons.edit_note_rounded, label: '${module.exercises.length} exercices'),
          if (totalMinutes > 0)
            _MetaBit(icon: Icons.schedule_rounded, label: '≈ $totalMinutes min de lecture'),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      Container(width: 54, height: 2, color: AppColors.gold.withValues(alpha: 0.7)),
      const SizedBox(height: AppSpacing.xl),
    ];

    var lessonIndex = 0;
    for (var i = 0; i < anchors.length; i++) {
      final anchor = anchors[i];
      final Widget block;
      switch (anchor.kind) {
        case _AnchorKind.lesson:
          final l = lessonIndex;
          lessonIndex++;
          block = _LessonBlock(order: l + 1, lesson: module.lessons[l]);
        case _AnchorKind.revision:
          block = _RevisionPanel(module: module);
        case _AnchorKind.exercises:
          block = _ExercisesSection(module: module);
      }
      children.add(
        KeyedSubtree(
          key: keys[i],
          child: Padding(
            padding: EdgeInsets.only(bottom: i == anchors.length - 1 ? 0 : AppSpacing.xl),
            child: EntranceFadeSlide(index: i, child: block),
          ),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}

class _LessonBlock extends StatelessWidget {
  const _LessonBlock({required this.order, required this.lesson});

  final int order;
  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final reading = (textTheme.bodyMedium ?? const TextStyle()).copyWith(
      fontFamily: 'Lora',
      color: AppColors.textPrimary,
      height: 1.8,
      fontSize: 16,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'Leçon $order',
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
                letterSpacing: AppLetterSpacing.label,
              ),
            ),
            const Spacer(),
            Icon(Icons.schedule_rounded, size: 13, color: AppColors.textDisabled),
            const SizedBox(width: 4),
            Text(
              '${lesson.estimatedMinutes} min',
              style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          lesson.title,
          style: textTheme.titleLarge?.copyWith(fontFamily: 'Libre Caslon Display', height: 1.2),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(width: 32, height: 1, color: AppColors.gold.withValues(alpha: 0.35)),
        const SizedBox(height: AppSpacing.md),
        for (final paragraph in lesson.content.split('\n\n'))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(paragraph.trim(), textAlign: TextAlign.justify, style: reading),
          ),
      ],
    );
  }
}

class _RevisionPanel extends StatelessWidget {
  const _RevisionPanel({required this.module});

  final CourseModule module;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FICHE DE RÉVISION',
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.goldLight,
            letterSpacing: AppLetterSpacing.caps,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final sheet in module.revisionSheets)
          GlassContainer(
            padding: const EdgeInsets.all(AppSpacing.lg),
            borderColor: AppColors.gold.withValues(alpha: 0.35),
            borderWidth: 0.8,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x24C9A227), Color(0x0FC9A227)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bookmark_rounded, size: 16, color: AppColors.goldLight),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        sheet.title,
                        style: textTheme.titleMedium?.copyWith(fontFamily: 'Libre Caslon Display'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                for (final point in sheet.keyPoints)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Transform.rotate(
                            angle: math.pi / 4,
                            child: Container(
                              width: 6,
                              height: 6,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            point,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ExercisesSection extends StatelessWidget {
  const _ExercisesSection({required this.module});

  final CourseModule module;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "S'ENTRAÎNER",
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.goldLight,
            letterSpacing: AppLetterSpacing.caps,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < module.exercises.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == module.exercises.length - 1 ? 0 : AppSpacing.md,
            ),
            child: GlassContainer(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _DesktopExerciseTile(order: i + 1, exercise: module.exercises[i]),
            ),
          ),
      ],
    );
  }
}

class _DesktopExerciseTile extends StatefulWidget {
  const _DesktopExerciseTile({required this.order, required this.exercise});

  final int order;
  final Exercise exercise;

  @override
  State<_DesktopExerciseTile> createState() => _DesktopExerciseTileState();
}

class _DesktopExerciseTileState extends State<_DesktopExerciseTile> {
  bool _showCorrection = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Exercice ${widget.order}',
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
                letterSpacing: AppLetterSpacing.label,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.legalBlueDark.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.glassBorder, width: 0.7),
              ),
              child: Text(
                _difficultyLabel(widget.exercise.difficulty),
                style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          widget.exercise.statement,
          style: (textTheme.bodyLarge ?? const TextStyle()).copyWith(
            fontFamily: 'Lora',
            height: 1.7,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _showCorrection ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _showCorrection = true),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 9),
              ),
              icon: const Icon(Icons.lightbulb_outline_rounded, size: 15),
              label: const Text('Voir la correction'),
            ),
          ),
          secondChild: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.legalBlueDark.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(AppRadius.small),
              border: Border(
                left: BorderSide(color: AppColors.gold.withValues(alpha: 0.5), width: 2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.goldLight),
                    const SizedBox(width: 6),
                    Text(
                      'Correction',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.goldLight,
                        fontWeight: FontWeight.w700,
                        letterSpacing: AppLetterSpacing.label,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.exercise.correctionGuideline,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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

/// Rail latéral permanent : le tuteur IA du module, toujours à portée
/// pendant qu'on étudie la leçon.
class _TutorRail extends StatelessWidget {
  const _TutorRail({required this.module});

  final CourseModule module;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.nightBlueDeep.withValues(alpha: 0.35),
        border: Border(
          left: BorderSide(color: AppColors.gold.withValues(alpha: 0.16), width: 1),
        ),
      ),
      child: _TutorTab(module: module),
    );
  }
}

/// Fines poussières d'or en suspension — la respiration « vivante » du
/// registre desktop.
class _ModuleAmbience extends StatefulWidget {
  const _ModuleAmbience();

  @override
  State<_ModuleAmbience> createState() => _ModuleAmbienceState();
}

class _ModuleAmbienceState extends State<_ModuleAmbience> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 38))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(painter: _ModuleAmbiencePainter(_controller.value)),
    );
  }
}

class _ModuleAmbiencePainter extends CustomPainter {
  const _ModuleAmbiencePainter(this.t);

  final double t;
  static const int _count = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < _count; i++) {
      final seed = i * 63.0;
      final baseX = seed % size.width;
      final drift = math.sin((t * 2 * math.pi) + seed) * 18;
      final x = (baseX + drift) % size.width;
      final y = (size.height * ((i / _count) + t) % 1.0);
      final radius = 0.7 + (i % 3) * 0.6;
      final opacity = 0.04 + 0.07 * (0.5 + 0.5 * math.sin((t * 2 * math.pi) + seed * 1.7));
      paint.color = AppColors.goldLight.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ModuleAmbiencePainter oldDelegate) => oldDelegate.t != t;
}
