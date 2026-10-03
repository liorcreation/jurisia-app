import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/litigation/presentation/controllers/litigation_chat_controller.dart';
import '../../features/profile/presentation/controllers/profile_controller.dart';
import '../../features/subscription/presentation/screens/subscription_screen.dart';
import '../entitlements/entitlements_controller.dart';
import '../entitlements/plan.dart';
import '../widgets/glass_container.dart';
import '../widgets/tap_scale.dart';
import '../../theme/app_theme.dart';
import 'profile_monogram.dart';
import 'profile_sheet.dart';

/// Carte profil en pied de sidebar — le point d'orgue « ultra premium » :
/// monogramme métallique animé, nom en serif, rôle, compteur d'activité du
/// mois, et un bouton « Mettre à niveau » vers l'offre supérieure. Tap sur la
/// carte → feuille profil (édition, mentions légales, déconnexion).
class SidebarProfileCard extends StatelessWidget {
  const SidebarProfileCard({super.key, this.compact = false});

  final bool compact;

  int _consultationsThisMonth(BuildContext context) {
    final history = context.watch<LitigationChatController>().history;
    final now = DateTime.now();
    return history.where((c) => c.updatedAt.year == now.year && c.updatedAt.month == now.month).length;
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>().profile;

    final entitlements = context.watch<EntitlementsController>();
    final canUpgrade = entitlements.plan != PlanCode.cabinet;

    if (compact) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canUpgrade) ...[
              _UpgradeButton(entitlements: entitlements, compact: true),
              const SizedBox(height: AppSpacing.sm),
            ],
            Tooltip(
              message: profile?.displayName ?? 'Mon compte',
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => showProfileSheet(context),
                  child: ProfileMonogram(profile: profile, size: 36),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final textTheme = Theme.of(context).textTheme;
    final count = _consultationsThisMonth(context);

    return GlassContainer(
      onTap: () => showProfileSheet(context),
      borderRadius: AppRadius.medium,
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: AppColors.gold.withValues(alpha: 0.30),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xD9162233), Color(0xE6090E18)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ProfileMonogram(profile: profile, size: 44),
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
                      style: textTheme.titleSmall?.copyWith(
                        fontFamily: 'Libre Caslon Display',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile?.roleLabel ?? 'Compte JurisIA',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            entitlements.definition.name.replaceFirst('JurisIA ', ''),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.goldLight,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.glassHighlight,
                  border: Border.all(color: AppColors.glassBorder, width: 0.7),
                ),
                child: const Icon(Icons.arrow_outward_rounded, size: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: _ProfileCardDivider(),
          ),
          Row(
            children: [
              const Icon(Icons.forum_outlined, size: 14, color: AppColors.cobaltLight),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Consultations ce mois',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                ),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 26),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.cobalt.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.cobaltLight.withValues(alpha: 0.28)),
                ),
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (canUpgrade) ...[const SizedBox(height: AppSpacing.md), _UpgradeButton(entitlements: entitlements)],
        ],
      ),
    );
  }
}

class _ProfileCardDivider extends StatelessWidget {
  const _ProfileCardDivider();

  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.transparent,
          AppColors.gold.withValues(alpha: 0.30),
          AppColors.cobaltLight.withValues(alpha: 0.20),
          Colors.transparent,
        ],
      ),
    ),
  );
}

/// Bouton « Mettre à niveau » — pilule de verre à liseré d'or sur la carte
/// profil dépliée, pastille d'or ronde dans le rail replié. Ouvre l'écran
/// des offres dans les deux cas, pour que la montée en gamme reste toujours
/// à un clic.
class _UpgradeButton extends StatefulWidget {
  const _UpgradeButton({required this.entitlements, this.compact = false});

  final EntitlementsController entitlements;
  final bool compact;

  @override
  State<_UpgradeButton> createState() => _UpgradeButtonState();
}

class _UpgradeButtonState extends State<_UpgradeButton> {
  bool _hovered = false;

  void _open() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<EntitlementsController>.value(
          value: widget.entitlements,
          child: const SubscriptionScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goldFill = LinearGradient(
      colors: _hovered
          ? [AppColors.gold.withValues(alpha: 0.30), AppColors.gold.withValues(alpha: 0.15)]
          : [AppColors.gold.withValues(alpha: 0.16), AppColors.gold.withValues(alpha: 0.06)],
    );

    if (widget.compact) {
      return MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Tooltip(
          message: 'Mettre à niveau',
          child: TapScale(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _open,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: goldFill,
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.6), width: 0.8),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, size: 15, color: AppColors.goldLight),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: _open,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 7),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              gradient: goldFill,
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.55), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 13, color: AppColors.goldLight),
                const SizedBox(width: 6),
                Text(
                  'Mettre à niveau',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
