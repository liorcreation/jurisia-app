import 'package:flutter/material.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/luxury_scaffold_background.dart';
import '../../../theme/app_theme.dart';

/// Console — Journal d'audit (lecture seule, immuable). Chaque action tracée
/// (changement de statut d'une demande, etc.) y apparaît avec son acteur,
/// sa cible et le détail avant / après.
class AdminAuditScreen extends StatelessWidget {
  const AdminAuditScreen({super.key});

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await SupabaseConfig.client
        .from('admin_audit_log')
        .select('created_at, actor_id, action, target_type, target_id, before, after, reason')
        .order('created_at', ascending: false)
        .limit(200);
    return (rows as List).map((row) => (row as Map).cast<String, dynamic>()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Journal d\'audit')),
        body: SafeArea(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _load(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Chargement impossible (droits ou migration 006).'));
              }
              final rows = snapshot.data ?? const [];
              if (rows.isEmpty) {
                return const Center(child: Text('Aucune entrée pour l\'instant.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: rows.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return GlassContainer(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(row['action'] as String? ?? '—', style: textTheme.titleSmall),
                            const Spacer(),
                            Text('${row['created_at']}', style: textTheme.labelSmall),
                          ],
                        ),
                        if (row['target_type'] != null)
                          Text(
                            '${row['target_type']} · ${row['target_id']}',
                            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          ),
                        if (row['before'] != null || row['after'] != null)
                          Text(
                            '${row['before']} → ${row['after']}',
                            style: textTheme.labelSmall,
                          ),
                        if (row['reason'] != null)
                          Text('Motif : ${row['reason']}', style: textTheme.labelSmall),
                        SelectableText(
                          'Acteur : ${row['actor_id']}',
                          style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled),
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
