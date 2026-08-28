import 'package:flutter/material.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/luxury_scaffold_background.dart';
import '../../../features/contact_professional/domain/entities/contact_request.dart';
import '../../../theme/app_theme.dart';
import '../../auth/staff_role.dart';
import '../../theme/admin_theme.dart';

/// Console — Tableau de bord. Volontairement minimal pour ce scaffold : un
/// mot d'accueil et un indicateur réel (demandes en attente). Les KPI riches
/// (MAU, revenu récurrent, coût d'IA, latence) viendront avec le cockpit.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key, required this.identity});

  final StaffIdentity identity;

  Future<int> _pendingRequests() async {
    final rows = await SupabaseConfig.client
        .from('professional_contact_requests')
        .select('id')
        .eq('status', ContactRequestStatus.pending.name)
        .limit(1000);
    return (rows as List).length;
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
              FutureBuilder<int>(
                future: _pendingRequests(),
                builder: (context, snapshot) {
                  final value = snapshot.hasData ? '${snapshot.data}' : '—';
                  return _StatTile(
                    label: 'Demandes de mise en relation en attente',
                    value: value,
                    icon: Icons.support_agent_rounded,
                    loading: snapshot.connectionState == ConnectionState.waiting,
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
    required this.loading,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool loading;

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
          if (loading)
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          else
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
