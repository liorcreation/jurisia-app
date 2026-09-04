import 'package:flutter/material.dart';

import '../../../core/entitlements/entitlement_feature.dart';
import '../../../core/entitlements/plan.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/luxury_scaffold_background.dart';
import '../../../features/contact_professional/domain/entities/contact_request.dart';
import '../../../theme/app_theme.dart';
import '../../auth/staff_role.dart';
import '../../theme/admin_theme.dart';

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
    final textTheme = Theme.of(context).textTheme;

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Tableau de bord')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Console d\'administration JurisIA',
                      style: textTheme.titleLarge?.copyWith(fontFamily: 'Libre Caslon Display'),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Connecté en tant que ${identity.primary?.label ?? 'membre du personnel'}.',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FutureBuilder<_DashboardSnapshot>(
                future: _load(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return GlassContainer(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        'Chargement impossible (droits ou migration 007/008).',
                        style: textTheme.bodyMedium,
                      ),
                    );
                  }
                  final data = snapshot.data!;
                  final pending = data.contactStatusCounts[ContactRequestStatus.pending] ?? 0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatTile(
                        label: 'Demandes de mise en relation en attente',
                        value: '$pending',
                        icon: Icons.support_agent_rounded,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SectionCard(
                        title: 'Demandes de mise en relation',
                        icon: Icons.forum_rounded,
                        child: Row(
                          children: [
                            for (final status in ContactRequestStatus.values) ...[
                              if (status != ContactRequestStatus.values.first)
                                const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: _MiniStat(
                                  label: status.label,
                                  value: data.contactStatusCounts[status] ?? 0,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SectionCard(
                        title: 'Abonnements payants actifs',
                        icon: Icons.credit_card_rounded,
                        child: data.subscriptionCounts.isEmpty
                            ? Text(
                                'Aucun abonnement payant pour l\'instant.',
                                style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final code in PlanCode.values)
                                    if (data.subscriptionCounts.containsKey(code))
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                                        child: _BreakdownRow(
                                          label: PlanCatalog.of(code).name,
                                          value: data.subscriptionCounts[code]!,
                                        ),
                                      ),
                                ],
                              ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SectionCard(
                        title: 'Consommation IA — ce mois-ci',
                        icon: Icons.bolt_rounded,
                        child: data.usageThisMonth.isEmpty
                            ? Text(
                                'Aucune consommation mesurée pour l\'instant.',
                                style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final entry in data.usageThisMonth.entries)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                                      child: _BreakdownRow(
                                        label: EntitlementFeature.label(entry.key),
                                        value: entry.value,
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(icon, color: AdminTheme.accentLight),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: textTheme.bodyMedium)),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              fontFamily: 'Libre Caslon Display',
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte de section du cockpit : eyebrow + icône, puis le contenu (une
/// rangée de mini-stats ou une liste de répartition).
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AdminTheme.accentLight),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title.toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: AdminTheme.accentLight,
                  letterSpacing: AppLetterSpacing.caps,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

/// Petit total centré (statut de demande de contact), côte à côte avec ses
/// pairs dans une rangée qui se partage la largeur de la carte.
class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.legalBlueDark.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: AppColors.glassBorder, width: 0.6),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: textTheme.titleLarge?.copyWith(fontFamily: 'Libre Caslon Display'),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Ligne label / valeur d'une répartition (offres, fonctionnalités…).
class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$value',
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
