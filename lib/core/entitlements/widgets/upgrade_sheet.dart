import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/subscription/presentation/screens/subscription_screen.dart';
import '../../platform/app_platform_style.dart';
import '../../widgets/gradient_icon_badge.dart';
import '../../widgets/luxury_elevated_button.dart';
import '../../widgets/smoked_glass_surface.dart';
import '../../../theme/app_theme.dart';
import '../entitlement_feature.dart';
import '../entitlements_controller.dart';
import '../plan.dart';

/// Affiche la feuille d'incitation à l'abonnement quand un quota de l'offre
/// gratuite est atteint : feuille modale en bas d'écran sur mobile, boîte de
/// dialogue centrée sur desktop — même traitement que la feuille profil,
/// dans le registre « verre fumé & or brossé ».
///
/// Le [EntitlementsController] de la coquille est lu ici puis réinjecté dans
/// la route « Mon abonnement », qui ne descend pas de [AppShell].
Future<void> showUpgradeSheet(BuildContext context, {required String feature}) {
  final entitlements = context.read<EntitlementsController>();
  final isDesktop = AppPlatformStyle.of(context) == AppPlatformStyle.desktop;

  final body = _UpgradeSheetBody(feature: feature, entitlements: entitlements);

  if (isDesktop) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SmokedGlassSurface(
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: AppColors.glassBorder, width: 0.6),
            child: body,
          ),
        ),
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SmokedGlassSurface(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
      border: Border.all(color: AppColors.glassBorder, width: 0.6),
      child: body,
    ),
  );
}

/// Choisit l'offre à mettre en avant selon la fonctionnalité bloquée.
PlanDefinition _suggestedPlanFor(String feature) {
  switch (feature) {
    case EntitlementFeature.proEspace:
      return PlanCatalog.pro;
    default:
      return PlanCatalog.plus;
  }
}

String _headlineFor(String feature) {
  switch (feature) {
    case EntitlementFeature.litigeConsultations:
      return 'Vous avez utilisé vos consultations du mois';
    case EntitlementFeature.contactRequests:
      return 'Vous avez utilisé votre demande du mois';
    case EntitlementFeature.proEspace:
      return "L'Espace professionnel est réservé aux offres Pro";
    default:
      return 'Cette fonctionnalité fait partie de JurisIA+';
  }
}

class _UpgradeSheetBody extends StatelessWidget {
  const _UpgradeSheetBody({required this.feature, required this.entitlements});

  final String feature;
  final EntitlementsController entitlements;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final plan = _suggestedPlanFor(feature);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const GradientIconBadge(icon: Icons.workspace_premium_rounded, size: 46),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    _headlineFor(feature),
                    style: textTheme.titleLarge?.copyWith(fontFamily: 'Libre Caslon Display'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Passez à ${plan.name} pour continuer sans limite :',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            for (final line in plan.highlights.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.check_circle_rounded, size: 16, color: AppColors.gold),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(line, style: textTheme.bodySmall)),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            LuxuryElevatedButton(
              icon: Icons.arrow_forward_rounded,
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider<EntitlementsController>.value(
                      value: entitlements,
                      child: const SubscriptionScreen(),
                    ),
                  ),
                );
              },
              child: const Text('Voir les offres'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Plus tard'),
            ),
          ],
        ),
      ),
    );
  }
}
