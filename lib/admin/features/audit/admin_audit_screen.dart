import 'dart:convert';

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
import '../../widgets/admin_section_card.dart';
import '../../widgets/admin_status_chip.dart';

enum _AuditFilter { all, positive, review, sensitive, other }

extension on _AuditFilter {
  String get label => switch (this) {
        _AuditFilter.all => 'Tout le journal',
        _AuditFilter.positive => 'Validations',
        _AuditFilter.review => 'Relectures',
        _AuditFilter.sensitive => 'Actions sensibles',
        _AuditFilter.other => 'Autres actions',
      };

  IconData get icon => switch (this) {
        _AuditFilter.all => Icons.view_timeline_rounded,
        _AuditFilter.positive => Icons.verified_rounded,
        _AuditFilter.review => Icons.rate_review_rounded,
        _AuditFilter.sensitive => Icons.shield_rounded,
        _AuditFilter.other => Icons.more_horiz_rounded,
      };
}

_AuditFilter _filterFor(String action) {
  final value = action.toLowerCase();
  if (value.contains('grant') || value.contains('approve') || value.contains('publish')) {
    return _AuditFilter.positive;
  }
  if (value.contains('request') || value.contains('change') || value.contains('review')) {
    return _AuditFilter.review;
  }
  if (value.contains('revoke') || value.contains('archive') || value.contains('reject') || value.contains('delete')) {
    return _AuditFilter.sensitive;
  }
  return _AuditFilter.other;
}

Color _actionTint(String action) {
  return switch (_filterFor(action)) {
    _AuditFilter.positive => AppColors.success,
    _AuditFilter.review => AppColors.warning,
    _AuditFilter.sensitive => AppColors.error,
    _ => AdminTheme.accentLight,
  };
}

IconData _actionIcon(String action) => switch (_filterFor(action)) {
      _AuditFilter.positive => Icons.check_circle_outline_rounded,
      _AuditFilter.review => Icons.rate_review_outlined,
      _AuditFilter.sensitive => Icons.gpp_maybe_outlined,
      _ => Icons.bolt_rounded,
    };

/// Journal immuable de la console. La recherche et les filtres sont locaux :
/// ils ne modifient jamais les entrées ni la requête d'audit source.
class AdminAuditScreen extends StatefulWidget {
  const AdminAuditScreen({super.key});

  @override
  State<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends State<AdminAuditScreen> {
  late Future<List<Map<String, dynamic>>> _entriesFuture;
  final _searchController = TextEditingController();
  _AuditFilter _filter = _AuditFilter.all;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _load();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await SupabaseConfig.client
        .from('admin_audit_log')
        .select('created_at, actor_id, action, target_type, target_id, before, after, reason')
        .order('created_at', ascending: false)
        .limit(200);
    return (rows as List).map((row) => (row as Map).cast<String, dynamic>()).toList();
  }

