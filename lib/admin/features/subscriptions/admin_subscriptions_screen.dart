import 'package:flutter/material.dart';

import '../../../core/entitlements/plan.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/widgets/entrance_fade.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/gradient_icon_badge.dart';
import '../../../core/widgets/luxury_scaffold_background.dart';
import '../../../core/widgets/premium_surface.dart';
import '../../../theme/app_theme.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_ambience.dart';
import '../../widgets/admin_empty_state.dart';
import '../../widgets/admin_filter_chip.dart';
import '../../widgets/admin_page_header.dart';
import '../../widgets/admin_stat_card.dart';
import '../../widgets/admin_status_chip.dart';

IconData _planIcon(PlanCode code) => switch (code) {
      PlanCode.decouverte => Icons.explore_rounded,
      PlanCode.plus => Icons.auto_awesome_rounded,
      PlanCode.etudiant => Icons.school_rounded,
      PlanCode.pro => Icons.work_rounded,
      PlanCode.cabinet => Icons.apartment_rounded,
    };

Color _planTint(PlanCode code) => switch (code) {
      PlanCode.decouverte => AppColors.textSecondary,
      PlanCode.plus => AppColors.gold,
      PlanCode.etudiant => AppColors.metalEmerald,
      PlanCode.pro => AdminTheme.accent,
      PlanCode.cabinet => AppColors.metalRoseGold,
    };

/// Console — supervision des abonnements en lecture seule. Les transitions
/// commerciales passent par le prestataire de paiement et son webhook ; la
/// console donne une vue opérateur claire sans créer de faux bouton d’action.
class AdminSubscriptionsScreen extends StatefulWidget {
  const AdminSubscriptionsScreen({super.key});

  @override
  State<AdminSubscriptionsScreen> createState() => _AdminSubscriptionsScreenState();
}

class _AdminSubscriptionsScreenState extends State<AdminSubscriptionsScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  String? _status;
  PlanCode? _plan;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await SupabaseConfig.client
        .from('subscriptions')
        .select('user_id, plan_code, status, current_period_end, trial_end, updated_at')
        .order('updated_at', ascending: false)
        .limit(200);
    return (rows as List).map((row) => (row as Map).cast<String, dynamic>()).toList();
  }

  void _refresh() {
    setState(() => _future = _load());
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
                icon: Icons.credit_card_rounded,
                title: 'Abonnements',
                subtitle: 'Supervision du portefeuille — les changements passent par le webhook de paiement.',
                actions: [
                  _ReadOnlyBadge(),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(tooltip: 'Rafraîchir le portefeuille', onPressed: _refresh, icon: const Icon(Icons.refresh_rounded)),
                ],
              ),
              Expanded(
                child: Stack(
                  children: [
                    const Positioned.fill(child: IgnorePointer(child: AdminAmbience())),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _future,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                        if (snapshot.hasError) return const AdminEmptyState(icon: Icons.cloud_off_rounded, message: 'Chargement impossible.', detail: 'Vérifiez les droits ou l’état des migrations d’abonnement.');
                        return _PortfolioContent(rows: snapshot.data ?? const [], status: _status, plan: _plan, onStatusChanged: (value) => setState(() => _status = value), onPlanChanged: (value) => setState(() => _plan = value));
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

class _PortfolioContent extends StatelessWidget {
  const _PortfolioContent({required this.rows, required this.status, required this.plan, required this.onStatusChanged, required this.onPlanChanged});

  final List<Map<String, dynamic>> rows;
  final String? status;
  final PlanCode? plan;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<PlanCode?> onPlanChanged;

  @override
  Widget build(BuildContext context) {
    final filtered = rows.where((row) {
      final rowStatus = row['status'] as String?;
      final code = PlanCodeName.fromName(row['plan_code'] as String?);
      return (status == null || rowStatus == status) && (plan == null || code == plan);
    }).toList();
    final active = rows.where((row) => row['status'] == 'active').length;
    final trialing = rows.where((row) => row['status'] == 'trialing').length;
    final attention = rows.where((row) => row['status'] == 'past_due').length;
    final mix = {for (final code in PlanCode.values) code: rows.where((row) => PlanCodeName.fromName(row['plan_code'] as String?) == code).length};

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1080;
        final content = ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
          children: [
            const _BillingHero(),
            const SizedBox(height: AppSpacing.md),
            _StatRow(total: rows.length, active: active, trialing: trialing, attention: attention),
            const SizedBox(height: AppSpacing.xl),
            PremiumSectionHeader(
              eyebrow: 'PORTEFEUILLE ACTIF',
              title: 'Les comptes abonnés',
              subtitle: filtered.isEmpty ? 'Aucun compte ne correspond à cette vue.' : '${filtered.length} compte${filtered.length == 1 ? '' : 's'} affiché${filtered.length == 1 ? '' : 's'} sur ${rows.length}.',
              action: _PlanFilters(selected: plan, mix: mix, onChanged: onPlanChanged),
            ),
            const SizedBox(height: AppSpacing.sm),
            _StatusFilters(selected: status, rows: rows, onChanged: onStatusChanged),
            const SizedBox(height: AppSpacing.md),
            rows.isEmpty
                ? const AdminEmptyState(icon: Icons.credit_card_off_rounded, message: 'Aucun abonnement payant pour l’instant.', detail: 'Le portefeuille apparaîtra ici dès les premiers paiements confirmés.')
                : filtered.isEmpty
                    ? const AdminEmptyState(icon: Icons.filter_alt_off_rounded, message: 'Aucun résultat pour ces filtres.')
                    : Column(children: [for (var i = 0; i < filtered.length; i++) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: EntranceFadeSlide(index: i, child: _SubscriptionCard(row: filtered[i])))])
          ],
        );
        if (!wide) return content;
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: content), const SizedBox(width: AppSpacing.md), SizedBox(width: 300, child: _PortfolioGuide(mix: mix, attention: attention))]);
      },
    );
  }
}

