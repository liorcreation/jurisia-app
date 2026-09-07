import 'package:flutter/material.dart';

import '../../../core/entitlements/entitlement_feature.dart';
import '../../../core/entitlements/plan.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/widgets/entrance_fade.dart';
import '../../../core/widgets/luxury_scaffold_background.dart';
import '../../../features/contact_professional/domain/entities/contact_request.dart';
import '../../../theme/app_theme.dart';
import '../../auth/staff_role.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_ambience.dart';
import '../../widgets/admin_bar_row.dart';
import '../../widgets/admin_donut_chart.dart';
import '../../widgets/admin_empty_state.dart';
import '../../widgets/admin_page_header.dart';
import '../../widgets/admin_section_card.dart';
import '../../widgets/admin_stat_card.dart';
import '../../widgets/admin_status_chip.dart';

/// Un instantané du cockpit : tout ce que le tableau de bord affiche,
/// rassemblé en un seul aller-retour réseau pour n'avoir qu'un état de
/// chargement, jamais trois indicateurs qui apparaissent en cascade.
class _DashboardSnapshot {
  const _DashboardSnapshot({
    required this.contactStatusCounts,
    required this.subscriptionCounts,
    required this.usageThisMonth,
  });

  /// Nombre de demandes de mise en relation par statut.
  final Map<ContactRequestStatus, int> contactStatusCounts;

  /// Nombre d'abonnements payants par offre, tous statuts confondus sauf
  /// résiliés (`canceled`).
  final Map<PlanCode, int> subscriptionCounts;

  /// Somme de la consommation du mois en cours, par fonctionnalité, tous
  /// comptes confondus.
  final Map<String, int> usageThisMonth;

  int get pending => contactStatusCounts[ContactRequestStatus.pending] ?? 0;
  int get handled =>
      (contactStatusCounts[ContactRequestStatus.contacted] ?? 0) +
      (contactStatusCounts[ContactRequestStatus.closed] ?? 0);
  int get activeSubscriptions => subscriptionCounts.values.fold(0, (a, b) => a + b);
  int get totalUsage => usageThisMonth.values.fold(0, (a, b) => a + b);
}

/// Console — Tableau de bord. Un aperçu réel de l'activité — demandes de
/// mise en relation, répartition des abonnements payants, consommation IA
/// du mois — construit à partir des tables déjà accessibles au personnel
/// (RLS `jurisia_is_staff()`, migration_008). Pas encore de séries
/// temporelles ni de coût IA converti en F CFA : la matière première
/// (`usage_events`) est en place, ce sera le prochain incrément du cockpit.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key, required this.identity});

  final StaffIdentity identity;

  Future<_DashboardSnapshot> _load() async {
    final client = SupabaseConfig.client;
    final now = DateTime.now();
    final period = DateTime(now.year, now.month, 1).toIso8601String().split('T').first;

    final results = await Future.wait([
      client.from('professional_contact_requests').select('status').limit(5000),
      client.from('subscriptions').select('plan_code, status').limit(5000),
      client.from('usage_counters').select('feature, used').eq('period', period).limit(5000),
    ]);

    final contactCounts = {for (final status in ContactRequestStatus.values) status: 0};
    for (final row in results[0] as List) {
      final status = ContactRequestStatus.fromName((row as Map)['status'] as String? ?? '');
      contactCounts[status] = (contactCounts[status] ?? 0) + 1;
    }

    final subscriptionCounts = <PlanCode, int>{};
    for (final row in results[1] as List) {
      final map = row as Map;
      if (map['status'] == 'canceled') continue;
      final code = PlanCodeName.fromName(map['plan_code'] as String?);
      if (code == PlanCode.decouverte) continue; // hors offre gratuite implicite
      subscriptionCounts[code] = (subscriptionCounts[code] ?? 0) + 1;
    }

    final usageTotals = <String, int>{};
    for (final row in results[2] as List) {
      final map = row as Map;
      final feature = map['feature'] as String? ?? '—';
      final used = (map['used'] as num?)?.toInt() ?? 0;
      usageTotals[feature] = (usageTotals[feature] ?? 0) + used;
    }

    return _DashboardSnapshot(
      contactStatusCounts: contactCounts,
      subscriptionCounts: subscriptionCounts,
      usageThisMonth: usageTotals,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              AdminPageHeader(
                icon: Icons.dashboard_rounded,
                title: 'Tableau de bord',
                subtitle: 'Connecté en tant que ${identity.primary?.label ?? 'membre du personnel'}.',
              ),
              Expanded(
                child: Stack(
                  children: [
                    const Positioned.fill(child: IgnorePointer(child: AdminAmbience())),
                    FutureBuilder<_DashboardSnapshot>(
                      future: _load(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return const AdminEmptyState(
                            icon: Icons.cloud_off_rounded,
                            message: 'Chargement impossible.',
                            detail: 'Vérifiez les droits ou l\'état des migrations 007/008.',
                          );
                        }
                        final data = snapshot.data!;
                        return _DashboardBody(data: data);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.data});

  final _DashboardSnapshot data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _KpiRow(data: data, wide: wide),
              const SizedBox(height: AppSpacing.lg),
              if (wide)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 5,
                        child: EntranceFadeSlide(index: 1, child: _ContactStatusSection(data: data)),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        flex: 4,
                        child: EntranceFadeSlide(index: 2, child: _SubscriptionsSection(data: data)),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        flex: 4,
                        child: EntranceFadeSlide(index: 3, child: _UsageSection(data: data)),
                      ),
                    ],
                  ),
                )
              else ...[
                EntranceFadeSlide(index: 1, child: _ContactStatusSection(data: data)),
                const SizedBox(height: AppSpacing.lg),
                EntranceFadeSlide(index: 2, child: _SubscriptionsSection(data: data)),
                const SizedBox(height: AppSpacing.lg),
                EntranceFadeSlide(index: 3, child: _UsageSection(data: data)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.data, required this.wide});

  final _DashboardSnapshot data;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final cards = [
      AdminStatCard(
        icon: Icons.hourglass_top_rounded,
        label: 'Demandes en attente',
        value: '${data.pending}',
        accentColor: AppColors.warning,
      ),
      AdminStatCard(
        icon: Icons.task_alt_rounded,
        label: 'Demandes traitées',
        value: '${data.handled}',
        accentColor: AppColors.success,
      ),
      AdminStatCard(
        icon: Icons.credit_card_rounded,
        label: 'Abonnements payants actifs',
        value: '${data.activeSubscriptions}',
        accentColor: AdminTheme.accent,
      ),
      AdminStatCard(
        icon: Icons.bolt_rounded,
        label: 'Consommation IA — ce mois',
        value: '${data.totalUsage}',
        accentColor: AppColors.metalRoseGold,
      ),
    ];

    if (!wide) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: EntranceFadeSlide(index: i, child: cards[i]),
            ),
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.md),
            Expanded(child: EntranceFadeSlide(index: i, child: cards[i])),
          ],
        ],
      ),
    );
  }
}

