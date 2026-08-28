import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/billing/billing_controller.dart';
import '../../../../core/billing/billing_providers.dart';
import '../../../../core/entitlements/entitlement_feature.dart';
import '../../../../core/entitlements/entitlements_controller.dart';
import '../../../../core/entitlements/plan.dart';
import '../../../../core/entitlements/quota_state.dart';
import '../../../../core/widgets/entrance_fade.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/gradient_icon_badge.dart';
import '../../../../core/widgets/luxury_scaffold_background.dart';
import '../../../../theme/app_theme.dart';

/// Écran « Mon abonnement » : l'offre en cours, les jauges d'usage du mois,
/// et le catalogue complet des offres avec passage à une offre payante
/// (Mobile Money / carte via l'Edge Function `billing-checkout`).
///
/// À ouvrir en réinjectant le [EntitlementsController] de la coquille via
/// `ChangeNotifierProvider.value`, car une route poussée sur le navigateur
/// racine ne descend pas de [AppShell].
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entitlements = context.read<EntitlementsController>();

    return ChangeNotifierProvider<BillingController>(
      create: (_) => BillingController(
        repository: buildBillingRepository(),
        onActivated: entitlements.refresh,
      ),
      child: const _SubscriptionView(),
    );
  }
}

class _SubscriptionView extends StatelessWidget {
  const _SubscriptionView();

  @override
  Widget build(BuildContext context) {
    final entitlements = context.watch<EntitlementsController>();
    final billing = context.watch<BillingController>();
    final current = entitlements.definition;

    final message = billing.error ?? billing.info;
    if (message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        billing.clearMessages();
      });
    }

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Mon abonnement')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _CurrentPlanCard(plan: current),
              const SizedBox(height: AppSpacing.lg),
              _UsageSection(entitlements: entitlements),
              const SizedBox(height: AppSpacing.lg),
              Text('Toutes les offres', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              for (var i = 0; i < PlanCatalog.all.length; i++)
                EntranceFadeSlide(
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _PlanCard(
                      plan: PlanCatalog.all[i],
                      isCurrent: PlanCatalog.all[i].code == current.code,
                      busy: billing.pendingPlan == PlanCatalog.all[i].code,
                      anyBusy: billing.isBusy,
                      onChoose: () => billing.choosePlan(PlanCatalog.all[i].code),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textDisabled),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Paiement par Mobile Money (Orange, Moov) et carte. '
                      'JurisIA Cabinet se souscrit sur devis.',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.textDisabled),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({required this.plan});

  final PlanDefinition plan;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isPremium = !plan.isFree;

    return GlassContainer(
      borderColor: isPremium ? AppColors.gold : AppColors.glassBorder,
      borderWidth: isPremium ? 1 : 0.5,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GradientIconBadge(
                icon: isPremium ? Icons.workspace_premium_rounded : Icons.explore_rounded,
                size: 46,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: textTheme.titleLarge?.copyWith(fontFamily: 'Libre Caslon Display'),
                    ),
                    Text(plan.tagline, style: textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Text(
              'Offre actuelle',
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.goldLight,
                fontWeight: FontWeight.w700,
                letterSpacing: AppLetterSpacing.label,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageSection extends StatelessWidget {
  const _UsageSection({required this.entitlements});

  final EntitlementsController entitlements;

  @override
  Widget build(BuildContext context) {
    const tracked = [
      EntitlementFeature.litigeConsultations,
      EntitlementFeature.contactRequests,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ce mois-ci', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        for (final feature in tracked)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _UsageMeter(
              label: EntitlementFeature.label(feature),
              state: entitlements.quotaFor(feature),
            ),
          ),
      ],
    );
  }
}

class _UsageMeter extends StatelessWidget {
  const _UsageMeter({required this.label, required this.state});

  final String label;
  final QuotaState state;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final fraction = state.fraction;
    final valueLabel = state.isUnlimited ? 'Illimité' : '${state.used} / ${state.limit}';
    final nearLimit = fraction != null && fraction >= 0.8;

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary)),
              Text(
                valueLabel,
                style: textTheme.labelMedium?.copyWith(
                  color: nearLimit ? AppColors.warning : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (fraction != null) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: AppColors.legalBlueDark,
                valueColor: AlwaysStoppedAnimation(
                  nearLimit ? AppColors.warning : AppColors.gold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.busy,
    required this.anyBusy,
    required this.onChoose,
  });

  final PlanDefinition plan;
  final bool isCurrent;
  final bool busy;
  final bool anyBusy;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final highlight = !plan.isFree;

    return GlassContainer(
      borderColor: isCurrent
          ? AppColors.gold
          : (highlight ? AppColors.glassBorder : AppColors.divider),
      borderWidth: isCurrent ? 1 : 0.5,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: textTheme.titleMedium?.copyWith(fontFamily: 'Libre Caslon Display'),
                    ),
                    Text(plan.tagline, style: textTheme.bodySmall),
                  ],
                ),
              ),
              Text(
                plan.priceLabel,
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final line in plan.highlights)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.check_rounded, size: 14, color: AppColors.gold),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(line, style: textTheme.bodySmall)),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(width: double.infinity, child: _action(context)),
        ],
      ),
    );
  }

  Widget _action(BuildContext context) {
    if (isCurrent) {
      return const OutlinedButton(onPressed: null, child: Text('Offre actuelle'));
    }
    if (!plan.isPurchasable) {
      // JurisIA Cabinet : sur devis.
      return OutlinedButton(
        onPressed: anyBusy ? null : () => _contactSales(context),
        child: const Text('Nous contacter'),
      );
    }
    return ElevatedButton(
      onPressed: anyBusy ? null : onChoose,
      child: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Choisir cette offre'),
    );
  }

  void _contactSales(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(plan.name),
        content: const Text(
          'Écrivez-nous à contact@jurisia.app en précisant le nombre de '
          'sièges souhaités : nous préparons un devis et l\'accès délégué.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }
}
