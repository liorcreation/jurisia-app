import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/billing/billing_controller.dart';
import '../../../../core/billing/billing_providers.dart';
import '../../../../core/entitlements/entitlement_feature.dart';
import '../../../../core/entitlements/entitlements_controller.dart';
import '../../../../core/entitlements/plan.dart';
import '../../../../core/entitlements/quota_state.dart';
import '../../../../core/platform/app_platform_style.dart';
import '../../../../core/widgets/entrance_fade.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/gradient_icon_badge.dart';
import '../../../../core/widgets/luxury_scaffold_background.dart';
import '../../../../core/widgets/shimmer_sweep.dart';
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

    if (AppPlatformStyle.of(context) == AppPlatformStyle.desktop) {
      return _DesktopSubscriptionView(entitlements: entitlements, billing: billing);
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

// ===========================================================================
//  DESKTOP — « Passez à la vitesse supérieure »
// ===========================================================================

({IconData icon, Color tint}) _planStyle(PlanCode code) {
  switch (code) {
    case PlanCode.decouverte:
      return (icon: Icons.explore_rounded, tint: AppColors.metalSilver);
    case PlanCode.plus:
      return (icon: Icons.workspace_premium_rounded, tint: AppColors.metalDeepGold);
    case PlanCode.etudiant:
      return (icon: Icons.school_rounded, tint: AppColors.metalEmerald);
    case PlanCode.pro:
      return (icon: Icons.design_services_rounded, tint: AppColors.metalCobalt);
    case PlanCode.cabinet:
      return (icon: Icons.domain_rounded, tint: AppColors.metalGunmetal);
  }
}

/// L'offre mise en avant : la montée en gamme grand public.
const _recommendedPlan = PlanCode.plus;

String _nextResetLabel(DateTime now) {
  const months = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];
  final month = now.month == 12 ? 0 : now.month;
  return '1er ${months[month]}';
}

class _DesktopSubscriptionView extends StatelessWidget {
  const _DesktopSubscriptionView({required this.entitlements, required this.billing});

  final EntitlementsController entitlements;
  final BillingController billing;

  @override
  Widget build(BuildContext context) {
    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(child: IgnorePointer(child: _PlansAmbience())),
              Column(
                children: [
                  const _DesktopSubscriptionHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1180),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.xl,
                              AppSpacing.xl,
                              AppSpacing.xl,
                              AppSpacing.xxl,
                            ),
                            child: _SubscriptionBody(
                              entitlements: entitlements,
                              billing: billing,
                            ),
                          ),
                        ),
                      ),
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

class _DesktopSubscriptionHeader extends StatelessWidget {
  const _DesktopSubscriptionHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.smokedGlass,
        border: Border(
          bottom: BorderSide(color: AppColors.gold.withValues(alpha: 0.18), width: 0.6),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Retour',
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(Icons.workspace_premium_rounded, size: 18, color: AppColors.gold),
          const SizedBox(width: AppSpacing.sm),
          Text('Mon abonnement', style: textTheme.headlineSmall),
        ],
      ),
    );
  }
}

class _SubscriptionBody extends StatelessWidget {
  const _SubscriptionBody({required this.entitlements, required this.billing});

  final EntitlementsController entitlements;
  final BillingController billing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final current = entitlements.definition;

    Widget planRow(List<PlanDefinition> plans) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final stack = constraints.maxWidth < 720 && plans.length > 1;
          if (stack) {
            return Column(
              children: [
                for (var i = 0; i < plans.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: i == plans.length - 1 ? 0 : AppSpacing.md),
                    child: _DesktopPlanCard(
                      plan: plans[i],
                      isCurrent: plans[i].code == current.code,
                      recommended: plans[i].code == _recommendedPlan,
                      busy: billing.pendingPlan == plans[i].code,
                      anyBusy: billing.isBusy,
                      onChoose: () => billing.choosePlan(plans[i].code),
                    ),
                  ),
              ],
            );
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < plans.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: EntranceFadeSlide(
                      index: i,
                      child: _DesktopPlanCard(
                        plan: plans[i],
                        isCurrent: plans[i].code == current.code,
                        recommended: plans[i].code == _recommendedPlan,
                        busy: billing.pendingPlan == plans[i].code,
                        anyBusy: billing.isBusy,
                        onChoose: () => billing.choosePlan(plans[i].code),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow('Mon abonnement'),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Passez à la vitesse supérieure',
          style: textTheme.displaySmall?.copyWith(fontFamily: 'Libre Caslon Display'),
        ),
        const SizedBox(height: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Text(
            'Votre offre actuelle, votre consommation du mois, et le catalogue complet. '
            'Le changement d\'offre est immédiat ; vous gardez tout votre historique.',
            style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary, height: 1.5),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _AccountBand(entitlements: entitlements),
        const SizedBox(height: AppSpacing.xxl),
        const _Eyebrow('Pour vous'),
        const SizedBox(height: AppSpacing.md),
        planRow(const [PlanCatalog.decouverte, PlanCatalog.plus, PlanCatalog.etudiant]),
        const SizedBox(height: AppSpacing.xl),
        const _Eyebrow('Pour les praticiens et les cabinets'),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: planRow(const [PlanCatalog.pro, PlanCatalog.cabinet]),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const _PaymentNote(),
      ],
    );
  }
}

