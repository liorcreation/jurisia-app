import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/ai_thinking_indicator.dart';
import '../../../../core/widgets/chat_bubble.dart';
import '../../../../core/widgets/chat_composer.dart';
import '../../../../core/widgets/luxury_scaffold_background.dart';
import '../../../../core/widgets/markdown_text.dart';
import '../../../../models/chat/message_model.dart';
import '../../../../theme/app_theme.dart';
import '../../../../core/ai/claude_api_datasource.dart';
import '../../data/repositories/litigation_repository_impl.dart';
import '../../domain/usecases/analyze_litigation_usecase.dart';
import '../controllers/litigation_chat_controller.dart';

AnalyzeLitigationUseCase _buildAnalyzeLitigationUseCase() {
  final dataSource = AnthropicClaudeDataSource();
  final repository = LitigationRepositoryImpl(dataSource: dataSource);
  return AnalyzeLitigationUseCase(repository: repository);
}

/// Section 1 — Litiges et consultations : interface de chat naturel avec
/// l'IA juridique, connectée à l'API Claude via [LitigationChatController].
class LitigationScreen extends StatelessWidget {
  const LitigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LitigationChatController>(
      create: (_) => LitigationChatController(useCase: _buildAnalyzeLitigationUseCase()),
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

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LitigationChatController>();

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());

    final messages = controller.conversation.messages;
    final itemCount =
        messages.length + (controller.isSending ? 1 : 0) + (controller.errorMessage != null ? 1 : 0);

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Litiges et consultations'),
          actions: [
            IconButton(
              tooltip: 'Nouvelle consultation',
              icon: const Icon(Icons.add_comment_outlined),
              onPressed: controller.isSending ? null : controller.startNewConsultation,
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
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
              ChatComposer(
                controller: _inputController,
                enabled: !controller.isSending,
                onSend: () => _handleSend(controller),
                hintText: 'Décrivez votre situation…',
              ),
            ],
          ),
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

