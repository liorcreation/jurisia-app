import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../core/widgets/entrance_fade.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/gradient_icon_badge.dart';
import '../../../core/widgets/luxury_scaffold_background.dart';
import '../../../core/widgets/premium_surface.dart';
import '../../../features/contact_professional/domain/entities/contact_request.dart';
import '../../../features/contact_professional/domain/entities/professional_category.dart';
import '../../../theme/app_theme.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_ambience.dart';
import '../../widgets/admin_empty_state.dart';
import '../../widgets/admin_filter_chip.dart';
import '../../widgets/admin_page_header.dart';
import '../../widgets/admin_stat_card.dart';
import '../../widgets/admin_status_chip.dart';
import 'admin_contact_request.dart';
import 'admin_contact_request_repository.dart';
import 'admin_contact_requests_controller.dart';

IconData _categoryIcon(ProfessionalCategory category) => switch (category) {
      ProfessionalCategory.notaire => Icons.description_rounded,
      ProfessionalCategory.avocat => Icons.gavel_rounded,
      ProfessionalCategory.juriste => Icons.balance_rounded,
      ProfessionalCategory.huissier => Icons.assignment_turned_in_rounded,
      ProfessionalCategory.greffier => Icons.folder_rounded,
      ProfessionalCategory.juge => Icons.account_balance_rounded,
    };

/// Console — centre de pilotage des demandes de mise en relation.
/// Le repository et le journal d'audit restent inchangés : cette surface
/// organise seulement la file pour permettre une prise en charge rapide et
/// traçable.
class AdminContactRequestsScreen extends StatelessWidget {
  const AdminContactRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminContactRequestsController>(
      create: (_) => AdminContactRequestsController(
        repository: SupabaseAdminContactRequestRepository(client: SupabaseConfig.client),
      ),
      child: const _View(),
    );
  }
}

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  ProfessionalCategory? _category;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminContactRequestsController>();
    final requests = controller.items
        .where((request) => _category == null || request.category == _category)
        .toList();
    final waiting = controller.countFor(ContactRequestStatus.pending);
    final contacted = controller.countFor(ContactRequestStatus.contacted);
    final closed = controller.countFor(ContactRequestStatus.closed);
    final error = controller.error;

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              AdminPageHeader(
                icon: Icons.support_agent_rounded,
                title: 'Mise en relation',
                subtitle: 'Pilotez chaque demande jusqu’à la bonne prise en charge.',
                actions: [
                  _PendingBadge(count: waiting),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    tooltip: 'Rafraîchir les demandes',
                    onPressed: controller.isLoading ? null : controller.load,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              if (error != null)
                AdminErrorBanner(message: error, onDismiss: controller.dismissError),
              Expanded(
                child: Stack(
                  children: [
                    const Positioned.fill(child: IgnorePointer(child: AdminAmbience())),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 1080;
                        final queue = _QueueContent(
                          controller: controller,
                          requests: requests,
                          category: _category,
                          onCategoryChanged: (value) => setState(() => _category = value),
                        );
                        if (!wide) return queue;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: queue),
                            const SizedBox(width: AppSpacing.md),
                            SizedBox(
                              width: 300,
                              child: _ConnectionGuide(
                                waiting: waiting,
                                contacted: contacted,
                                closed: closed,
                              ),
                            ),
                          ],
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

class _QueueContent extends StatelessWidget {
  const _QueueContent({
    required this.controller,
    required this.requests,
    required this.category,
    required this.onCategoryChanged,
  });

  final AdminContactRequestsController controller;
  final List<AdminContactRequest> requests;
  final ProfessionalCategory? category;
  final ValueChanged<ProfessionalCategory?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final total = controller.items.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
      children: [
        const _ConnectionHero(),
        const SizedBox(height: AppSpacing.md),
        _StatRow(controller: controller),
        const SizedBox(height: AppSpacing.xl),
        PremiumSectionHeader(
          eyebrow: 'FILE DE RELATION',
          title: 'Les demandes à traiter',
          subtitle: requests.isEmpty
              ? 'Aucune demande ne correspond à cette vue.'
              : '$total demande${total == 1 ? '' : 's'} dans la file, triées de la plus récente à la plus ancienne.',
          action: _CategoryFilters(selected: category, onChanged: onCategoryChanged),
        ),
        const SizedBox(height: AppSpacing.sm),
        _StatusFilters(controller: controller),
        const SizedBox(height: AppSpacing.md),
        controller.isLoading && requests.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: Center(child: CircularProgressIndicator()),
              )
            : requests.isEmpty
                ? const AdminEmptyState(
                    icon: Icons.forum_rounded,
                    message: 'La file est calme.',
                    detail: 'Les nouvelles demandes apparaîtront ici dès leur réception.',
                  )
                : Column(
                    children: [
                      for (var i = 0; i < requests.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: EntranceFadeSlide(
                            index: i,
                            child: _RequestCard(
                              request: requests[i],
                              busy: controller.isUpdating(requests[i].id),
                              onStatus: (status) => controller.updateStatus(requests[i].id, status),
                            ),
                          ),
                        ),
                    ],
                  ),
      ],
    );
  }
}