class _AccountBand extends StatelessWidget {
  const _AccountBand({required this.entitlements});

  final EntitlementsController entitlements;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final plan = entitlements.definition;
    final style = _planStyle(plan.code);
    final resetLabel = _nextResetLabel(DateTime.now());

    final currentTile = GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: AppColors.gold.withValues(alpha: 0.4),
      borderWidth: 0.9,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GradientIconBadge(icon: style.icon, size: 42),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Offre actuelle',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.goldLight,
                        letterSpacing: AppLetterSpacing.label,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      plan.name,
                      style: textTheme.titleMedium?.copyWith(fontFamily: 'Libre Caslon Display'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            plan.tagline,
            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const Spacer(),
          const SizedBox(height: AppSpacing.sm),
          Text(
            plan.priceLabel,
            style: textTheme.titleSmall?.copyWith(
              color: AppColors.goldLight,
              fontWeight: FontWeight.w700,
              fontFeatures: const [],
            ),
          ),
        ],
      ),
    );

    final meters = [
      EntitlementFeature.litigeConsultations,
      EntitlementFeature.contactRequests,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 820;
        final children = <Widget>[
          SizedBox(width: wide ? 300 : double.infinity, child: currentTile),
          for (final feature in meters)
            wide
                ? Expanded(
                    child: _DesktopUsageMeter(
                      label: EntitlementFeature.label(feature),
                      state: entitlements.quotaFor(feature),
                      resetLabel: resetLabel,
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    child: _DesktopUsageMeter(
                      label: EntitlementFeature.label(feature),
                      state: entitlements.quotaFor(feature),
                      resetLabel: resetLabel,
                    ),
                  ),
        ];

        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: i == children.length - 1 ? 0 : AppSpacing.md),
                  child: children[i],
                ),
            ],
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.md),
                children[i],
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DesktopUsageMeter extends StatelessWidget {
  const _DesktopUsageMeter({
    required this.label,
    required this.state,
    required this.resetLabel,
  });

  final String label;
  final QuotaState state;
  final String resetLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final fraction = state.fraction;
    final nearLimit = fraction != null && fraction >= 0.8;
    final meterColor = nearLimit ? AppColors.warning : AppColors.gold;

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: AppLetterSpacing.label,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (state.isUnlimited)
            Row(
              children: [
                const Icon(Icons.all_inclusive_rounded, size: 20, color: AppColors.goldLight),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Illimité',
                  style: textTheme.titleMedium?.copyWith(
                    fontFamily: 'Libre Caslon Display',
                    color: AppColors.goldLight,
                  ),
                ),
              ],
            )
          else ...[
            RichText(
              text: TextSpan(
                style: textTheme.headlineSmall?.copyWith(fontFamily: 'Libre Caslon Display'),
                children: [
                  TextSpan(text: '${state.used}'),
                  TextSpan(
                    text: '  /  ${state.limit}',
                    style: textTheme.titleSmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Stack(
                children: [
                  Container(height: 7, color: AppColors.legalBlueDark),
                  FractionallySizedBox(
                    widthFactor: (fraction ?? 0).clamp(0.02, 1.0),
                    child: Container(
                      height: 7,
                      decoration: BoxDecoration(
                        gradient: nearLimit
                            ? null
                            : AppGradients.goldMetallic,
                        color: nearLimit ? meterColor : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              state.isExhausted
                  ? 'Quota atteint — se réinitialise le $resetLabel'
                  : '${state.remaining} restante${(state.remaining ?? 0) > 1 ? 's' : ''} · '
                        'réinitialisation le $resetLabel',
              style: textTheme.labelSmall?.copyWith(
                color: state.isExhausted ? AppColors.warning : AppColors.textDisabled,
              ),
            ),
          ],
          if (state.isUnlimited) ...[
            const Spacer(),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Aucune limite mensuelle sur votre offre.',
              style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled),
            ),
          ],
        ],
      ),
    );
  }
}

class _DesktopPlanCard extends StatefulWidget {
  const _DesktopPlanCard({
    required this.plan,
    required this.isCurrent,
    required this.recommended,
    required this.busy,
    required this.anyBusy,
    required this.onChoose,
  });

  final PlanDefinition plan;
  final bool isCurrent;
  final bool recommended;
  final bool busy;
  final bool anyBusy;
  final VoidCallback onChoose;

  @override
  State<_DesktopPlanCard> createState() => _DesktopPlanCardState();
}

class _DesktopPlanCardState extends State<_DesktopPlanCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final plan = widget.plan;
    final style = _planStyle(plan.code);
    final featured = widget.recommended && !widget.isCurrent;

    final Color border;
    if (widget.isCurrent) {
      border = AppColors.gold.withValues(alpha: 0.55);
    } else if (featured) {
      border = AppColors.gold.withValues(alpha: 0.7);
    } else if (_hovered) {
      border = style.tint.withValues(alpha: 0.5);
    } else {
      border = style.tint.withValues(alpha: 0.22);
    }

    Widget badge = GradientIconBadge(
      icon: style.icon,
      size: 44,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(style.tint, Colors.white, 0.35)!,
          style.tint,
          Color.lerp(style.tint, AppColors.nightBlueDeep, 0.35)!,
        ],
      ),
    );
    if (featured) {
      badge = ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: ShimmerSweep(duration: const Duration(milliseconds: 2000), child: badge),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedSlide(
        offset: featured || _hovered ? const Offset(0, -0.015) : Offset.zero,
        duration: const Duration(milliseconds: 160),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            boxShadow: featured ? AppShadows.goldGlow : null,
          ),
          child: GlassContainer(
            borderColor: border,
            borderWidth: widget.isCurrent || featured ? 1.1 : 0.6,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    badge,
                    const Spacer(),
                    if (widget.isCurrent)
                      _Pill(label: 'Offre actuelle', color: AppColors.goldLight)
                    else if (widget.recommended)
                      _Pill(label: 'Recommandé', color: AppColors.gold, filled: true),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  plan.name,
                  style: textTheme.titleLarge?.copyWith(fontFamily: 'Libre Caslon Display'),
                ),
                const SizedBox(height: 4),
                Text(
                  plan.tagline,
                  style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.35),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  plan.priceLabel,
                  style: textTheme.headlineSmall?.copyWith(
                    fontFamily: 'Libre Caslon Display',
                    color: plan.isFree ? AppColors.textPrimary : AppColors.goldLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Divider(color: AppColors.gold.withValues(alpha: 0.15), height: 1),
                const SizedBox(height: AppSpacing.md),
                for (final line in plan.highlights)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2.5),
                          child: Icon(Icons.check_rounded, size: 13, color: style.tint),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            line,
                            style: textTheme.bodySmall?.copyWith(height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                const SizedBox(height: AppSpacing.md),
                SizedBox(width: double.infinity, child: _PlanAction(widget: widget)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanAction extends StatelessWidget {
  const _PlanAction({required this.widget});

  final _DesktopPlanCard widget;

  void _contactSales(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(widget.plan.name),
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (widget.isCurrent) {
      return OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13)),
        child: const Text('Votre offre'),
      );
    }
    if (!widget.plan.isPurchasable) {
      return OutlinedButton.icon(
        onPressed: widget.anyBusy ? null : () => _contactSales(context),
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13)),
        icon: const Icon(Icons.mail_outline_rounded, size: 16),
        label: const Text('Nous contacter'),
      );
    }
    return FilledButton.icon(
      onPressed: widget.anyBusy ? null : widget.onChoose,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.nightBlueDeep,
        padding: const EdgeInsets.symmetric(vertical: 13),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      icon: widget.busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.nightBlueDeep),
            )
          : const Icon(Icons.arrow_forward_rounded, size: 17),
      label: Text(widget.busy ? 'Redirection…' : 'Choisir cette offre'),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, this.filled = false});

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: filled ? 1 : 0.45), width: 0.8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: filled ? AppColors.nightBlueDeep : color,
              fontWeight: FontWeight.w800,
              letterSpacing: AppLetterSpacing.label,
            ),
      ),
    );
  }
}