  void _refresh() {
    setState(() => _entriesFuture = _load());
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
                icon: Icons.receipt_long_rounded,
                title: 'Journal d’audit',
                subtitle: 'La mémoire immuable des opérations de la console.',
                actions: [
                  IconButton(tooltip: 'Actualiser le journal', onPressed: _refresh, icon: const Icon(Icons.refresh_rounded)),
                ],
              ),
              Expanded(
                child: Stack(
                  children: [
                    const Positioned.fill(child: IgnorePointer(child: AdminAmbience())),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _entriesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 560),
                              child: _AuditLoadError(onRetry: _refresh),
                            ),
                          );
                        }
                        final allRows = snapshot.data ?? const <Map<String, dynamic>>[];
                        final rows = _visibleRows(allRows);
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 1180;
                            final maxWidth = wide ? 1380.0 : 900.0;
                            return Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: maxWidth),
                                child: ListView(
                                  padding: EdgeInsets.fromLTRB(
                                    wide ? AppSpacing.xl : AppSpacing.md,
                                    AppSpacing.lg,
                                    wide ? AppSpacing.xl : AppSpacing.md,
                                    AppSpacing.xl,
                                  ),
                                  children: [
                                    _AuditHero(total: allRows.length, filtered: rows.length),
                                    const SizedBox(height: AppSpacing.md),
                                    _AuditMetrics(rows: allRows),
                                    const SizedBox(height: AppSpacing.lg),
                                    _AuditControls(
                                      searchController: _searchController,
                                      selected: _filter,
                                      counts: _filterCounts(allRows),
                                      onFilter: (filter) => setState(() => _filter = filter),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    if (rows.isEmpty)
                                      SizedBox(
                                        height: 280,
                                        child: AdminEmptyState(
                                          icon: allRows.isEmpty ? Icons.history_rounded : Icons.search_off_rounded,
                                          message: allRows.isEmpty ? 'Le journal est prêt à tracer les opérations.' : 'Aucune opération ne correspond à cette recherche.',
                                          detail: allRows.isEmpty ? 'Les actions d’administration apparaîtront ici.' : 'Essayez un autre terme ou changez de filtre.',
                                        ),
                                      )
                                    else ...[
                                      _TimelineHeading(count: rows.length, total: allRows.length),
                                      const SizedBox(height: AppSpacing.sm),
                                      for (var i = 0; i < rows.length; i++)
                                        Padding(
                                          padding: EdgeInsets.only(bottom: i == rows.length - 1 ? 0 : AppSpacing.sm),
                                          child: EntranceFadeSlide(index: i, child: _AuditEntryCard(row: rows[i], last: i == rows.length - 1)),
                                        ),
                                      if (allRows.length >= 200) ...[
                                        const SizedBox(height: AppSpacing.md),
                                        const _LimitNotice(),
                                      ],
                                    ],
                                  ],
                                ),
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

  List<Map<String, dynamic>> _visibleRows(List<Map<String, dynamic>> allRows) {
    final query = _searchController.text.trim().toLowerCase();
    return allRows.where((row) {
      final action = row['action'] as String? ?? '';
      if (_filter != _AuditFilter.all && _filterFor(action) != _filter) return false;
      if (query.isEmpty) return true;
      final searchable = [
        row['action'], row['actor_id'], row['target_type'], row['target_id'], row['reason'],
        _stringify(row['before']), _stringify(row['after']), row['created_at'],
      ].where((value) => value != null).join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList();
  }

  Map<_AuditFilter, int> _filterCounts(List<Map<String, dynamic>> rows) {
    return {for (final filter in _AuditFilter.values) filter: filter == _AuditFilter.all ? rows.length : rows.where((row) => _filterFor(row['action'] as String? ?? '') == filter).length};
  }
}

class _AuditHero extends StatelessWidget {
  const _AuditHero({required this.total, required this.filtered});
  final int total;
  final int filtered;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.large),
        gradient: LinearGradient(
          colors: [AdminTheme.accentDark.withValues(alpha: 0.90), AppColors.deepSlate.withValues(alpha: 0.91), AppColors.deepSlateDeep.withValues(alpha: 0.96)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AdminTheme.accentLight.withValues(alpha: 0.28)),
        boxShadow: [BoxShadow(color: AdminTheme.accent.withValues(alpha: 0.14), blurRadius: 30, spreadRadius: -12)],
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 660;
        final intro = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.success.withValues(alpha: 0.30))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.lock_clock_rounded, size: 15, color: AppColors.success), const SizedBox(width: 7), Text('TRACE IMMUABLE · LECTURE SEULE', style: textTheme.labelSmall?.copyWith(color: AppColors.success, letterSpacing: AppLetterSpacing.caps, fontWeight: FontWeight.w800))]),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Chaque décision\na son empreinte.', style: (compact ? textTheme.headlineSmall : textTheme.headlineMedium)?.copyWith(fontFamily: 'Libre Caslon Display', height: 1.04)),
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(constraints: const BoxConstraints(maxWidth: 610), child: Text('Retrouvez qui a fait quoi, sur quelle cible et à quel moment. Les changements de statut et leurs motifs sont conservés dans un historique consultable.', style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.45))),
        ]);
        final countPanel = Container(
          constraints: BoxConstraints(minWidth: compact ? 0 : 215, maxWidth: 260),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.055), borderRadius: BorderRadius.circular(AppRadius.medium), border: Border.all(color: Colors.white.withValues(alpha: 0.10))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('FENÊTRE D’OBSERVATION', style: textTheme.labelSmall?.copyWith(color: AdminTheme.accentLight, letterSpacing: AppLetterSpacing.caps, fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.sm),
            Text('$total', style: textTheme.displaySmall?.copyWith(fontFamily: 'Libre Caslon Display')),
            Text('événements récents chargés', style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [const Icon(Icons.filter_alt_outlined, size: 15, color: AppColors.gold), const SizedBox(width: 6), Text('$filtered visibles après filtre', style: textTheme.labelSmall?.copyWith(color: AppColors.goldLight))]),
          ]),
        );
        return compact ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [intro, const SizedBox(height: AppSpacing.md), countPanel]) : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: intro), const SizedBox(width: AppSpacing.lg), countPanel]);
      }),
    );
  }
}

