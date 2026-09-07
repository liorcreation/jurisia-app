import 'package:flutter/material.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../core/widgets/entrance_fade.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/luxury_scaffold_background.dart';
import '../../../theme/app_theme.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_ambience.dart';
import '../../widgets/admin_empty_state.dart';
import '../../widgets/admin_page_header.dart';

Color _actionTint(String action) {
  final a = action.toLowerCase();
  if (a.contains('grant') || a.contains('approve') || a.contains('publish')) return AppColors.success;
  if (a.contains('revoke') || a.contains('archive') || a.contains('reject')) return AppColors.error;
  if (a.contains('request') || a.contains('change')) return AppColors.warning;
  return AdminTheme.accentLight;
}

/// Console — Journal d'audit (lecture seule, immuable). Chaque action tracée
/// (changement de statut d'une demande, etc.) y apparaît avec son acteur,
/// sa cible et le détail avant / après — présenté en frise chronologique.
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
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 860),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              itemCount: rows.length,
                              separatorBuilder: (context, index) => const Padding(
                                padding: EdgeInsets.only(left: 13.5),
                                child: SizedBox(height: AppSpacing.sm, width: 1, child: ColoredBox(color: AppColors.divider)),
                              ),
                              itemBuilder: (context, index) => EntranceFadeSlide(
                                index: index,
                                child: _AuditRow(row: rows[index]),
                              ),
                            ),
                          ),
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

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final action = row['action'] as String? ?? '—';
    final tint = _actionTint(action);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                const SizedBox(height: 6),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tint,
                    boxShadow: [BoxShadow(color: tint.withValues(alpha: 0.55), blurRadius: 8)],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 1,
                    margin: const EdgeInsets.only(top: 4),
                    color: AppColors.divider,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: GlassContainer(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            action,
                            style: textTheme.titleSmall?.copyWith(color: tint, fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text('${row['created_at']}', style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled)),
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
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Row(
                          children: [
                            Flexible(child: _DiffPill(label: '${row['before']}', dim: true)),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(Icons.arrow_forward_rounded, size: 13, color: AppColors.textDisabled),
                            ),
                            Flexible(child: _DiffPill(label: '${row['after']}', dim: false)),
                          ],
                        ),
                      ),
                    if (row['reason'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          'Motif : ${row['reason']}',
                          style: textTheme.labelSmall?.copyWith(color: AppColors.warning),
                        ),
                      ),
                    const SizedBox(height: 4),
                    SelectableText(
                      'Acteur : ${row['actor_id']}',
                      style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiffPill extends StatelessWidget {
  const _DiffPill({required this.label, required this.dim});

  final String label;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (dim ? AppColors.textDisabled : AdminTheme.accentLight).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: dim ? AppColors.textDisabled : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