class _PaymentNote extends StatelessWidget {
  const _PaymentNote();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.2), width: 0.7),
      ),
      child: Row(
        children: [
          const Icon(Icons.payments_rounded, size: 16, color: AppColors.goldLight),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Paiement par Mobile Money (Orange, Moov) ou carte bancaire. Résiliable à tout '
              'moment. JurisIA Cabinet se souscrit sur devis, avec facture OHADA.',
              style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 1, color: AppColors.gold.withValues(alpha: 0.6)),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.goldLight,
                  letterSpacing: AppLetterSpacing.caps,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

/// Fines poussières d'or en suspension — la respiration « vivante » du
/// registre desktop.
class _PlansAmbience extends StatefulWidget {
  const _PlansAmbience();

  @override
  State<_PlansAmbience> createState() => _PlansAmbienceState();
}

class _PlansAmbienceState extends State<_PlansAmbience> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 34))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(painter: _PlansAmbiencePainter(_controller.value)),
    );
  }
}

class _PlansAmbiencePainter extends CustomPainter {
  const _PlansAmbiencePainter(this.t);

  final double t;
  static const int _count = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < _count; i++) {
      final seed = i * 51.0;
      final baseX = seed % size.width;
      final drift = math.sin((t * 2 * math.pi) + seed) * 24;
      final x = (baseX + drift) % size.width;
      final y = (size.height * ((i / _count) + t) % 1.0);
      final radius = 0.8 + (i % 3) * 0.7;
      final opacity = 0.05 + 0.09 * (0.5 + 0.5 * math.sin((t * 2 * math.pi) + seed * 1.7));
      paint.color = AppColors.goldLight.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PlansAmbiencePainter oldDelegate) => oldDelegate.t != t;
}
