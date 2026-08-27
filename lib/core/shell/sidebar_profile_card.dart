import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/litigation/presentation/controllers/litigation_chat_controller.dart';
import '../../features/profile/presentation/controllers/profile_controller.dart';
import '../widgets/glass_container.dart';
import '../../theme/app_theme.dart';
import 'profile_monogram.dart';
import 'profile_sheet.dart';

/// Carte profil en pied de sidebar — le point d'orgue « ultra premium » :
/// monogramme métallique animé, nom en serif, rôle, et compteur d'activité
/// du mois. Tap → feuille profil (édition, mentions légales, déconnexion).
class SidebarProfileCard extends StatelessWidget {
  const SidebarProfileCard({super.key, this.compact = false});

  final bool compact;

  int _consultationsThisMonth(BuildContext context) {
    final history = context.watch<LitigationChatController>().history;
    final now = DateTime.now();
    return history
        .where((c) => c.updatedAt.year == now.year && c.updatedAt.month == now.month)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>().profile;

    if (compact) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Tooltip(
          message: profile?.displayName ?? 'Mon compte',
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => showProfileSheet(context),
            child: ProfileMonogram(profile: profile, size: 36),
          ),
        ),
      );
    }

    final textTheme = Theme.of(context).textTheme;
    final count = _consultationsThisMonth(context);

    return GlassContainer(
      onTap: () => showProfileSheet(context),
      borderRadius: AppRadius.medium,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          ProfileMonogram(profile: profile, size: 40),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  profile?.displayName ?? 'Mon compte',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(fontFamily: 'Libre Caslon Display'),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppGradients.goldSheen),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        profile?.roleLabel ?? 'Compte JurisIA',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(color: AppColors.goldLight),
                      ),
                    ),
                  ],
                ),
                if (count > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    count == 1 ? '1 consultation ce mois' : '$count consultations ce mois',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.unfold_more_rounded, size: 18, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