class _AuditMetrics extends StatelessWidget {
  const _AuditMetrics({required this.rows});
  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _AuditMetric('Validations', _count(_AuditFilter.positive), Icons.verified_outlined, AppColors.success),
      _AuditMetric('Relectures', _count(_AuditFilter.review), Icons.rate_review_outlined, AppColors.warning),
      _AuditMetric('Sensibles', _count(_AuditFilter.sensitive), Icons.shield_outlined, AppColors.error),
      _AuditMetric('Autres', _count(_AuditFilter.other), Icons.bolt_outlined, AdminTheme.accentLight),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 660;
      return compact
          ? Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [for (final metric in metrics) SizedBox(width: (constraints.maxWidth - AppSpacing.sm) / 2, child: metric)])
          : Row(children: [for (var i = 0; i < metrics.length; i++) Expanded(child: Padding(padding: EdgeInsets.only(right: i == metrics.length - 1 ? 0 : AppSpacing.sm), child: metrics[i]))]);
    });
  }

  int _count(_AuditFilter filter) => rows.where((row) => _filterFor(row['action'] as String? ?? '') == filter).length;
}

class _AuditMetric extends StatelessWidget {
  const _AuditMetric(this.label, this.value, this.icon, this.color);
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => GlassContainer(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(children: [Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle), child: Icon(icon, size: 18, color: color)), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textDisabled, letterSpacing: AppLetterSpacing.caps, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text('$value', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontFamily: 'Libre Caslon Display'))]))]),
      );
}

class _AuditControls extends StatelessWidget {
  const _AuditControls({required this.searchController, required this.selected, required this.counts, required this.onFilter});
  final TextEditingController searchController;
  final _AuditFilter selected;
  final Map<_AuditFilter, int> counts;
  final ValueChanged<_AuditFilter> onFilter;

  @override
  Widget build(BuildContext context) => AdminSectionCard(
        title: 'Explorer les événements',
        icon: Icons.manage_search_rounded,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher une action, un acteur, une cible…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchController.text.isEmpty ? null : IconButton(tooltip: 'Effacer la recherche', onPressed: searchController.clear, icon: const Icon(Icons.close_rounded)),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final filter in _AuditFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: _AuditFilterChip(label: filter.label, count: counts[filter] ?? 0, icon: filter.icon, selected: selected == filter, onTap: () => onFilter(filter)),
                ),
            ]),
          ),
        ]),
      );
}

