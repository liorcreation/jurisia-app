import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/litigation/presentation/controllers/litigation_chat_controller.dart';
import '../../../models/chat/conversation_model.dart';
import '../../widgets/entrance_fade.dart';
import '../../widgets/glass_container.dart';
import '../../../theme/app_theme.dart';
import '../app_shell.dart';

/// Historique des consultations dans la sidebar — la grammaire ChatGPT /
/// Claude / Gemini : section « Épinglées » puis groupes datés
/// (Aujourd'hui / Hier / 7 derniers jours / Plus ancien), consultation
/// active mise en évidence par un filet d'or, actions (épingler, renommer,
/// supprimer) au survol / appui long.
class LitigationHistorySection extends StatelessWidget {
  const LitigationHistorySection({super.key, required this.query});

  final ValueNotifier<String> query;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LitigationChatController>();
    final history = controller.history;

    return ValueListenableBuilder<String>(
      valueListenable: query,
      builder: (context, rawQuery, _) {
        final q = rawQuery.trim().toLowerCase();
        final filtered = q.isEmpty
            ? history
            : history.where((c) => c.title.toLowerCase().contains(q)).toList();

        if (history.isEmpty) {
          return const _HistoryHint(
            "Vos consultations apparaîtront ici dès que vous en aurez commencé une.",
          );
        }
        if (filtered.isEmpty) {
          return _HistoryHint('Aucune consultation ne correspond à « $rawQuery ».');
        }

        final pinned = filtered.where((c) => c.isFavorite).toList();
        final rest = filtered.where((c) => !c.isFavorite).toList();
        final sections = <MapEntry<String, List<Conversation>>>[
          if (pinned.isNotEmpty) MapEntry('Épinglées', pinned),
          ..._groupedByDate(rest),
        ];

        var tileIndex = 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final section in sections) ...[
              _SectionLabel(section.key),
              for (final conversation in section.value)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 3),
                  child: EntranceFadeSlide(
                    index: tileIndex++,
                    child: _ConversationTile(
                      conversation: conversation,
                      active: conversation.id == controller.conversation.id,
                      onTap: () {
                        AppShellScope.of(context).selectModule(0);
                        controller.openConversation(conversation.id);
                      },
                      onPin: () => controller.togglePin(conversation.id),
                      onRename: () => _promptRename(context, controller, conversation),
                      onDelete: () => _confirmDelete(context, controller, conversation),
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  /// Répartit une liste déjà triée du plus récent au plus ancien dans les
  /// sections datées — le regroupement visuel de ChatGPT/Claude.
  List<MapEntry<String, List<Conversation>>> _groupedByDate(List<Conversation> conversations) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sections = <String, List<Conversation>>{
      "Aujourd'hui": [],
      'Hier': [],
      '7 derniers jours': [],
      'Plus ancien': [],
    };

    for (final conversation in conversations) {
      final date = conversation.updatedAt;
      final day = DateTime(date.year, date.month, date.day);
      final difference = today.difference(day).inDays;
      if (difference <= 0) {
        sections["Aujourd'hui"]!.add(conversation);
      } else if (difference == 1) {
        sections['Hier']!.add(conversation);
      } else if (difference < 7) {
        sections['7 derniers jours']!.add(conversation);
      } else {
        sections['Plus ancien']!.add(conversation);
      }
    }

    return sections.entries.where((entry) => entry.value.isNotEmpty).toList();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    LitigationChatController controller,
    Conversation conversation,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer cette consultation ?'),
        content: Text(
          '« ${conversation.title} » et tous ses messages seront définitivement supprimés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) controller.deleteConversation(conversation.id);
  }

  Future<void> _promptRename(
    BuildContext context,
    LitigationChatController controller,
    Conversation conversation,
  ) async {
    final textController = TextEditingController(text: conversation.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Renommer la consultation'),
        content: TextField(controller: textController, autofocus: true, maxLength: 60),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(textController.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    textController.dispose();
    if (newTitle != null && newTitle.isNotEmpty) {
      controller.renameConversation(conversation.id, newTitle);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textDisabled,
              fontWeight: FontWeight.w700,
              letterSpacing: AppLetterSpacing.caps,
            ),
      ),
    );
  }
}

class _HistoryHint extends StatelessWidget {
  const _HistoryHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _ConversationTile extends StatefulWidget {
  const _ConversationTile({
    required this.conversation,
    required this.active,
    required this.onTap,
    required this.onPin,
    required this.onRename,
    required this.onDelete,
  });

  final Conversation conversation;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  State<_ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<_ConversationTile> {
  bool _hovered = false;

  String _relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = today.difference(target).inDays;
    if (difference == 0) return "Aujourd'hui";
    if (difference == 1) return 'Hier';
    if (difference < 7) return 'Il y a $difference jours';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final conversation = widget.conversation;
    final showActions = _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onLongPress: () => _openMenu(context),
        child: GlassContainer(
          onTap: widget.onTap,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
          borderColor: widget.active ? AppColors.gold : AppColors.glassBorder,
          borderWidth: widget.active ? 1 : 0.5,
          child: Row(
            children: [
              if (conversation.isFavorite) ...[
                const Icon(Icons.push_pin_rounded, size: 13, color: AppColors.gold),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        color: widget.active ? AppColors.gold : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(_relativeDate(conversation.updatedAt), style: textTheme.labelSmall),
                        if (conversation.domain != null) ...[
                          const Text(' · ', style: TextStyle(color: AppColors.textDisabled)),
                          Expanded(
                            child: Text(
                              conversation.domain!.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelSmall,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (showActions)
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: 'Actions',
                    icon: const Icon(Icons.more_horiz_rounded, size: 18, color: AppColors.textSecondary),
                    onPressed: () => _openMenu(context),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openMenu(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(box.size.centerRight(Offset.zero), ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final choice = await showMenu<String>(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          value: 'pin',
          child: Row(
            children: [
              Icon(
                widget.conversation.isFavorite
                    ? Icons.push_pin_outlined
                    : Icons.push_pin_rounded,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(widget.conversation.isFavorite ? 'Désépingler' : 'Épingler'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: AppSpacing.sm),
              Text('Renommer'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
              SizedBox(width: AppSpacing.sm),
              Text('Supprimer', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    );

    switch (choice) {
      case 'pin':
        widget.onPin();
      case 'rename':
        widget.onRename();
      case 'delete':
        widget.onDelete();
    }
  }
}
