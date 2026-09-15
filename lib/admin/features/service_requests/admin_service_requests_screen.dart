import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../core/widgets/entrance_fade.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/gradient_icon_badge.dart';
import '../../../core/widgets/luxury_scaffold_background.dart';
import '../../../features/professional/domain/entities/professional_service_category.dart';
import '../../../features/professional/domain/entities/professional_service_request.dart';
import '../../../theme/app_theme.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_ambience.dart';
import '../../widgets/admin_empty_state.dart';
import '../../widgets/admin_filter_chip.dart';
import '../../widgets/admin_page_header.dart';
import '../../widgets/admin_status_chip.dart';
import 'admin_service_request_repository.dart';
import 'admin_service_requests_controller.dart';

class AdminServiceRequestsScreen extends StatelessWidget {
  const AdminServiceRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminServiceRequestsController>(
      create: (_) => AdminServiceRequestsController(
        repository: SupabaseAdminServiceRequestRepository(
          client: SupabaseConfig.client,
        ),
      ),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminServiceRequestsController>();
    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              AdminPageHeader(
                icon: Icons.assignment_rounded,
                title: 'Demandes d’actes & rendez-vous',
                subtitle:
                    'Devis, créneaux et lieux de dépôt — chaque notification est authentifiée.',
                actions: [
                  IconButton(
                    tooltip: 'Rafraîchir',
                    onPressed: controller.isLoading ? null : controller.load,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              _FilterBar(controller: controller),
              if (controller.error != null)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: MaterialBanner(
                    backgroundColor: AppColors.error.withValues(alpha: 0.12),
                    content: Text(controller.error!),
                    actions: [
                      TextButton(
                        onPressed: controller.dismissError,
                        child: const Text('Fermer'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: IgnorePointer(child: AdminAmbience()),
                    ),
                    controller.isLoading && controller.items.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : controller.items.isEmpty
                        ? const AdminEmptyState(
                            icon: Icons.assignment_late_rounded,
                            message: 'Aucune demande d’acte ou de rendez-vous.',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            itemCount: controller.items.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              final request = controller.items[index];
                              return EntranceFadeSlide(
                                index: index,
                                child: _RequestCard(
                                  request: request,
                                  busy: controller.isUpdating(request.id),
                                  onStatus: (status) => _handleStatus(
                                    context,
                                    controller,
                                    request,
                                    status,
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

    final amount = TextEditingController(
      text: request.quoteAmount?.toString() ?? '',
    );
    final deposit = TextEditingController(text: request.depositUrl ?? '');
    final dropoff = TextEditingController(text: request.dropoffLocation ?? '');
    final pickup = TextEditingController(text: request.pickupLocation ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Préparer le devis'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Montant (XOF)'),
              ),
              TextField(
                controller: deposit,
                decoration: const InputDecoration(
                  labelText: 'Lien de paiement (facultatif)',
                ),
              ),
              TextField(
                controller: dropoff,
                decoration: const InputDecoration(
                  labelText: 'Lieu de dépôt (facultatif)',
                ),
              ),
              TextField(
                controller: pickup,
                decoration: const InputDecoration(
                  labelText: 'Lieu de retrait (facultatif)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Notifier le devis'),
          ),
        ],
      ),
    );
    final quote = num.tryParse(amount.text.replaceAll(',', '.').trim());
    if (confirmed == true && quote != null) {
      await controller.updateStatus(
        request.id,
        status,
        quoteAmount: quote,
        depositUrl: deposit.text.trim(),
        dropoffLocation: dropoff.text.trim(),
        pickupLocation: pickup.text.trim(),
      );
    }
    amount.dispose();
    deposit.dispose();
    dropoff.dispose();
    pickup.dispose();
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.controller});

  final AdminServiceRequestsController controller;

  @override
  Widget build(BuildContext context) {
    final statuses = ProfessionalServiceRequestStatus.values;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: AdminFilterChip(
                label: 'Toutes',
                count: controller.items.length,
                selected: controller.filter == null,
                onTap: () => controller.setFilter(null),
              ),
            ),
            for (final status in statuses)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: AdminFilterChip(
                  label: status.label,
                  count: controller.countFor(status),
                  selected: controller.filter == status,
                  onTap: () => controller.setFilter(status),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.busy,
    required this.onStatus,
  });

  final ProfessionalServiceRequest request;
  final bool busy;
  final ValueChanged<ProfessionalServiceRequestStatus> onStatus;

  @override
  Widget build(BuildContext context) {
    final title = request.kind == ProfessionalRequestKind.legalAct
        ? request.actType ?? 'Acte juridique'
        : 'Rendez-vous ${request.category.label.toLowerCase()}';
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientIconBadge(
                icon: request.kind == ProfessionalRequestKind.legalAct
                    ? Icons.article_rounded
                    : Icons.calendar_month_rounded,
                size: 40,
                gradient: AdminGradients.cobaltMetallic,
                iconColor: AppColors.textPrimary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    Text(
                      '${request.fullName} · ${request.category.label}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AdminTheme.accentLight,
                      ),
                    ),
                  ],
                ),
              ),
              AdminStatusChip(
                label: request.status.label,
                color: _statusColor(request.status),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${request.email} · ${request.phone}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(request.details, maxLines: 3, overflow: TextOverflow.ellipsis),
          if (request.quoteAmount != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Devis : ${request.quoteAmount} ${request.quoteCurrency}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.goldLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (busy) ...[
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final status in const [
                      ProfessionalServiceRequestStatus.acknowledged,
                      ProfessionalServiceRequestStatus.quoteReady,
                      ProfessionalServiceRequestStatus.scheduled,
                      ProfessionalServiceRequestStatus.closed,
                      ProfessionalServiceRequestStatus.cancelled,
                    ])
                      AdminFilterChip(
                        label:
                            status ==
                                ProfessionalServiceRequestStatus.quoteReady
                            ? 'Devis'
                            : status.label,
                        selected: request.status == status,
                        onTap: busy ? () {} : () => onStatus(status),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Color _statusColor(ProfessionalServiceRequestStatus status) => switch (status) {
  ProfessionalServiceRequestStatus.submitted => AppColors.warning,
  ProfessionalServiceRequestStatus.acknowledged => AdminTheme.accentLight,
  ProfessionalServiceRequestStatus.quoteReady => AppColors.gold,
  ProfessionalServiceRequestStatus.scheduled => AppColors.success,
  ProfessionalServiceRequestStatus.closed => AppColors.textSecondary,
  ProfessionalServiceRequestStatus.cancelled => AppColors.error,
};