class _ContactStatusSection extends StatelessWidget {
  const _ContactStatusSection({required this.data});

  final _DashboardSnapshot data;

  static const _statusColors = {
    ContactRequestStatus.pending: AppColors.warning,
    ContactRequestStatus.contacted: AdminTheme.accentLight,
    ContactRequestStatus.closed: AppColors.success,
  };

  @override
  Widget build(BuildContext context) {
    final segments = [
      for (final status in ContactRequestStatus.values)
        AdminDonutSegment(
          label: status.label,
          value: (data.contactStatusCounts[status] ?? 0).toDouble(),
          color: _statusColors[status]!,
        ),
    ];

    return AdminSectionCard(
      title: 'Demandes de mise en relation',
      icon: Icons.forum_rounded,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AdminDonutChart(segments: segments),
          const SizedBox(width: AppSpacing.lg),
          Expanded(child: AdminDonutLegend(segments: segments)),
        ],
      ),
    );
  }
}

class _SubscriptionsSection extends StatelessWidget {
  const _SubscriptionsSection({required this.data});

  final _DashboardSnapshot data;

  @override
  Widget build(BuildContext context) {
    final counts = data.subscriptionCounts;
    final maxValue = counts.values.isEmpty ? 0 : counts.values.reduce((a, b) => a > b ? a : b);

    return AdminSectionCard(
      title: 'Abonnements payants actifs',
      icon: Icons.credit_card_rounded,
      trailing: AdminStatusChip(label: '${data.activeSubscriptions}', color: AdminTheme.accent),
      child: counts.isEmpty
          ? Text(
              'Aucun abonnement payant pour l\'instant.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final code in PlanCode.values)
                  if (counts.containsKey(code))
                    AdminBarRow(
                      label: PlanCatalog.of(code).name,
                      value: counts[code]!,
                      maxValue: maxValue,
                      color: AdminTheme.accent,
                    ),
              ],
            ),
    );
  }
}

class _UsageSection extends StatelessWidget {
  const _UsageSection({required this.data});

  final _DashboardSnapshot data;

  @override
  Widget build(BuildContext context) {
    final usage = data.usageThisMonth;
    final maxValue = usage.values.isEmpty ? 0 : usage.values.reduce((a, b) => a > b ? a : b);

    return AdminSectionCard(
      title: 'Consommation IA — ce mois-ci',
      icon: Icons.bolt_rounded,
      trailing: AdminStatusChip(label: '${data.totalUsage}', color: AppColors.metalRoseGold),
      child: usage.isEmpty
          ? Text(
              'Aucune consommation mesurée pour l\'instant.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final entry in usage.entries)
                  AdminBarRow(
                    label: EntitlementFeature.label(entry.key),
                    value: entry.value,
                    maxValue: maxValue,
                    color: AppColors.metalRoseGold,
                  ),
              ],
            ),
    );
  }
}
