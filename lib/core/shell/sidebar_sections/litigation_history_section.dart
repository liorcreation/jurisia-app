import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/litigation/presentation/controllers/litigation_chat_controller.dart';
import '../../../models/chat/conversation_model.dart';
import '../../../theme/app_theme.dart';
import '../app_shell.dart';
import 'sidebar_section_scaffold.dart';

/// Historique des consultations — la grammaire ChatGPT / Claude / Gemini :
/// section « Épinglées » puis groupes datés (Aujourd'hui, Hier, 7 jours
/// précédents, 30 jours précédents, puis par mois), lignes d'une seule
/// ligne, légères, avec le menu d'actions (épingler, renommer, supprimer)
/// au survol. La consultation active porte un fond doré discret.
class LitigationHistorySection extends StatelessWidget {
  const LitigationHistorySection({super.key, required this.query});

  final ValueNotifier<String> query;

  static const List<String> _months = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];

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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final section in sections) ...[
              SidebarGroupLabel(section.key),
              for (final conversation in section.value)
                _ConversationTile(
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
            ],
          ],
        );
      },
    );
  }

  /// Répartit une liste déjà triée du plus récent au plus ancien dans les
  /// groupes datés — le regroupement de ChatGPT/Claude, étendu aux mois pour
  /// les consultations plus anciennes.
  List<MapEntry<String, List<Conversation>>> _groupedByDate(List<Conversation> conversations) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final recent = <String, List<Conversation>>{
      "Aujourd'hui": [],
      'Hier': [],
      '7 jours précédents': [],
      '30 jours précédents': [],
    };
    final byMonth = <String, List<Conversation>>{};

    for (final conversation in conversations) {
      final date = conversation.updatedAt;
      final day = DateTime(date.year, date.month, date.day);
      final difference = today.difference(day).inDays;
      if (difference <= 0) {
        recent["Aujourd'hui"]!.add(conversation);
      } else if (difference == 1) {
        recent['Hier']!.add(conversation);
      } else if (difference < 7) {
        recent['7 jours précédents']!.add(conversation);
      } else if (difference < 30) {
        recent['30 jours précédents']!.add(conversation);
      } else {
        final key = date.year == now.year
            ? _months[date.month - 1]
            : '${_months[date.month - 1]} ${date.year}';
        byMonth.putIfAbsent(_capitalize(key), () => []).add(conversation);
      }
    }

    return [
      for (final entry in recent.entries)
        if (entry.value.isNotEmpty) entry,
      for (final entry in byMonth.entries) entry,
    ];
  }

  static String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

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

class _HistoryHint extends StatelessWidget {
  const _HistoryHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(height: 1.4),
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final conversation = widget.conversation;
    final active = widget.active;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 1),
        child: GestureDetector(
          onLongPress: () => _openMenu(context),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 6, 4, 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  color: active
                      ? AppColors.gold.withValues(alpha: 0.13)
                      : _hovered
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.transparent,
                ),
                child: Row(
                  children: [
                    if (conversation.isFavorite) ...[
                      const Icon(Icons.push_pin_rounded, size: 11, color: AppColors.gold),
                      const SizedBox(width: 5),
                    ],
                    Expanded(
                      child: Text(
                        conversation.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontSize: 13,
                          color: active ? AppColors.gold : AppColors.textPrimary,
                          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 26,
                      height: 22,
                      child: AnimatedOpacity(
                        opacity: _hovered ? 1 : 0,
                        duration: const Duration(milliseconds: 120),
                        child: IgnorePointer(
                          ignoring: !_hovered,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            tooltip: 'Actions',
                            icon: const Icon(Icons.more_horiz_rounded,
                                size: 16, color: AppColors.textSecondary),
                            onPressed: () => _openMenu(context),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
