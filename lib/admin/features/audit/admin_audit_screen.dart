import 'package:flutter/material.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/luxury_scaffold_background.dart';
import '../../../theme/app_theme.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_empty_state.dart';
import '../../widgets/admin_page_header.dart';

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
        body: SafeArea(
          child: Column(
            children: [
              const AdminPageHeader(
                icon: Icons.receipt_long_rounded,
                title: 'Journal d\'audit',
                subtitle: 'Lecture seule, immuable — chaque action tracée avec son acteur et sa cible.',
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
                        detail: 'Vérifiez les droits ou l\'état de la migration 006.',
                      );
                    }
                    final rows = snapshot.data ?? const [];
                    if (rows.isEmpty) {
                      return const AdminEmptyState(
                        icon: Icons.history_rounded,
                        message: 'Aucune entrée pour l\'instant.',
                      );
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
                                  Icon(Icons.bolt_rounded, size: 14, color: AdminTheme.accentLight),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: Text(row['action'] as String? ?? '—', style: textTheme.titleSmall),
                                  ),
                                  Text('${row['created_at']}', style: textTheme.labelSmall),
                                ],
                              ),
                              if (row['target_type'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '${row['target_type']} · ${row['target_id']}',
                                    style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                                  ),
                                ),
                              if (row['before'] != null || row['after'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('${row['before']} → ${row['after']}', style: textTheme.labelSmall),
                                ),
                              if (row['reason'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('Motif : ${row['reason']}', style: textTheme.labelSmall),
                                ),
                              const SizedBox(height: 4),
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
            ],
          ),
        ),
      ),
    );
  }
}