class _AuditFilterChip extends StatelessWidget {
  const _AuditFilterChip({required this.label, required this.count, required this.icon, required this.selected, required this.onTap});
  final String label;
  final int count;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AdminTheme.accentLight : AppColors.textSecondary;
    return Material(
      color: selected ? AdminTheme.accent.withValues(alpha: 0.19) : AppColors.legalBlueDark.withValues(alpha: 0.32),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: selected ? AdminTheme.accentLight.withValues(alpha: 0.48) : AppColors.divider)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 15, color: color), const SizedBox(width: 7), Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)), const SizedBox(width: 7), Text('$count', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: selected ? AppColors.textPrimary : AppColors.textDisabled))]),
        ),
      ),
    );
  }
}

class _TimelineHeading extends StatelessWidget {
  const _TimelineHeading({required this.count, required this.total});
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.success, blurRadius: 8)])),
        const SizedBox(width: 9),
        Expanded(child: Text('Chronologie', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontFamily: 'Libre Caslon Display'))),
        Text('$count / $total événements', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary)),
      ]);
}

class _AuditEntryCard extends StatelessWidget {
  const _AuditEntryCard({required this.row, required this.last});
  final Map<String, dynamic> row;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final action = row['action'] as String? ?? 'Action non précisée';
    final tint = _actionTint(action);
    final targetType = row['target_type']?.toString();
    final targetId = row['target_id']?.toString();
    final actor = row['actor_id']?.toString() ?? 'Acteur non renseigné';
    final before = row['before'];
    final after = row['after'];
    final reason = row['reason']?.toString();
    final time = _parseDate(row['created_at']);
    return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(width: 30, child: Column(children: [const SizedBox(height: 17), Container(width: 12, height: 12, decoration: BoxDecoration(color: tint, shape: BoxShape.circle, boxShadow: [BoxShadow(color: tint.withValues(alpha: 0.45), blurRadius: 9)])), if (!last) Expanded(child: Container(width: 1, margin: const EdgeInsets.only(top: 6), color: AppColors.divider))])),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: GlassContainer(
            padding: const EdgeInsets.all(AppSpacing.md),
            borderColor: tint.withValues(alpha: 0.23),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: tint.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.small)), child: Icon(_actionIcon(action), size: 18, color: tint)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [Text(_prettyAction(action), style: Theme.of(context).textTheme.titleSmall?.copyWith(color: tint, fontWeight: FontWeight.w800)), _AuditTypeBadge(label: _filterFor(action).label, color: tint)]),
                  const SizedBox(height: 5),
                  Text(_formatDateTime(time, row['created_at']), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textDisabled)),
                ])),
              ]),
              if (targetType != null || targetId != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(width: double.infinity, padding: const EdgeInsets.all(AppSpacing.sm), decoration: BoxDecoration(color: AppColors.deepSlateDeep.withValues(alpha: 0.32), borderRadius: BorderRadius.circular(AppRadius.small)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.track_changes_rounded, size: 16, color: AdminTheme.accentLight), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('CIBLE', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AdminTheme.accentLight, letterSpacing: AppLetterSpacing.caps, fontWeight: FontWeight.w700)), const SizedBox(height: 3), SelectableText([targetType, targetId].whereType<String>().where((s) => s.isNotEmpty).join(' · '), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary))]))])),
              ],
              if (before != null || after != null) ...[
                const SizedBox(height: AppSpacing.md),
                _StateTransition(before: before, after: after),
              ],
              if (reason != null && reason.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(width: double.infinity, padding: const EdgeInsets.all(AppSpacing.sm), decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppRadius.small), border: Border.all(color: AppColors.warning.withValues(alpha: 0.16))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.subject_rounded, size: 16, color: AppColors.warning), const SizedBox(width: 7), Expanded(child: Text(reason, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.warning, height: 1.35)))])),
              ],
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),
              Row(children: [const Icon(Icons.person_outline_rounded, size: 15, color: AppColors.textDisabled), const SizedBox(width: 6), Expanded(child: SelectableText(actor, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textDisabled))), const Icon(Icons.fingerprint_rounded, size: 15, color: AppColors.textDisabled), const SizedBox(width: 5), Text('Trace conservée', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textDisabled))]),
            ]),
          ),
        ),
      ),
    ]);
  }
}