class _BillingHero extends StatelessWidget {
  const _BillingHero();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return PremiumSurface(
      tone: PremiumSurfaceTone.cobalt,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 590;
        final copy = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const GradientIconBadge(icon: Icons.insights_rounded, size: 48, gradient: AdminGradients.cobaltMetallic, iconColor: AppColors.textPrimary), const SizedBox(width: AppSpacing.md), Text('PILOTAGE COMMERCIAL', style: textTheme.labelSmall?.copyWith(color: AppColors.goldLight, fontWeight: FontWeight.w700, letterSpacing: AppLetterSpacing.caps))]),
          const SizedBox(height: AppSpacing.md),
          Text('La confiance se lit aussi dans les bons signaux.', style: textTheme.headlineSmall?.copyWith(fontFamily: 'Libre Caslon Display')),
          const SizedBox(height: AppSpacing.xs),
          Text('Suivez la santé du portefeuille JurisIA, repérez les comptes à surveiller et gardez une lecture nette des offres utilisées.', style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.45)),
        ]);
        final signal = Container(width: compact ? double.infinity : 180, padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(color: AppColors.deepSlateDeep.withValues(alpha: 0.48), borderRadius: BorderRadius.circular(AppRadius.medium), border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.10))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.lock_clock_rounded, color: AppColors.goldLight, size: 20), const SizedBox(height: AppSpacing.sm), Text('SOURCE DE VÉRITÉ', style: textTheme.labelSmall?.copyWith(color: AppColors.goldLight, letterSpacing: AppLetterSpacing.label)), const SizedBox(height: AppSpacing.xs), Text('Paiement · Webhook · Supabase', style: textTheme.titleSmall)]));
        if (compact) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [copy, const SizedBox(height: AppSpacing.md), signal]);
        return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Expanded(child: copy), const SizedBox(width: AppSpacing.lg), signal]);
      }),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.total, required this.active, required this.trialing, required this.attention});

  final int total;
  final int active;
  final int trialing;
  final int attention;

  @override
  Widget build(BuildContext context) {
    final cards = [
      AdminStatCard(icon: Icons.groups_rounded, label: 'Total', value: '$total', hint: 'Comptes suivis', accentColor: AdminTheme.accentLight),
      AdminStatCard(icon: Icons.check_circle_rounded, label: 'Actifs', value: '$active', hint: 'Accès en cours', accentColor: AppColors.success),
      AdminStatCard(icon: Icons.hourglass_top_rounded, label: 'À l’essai', value: '$trialing', hint: 'Conversion à suivre', accentColor: AppColors.warning),
      AdminStatCard(icon: Icons.priority_high_rounded, label: 'À surveiller', value: '$attention', hint: 'Paiement à vérifier', accentColor: attention == 0 ? AppColors.textSecondary : AppColors.error),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 610) return Column(children: [for (var i = 0; i < cards.length; i++) ...[cards[i], if (i != cards.length - 1) const SizedBox(height: AppSpacing.sm)]]);
      final columns = constraints.maxWidth < 860 ? 2 : 4;
      return GridView.count(crossAxisCount: columns, crossAxisSpacing: AppSpacing.sm, mainAxisSpacing: AppSpacing.sm, childAspectRatio: columns == 2 ? 2.2 : 1.25, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: cards);
    });
  }
}

