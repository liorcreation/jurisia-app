import 'package:flutter/material.dart';

import '../../../../core/widgets/entrance_fade.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/luxury_elevated_button.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../models/chat/conversation_model.dart';
import '../../../../theme/app_theme.dart';

/// Panneau d'historique des consultations — panneau permanent sur desktop,
/// contenu d'un `Drawer` sur mobile (voir `LitigationScreen`), organisé
/// comme le sélecteur de conversation de ChatGPT/Claude/Gemini : liste
/// triée du plus récent au plus ancien, conversation active mise en
/// évidence, bouton "Nouvelle consultation" en tête.
class ConversationHistoryPanel extends StatelessWidget {
  const ConversationHistoryPanel({
    super.key,
    required this.history,
    required this.activeId,
    required this.onSelect,
    required this.onDelete,
    required this.onNewConsultation,
  });

  final List<Conversation> history;
  final String? activeId;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onDelete;
  final VoidCallback onNewConsultation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
          child: LuxuryElevatedButton(
            icon: Icons.add_comment_rounded,
            onPressed: onNewConsultation,
            child: const Text('Nouvelle consultation'),
          ),
        ),
        Expanded(
          child: history.isEmpty
              ? _EmptyHistory(padding: const EdgeInsets.all(AppSpacing.md))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final entry = history[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: EntranceFadeSlide(
                        index: index,
                        child: _ConversationTile(
                          conversation: entry,
                          active: entry.id == activeId,
                          onTap: () => onSelect(entry.id),
                          onDelete: () => _confirmDelete(context, entry),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, Conversation conversation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer cette consultation ?'),
        content: Text(
          '« ${conversation.title} » et tous ses messages seront définitivement supprimés.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete(conversation.id);
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.padding});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Center(
        child: Text(
          'Vos consultations apparaîtront ici dès que vous en aurez commencé une.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.active,
    required this.onTap,
    required this.onDelete,
  });

  final Conversation conversation;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onDelete;

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

    return GlassContainer(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      borderColor: active ? AppColors.gold : AppColors.glassBorder,
      borderWidth: active ? 1 : 0.5,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(color: active ? AppColors.gold : AppColors.textPrimary),
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
          TapScale(
            child: IconButton(
              tooltip: 'Supprimer',
              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.textSecondary),
              onPressed: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}
