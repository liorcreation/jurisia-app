import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../core/widgets/entrance_fade.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/gradient_icon_badge.dart';
import '../../../core/widgets/luxury_scaffold_background.dart';
import '../../../core/widgets/premium_surface.dart';
import '../../../features/professional/domain/entities/professional_service_category.dart';
import '../../../features/professional/domain/entities/professional_service_request.dart';
import '../../../theme/app_theme.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_ambience.dart';
import '../../widgets/admin_empty_state.dart';
import '../../widgets/admin_filter_chip.dart';
import '../../widgets/admin_page_header.dart';
import '../../widgets/admin_stat_card.dart';
import '../../widgets/admin_status_chip.dart';
import 'admin_service_request_repository.dart';
import 'admin_service_requests_controller.dart';

/// Console — centre de pilotage des actes et rendez-vous professionnels.
/// Les données, notifications et transitions métier restent confiées au
/// contrôleur et au repository existants ; cette vue clarifie le parcours.
class AdminServiceRequestsScreen extends StatelessWidget {
  const AdminServiceRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminServiceRequestsController>(
      create: (_) => AdminServiceRequestsController(
        repository: SupabaseAdminServiceRequestRepository(client: SupabaseConfig.client),
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
  ProfessionalRequestKind? _kind;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminServiceRequestsController>();
    final requests = controller.items.where((request) => _kind == null || request.kind == _kind).toList();
    final received = controller.countFor(ProfessionalServiceRequestStatus.submitted);
    final quotes = controller.countFor(ProfessionalServiceRequestStatus.quoteReady);
    final scheduled = controller.countFor(ProfessionalServiceRequestStatus.scheduled);

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              AdminPageHeader(
                icon: Icons.assignment_rounded,
                title: 'Actes & rendez-vous',
                subtitle: 'De la première demande à la livraison, chaque étape reste visible.',
                actions: [
                  _IncomingBadge(count: received),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    tooltip: 'Rafraîchir les demandes',
                    onPressed: controller.isLoading ? null : controller.load,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              if (controller.error != null)
                AdminErrorBanner(message: controller.error!, onDismiss: controller.dismissError),
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
                          kind: _kind,
                          onKindChanged: (value) => setState(() => _kind = value),
                          onStatus: (request, status) => _handleStatus(context, controller, request, status),
                        );
                        if (!wide) return queue;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: queue),
                            const SizedBox(width: AppSpacing.md),
                            SizedBox(
                              width: 300,
                              child: _ServiceFlowGuide(received: received, quotes: quotes, scheduled: scheduled),
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

  Future<void> _handleStatus(
    BuildContext context,
    AdminServiceRequestsController controller,
    ProfessionalServiceRequest request,
    ProfessionalServiceRequestStatus status,
  ) async {
    if (status != ProfessionalServiceRequestStatus.quoteReady) {
      await controller.updateStatus(request.id, status);
      return;
    }

    final amount = TextEditingController(text: request.quoteAmount?.toString() ?? '');
    final deposit = TextEditingController(text: request.depositUrl ?? '');
    final dropoff = TextEditingController(text: request.dropoffLocation ?? '');
    final pickup = TextEditingController(text: request.pickupLocation ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Préparer le devis'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Les informations seront envoyées au demandeur avec la notification de devis.', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Montant (XOF)')),
            TextField(controller: deposit, decoration: const InputDecoration(labelText: 'Lien de paiement (facultatif)')),
            TextField(controller: dropoff, decoration: const InputDecoration(labelText: 'Lieu de dépôt (facultatif)')),
            TextField(controller: pickup, decoration: const InputDecoration(labelText: 'Lieu de retrait (facultatif)')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Notifier le devis')),
        ],
      ),
    );
    final quote = num.tryParse(amount.text.replaceAll(',', '.').trim());
    if (confirmed == true && quote != null) {
      await controller.updateStatus(request.id, status, quoteAmount: quote, depositUrl: deposit.text.trim(), dropoffLocation: dropoff.text.trim(), pickupLocation: pickup.text.trim());
    }
    amount.dispose();
    deposit.dispose();
    dropoff.dispose();
    pickup.dispose();
  }
}

class _QueueContent extends StatelessWidget {
  const _QueueContent({required this.controller, required this.requests, required this.kind, required this.onKindChanged, required this.onStatus});

  final AdminServiceRequestsController controller;
  final List<ProfessionalServiceRequest> requests;
  final ProfessionalRequestKind? kind;
  final ValueChanged<ProfessionalRequestKind?> onKindChanged;
  final Future<void> Function(ProfessionalServiceRequest, ProfessionalServiceRequestStatus) onStatus;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
      children: [
        const _ServiceHero(),
        const SizedBox(height: AppSpacing.md),
        _StatRow(controller: controller),
        const SizedBox(height: AppSpacing.xl),
        PremiumSectionHeader(
          eyebrow: 'ATELIER OPÉRATIONNEL',
          title: 'Les demandes actives',
          subtitle: requests.isEmpty ? 'Aucune demande ne correspond à cette vue.' : '${requests.length} demande${requests.length == 1 ? '' : 's'} à suivre dans le parcours.',
          action: _KindFilters(selected: kind, onChanged: onKindChanged),
        ),
        const SizedBox(height: AppSpacing.sm),
        _StatusFilters(controller: controller),
        const SizedBox(height: AppSpacing.md),
        controller.isLoading && requests.isEmpty
            ? const Padding(padding: EdgeInsets.all(AppSpacing.xxl), child: Center(child: CircularProgressIndicator()))
            : requests.isEmpty
                ? const AdminEmptyState(icon: Icons.assignment_turned_in_rounded, message: 'Aucune demande active.', detail: 'Les nouvelles demandes d’acte et de rendez-vous apparaîtront ici.')
                : Column(children: [for (var i = 0; i < requests.length; i++) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: EntranceFadeSlide(index: i, child: _RequestCard(request: requests[i], busy: controller.isUpdating(requests[i].id), onStatus: (status) => onStatus(requests[i], status))))]),
      ],
    );
  }
}

