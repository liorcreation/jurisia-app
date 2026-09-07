import 'package:flutter/material.dart';

import '../../../core/entitlements/plan.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/luxury_scaffold_background.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/admin_empty_state.dart';
import '../../widgets/admin_page_header.dart';
import '../../widgets/admin_status_chip.dart';

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
    final textTheme = Theme.of(context).textTheme;

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
                child: FutureBuilder<List<Map<String, dynamic>>>(
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
                    return ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: rows.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        final plan = PlanCatalog.of(PlanCodeName.fromName(row['plan_code'] as String?));
                        final status = row['status'] as String?;
                        return GlassContainer(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(plan.name, style: textTheme.titleSmall),
                                  const Spacer(),
                                  AdminStatusChip(label: status ?? '—', color: subscriptionStatusColor(status)),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              SelectableText(
                                'Compte : ${row['user_id']}',
                                style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                              ),
                              if (row['current_period_end'] != null)
                                Text(
                                  'Échéance : ${row['current_period_end']}',
                                  style: textTheme.labelSmall,
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