class _ConnectionHero extends StatelessWidget {
  const _ConnectionHero();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return PremiumSurface(
      tone: PremiumSurfaceTone.cobalt,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 590;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const GradientIconBadge(
                    icon: Icons.hub_rounded,
                    size: 48,
                    gradient: AdminGradients.cobaltMetallic,
                    iconColor: AppColors.textPrimary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'RELATION · JURISIA',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.goldLight,
                      fontWeight: FontWeight.w700,
                      letterSpacing: AppLetterSpacing.caps,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'La bonne expertise, au bon moment.',
                style: textTheme.headlineSmall?.copyWith(fontFamily: 'Libre Caslon Display'),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Chaque demande mérite une lecture attentive, une orientation juste et une réponse suivie.',
                style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.45),
              ),
            ],
          );
          final signal = Container(
            width: compact ? double.infinity : 180,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.deepSlateDeep.withValues(alpha: 0.48),
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.route_rounded, color: AppColors.goldLight, size: 20),
                const SizedBox(height: AppSpacing.sm),
                Text('PARCOURS SUIVI', style: textTheme.labelSmall?.copyWith(color: AppColors.goldLight, letterSpacing: AppLetterSpacing.label)),
                const SizedBox(height: AppSpacing.xs),
                Text('Reçue · Orientée · Suivie', style: textTheme.titleSmall),
              ],
            ),
          );
          if (compact) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [copy, const SizedBox(height: AppSpacing.md), signal]);
          }
          return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Expanded(child: copy), const SizedBox(width: AppSpacing.lg), signal]);
        },
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.controller});

  final AdminContactRequestsController controller;

  @override
  Widget build(BuildContext context) {
    final cards = [
      AdminStatCard(icon: Icons.inbox_rounded, label: 'Total', value: '${controller.items.length}', hint: 'File actuelle', accentColor: AdminTheme.accentLight),
      AdminStatCard(icon: Icons.schedule_rounded, label: 'En attente', value: '${controller.countFor(ContactRequestStatus.pending)}', hint: 'À prioriser', accentColor: AppColors.warning),
      AdminStatCard(icon: Icons.handshake_rounded, label: 'Prises en charge', value: '${controller.countFor(ContactRequestStatus.contacted)}', hint: 'Suivi engagé', accentColor: AppColors.cobaltLight),
      AdminStatCard(icon: Icons.check_circle_outline_rounded, label: 'Clôturées', value: '${controller.countFor(ContactRequestStatus.closed)}', hint: 'Parcours terminé', accentColor: AppColors.success),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 610) {
          return Column(children: [for (var i = 0; i < cards.length; i++) ...[cards[i], if (i != cards.length - 1) const SizedBox(height: AppSpacing.sm)]]);
        }
        final columns = constraints.maxWidth < 860 ? 2 : 4;
        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: columns == 2 ? 2.2 : 1.25,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cards,
        );
      },
    );
  }
}

class _StatusFilters extends StatelessWidget {
  const _StatusFilters({required this.controller});

  final AdminContactRequestsController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: AdminFilterChip(label: 'Toutes', count: controller.items.length, selected: controller.filter == null, onTap: () => controller.setFilter(null)),
          ),
          for (final status in ContactRequestStatus.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: AdminFilterChip(label: status.label, count: controller.countFor(status), selected: controller.filter == status, onTap: () => controller.setFilter(status)),
            ),
        ],
      ),
    );
  }
}

class _CategoryFilters extends StatelessWidget {
  const _CategoryFilters({required this.selected, required this.onChanged});