class _ServiceHero extends StatelessWidget {
  const _ServiceHero();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return PremiumSurface(
      tone: PremiumSurfaceTone.cobalt,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 590;
        final copy = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const GradientIconBadge(icon: Icons.auto_awesome_motion_rounded, size: 48, gradient: AdminGradients.cobaltMetallic, iconColor: AppColors.textPrimary), const SizedBox(width: AppSpacing.md), Text('ATELIER JURISIA', style: textTheme.labelSmall?.copyWith(color: AppColors.goldLight, fontWeight: FontWeight.w700, letterSpacing: AppLetterSpacing.caps))]),
          const SizedBox(height: AppSpacing.md),
          Text('Transformer une demande en résultat concret.', style: textTheme.headlineSmall?.copyWith(fontFamily: 'Libre Caslon Display')),
          const SizedBox(height: AppSpacing.xs),
          Text('Préparer un acte, cadrer un devis, confirmer un rendez-vous : chaque détail compte pour offrir une expérience professionnelle.', style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.45)),
        ]);
        final signal = Container(width: compact ? double.infinity : 180, padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(color: AppColors.deepSlateDeep.withValues(alpha: 0.48), borderRadius: BorderRadius.circular(AppRadius.medium), border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.10))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.timeline_rounded, color: AppColors.goldLight, size: 20), const SizedBox(height: AppSpacing.sm), Text('PARCOURS SUIVI', style: textTheme.labelSmall?.copyWith(color: AppColors.goldLight, letterSpacing: AppLetterSpacing.label)), const SizedBox(height: AppSpacing.xs), Text('Brief · Devis · Rendez-vous', style: textTheme.titleSmall)]));
        if (compact) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [copy, const SizedBox(height: AppSpacing.md), signal]);
        return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Expanded(child: copy), const SizedBox(width: AppSpacing.lg), signal]);
      }),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.controller});

  final AdminServiceRequestsController controller;

  @override
  Widget build(BuildContext context) {
    final cards = [
      AdminStatCard(icon: Icons.inbox_rounded, label: 'Total', value: '${controller.items.length}', hint: 'File actuelle', accentColor: AdminTheme.accentLight),
      AdminStatCard(icon: Icons.mark_email_unread_rounded, label: 'Reçues', value: '${controller.countFor(ProfessionalServiceRequestStatus.submitted)}', hint: 'À prendre en charge', accentColor: AppColors.warning),
      AdminStatCard(icon: Icons.request_quote_rounded, label: 'Devis', value: '${controller.countFor(ProfessionalServiceRequestStatus.quoteReady)}', hint: 'À confirmer', accentColor: AppColors.gold),
      AdminStatCard(icon: Icons.event_available_rounded, label: 'Rendez-vous', value: '${controller.countFor(ProfessionalServiceRequestStatus.scheduled)}', hint: 'Confirmés', accentColor: AppColors.success),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 610) return Column(children: [for (var i = 0; i < cards.length; i++) ...[cards[i], if (i != cards.length - 1) const SizedBox(height: AppSpacing.sm)]]);
      final columns = constraints.maxWidth < 860 ? 2 : 4;
      return GridView.count(crossAxisCount: columns, crossAxisSpacing: AppSpacing.sm, mainAxisSpacing: AppSpacing.sm, childAspectRatio: columns == 2 ? 2.2 : 1.25, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: cards);
    });
  }
}

