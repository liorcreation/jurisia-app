import 'package:flutter/material.dart';

import '../../../core/entitlements/plan.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/widgets/entrance_fade.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/gradient_icon_badge.dart';
import '../../../core/widgets/luxury_scaffold_background.dart';
import '../../../theme/app_theme.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_ambience.dart';
import '../../widgets/admin_empty_state.dart';
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

/// Console — Abonnements (lecture seule pour ce scaffold). La création /
/// modification d'un abonnement passera par le webhook du prestataire de
/// paiement (Edge Function), jamais par la console à la main.
class AdminSubscriptionsScreen extends StatelessWidget {
  const AdminSubscriptionsScreen({super.key});

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await SupabaseConfig.client
        .from('subscriptions')
        .select('user_id, plan_code, status, current_period_end, trial_end, updated_at')
        .order('updated_at', ascending: false)
        .limit(200);
    return (rows as List).map((row) => (row as Map).cast<String, dynamic>()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              const AdminPageHeader(
                icon: Icons.credit_card_rounded,
                title: 'Abonnements',
                subtitle:
                    'Lecture seule — la création/modification passe par le webhook du prestataire de paiement.',
              ),
              Expanded(
                child: Stack(
                  children: [
                    const Positioned.fill(child: IgnorePointer(child: AdminAmbience())),
                    FutureBuilder<List<Map<String, dynamic>>>(
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
                        final rows = snapshot.data ?? const [];
                        if (rows.isEmpty) {
                          return const AdminEmptyState(
                            icon: Icons.credit_card_off_rounded,
                            message: 'Aucun abonnement payant pour l\'instant.',
                          );
                        }
                        final active = rows.where((r) => r['status'] == 'active').length;
                        final trialing = rows.where((r) => r['status'] == 'trialing').length;

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 900;
                            return SingleChildScrollView(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          child: AdminStatCard(
                                            icon: Icons.groups_rounded,
                                            label: 'Total',
                                            value: '${rows.length}',
                                            accentColor: AdminTheme.accent,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: AdminStatCard(
                                            icon: Icons.check_circle_rounded,
                                            label: 'Actifs',
                                            value: '$active',
                                            accentColor: AppColors.success,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: AdminStatCard(
                                            icon: Icons.hourglass_top_rounded,
                                            label: 'À l\'essai',
                                            value: '$trialing',
                                            accentColor: AppColors.warning,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: rows.length,
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: wide ? 2 : 1,
                                      mainAxisSpacing: AppSpacing.sm,
                                      crossAxisSpacing: AppSpacing.sm,
                                      mainAxisExtent: 128,
                                    ),
                                    itemBuilder: (context, index) {
                                      final row = rows[index];
                                      final code = PlanCodeName.fromName(row['plan_code'] as String?);
                                      final plan = PlanCatalog.of(code);
                                      final status = row['status'] as String?;
                                      return EntranceFadeSlide(
                                        index: index,
                                        child: GlassContainer(
                                          padding: const EdgeInsets.all(AppSpacing.md),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              GradientIconBadge(
                                                icon: _planIcon(code),
                                                size: 40,
                                                gradient: LinearGradient(
                                                  colors: [
                                                    _planTint(code).withValues(alpha: 0.95),
                                                    _planTint(code).withValues(alpha: 0.55),
                                                  ],
                                                ),
                                                iconColor: AppColors.textPrimary,
                                              ),
                                              const SizedBox(width: AppSpacing.sm),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            plan.name,
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: Theme.of(context).textTheme.titleSmall,
                                                          ),
                                                        ),
                                                        AdminStatusChip(
                                                          label: status ?? '—',
                                                          color: subscriptionStatusColor(status),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    SelectableText(
                                                      'Compte : ${row['user_id']}',
                                                      maxLines: 1,
                                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                            color: AppColors.textDisabled,
                                                          ),
                                                    ),
                                                    if (row['current_period_end'] != null)
                                                      Padding(
                                                        padding: const EdgeInsets.only(top: 2),
                                                        child: Text(
                                                          'Échéance : ${row['current_period_end']}',
                                                          style: Theme.of(context).textTheme.labelSmall,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
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