class _StatusFilters extends StatelessWidget {
  const _StatusFilters({required this.selected, required this.rows, required this.onChanged});

  final String? selected;
  final List<Map<String, dynamic>> rows;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    const statuses = ['active', 'trialing', 'past_due', 'canceled'];
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [Padding(padding: const EdgeInsets.only(right: AppSpacing.sm), child: AdminFilterChip(label: 'Tous', count: rows.length, selected: selected == null, onTap: () => onChanged(null))), for (final value in statuses) Padding(padding: const EdgeInsets.only(right: AppSpacing.sm), child: AdminFilterChip(label: _statusLabel(value), count: rows.where((row) => row['status'] == value).length, selected: selected == value, onTap: () => onChanged(value)))]));
  }
}

class _PlanFilters extends StatelessWidget {
  const _PlanFilters({required this.selected, required this.mix, required this.onChanged});

  final PlanCode? selected;
  final Map<PlanCode, int> mix;
  final ValueChanged<PlanCode?> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [_PlanPill(label: 'Toutes les offres', count: mix.values.fold(0, (sum, value) => sum + value), selected: selected == null, onTap: () => onChanged(null)), for (final code in PlanCode.values) _PlanPill(label: PlanCatalog.of(code).name, count: mix[code] ?? 0, selected: selected == code, onTap: () => onChanged(code))]);
}

class _PlanPill extends StatelessWidget {
  const _PlanPill({required this.label, required this.count, required this.selected, required this.onTap});

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.goldLight : AppColors.textSecondary;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AppRadius.pill), child: AnimatedContainer(duration: AppMotion.quick, padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs), decoration: BoxDecoration(color: selected ? AppColors.gold.withValues(alpha: 0.16) : AppColors.textPrimary.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: color.withValues(alpha: selected ? 0.50 : 0.18))), child: Row(mainAxisSize: MainAxisSize.min, children: [Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700)), const SizedBox(width: 5), Text('$count', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color))])));
  }
}

class _PortfolioGuide extends StatelessWidget {
  const _PortfolioGuide({required this.mix, required this.attention});

  final Map<PlanCode, int> mix;
  final int attention;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(padding: const EdgeInsets.only(top: AppSpacing.lg, right: AppSpacing.lg), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('LENS PORTEFEUILLE', style: textTheme.labelSmall?.copyWith(color: AppColors.goldLight, fontWeight: FontWeight.w700, letterSpacing: AppLetterSpacing.caps)), const SizedBox(height: AppSpacing.sm), Text('Une lecture nette des offres.', style: textTheme.titleLarge?.copyWith(fontFamily: 'Libre Caslon Display')), const SizedBox(height: AppSpacing.md), PremiumSurface(padding: const EdgeInsets.all(AppSpacing.md), tone: PremiumSurfaceTone.elevated, child: Column(children: [for (final code in PlanCode.values) ...[_PlanMixRow(code: code, count: mix[code] ?? 0), if (code != PlanCode.cabinet) const _GuideDivider()]])), const SizedBox(height: AppSpacing.md), Container(padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(color: (attention == 0 ? AppColors.success : AppColors.warning).withValues(alpha: 0.10), borderRadius: BorderRadius.circular(AppRadius.medium), border: Border.all(color: (attention == 0 ? AppColors.success : AppColors.warning).withValues(alpha: 0.28))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(attention == 0 ? Icons.verified_rounded : Icons.warning_amber_rounded, size: 20, color: attention == 0 ? AppColors.success : AppColors.warning), const SizedBox(width: AppSpacing.sm), Expanded(child: Text(attention == 0 ? 'Aucun paiement à surveiller.' : '$attention compte${attention == 1 ? '' : 's'} demande${attention == 1 ? '' : 'nt'} une vérification.', style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.4)))])), const SizedBox(height: AppSpacing.md), Text('Lecture seule : toute modification d’offre ou de statut doit provenir du prestataire de paiement et de son webhook.', style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.45))]));
  }
}