class _StatusFilters extends StatelessWidget {
  const _StatusFilters({required this.controller});

  final AdminServiceRequestsController controller;

  @override
  Widget build(BuildContext context) {
    final statuses = ProfessionalServiceRequestStatus.values;
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [Padding(padding: const EdgeInsets.only(right: AppSpacing.sm), child: AdminFilterChip(label: 'Toutes', count: controller.items.length, selected: controller.filter == null, onTap: () => controller.setFilter(null))), for (final status in statuses) Padding(padding: const EdgeInsets.only(right: AppSpacing.sm), child: AdminFilterChip(label: _statusLabel(status), count: controller.countFor(status), selected: controller.filter == status, onTap: () => controller.setFilter(status)))]));
  }
}

class _KindFilters extends StatelessWidget {
  const _KindFilters({required this.selected, required this.onChanged});

  final ProfessionalRequestKind? selected;
  final ValueChanged<ProfessionalRequestKind?> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [_KindPill(label: 'Tout', icon: Icons.grid_view_rounded, selected: selected == null, onTap: () => onChanged(null)), _KindPill(label: 'Actes', icon: Icons.article_rounded, selected: selected == ProfessionalRequestKind.legalAct, onTap: () => onChanged(ProfessionalRequestKind.legalAct)), _KindPill(label: 'Rendez-vous', icon: Icons.calendar_month_rounded, selected: selected == ProfessionalRequestKind.expertAppointment, onTap: () => onChanged(ProfessionalRequestKind.expertAppointment))]);
}

class _KindPill extends StatelessWidget {
  const _KindPill({required this.label, required this.icon, required this.selected, required this.onTap});

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.goldLight : AppColors.textSecondary;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AppRadius.pill), child: AnimatedContainer(duration: AppMotion.quick, padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs), decoration: BoxDecoration(color: selected ? AppColors.gold.withValues(alpha: 0.16) : AppColors.textPrimary.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: color.withValues(alpha: selected ? 0.50 : 0.18))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 15, color: color), const SizedBox(width: 5), Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700))])));
  }
}

class _ServiceFlowGuide extends StatelessWidget {
  const _ServiceFlowGuide({required this.received, required this.quotes, required this.scheduled});

  final int received;
  final int quotes;
  final int scheduled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(padding: const EdgeInsets.only(top: AppSpacing.lg, right: AppSpacing.lg), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('VUE OPÉRATEUR', style: textTheme.labelSmall?.copyWith(color: AppColors.goldLight, fontWeight: FontWeight.w700, letterSpacing: AppLetterSpacing.caps)), const SizedBox(height: AppSpacing.sm), Text('Un parcours sans angle mort.', style: textTheme.titleLarge?.copyWith(fontFamily: 'Libre Caslon Display')), const SizedBox(height: AppSpacing.md), PremiumSurface(padding: const EdgeInsets.all(AppSpacing.md), tone: PremiumSurfaceTone.elevated, child: Column(children: [_FlowRow(label: 'Demandes reçues', value: received, color: AppColors.warning, icon: Icons.mark_email_unread_rounded), const _FlowDivider(), _FlowRow(label: 'Devis disponibles', value: quotes, color: AppColors.gold, icon: Icons.request_quote_rounded), const _FlowDivider(), _FlowRow(label: 'Rendez-vous confirmés', value: scheduled, color: AppColors.success, icon: Icons.event_available_rounded)])), const SizedBox(height: AppSpacing.md), Text('La notification de devis rassemble le montant, le paiement et les lieux de dépôt ou de retrait lorsqu’ils sont renseignés.', style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.45))]));
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

