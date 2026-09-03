import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/entitlements/entitlement_feature.dart';
import '../../../../core/entitlements/entitlements_controller.dart';
import '../../../../core/entitlements/widgets/upgrade_sheet.dart';
import '../../../../core/legal/legal_document_screen.dart';
import '../../../../core/legal/legal_documents.dart';
import '../../../../core/platform/app_platform_style.dart';
import '../../../../core/validation/input_limits.dart';
import '../../../../core/widgets/ai_thinking_indicator.dart';
import '../../../../core/widgets/app_shell_menu_button.dart';
import '../../../../core/widgets/chat_bubble.dart';
import '../../../../core/widgets/chat_composer.dart';
import '../../../../core/widgets/entrance_fade.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/gold_fab.dart';
import '../../../../core/widgets/gradient_icon_badge.dart';
import '../../../../core/widgets/ios_large_title_bar.dart';
import '../../../../core/widgets/ios_new_consultation_sheet.dart';
import '../../../../core/widgets/jurisia_mark.dart';
import '../../../../core/widgets/luxury_scaffold_background.dart';
import '../../../../core/widgets/markdown_text.dart';
import '../../../../models/chat/conversation_model.dart';
import '../../../../models/chat/message_model.dart';
import '../../../../theme/app_theme.dart';
import '../controllers/litigation_chat_controller.dart';

/// Section 1 — Litiges et consultations : interface de chat naturel avec
/// l'IA juridique. Le contrôleur ([LitigationChatController]) est fourni par
/// la coquille applicative ([AppShell]) — la sidebar unifiée pilote
/// l'historique des consultations, cet écran n'affiche que la conversation
/// active et son composeur.
///
/// Deux mises en page distinctes selon le registre de plateforme :
///  - **desktop** ([_DesktopLitigationView]) : en-tête « cabinet numérique »,
///    colonne de lecture centrée, état d'accueil éditorial avec amorces de
///    situation, composeur large (⏎ pour envoyer, ⇧⏎ pour un saut de ligne) ;
///  - **mobile / iOS / Android** : le fil de bulles habituel + `ChatComposer`.
class LitigationScreen extends StatelessWidget {
  const LitigationScreen({super.key});

  @override
  Widget build(BuildContext context) => const _LitigationView();
}

class _LitigationView extends StatefulWidget {
  const _LitigationView();

  @override
  State<_LitigationView> createState() => _LitigationViewState();
}

class _LitigationViewState extends State<_LitigationView> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _composerFocus = FocusNode();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _composerFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSend(LitigationChatController controller) async {
    final text = _inputController.text;
    if (text.trim().isEmpty || controller.isSending) return;

    // Le quota « consultations » de l'offre gratuite se décompte à
    // l'ouverture réelle d'une consultation, c.-à-d. au premier message de
    // l'utilisateur d'une conversation neuve. Une relance après échec réseau
    // passe par `controller.retry` et n'est jamais recomptée.
    final isFirstUserMessage =
        controller.conversation.messages.every((m) => m.sender != MessageSender.user);
    if (isFirstUserMessage) {
      final allowed =
          await context.read<EntitlementsController>().tryConsume(EntitlementFeature.litigeConsultations);
      if (!allowed) {
        if (mounted) {
          await showUpgradeSheet(context, feature: EntitlementFeature.litigeConsultations);
        }
        return;
      }
      if (!mounted) return;
    }