  final ProfessionalCategory? selected;
  final ValueChanged<ProfessionalCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        _CategoryPill(label: 'Toutes les expertises', icon: Icons.grid_view_rounded, selected: selected == null, onTap: () => onChanged(null)),
        for (final category in ProfessionalCategory.values)
          _CategoryPill(label: category.label, icon: _categoryIcon(category), selected: selected == category, onTap: () => onChanged(category)),
      ],
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label, required this.icon, required this.selected, required this.onTap});

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.goldLight : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: AnimatedContainer(
        duration: AppMotion.quick,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold.withValues(alpha: 0.16) : AppColors.textPrimary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: color.withValues(alpha: selected ? 0.50 : 0.18)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 15, color: color), const SizedBox(width: 5), Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700))]),
      ),
    );
  }
}

class _ConnectionGuide extends StatelessWidget {
  const _ConnectionGuide({required this.waiting, required this.contacted, required this.closed});

  final int waiting;
  final int contacted;
  final int closed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, right: AppSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('VUE OPÉRATEUR', style: textTheme.labelSmall?.copyWith(color: AppColors.goldLight, fontWeight: FontWeight.w700, letterSpacing: AppLetterSpacing.caps)),
        const SizedBox(height: AppSpacing.sm),
        Text('Une file qui respire.', style: textTheme.titleLarge?.copyWith(fontFamily: 'Libre Caslon Display')),
        const SizedBox(height: AppSpacing.md),
        PremiumSurface(
          padding: const EdgeInsets.all(AppSpacing.md),
          tone: PremiumSurfaceTone.elevated,
          child: Column(children: [
            _FlowRow(label: 'En attente', value: waiting, color: AppColors.warning, icon: Icons.schedule_rounded),
            const _FlowDivider(),
            _FlowRow(label: 'Prise en charge', value: contacted, color: AppColors.cobaltLight, icon: Icons.handshake_rounded),
            const _FlowDivider(),
            _FlowRow(label: 'Clôturées', value: closed, color: AppColors.success, icon: Icons.check_circle_outline_rounded),
          ]),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Chaque changement de statut est envoyé à la procédure d’administration et journalisé côté serveur.', style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.45)),
      ]),
    );
  }
}

class _FlowRow extends StatelessWidget {
  const _FlowRow({required this.label, required this.value, required this.color, required this.icon});

  final String label;
  final int value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(children: [Icon(icon, size: 18, color: color), const SizedBox(width: AppSpacing.sm), Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall)), Text('$value', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w700))]);
}

class _FlowDivider extends StatelessWidget {
  const _FlowDivider();

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm), child: Divider(color: AppColors.textPrimary.withValues(alpha: 0.08), height: 1));
}

class _PendingBadge extends StatelessWidget {
  const _PendingBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final color = count == 0 ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: color.withValues(alpha: 0.28))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(count == 0 ? Icons.check_circle_outline_rounded : Icons.schedule_rounded, size: 16, color: color), const SizedBox(width: 5), Text('$count à traiter', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700))]),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.busy, required this.onStatus});

  final AdminContactRequest request;
  final bool busy;
  final ValueChanged<ContactRequestStatus> onStatus;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final statusColor = contactStatusColor(request.status);
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: statusColor.withValues(alpha: 0.32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GradientIconBadge(icon: _categoryIcon(request.category), size: 42, gradient: AdminGradients.cobaltMetallic, iconColor: AppColors.textPrimary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('DEMANDE DE ${request.category.label.toUpperCase()}', style: textTheme.labelSmall?.copyWith(color: AdminTheme.accentLight, fontWeight: FontWeight.w700, letterSpacing: AppLetterSpacing.label)),
            const SizedBox(height: 2),
            Text(request.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [AdminStatusChip(label: request.status.label, color: statusColor), const SizedBox(height: 4), Text(_formatDate(request.createdAt), style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled))]),
        ]),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(color: AppColors.deepSlateDeep.withValues(alpha: 0.34), borderRadius: BorderRadius.circular(AppRadius.small), border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.08))),
          child: Row(children: [const Icon(Icons.alternate_email_rounded, size: 17, color: AppColors.goldLight), const SizedBox(width: AppSpacing.sm), Expanded(child: SelectableText(request.contactInfo, style: textTheme.bodySmall?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)))]),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(request.message, maxLines: 3, overflow: TextOverflow.ellipsis, style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.4)),
        const SizedBox(height: AppSpacing.md),
        Row(children: [if (busy) ...[const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: AppSpacing.sm)], Expanded(child: Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [for (final status in ContactRequestStatus.values) AdminFilterChip(label: status.label, selected: request.status == status, onTap: busy ? () {} : () => onStatus(status))]))]),
      ]),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year}';
  }
}