class _AuditTypeBadge extends StatelessWidget {
  const _AuditTypeBadge({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: color.withValues(alpha: 0.22))), child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700)));
}

class _StateTransition extends StatelessWidget {
  const _StateTransition({required this.before, required this.after});
  final dynamic before;
  final dynamic after;

  @override
  Widget build(BuildContext context) {
    final oldValue = _stringify(before);
    final newValue = _stringify(after);
    if ((before is Map || before is List) || (after is Map || after is List)) {
      return ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
        leading: const Icon(Icons.compare_arrows_rounded, color: AdminTheme.accentLight, size: 19),
        title: Text('Détail des changements', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
        subtitle: const Text('Afficher les valeurs avant / après'),
        children: [
          _JsonState(label: 'AVANT', value: oldValue, color: AppColors.textDisabled),
          const SizedBox(height: AppSpacing.xs),
          _JsonState(label: 'APRÈS', value: newValue, color: AdminTheme.accentLight),
        ],
      );
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: _StatePill(label: 'AVANT', value: oldValue, color: AppColors.textDisabled)),
      const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 18), child: Icon(Icons.arrow_forward_rounded, size: 15, color: AppColors.textDisabled)),
      Expanded(child: _StatePill(label: 'APRÈS', value: newValue, color: AdminTheme.accentLight)),
    ]);
  }
}

class _StatePill extends StatelessWidget {
  const _StatePill({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(AppSpacing.sm), decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppRadius.small), border: Border.all(color: color.withValues(alpha: 0.17))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, letterSpacing: AppLetterSpacing.caps, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(value, maxLines: 3, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary))]));
}

class _JsonState extends StatelessWidget {
  const _JsonState({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(AppSpacing.sm), decoration: BoxDecoration(color: AppColors.deepSlateDeep.withValues(alpha: 0.46), borderRadius: BorderRadius.circular(AppRadius.small), border: Border.all(color: color.withValues(alpha: 0.20))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, letterSpacing: AppLetterSpacing.caps, fontWeight: FontWeight.w800)), const SizedBox(height: 5), SelectableText(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace', height: 1.35))]));
}

class _AuditLoadError extends StatelessWidget {
  const _AuditLoadError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => AdminSectionCard(title: 'Journal momentanément indisponible', icon: Icons.cloud_off_rounded, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Les événements n’ont pas pu être récupérés. Vérifiez les droits d’accès ou la migration 006, puis réessayez.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)), const SizedBox(height: AppSpacing.md), FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Réessayer'))]));
}

class _LimitNotice extends StatelessWidget {
  const _LimitNotice();
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(color: AdminTheme.accent.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(AppRadius.medium), border: Border.all(color: AdminTheme.accent.withValues(alpha: 0.22))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.info_outline_rounded, size: 18, color: AdminTheme.accentLight), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('Les 200 événements les plus récents sont affichés. Utilisez la recherche et les filtres pour explorer cette fenêtre.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.35)))]));
}

String _prettyAction(String value) {
  final normalized = value.replaceAll('_', ' ').replaceAll('.', ' ').trim();
  if (normalized.isEmpty) return 'Action non précisée';
  return normalized[0].toUpperCase() + normalized.substring(1);
}

String _stringify(dynamic value) {
  if (value == null) return '—';
  if (value is Map || value is List) {
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }
  return value.toString();
}

DateTime? _parseDate(dynamic value) => value == null ? null : DateTime.tryParse(value.toString())?.toLocal();

String _formatDateTime(DateTime? date, dynamic fallback) {
  if (date == null) return fallback?.toString() ?? 'Date non renseignée';
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/${date.year} · $hour:$minute';
}
