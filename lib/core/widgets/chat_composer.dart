import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../validation/input_limits.dart';
import 'glass_container.dart';

/// Barre de saisie de chat partagée par l'assistant juridique (Section 1)
/// et le tuteur de module (Section 3) : pilule de verre fumé, bouton
/// d'envoi en or brossé, et une touche de focus **cobalt** explicite —
/// bordure et lueur douce — lorsque le champ de texte est actif.
class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onSend,
    this.hintText = 'Écrivez votre message…',
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;
  final String hintText;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!mounted) return;
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: AppColors.cobalt.withValues(alpha: 0.32),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ]
              : const [],
        ),
        child: GlassContainer(
          borderRadius: AppRadius.pill,
          borderColor: _focused ? AppColors.cobalt : AppColors.glassBorder,
          borderWidth: _focused ? 1.1 : 0.5,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: AppInputLimits.chatMessage,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: widget.hintText,
                    counterText: '',
                  ),
                  onSubmitted: (_) => widget.onSend(),
                  textInputAction: TextInputAction.send,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  gradient: widget.enabled ? AppGradients.goldMetallic : null,
                  color: widget.enabled ? null : AppColors.legalBlueDark,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_upward_rounded,
                    color: widget.enabled ? AppColors.nightBlueDeep : AppColors.textDisabled,
                  ),
                  onPressed: widget.enabled ? widget.onSend : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