class _PlanMixRow extends StatelessWidget {
  const _PlanMixRow({required this.code, required this.count});

  final PlanCode code;
  final int count;

  @override
  Widget build(BuildContext context) => Row(children: [GradientIconBadge(icon: _planIcon(code), size: 28, gradient: LinearGradient(colors: [_planTint(code).withValues(alpha: 0.95), _planTint(code).withValues(alpha: 0.55)]), iconColor: AppColors.textPrimary), const SizedBox(width: AppSpacing.sm), Expanded(child: Text(PlanCatalog.of(code).name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall)), Text('$count', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: _planTint(code), fontWeight: FontWeight.w700))]);
}

class _GuideDivider extends StatelessWidget {
  const _GuideDivider();

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm), child: Divider(color: AppColors.textPrimary.withValues(alpha: 0.08), height: 1));
}

class _ReadOnlyBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs), decoration: BoxDecoration(color: AppColors.cobalt.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.cobaltLight.withValues(alpha: 0.28))), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.visibility_outlined, size: 16, color: AdminTheme.accentLight), const SizedBox(width: 5), Text('LECTURE SEULE', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AdminTheme.accentLight, fontWeight: FontWeight.w700))]));
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final code = PlanCodeName.fromName(row['plan_code'] as String?);
    final plan = PlanCatalog.of(code);
    final status = row['status'] as String?;
    final color = _planTint(code);
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: color.withValues(alpha: 0.30),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GradientIconBadge(icon: _planIcon(code), size: 42, gradient: LinearGradient(colors: [color.withValues(alpha: 0.95), color.withValues(alpha: 0.55)]), iconColor: AppColors.textPrimary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('COMPTE ABONNÉ', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AdminTheme.accentLight, fontWeight: FontWeight.w700, letterSpacing: AppLetterSpacing.label)), const SizedBox(height: 2), Text(plan.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)), Text(plan.priceLabel, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary))])),
          AdminStatusChip(label: _statusLabel(status), color: subscriptionStatusColor(status)),
        ]),
        const SizedBox(height: AppSpacing.md),
        Container(padding: const EdgeInsets.all(AppSpacing.sm), decoration: BoxDecoration(color: AppColors.deepSlateDeep.withValues(alpha: 0.34), borderRadius: BorderRadius.circular(AppRadius.small), border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.08))), child: Row(children: [const Icon(Icons.person_outline_rounded, size: 17, color: AppColors.goldLight), const SizedBox(width: AppSpacing.sm), Expanded(child: SelectableText('Compte : ${row['user_id']}', maxLines: 1, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)))])),
        const SizedBox(height: AppSpacing.sm),
        Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [if (row['current_period_end'] != null) _DateTag(label: 'Échéance : ${_shortDate(row['current_period_end'])}', icon: Icons.event_repeat_rounded), if (row['trial_end'] != null) _DateTag(label: 'Essai jusqu’au ${_shortDate(row['trial_end'])}', icon: Icons.hourglass_bottom_rounded), if (row['updated_at'] != null) _DateTag(label: 'Mis à jour : ${_shortDate(row['updated_at'])}', icon: Icons.update_rounded)]),
      ]),
    );
  }
}

class _DateTag extends StatelessWidget {
  const _DateTag({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs), decoration: BoxDecoration(color: AppColors.cobalt.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.cobaltLight.withValues(alpha: 0.24))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: AppColors.cobaltLight), const SizedBox(width: 4), Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.cobaltLight, fontWeight: FontWeight.w600))]));
}

String _statusLabel(String? status) => switch (status) {
      'active' => 'Actif',
      'trialing' => 'À l’essai',
      'past_due' => 'Paiement à vérifier',
      'canceled' || 'cancelled' => 'Résilié',
      _ => status ?? 'Inconnu',
    };

String _shortDate(Object? value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  if (parsed == null) return value?.toString() ?? '—';
  final local = parsed.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}
