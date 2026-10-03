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
  int get activeSubscriptions =>
      subscriptionCounts.values.fold(0, (a, b) => a + b);
  int get totalUsage => usageThisMonth.values.fold(0, (a, b) => a + b);
}

/// Console — Tableau de bord. Un aperçu réel de l'activité — demandes de
/// mise en relation, répartition des abonnements payants, consommation IA
/// du mois — construit à partir des tables déjà accessibles au personnel
/// (RLS `jurisia_is_staff()`, migration_008). Pas encore de séries
/// temporelles ni de coût IA converti en F CFA : la matière première
/// (`usage_events`) est en place, ce sera le prochain incrément du cockpit.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, required this.identity});

  final StaffIdentity identity;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<_DashboardSnapshot> _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot = _load();
  }

  Future<_DashboardSnapshot> _load() async {
    final client = SupabaseConfig.client;
    final now = DateTime.now();
    final period = DateTime(
      now.year,
      now.month,
      1,
    ).toIso8601String().split('T').first;

    final results = await Future.wait([
      client.from('professional_contact_requests').select('status').limit(5000),
      client.from('subscriptions').select('plan_code, status').limit(5000),
      client
          .from('usage_counters')
          .select('feature, used')
          .eq('period', period)
          .limit(5000),
    ]);

    final contactCounts = {
      for (final status in ContactRequestStatus.values) status: 0,
    };
    for (final row in results[0] as List) {
      final status = ContactRequestStatus.fromName(
        (row as Map)['status'] as String? ?? '',
      );
      contactCounts[status] = (contactCounts[status] ?? 0) + 1;
    }

    final subscriptionCounts = <PlanCode, int>{};
    for (final row in results[1] as List) {
      final map = row as Map;
      if (map['status'] == 'canceled') continue;
      final code = PlanCodeName.fromName(map['plan_code'] as String?);
      if (code == PlanCode.decouverte) {
        continue; // hors offre gratuite implicite
      }
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

  void _refresh() => setState(() => _snapshot = _load());

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
                subtitle:
                    'Connecté en tant que ${widget.identity.primary?.label ?? 'membre du personnel'}.',
                actions: [
                  IconButton(
                    tooltip: 'Actualiser les données',
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              Expanded(
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: IgnorePointer(child: AdminAmbience()),
                    ),
                    FutureBuilder<_DashboardSnapshot>(
                      future: _snapshot,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const _DashboardLoading();
                        }
                        if (snapshot.hasError) {
                          return _DashboardFailure(onRetry: _refresh);
                        }
                        final data = snapshot.data!;
                        return _DashboardBody(
                          data: data,
                          identity: widget.identity,
                        );
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
  const _DashboardBody({required this.data, required this.identity});

  final _DashboardSnapshot data;
  final StaffIdentity identity;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            constraints.maxWidth < 560 ? AppSpacing.md : AppSpacing.xl,
            constraints.maxWidth < 560 ? AppSpacing.md : AppSpacing.xl,
            constraints.maxWidth < 560 ? AppSpacing.md : AppSpacing.xl,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EntranceFadeSlide(
                child: _DashboardWelcome(data: data, identity: identity),
              ),
              const SizedBox(height: AppSpacing.xl),
              _DashboardSectionHeading(
                eyebrow: 'VUE D’ENSEMBLE',
                title: 'Les indicateurs clés',
                detail: 'Une lecture immédiate de l’activité JurisIA',
              ),
              const SizedBox(height: AppSpacing.md),
              _KpiGrid(data: data),
              const SizedBox(height: AppSpacing.xl),
              _DashboardSectionHeading(
                eyebrow: 'ANALYSE OPÉRATIONNELLE',
                title: 'Flux & répartition',
                detail: 'Demandes, abonnements et utilisation mesurée',
              ),
              const SizedBox(height: AppSpacing.md),
              if (wide)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 5,
                        child: EntranceFadeSlide(
                          index: 1,
                          child: _ContactStatusSection(data: data),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 4,
                        child: EntranceFadeSlide(
                          index: 2,
                          child: _SubscriptionsSection(data: data),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 4,
                        child: EntranceFadeSlide(
                          index: 3,
                          child: _UsageSection(data: data),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                EntranceFadeSlide(
                  index: 1,
                  child: _ContactStatusSection(data: data),
                ),
                const SizedBox(height: AppSpacing.md),
                EntranceFadeSlide(
                  index: 2,
                  child: _SubscriptionsSection(data: data),
                ),
                const SizedBox(height: AppSpacing.md),
                EntranceFadeSlide(index: 3, child: _UsageSection(data: data)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DashboardWelcome extends StatelessWidget {
  const _DashboardWelcome({required this.data, required this.identity});

  final _DashboardSnapshot data;
  final StaffIdentity identity;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 620;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: AdminTheme.accentLight.withValues(alpha: 0.32),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF17345C), Color(0xFF0D192B), Color(0xFF0A101C)],
          stops: [0, 0.52, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: AdminTheme.accent.withValues(alpha: 0.17),
            blurRadius: 34,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: Stack(
          children: [
            Positioned(
              right: compact ? -100 : 32,
              top: -118,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.055),
                    width: 1,
                  ),
                ),
              ),
            ),
            Positioned(
              right: compact ? -44 : 88,
              top: -62,
              child: Container(
                width: 168,
                height: 168,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AdminTheme.accent.withValues(alpha: 0.09),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontal = constraints.maxWidth >= 720;
                  final intro = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Eyebrow(
                        icon: Icons.auto_awesome_rounded,
                        label: 'CENTRE DE PILOTAGE',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'JurisIA, en un regard.',
                        style: textTheme.headlineMedium?.copyWith(
                          fontFamily: 'Libre Caslon Display',
                          fontSize: compact ? 29 : 36,
                          height: 1.06,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Text(
                          'Les repères essentiels de la plateforme, réunis dans une vue claire et exploitable.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.55,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _RoleBadge(
                        label: identity.primary?.label ?? 'Membre du personnel',
                      ),
                    ],
                  );
                  final pulse = _WelcomePulse(data: data, compact: !horizontal);

                  if (!horizontal) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        intro,
                        const SizedBox(height: AppSpacing.lg),
                        pulse,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(flex: 6, child: intro),
                      const SizedBox(width: AppSpacing.xl),
                      Expanded(flex: 4, child: pulse),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePulse extends StatelessWidget {
  const _WelcomePulse({required this.data, required this.compact});

  final _DashboardSnapshot data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final first = _PulseMetric(
      label: 'À traiter',
      value: data.pending,
      icon: Icons.hourglass_top_rounded,
      color: AppColors.warning,
    );
    final second = _PulseMetric(
      label: 'Traitées',
      value: data.handled,
      icon: Icons.task_alt_rounded,
      color: AppColors.success,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.deepSlateDeep.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow(
            icon: Icons.track_changes_rounded,
            label: 'SUIVI DES DEMANDES',
          ),
          const SizedBox(height: AppSpacing.md),
          if (compact)
            Row(
              children: [
                Expanded(child: first),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: second),
              ],
            )
          else ...[
            first,
            const SizedBox(height: AppSpacing.sm),
            Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
            const SizedBox(height: AppSpacing.sm),
            second,
          ],
        ],
      ),
    );
  }
}

class _PulseMetric extends StatelessWidget {
  const _PulseMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 17, color: color),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontFamily: 'Libre Caslon Display',
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AdminTheme.accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: AdminTheme.accentLight.withValues(alpha: 0.26),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_user_rounded,
            size: 14,
            color: AdminTheme.accentLight,
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.goldLight),
        const SizedBox(width: 7),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.goldLight,
            letterSpacing: AppLetterSpacing.caps,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DashboardSectionHeading extends StatelessWidget {
  const _DashboardSectionHeading({
    required this.eyebrow,
    required this.title,
    required this.detail,
  });

  final String eyebrow;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: textTheme.labelSmall?.copyWith(
                  color: AdminTheme.accentLight,
                  letterSpacing: AppLetterSpacing.caps,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: textTheme.headlineSmall?.copyWith(
                  fontFamily: 'Libre Caslon Display',
                  fontSize: 25,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detail,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.data});

  final _DashboardSnapshot data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1120
            ? 4
            : constraints.maxWidth >= 340
            ? 2
            : 1;
        const spacing = AppSpacing.md;
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final metrics = [
          _MetricSpec(
            icon: Icons.hourglass_top_rounded,
            label: 'Demandes en attente',
            value: data.pending,
            note: 'Nécessitent un suivi',
            color: AppColors.warning,
          ),
          _MetricSpec(
            icon: Icons.task_alt_rounded,
            label: 'Demandes traitées',
            value: data.handled,
            note: 'Contactées ou clôturées',
            color: AppColors.success,
          ),
          _MetricSpec(
            icon: Icons.credit_card_rounded,
            label: 'Abonnements payants',
            value: data.activeSubscriptions,
            note: 'Hors offres gratuites',
            color: AdminTheme.accentLight,
          ),
          _MetricSpec(
            icon: Icons.bolt_rounded,
            label: 'Usage IA ce mois',
            value: data.totalUsage,
            note: 'Opérations mesurées',
            color: AppColors.metalRoseGold,
          ),
        ];
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var index = 0; index < metrics.length; index++)
              SizedBox(
                width: cardWidth,
                child: EntranceFadeSlide(
                  index: index,
                  child: _DashboardMetricCard(spec: metrics[index]),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MetricSpec {
  const _MetricSpec({
    required this.icon,
    required this.label,
    required this.value,
    required this.note,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final String note;
  final Color color;
}

class _DashboardMetricCard extends StatelessWidget {
  const _DashboardMetricCard({required this.spec});

  final _MetricSpec spec;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 176),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            spec.color.withValues(alpha: 0.10),
            const Color(0xB8111826),
            const Color(0xE6090E17),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: spec.color.withValues(alpha: 0.045),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: spec.color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: spec.color.withValues(alpha: 0.25)),
                ),
                child: Icon(spec.icon, color: spec.color, size: 19),
              ),
              const Spacer(),
              Icon(
                Icons.north_east_rounded,
                size: 15,
                color: spec.color.withValues(alpha: 0.6),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: spec.value.toDouble()),
            duration: const Duration(milliseconds: 850),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Text(
              value.round().toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.headlineMedium?.copyWith(
                fontFamily: 'Libre Caslon Display',
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            spec.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            spec.note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(height: AppSpacing.md),
          Text('Préparation de votre vue d’ensemble…'),
        ],
      ),
    );
  }
}

class _DashboardFailure extends StatelessWidget {
  const _DashboardFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AdminEmptyState(
                icon: Icons.cloud_off_rounded,
                message: 'Les indicateurs ne sont pas disponibles.',
                detail:
                    'Vérifiez les droits d’accès et les migrations 007/008, puis réessayez.',
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
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
    final maxValue = counts.values.isEmpty
        ? 0
        : counts.values.reduce((a, b) => a > b ? a : b);

    return AdminSectionCard(
      title: 'Abonnements payants actifs',
      icon: Icons.credit_card_rounded,
      trailing: AdminStatusChip(
        label: '${data.activeSubscriptions}',
        color: AdminTheme.accent,
      ),
      child: counts.isEmpty
          ? Text(
              'Aucun abonnement payant pour l\'instant.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
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
    final maxValue = usage.values.isEmpty
        ? 0
        : usage.values.reduce((a, b) => a > b ? a : b);

    return AdminSectionCard(
      title: 'Consommation IA — ce mois-ci',
      icon: Icons.bolt_rounded,
      trailing: AdminStatusChip(
        label: '${data.totalUsage}',
        color: AppColors.metalRoseGold,
      ),
      child: usage.isEmpty
          ? Text(
              'Aucune consommation mesurée pour l\'instant.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
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
