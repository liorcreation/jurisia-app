import 'package:flutter/material.dart';

import '../../features/contact_professional/domain/entities/contact_request.dart';
import '../../theme/app_theme.dart';
import '../features/library_cms/admin_document_draft.dart';
import '../features/prompt_studio/admin_ai_prompt.dart';
import '../theme/admin_theme.dart';

/// Pastille de statut standard de la console : pastille de couleur (ou
/// icône) + libellé, contour et fond dérivés de la même couleur. Une seule
/// implémentation pour tous les statuts (demandes, brouillons, prompts,
/// abonnements) — seule la couleur change, choisie par les fonctions
/// ci-dessous plutôt que semée à la main dans chaque écran.
class AdminStatusChip extends StatelessWidget {
  const AdminStatusChip({super.key, required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 12, color: color)
          else
            Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

Color contactStatusColor(ContactRequestStatus status) => switch (status) {
      ContactRequestStatus.pending => AppColors.warning,
      ContactRequestStatus.contacted => AdminTheme.accentLight,
      ContactRequestStatus.closed => AppColors.success,
    };

Color draftStatusColor(DocumentDraftStatus status) => switch (status) {
      DocumentDraftStatus.draft => AppColors.textSecondary,
      DocumentDraftStatus.inReview => AdminTheme.accentLight,
      DocumentDraftStatus.changesRequested => AppColors.warning,
      DocumentDraftStatus.published => AppColors.success,
      DocumentDraftStatus.archived => AppColors.textDisabled,
    };

Color promptStatusColor(AiPromptStatus status) => switch (status) {
      AiPromptStatus.draft => AppColors.textSecondary,
      AiPromptStatus.tested => AdminTheme.accentLight,
      AiPromptStatus.published => AppColors.success,
      AiPromptStatus.archived => AppColors.textDisabled,
    };

Color subscriptionStatusColor(String? status) => switch (status) {
      'active' => AppColors.success,
      'trialing' => AdminTheme.accentLight,
      'past_due' => AppColors.warning,
      'canceled' => AppColors.textDisabled,
      _ => AppColors.textSecondary,
    };