class _IncomingBadge extends StatelessWidget {
  const _IncomingBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final color = count == 0 ? AppColors.success : AppColors.warning;
    return Container(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs), decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: color.withValues(alpha: 0.28))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(count == 0 ? Icons.check_circle_outline_rounded : Icons.mark_email_unread_rounded, size: 16, color: color), const SizedBox(width: 5), Text('$count reçue${count == 1 ? '' : 's'}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700))]));
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.busy, required this.onStatus});

  final ProfessionalServiceRequest request;
  final bool busy;
  final ValueChanged<ProfessionalServiceRequestStatus> onStatus;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final title = request.kind == ProfessionalRequestKind.legalAct ? request.actType ?? 'Acte juridique' : 'Rendez-vous ${request.category.label.toLowerCase()}';
    final statusColor = _statusColor(request.status);
    final actionStatuses = const [ProfessionalServiceRequestStatus.acknowledged, ProfessionalServiceRequestStatus.quoteReady, ProfessionalServiceRequestStatus.scheduled, ProfessionalServiceRequestStatus.closed, ProfessionalServiceRequestStatus.cancelled];
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: statusColor.withValues(alpha: 0.34),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GradientIconBadge(icon: request.kind == ProfessionalRequestKind.legalAct ? Icons.article_rounded : Icons.calendar_month_rounded, size: 42, gradient: AdminGradients.cobaltMetallic, iconColor: AppColors.textPrimary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(request.kind == ProfessionalRequestKind.legalAct ? 'DEMANDE D’ACTE' : 'DEMANDE DE RENDEZ-VOUS', style: textTheme.labelSmall?.copyWith(color: AdminTheme.accentLight, fontWeight: FontWeight.w700, letterSpacing: AppLetterSpacing.label)), const SizedBox(height: 2), Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)), const SizedBox(height: 2), Text('${request.fullName} · ${request.category.label}', style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary))])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [AdminStatusChip(label: _statusLabel(request.status), color: statusColor), const SizedBox(height: 4), Text(_formatDate(request.createdAt), style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled))]),
        ]),
        const SizedBox(height: AppSpacing.md),
        Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [_InfoTag(icon: Icons.priority_high_rounded, label: request.urgency.label, color: request.urgency == ProfessionalRequestUrgency.urgent ? AppColors.error : request.urgency == ProfessionalRequestUrgency.priority ? AppColors.warning : AppColors.textSecondary), if (request.desiredDate != null) _InfoTag(icon: Icons.event_rounded, label: 'Souhaité le ${_formatDate(request.desiredDate!)}', color: AppColors.cobaltLight), if (request.appointmentMode != null) _InfoTag(icon: Icons.video_call_rounded, label: request.appointmentMode!.label, color: AppColors.cobaltLight), if (request.attachmentNames.isNotEmpty) _InfoTag(icon: Icons.attach_file_rounded, label: '${request.attachmentNames.length} pièce${request.attachmentNames.length == 1 ? '' : 's'}', color: AppColors.goldLight)]),
        const SizedBox(height: AppSpacing.sm),
        Container(padding: const EdgeInsets.all(AppSpacing.sm), decoration: BoxDecoration(color: AppColors.deepSlateDeep.withValues(alpha: 0.34), borderRadius: BorderRadius.circular(AppRadius.small), border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.08))), child: Row(children: [const Icon(Icons.contact_mail_outlined, size: 17, color: AppColors.goldLight), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('${request.email} · ${request.phone}', maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.bodySmall?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)))])),
        const SizedBox(height: AppSpacing.sm),
        Text(request.details, maxLines: 3, overflow: TextOverflow.ellipsis, style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.4)),
        if (request.quoteAmount != null) ...[const SizedBox(height: AppSpacing.sm), Row(children: [const Icon(Icons.request_quote_rounded, size: 17, color: AppColors.goldLight), const SizedBox(width: AppSpacing.xs), Text('Devis : ${request.quoteAmount} ${request.quoteCurrency}', style: textTheme.labelMedium?.copyWith(color: AppColors.goldLight, fontWeight: FontWeight.w700))])],
        if (request.dropoffLocation != null || request.pickupLocation != null) ...[const SizedBox(height: AppSpacing.xs), Text('Logistique : ${request.dropoffLocation ?? 'Dépôt à définir'} → ${request.pickupLocation ?? 'Retrait à définir'}', style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled))],
        const SizedBox(height: AppSpacing.md),
        Row(children: [if (busy) ...[const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: AppSpacing.sm)], Expanded(child: Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [for (final status in actionStatuses) AdminFilterChip(label: status == ProfessionalServiceRequestStatus.quoteReady ? 'Devis' : _statusLabel(status), selected: request.status == status, onTap: busy ? () {} : () => onStatus(status))]))]),
      ]),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs), decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: color.withValues(alpha: 0.25))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: color), const SizedBox(width: 4), Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600))]));
}

String _statusLabel(ProfessionalServiceRequestStatus status) => status == ProfessionalServiceRequestStatus.quoteReady ? 'Devis disponible' : status.label;

Color _statusColor(ProfessionalServiceRequestStatus status) => switch (status) {
      ProfessionalServiceRequestStatus.submitted => AppColors.warning,
      ProfessionalServiceRequestStatus.acknowledged => AdminTheme.accentLight,
      ProfessionalServiceRequestStatus.quoteReady => AppColors.gold,
      ProfessionalServiceRequestStatus.scheduled => AppColors.success,
      ProfessionalServiceRequestStatus.closed => AppColors.textSecondary,
      ProfessionalServiceRequestStatus.cancelled => AppColors.error,
    };

String _formatDate(DateTime date) {
  final local = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year}';
}
