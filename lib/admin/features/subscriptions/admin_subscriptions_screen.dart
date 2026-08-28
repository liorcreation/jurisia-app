import 'package:flutter/material.dart';

import '../../../core/entitlements/plan.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/luxury_scaffold_background.dart';
import '../../../theme/app_theme.dart';

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
        appBar: AppBar(title: const Text('Abonnements')),
        body: SafeArea(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _load(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Chargement impossible (droits ou migration 007/008).'));
              }
              final rows = snapshot.data ?? const [];
              if (rows.isEmpty) {
                return const Center(child: Text('Aucun abonnement payant pour l\'instant.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: rows.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  final plan = PlanCatalog.of(PlanCodeName.fromName(row['plan_code'] as String?));
                  return GlassContainer(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(plan.name, style: textTheme.titleSmall),
                            const Spacer(),
                            Text(row['status'] as String? ?? '—', style: textTheme.labelSmall),
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
      ),
    );
  }
}