    _inputController.clear();
    controller.sendMessage(text);
  }

  void _scrollToEnd() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  /// Amorce depuis une carte de situation : pré-remplit le composeur (sans
  /// envoyer) et lui donne le focus pour que l'utilisateur complète.
  void _useStarter(String text) {
    _inputController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _composerFocus.requestFocus();
  }

  void _startNewConsultation(
    BuildContext context,
    LitigationChatController controller,
    AppPlatformStyle platformStyle,
  ) {
    if (platformStyle == AppPlatformStyle.ios) {
      showIosNewConsultationSheet(context, onConfirm: controller.startNewConsultation);
    } else {
      controller.startNewConsultation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LitigationChatController>();
    final platformStyle = AppPlatformStyle.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());

    if (platformStyle == AppPlatformStyle.desktop) {
      return _DesktopLitigationView(
        controller: controller,
        scrollController: _scrollController,
        inputController: _inputController,
        composerFocus: _composerFocus,
        onSend: () => _handleSend(controller),
        onUseStarter: _useStarter,
      );
    }

    final messages = controller.conversation.messages;
    final itemCount =
        messages.length + (controller.isSending ? 1 : 0) + (controller.errorMessage != null ? 1 : 0);

    final newConsultationAction = IconButton(
      tooltip: 'Nouvelle consultation',
      icon: const Icon(Icons.add_comment_outlined),
      onPressed: controller.isSending
          ? null
          : () => _startNewConsultation(context, controller, platformStyle),
    );

    final chatBody = Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (index < messages.length) {
                return _ChatBubble(message: messages[index]);
              }

              var remaining = index - messages.length;

              if (controller.isSending) {
                if (remaining == 0) {
                  return _AssistantThinkingBubble(streamingText: controller.streamingText);
                }
                remaining -= 1;
              }

              return ChatErrorBubble(
                message: controller.errorMessage ?? '',
                onRetry: controller.canRetry ? controller.retry : null,
                onDismiss: controller.dismissError,
              );
            },
          ),
        ),
        _AiDisclaimerHint(),
        ChatComposer(
          controller: _inputController,
          enabled: !controller.isSending,
          onSend: () => _handleSend(controller),
          hintText: 'Décrivez votre situation…',
        ),
      ],
    );

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: platformStyle == AppPlatformStyle.ios
            ? IosLargeTitleBar(
                title: 'Litiges et consultations',
                leading: const AppShellMenuButton(),
                actions: [newConsultationAction],
              )
            : AppBar(
                title: const Text('Litiges et consultations'),
                leading: const AppShellMenuButton(),
                actions: platformStyle == AppPlatformStyle.android ? null : [newConsultationAction],
              ),
        floatingActionButton: platformStyle == AppPlatformStyle.android
            ? GoldFab(
                tooltip: 'Nouvelle consultation',
                icon: Icons.add_comment_rounded,
                onPressed: controller.isSending ? null : controller.startNewConsultation,
              )
            : null,
        body: SafeArea(child: chatBody),
      ),
    );
  }
}

// ===========================================================================
//  DESKTOP — « cabinet numérique »
// ===========================================================================

/// Largeur maximale de la colonne de lecture (conversation + composeur).
const double _kReadingColumnWidth = 760;

class _DesktopLitigationView extends StatelessWidget {
  const _DesktopLitigationView({
    required this.controller,
    required this.scrollController,
    required this.inputController,
    required this.composerFocus,
    required this.onSend,
    required this.onUseStarter,
  });

  final LitigationChatController controller;
  final ScrollController scrollController;
  final TextEditingController inputController;
  final FocusNode composerFocus;
  final VoidCallback onSend;
  final ValueChanged<String> onUseStarter;

