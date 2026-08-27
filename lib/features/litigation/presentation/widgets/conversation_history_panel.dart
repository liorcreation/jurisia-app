import 'package:flutter/material.dart';

import '../../../../core/widgets/entrance_fade.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glow_focus_field.dart';
import '../../../../core/widgets/luxury_elevated_button.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../models/chat/conversation_model.dart';
import '../../../../theme/app_theme.dart';

/// Panneau d'historique des consultations — panneau permanent (repliable)
/// sur desktop, contenu d'un `Drawer` sur mobile (voir `LitigationScreen`),
/// organisé comme le sélecteur de conversation de ChatGPT/Claude/Gemini :
/// recherche, sections par date, conversation active mise en évidence,
/// bouton "Nouvelle consultation" en tête.
class ConversationHistoryPanel extends StatefulWidget {
  const ConversationHistoryPanel({
    super.key,
    required this.history,
    required this.activeId,
    required this.onSelect,
    required this.onDelete,
    required this.onRename,
    required this.onNewConsultation,
  });

  final List<Conversation> history;
  final String? activeId;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onDelete;
  final void Function(String id, String newTitle) onRename;
  final VoidCallback onNewConsultation;

  @override
  State<ConversationHistoryPanel> createState() => _ConversationHistoryPanelState();
}

class _ConversationHistoryPanelState extends State<ConversationHistoryPanel> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Conversation> get _filtered {
    if (_query.isEmpty) return widget.history;
    final query = _query.toLowerCase();
    return widget.history.where((c) => c.title.toLowerCase().contains(query)).toList();
  }

  /// Répartit une liste déjà triée du plus récent au plus ancien dans les
  /// sections "Aujourd'hui / Hier / 7 derniers jours / Plus ancien" —
  /// exactement le regroupement visuel de ChatGPT/Claude.
  List<MapEntry<String, List<Conversation>>> _groupedSections(List<Conversation> conversations) {
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final sections = _groupedSections(filtered);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
          child: LuxuryElevatedButton(
            icon: Icons.add_comment_rounded,
            onPressed: widget.onNewConsultation,
            child: const Text('Nouvelle consultation'),
          ),
        ),
        if (widget.history.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
            child: GlowFocusField(
              borderRadius: AppRadius.pill,
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  hintText: 'Rechercher…',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
            ),
          ),
        Expanded(
          child: widget.history.isEmpty
              ? const _EmptyHistory(padding: EdgeInsets.all(AppSpacing.md))
              : filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Center(
                        child: Text(
                          'Aucune consultation ne correspond à « $_query ».',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    )
                  : _buildSectionedList(sections),
        ),
      ],
    );
  }

  Widget _buildSectionedList(List<MapEntry<String, List<Conversation>>> sections) {
    var index = 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      children: [
        for (final section in sections) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.sm, AppSpacing.xs, AppSpacing.xs),
            child: Text(
              section.key,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          for (final conversation in section.value)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: EntranceFadeSlide(
                index: index++,
                child: _ConversationTile(
                  conversation: conversation,
                  active: conversation.id == widget.activeId,
                  onTap: () => widget.onSelect(conversation.id),
                  onDelete: () => _confirmDelete(context, conversation),
                  onRename: () => _promptRename(context, conversation),
                ),
              ),
            ),
        ],
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
    if (confirmed == true) widget.onDelete(conversation.id);
  }

  Future<void> _promptRename(BuildContext context, Conversation conversation) async {
    final controller = TextEditingController(text: conversation.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Renommer la consultation'),
        content: TextField(controller: controller, autofocus: true, maxLength: 60),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newTitle != null && newTitle.isNotEmpty) widget.onRename(conversation.id, newTitle);
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
    required this.onRename,
  });

  final Conversation conversation;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;

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
              tooltip: 'Renommer',
              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
              onPressed: onRename,
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
