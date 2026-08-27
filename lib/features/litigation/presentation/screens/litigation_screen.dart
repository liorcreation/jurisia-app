import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/legal/legal_document_screen.dart';
import '../../../../core/legal/legal_documents.dart';
import '../../../../core/platform/app_platform_style.dart';
import '../../../../core/widgets/ai_thinking_indicator.dart';
import '../../../../core/widgets/chat_bubble.dart';
import '../../../../core/widgets/chat_composer.dart';
import '../../../../core/widgets/gold_fab.dart';
import '../../../../core/widgets/ios_large_title_bar.dart';
import '../../../../core/widgets/ios_new_consultation_sheet.dart';
import '../../../../core/widgets/luxury_scaffold_background.dart';
import '../../../../core/widgets/markdown_text.dart';
import '../../../../core/widgets/smoked_glass_surface.dart';
import '../../../../models/chat/message_model.dart';
import '../../../../theme/app_theme.dart';
import '../../../../core/ai/groq_api_datasource.dart';
import '../../../../core/supabase/supabase_config.dart';
import '../../data/repositories/litigation_repository_impl.dart';
import '../../data/repositories/supabase_litigation_conversation_store.dart';
import '../../domain/repositories/litigation_conversation_store.dart';
import '../../domain/usecases/analyze_litigation_usecase.dart';
import '../controllers/litigation_chat_controller.dart';
import '../widgets/conversation_history_panel.dart';

AnalyzeLitigationUseCase _buildAnalyzeLitigationUseCase() {
  final dataSource = GroqDataSource();
  final repository = LitigationRepositoryImpl(dataSource: dataSource);
  return AnalyzeLitigationUseCase(repository: repository);
}

LitigationConversationStore? _buildConversationStore() {
  if (!SupabaseConfig.isReady) return null;
  final userId = SupabaseConfig.client.auth.currentUser?.id;
  if (userId == null) return null;
  return SupabaseLitigationConversationStore(client: SupabaseConfig.client, userId: userId);
}

/// Section 1 — Litiges et consultations : interface de chat naturel avec
/// l'IA juridique, connectée à l'API Groq via [LitigationChatController].
class LitigationScreen extends StatelessWidget {
  const LitigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LitigationChatController>(
      create: (_) => LitigationChatController(
        useCase: _buildAnalyzeLitigationUseCase(),
        conversationStore: _buildConversationStore(),
      ),
      child: const _LitigationView(),
    );
  }
}

class _LitigationView extends StatefulWidget {
  const _LitigationView();

  @override
  State<_LitigationView> createState() => _LitigationViewState();
}

class _LitigationViewState extends State<_LitigationView> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSend(LitigationChatController controller) {
    final text = _inputController.text;
    if (text.trim().isEmpty || controller.isSending) return;
    _inputController.clear();
    controller.sendMessage(text);
  }

  void _scrollToEnd() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
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
    final isDesktop = platformStyle == AppPlatformStyle.desktop;

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());

    final messages = controller.conversation.messages;
    final itemCount =
        messages.length + (controller.isSending ? 1 : 0) + (controller.errorMessage != null ? 1 : 0);

    // iOS propose l'action dans une feuille modale (registre « Verre
    // glacé ») ; Android la propose via un bouton d'action flottant
    // (registre « Or expressif ») ; le desktop garde l'icône directe.
    final newConsultationAction = IconButton(
      tooltip: 'Nouvelle consultation',
      icon: const Icon(Icons.add_comment_outlined),
      onPressed: controller.isSending
          ? null
          : () => _startNewConsultation(context, controller, platformStyle),
    );

    // Sur mobile, le panneau vit dans le tiroir : la sélection referme le
    // tiroir avant de basculer de consultation. Sur desktop, le panneau est
    // toujours visible, rien à fermer.
    Widget historyPanel({required bool inDrawer}) {
      return ConversationHistoryPanel(
        history: controller.history,
        activeId: controller.conversation.id,
        onNewConsultation: () {
          if (inDrawer) Navigator.of(context).maybePop();
          _startNewConsultation(context, controller, platformStyle);
        },
        onSelect: (id) {
          if (inDrawer) Navigator.of(context).maybePop();
          controller.openConversation(id);
        },
        onDelete: controller.deleteConversation,
      );
    }

    final historyButton = Builder(
      builder: (innerContext) => IconButton(
        tooltip: 'Historique des consultations',
        icon: const Icon(Icons.history_rounded),
        onPressed: () => Scaffold.of(innerContext).openDrawer(),
      ),
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
        drawer: isDesktop
            ? null
            : Drawer(child: SafeArea(child: historyPanel(inDrawer: true))),
        appBar: platformStyle == AppPlatformStyle.ios
            ? IosLargeTitleBar(
                title: 'Litiges et consultations',
                actions: [historyButton, newConsultationAction],
              )
            : AppBar(
                title: const Text('Litiges et consultations'),
                leading: isDesktop ? null : historyButton,
                actions: platformStyle == AppPlatformStyle.android ? null : [newConsultationAction],
              ),
        floatingActionButton: platformStyle == AppPlatformStyle.android
            ? GoldFab(
                tooltip: 'Nouvelle consultation',
                icon: Icons.add_comment_rounded,
                onPressed: controller.isSending ? null : controller.startNewConsultation,
              )
            : null,
        body: SafeArea(
          child: isDesktop
              ? Row(
                  children: [
                    SizedBox(
                      width: 280,
                      child: SmokedGlassSurface(
                        border: const Border(right: BorderSide(color: AppColors.glassBorder, width: 0.6)),
                        child: historyPanel(inDrawer: false),
                      ),
                    ),
                    Expanded(child: chatBody),
                  ],
                )
              : chatBody,
        ),
      ),
    );
  }
}

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
/// situation mais ne remplace pas un professionnel du droit — complète (sans
/// le remplacer) l'avertissement déjà intégré au fil de la conversation par
/// le system prompt de l'IA.
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