  @override
  Widget build(BuildContext context) {
    final conversation = controller.conversation;
    final messages = conversation.messages;
    final hasUserMessage = messages.any((m) => m.sender == MessageSender.user);
    final showConversation =
        hasUserMessage || controller.isSending || controller.errorMessage != null;

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _DesktopHeader(
                conversation: conversation,
                started: hasUserMessage,
                onNewConsultation:
                    controller.isSending ? null : controller.startNewConsultation,
              ),
              Expanded(
                child: showConversation
                    ? _ConversationStream(
                        controller: controller,
                        scrollController: scrollController,
                      )
                    : _WelcomeHero(onUseStarter: onUseStarter),
              ),
              _DesktopComposer(
                controller: inputController,
                focusNode: composerFocus,
                enabled: !controller.isSending,
                onSend: onSend,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// En-tête de l'écran : bascule de navigation, titre en serif, sous-titre
/// contextuel (consultation active + branche du droit + complexité), et
/// l'action « Nouvelle consultation ».
class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader({
    required this.conversation,
    required this.started,
    required this.onNewConsultation,
  });

  final Conversation conversation;
  final bool started;
  final VoidCallback? onNewConsultation;

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
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          const AppShellMenuButton(),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.forum_rounded, size: 18, color: AppColors.gold),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        'Litiges et consultations',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                _HeaderSubtitle(conversation: conversation, started: started),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Tooltip(
            message: 'Nouvelle consultation  (Ctrl / ⌘ N)',
            child: OutlinedButton.icon(
              onPressed: onNewConsultation,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                textStyle: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              icon: const Icon(Icons.add_comment_outlined, size: 18),
              label: const Text('Nouvelle consultation'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderSubtitle extends StatelessWidget {
  const _HeaderSubtitle({required this.conversation, required this.started});

  final Conversation conversation;
  final bool started;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (!started) {
      return Text(
        'Assistant juridique — confidentiel, sans jugement',
        style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
      );
    }

    return Row(
      children: [
        Flexible(
          child: Text(
            conversation.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.goldLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (conversation.domain != null) ...[
          const SizedBox(width: AppSpacing.sm),
          _MetaChip(icon: Icons.balance_rounded, label: conversation.domain!.label),
        ],
        if (conversation.complexity != null) ...[
          const SizedBox(width: 6),
          _ComplexityChip(level: conversation.complexity!),
        ],
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        color: AppColors.legalBlueDark.withValues(alpha: 0.55),
        border: Border.all(color: AppColors.glassBorder, width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.goldLight),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _ComplexityChip extends StatelessWidget {
  const _ComplexityChip({required this.level});

  final ComplexityLevel level;

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = switch (level) {
      ComplexityLevel.simple => ('Complexité faible', AppColors.success),
      ComplexityLevel.moyenne => ('Complexité moyenne', AppColors.warning),
      ComplexityLevel.complexe => ('Dossier complexe', AppColors.roseGold),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

/// Le fil de conversation, en colonne de lecture centrée. Messages de
/// l'utilisateur en cartes de verre à filet d'or (alignées à droite),
/// réponses de l'IA en prose ouverte précédée de la marque — la grammaire
/// des grands assistants, dans le registre JurisIA.
class _ConversationStream extends StatelessWidget {
  const _ConversationStream({required this.controller, required this.scrollController});

  final LitigationChatController controller;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final messages = controller.conversation.messages;

    final turns = <Widget>[
      for (final message in messages)
        if (message.sender == MessageSender.user)
          _UserTurn(text: message.content)
        else
          _AssistantTurn(
            content: message.content,
            suggestedProfessional: message.suggestedProfessional,
          ),
      if (controller.isSending)
        _AssistantTurn(content: controller.streamingText, thinking: true),
      if (controller.errorMessage != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: ChatErrorBubble(
            message: controller.errorMessage ?? '',
            onRetry: controller.canRetry ? controller.retry : null,
            onDismiss: controller.dismissError,
          ),
        ),
    ];

    return Scrollbar(
      controller: scrollController,
      child: SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _kReadingColumnWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < turns.length; i++)
                  Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : AppSpacing.lg),
                    child: turns[i],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssistantTurn extends StatelessWidget {
  const _AssistantTurn({
    required this.content,
    this.suggestedProfessional,
    this.thinking = false,
  });

  final String content;
  final String? suggestedProfessional;
  final bool thinking;

  @override
  Widget build(BuildContext context) {
    return EntranceFadeSlide(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _MarkAvatar(),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (thinking && content.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: AiThinkingIndicator(),
                  )
                else
                  MarkdownText(content),
                if (suggestedProfessional != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _ProfessionalSuggestionChip(label: suggestedProfessional!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkAvatar extends StatelessWidget {
  const _MarkAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.gold.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.glassBorder, width: 0.75),
      ),
      child: const JurisIAMark(size: 17),
    );
  }
}

class _UserTurn extends StatelessWidget {
  const _UserTurn({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return EntranceFadeSlide(
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: GlassContainer(
            gradient: AppGradients.heroCard,
            borderColor: AppColors.gold.withValues(alpha: 0.5),
            borderRadius: AppRadius.large,
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.textPrimary, height: 1.45),
            ),
          ),
        ),
      ),
    );
  }
}

/// État d'accueil : la marque, une invite en serif, le mot de bienvenue de
/// l'assistant, et quatre amorces de situations fréquentes.
class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero({required this.onUseStarter});

  final ValueChanged<String> onUseStarter;

  static const List<_Starter> _starters = [
    _Starter(
      icon: Icons.work_off_outlined,
      title: 'Litige avec mon employeur',
      subtitle: 'Licenciement, salaires ou heures impayés, congés, contrat non respecté.',
      prompt: "J'ai un litige avec mon employeur. ",
    ),
    _Starter(
      icon: Icons.landscape_outlined,
      title: 'Conflit foncier ou de voisinage',
      subtitle: 'Limites de parcelle, titre contesté, empiètement, nuisances répétées.',
      prompt: "J'ai un conflit foncier ou de voisinage. ",
    ),
    _Starter(
      icon: Icons.home_outlined,
      title: 'Problème de bail ou de loyer',
      subtitle: "Menace d'expulsion, caution non restituée, loyers, réparations.",
      prompt: "J'ai un problème lié à mon bail ou à mon logement. ",
    ),
    _Starter(
      icon: Icons.request_quote_outlined,
      title: 'Recouvrer une somme due',
      subtitle: 'Facture impayée, prêt entre particuliers, reconnaissance de dette.',
      prompt: "Je cherche à recouvrer une somme qu'on me doit. ",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _HeroMark(),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Exposez votre situation',
                textAlign: TextAlign.center,
                style: textTheme.displaySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: 64,
                height: 2,
                decoration: BoxDecoration(
                  gradient: AppGradients.goldSheen,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  "Racontez ce qui vous amène avec vos propres mots — les faits, les personnes "
                  "concernées, ce que vous cherchez à obtenir. Quelques questions suivront pour "
                  "cerner votre dossier.",
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.55),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.divider, endIndent: AppSpacing.md)),
                  Text(
                    "OU PARTEZ D'UNE SITUATION COURANTE",
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.textDisabled,
                      letterSpacing: AppLetterSpacing.caps,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.divider, indent: AppSpacing.md)),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoColumns = constraints.maxWidth >= 620;
                  final cardWidth = twoColumns
                      ? (constraints.maxWidth - AppSpacing.md) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      for (var i = 0; i < _starters.length; i++)
                        SizedBox(
                          width: cardWidth,
                          child: EntranceFadeSlide(
                            index: i,
                            child: _StarterCard(
                              starter: _starters[i],
                              onTap: () => onUseStarter(_starters[i].prompt),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              const _ConfidentialityNote(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroMark extends StatelessWidget {
  const _HeroMark();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 720),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.7 + 0.3 * t, child: child),
      ),
      child: SizedBox(
        width: 112,
        height: 112,
        child: Stack(
          alignment: Alignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.gold.withValues(alpha: 0.22),
                    AppColors.gold.withValues(alpha: 0),
                  ],
                ),
              ),
              child: const SizedBox.expand(),
            ),
            const JurisIAMark(size: 62),
          ],
        ),
      ),
    );
  }
}

class _Starter {
  const _Starter({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.prompt,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String prompt;
}

class _StarterCard extends StatelessWidget {
  const _StarterCard({required this.starter, required this.onTap});

  final _Starter starter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassContainer(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientIconBadge(icon: starter.icon, size: 42),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(starter.title, style: textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(
                  starter.subtitle,
                  style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfidentialityNote extends StatelessWidget {
  const _ConfidentialityNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_outline_rounded, size: 13, color: AppColors.textDisabled),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            "Vos échanges sont confidentiels. L'IA aide à comprendre, elle ne remplace pas un avocat.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textDisabled),
          ),
        ),
      ],
    );
  }
}

/// Composeur desktop : champ multi-ligne en verre, bouton d'envoi en or,
/// et une ligne de bas de champ (avertissement IA + raccourcis clavier).
/// ⏎ envoie, ⇧⏎ insère un saut de ligne.
class _DesktopComposer extends StatefulWidget {
  const _DesktopComposer({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onSend;

  @override
  State<_DesktopComposer> createState() => _DesktopComposerState();
}

class _DesktopComposerState extends State<_DesktopComposer> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
    widget.focusNode.onKeyEvent = _onKeyEvent;
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    if (widget.focusNode.onKeyEvent == _onKeyEvent) {
      widget.focusNode.onKeyEvent = null;
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (!mounted) return;
    setState(() => _focused = widget.focusNode.hasFocus);
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final isEnter = event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (event is KeyDownEvent && isEnter && !HardwareKeyboard.instance.isShiftPressed) {
      if (widget.enabled) widget.onSend();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kReadingColumnWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.fastOutSlowIn,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.large),
                  boxShadow: _focused
                      ? [
                          BoxShadow(
                            color: AppColors.cobalt.withValues(alpha: 0.28),
                            blurRadius: 22,
                            spreadRadius: 1,
                          ),
                        ]
                      : AppShadows.card,
                ),
                child: GlassContainer(
                  borderRadius: AppRadius.large,
                  borderColor: _focused ? AppColors.cobalt : AppColors.glassBorder,
                  borderWidth: _focused ? 1.1 : 0.5,
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, 4, 6, 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          child: TextField(
                            controller: widget.controller,
                            focusNode: widget.focusNode,
                            enabled: widget.enabled,
                            minLines: 1,
                            maxLines: 7,
                            maxLength: AppInputLimits.chatMessage,
                            style: textTheme.bodyLarge?.copyWith(
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                            decoration: const InputDecoration(
                              isCollapsed: true,
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              counterText: '',
                              hintText:
                                  'Décrivez votre situation : les faits, les dates, les personnes '
                                  'concernées, ce que vous cherchez…',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _SendButton(
                        enabled: widget.enabled,
                        onTap: widget.enabled ? widget.onSend : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              LayoutBuilder(
                builder: (context, constraints) {
                  final showShortcuts = constraints.maxWidth > 560;
                  return Row(
                    children: [
                      const Expanded(child: _DisclaimerLink()),
                      AnimatedBuilder(
                        animation: widget.controller,
                        builder: (context, _) {
                          final length = widget.controller.text.length;
                          if (length < AppInputLimits.chatMessage - 600) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.sm),
                            child: Text(
                              '$length / ${AppInputLimits.chatMessage}',
                              style: textTheme.labelSmall?.copyWith(
                                color: length >= AppInputLimits.chatMessage
                                    ? AppColors.error
                                    : AppColors.textDisabled,
                              ),
                            ),
                          );
                        },
                      ),
                      if (showShortcuts) const _KbdHint(),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: enabled ? AppGradients.goldMetallic : null,
        color: enabled ? null : AppColors.legalBlueDark,
        shape: BoxShape.circle,
        boxShadow: enabled ? AppShadows.goldGlowSoft : null,
      ),
      child: IconButton(
        tooltip: 'Envoyer  (⏎)',
        icon: Icon(
          Icons.arrow_upward_rounded,
          color: enabled ? AppColors.nightBlueDeep : AppColors.textDisabled,
        ),
        onPressed: onTap,
      ),
    );
  }
}

class _DisclaimerLink extends StatelessWidget {
  const _DisclaimerLink();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const LegalDocumentScreen(
            title: 'Avertissement',
            content: LegalDocuments.aiDisclaimer,
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline_rounded, size: 13, color: AppColors.textDisabled),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                "L'IA aide à comprendre, ne remplace pas un avocat.",
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textDisabled),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KbdHint extends StatelessWidget {
  const _KbdHint();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textDisabled);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Kbd('⏎'),
        Text(' envoyer', style: style),
        const SizedBox(width: AppSpacing.sm),
        const _Kbd('⇧ ⏎'),
        Text(' saut de ligne', style: style),
      ],
    );
  }
}

class _Kbd extends StatelessWidget {
  const _Kbd(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: AppColors.textSecondary.withValues(alpha: 0.12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

// ===========================================================================
//  MOBILE / iOS / Android — le fil de bulles
// ===========================================================================

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;

    return ChatBubble(
      isUser: isUser,
      footer: message.suggestedProfessional != null
          ? _ProfessionalSuggestionChip(label: message.suggestedProfessional!)
          : null,
      child: isUser
          ? Text(
              message.content,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.textPrimary, height: 1.4),
            )
          : MarkdownText(message.content),
    );
  }
}

class _ProfessionalSuggestionChip extends StatelessWidget {
  const _ProfessionalSuggestionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        gradient: AppGradients.goldMetallic,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.handshake_rounded, size: 14, color: AppColors.nightBlueDeep),
          const SizedBox(width: 4),
          Text(
            'Orientation suggérée : $label',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.nightBlueDeep,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

/// Rappel visible, au-dessus du composeur, que l'IA aide à comprendre une
/// situation mais ne remplace pas un professionnel du droit.
class _AiDisclaimerHint extends StatelessWidget {
  const _AiDisclaimerHint();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const LegalDocumentScreen(
            title: 'Avertissement',
            content: LegalDocuments.aiDisclaimer,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, size: 13, color: AppColors.textDisabled),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                "L'IA aide à comprendre, ne remplace pas un avocat.",
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textDisabled),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssistantThinkingBubble extends StatelessWidget {
  const _AssistantThinkingBubble({required this.streamingText});

  final String streamingText;

  @override
  Widget build(BuildContext context) {
    return ChatBubble(
      isUser: false,
      child: streamingText.isEmpty ? const AiThinkingIndicator() : MarkdownText(streamingText),
    );
  }
}
