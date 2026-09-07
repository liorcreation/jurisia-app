import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../core/widgets/entrance_fade.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/gradient_icon_badge.dart';
import '../../../core/widgets/luxury_scaffold_background.dart';
import '../../../features/contact_professional/domain/entities/contact_request.dart';
import '../../../features/contact_professional/domain/entities/professional_category.dart';
import '../../../theme/app_theme.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_ambience.dart';
import '../../widgets/admin_empty_state.dart';
import '../../widgets/admin_filter_chip.dart';
import '../../widgets/admin_page_header.dart';
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

/// Console — Demandes de mise en relation : la file de traitement. Trier par
/// statut, lire la demande, faire avancer le statut (chaque changement est
/// écrit au journal d'audit côté serveur).
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

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminContactRequestsController>();

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              AdminPageHeader(
                icon: Icons.support_agent_rounded,
                title: 'Demandes de mise en relation',
                subtitle: 'La file de traitement — chaque changement de statut est tracé au journal d\'audit.',
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
                AdminErrorBanner(message: controller.error!, onDismiss: controller.dismissError),
              Expanded(
                child: Stack(
                  children: [
                    const Positioned.fill(child: IgnorePointer(child: AdminAmbience())),
                    controller.isLoading && controller.items.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : controller.items.isEmpty
                            ? const AdminEmptyState(
                                icon: Icons.inbox_rounded,
                                message: 'Aucune demande pour l\'instant.',
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final columns = constraints.maxWidth >= 1100 ? 2 : 1;
                                  if (columns == 1) {
                                    return ListView.separated(
                                      padding: const EdgeInsets.all(AppSpacing.md),
                                      itemCount: controller.items.length,
                                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                                      itemBuilder: (context, index) => EntranceFadeSlide(
                                        index: index,
                                        child: _RequestCard(
                                          request: controller.items[index],
                                          busy: controller.isUpdating(controller.items[index].id),
                                          onStatus: (status) =>
                                              controller.updateStatus(controller.items[index].id, status),
                                        ),
                                      ),
                                    );
                                  }
                                  return GridView.builder(
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    itemCount: controller.items.length,
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: AppSpacing.sm,
                                      crossAxisSpacing: AppSpacing.sm,
                                      mainAxisExtent: 268,
                                    ),
                                    itemBuilder: (context, index) => EntranceFadeSlide(
                                      index: index,
                                      child: _RequestCard(
                                        request: controller.items[index],
                                        busy: controller.isUpdating(controller.items[index].id),
                                        onStatus: (status) =>
                                            controller.updateStatus(controller.items[index].id, status),
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

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.controller});

  final AdminContactRequestsController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
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
            for (final status in ContactRequestStatus.values)
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
  const _RequestCard({required this.request, required this.busy, required this.onStatus});

  final AdminContactRequest request;
  final bool busy;
  final ValueChanged<ContactRequestStatus> onStatus;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientIconBadge(
                icon: _categoryIcon(request.category),
                size: 38,
                gradient: AdminGradients.cobaltMetallic,
                iconColor: AppColors.textPrimary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(request.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.titleSmall),
                    Text(
                      request.category.label,
                      style: textTheme.labelSmall?.copyWith(color: AdminTheme.accentLight),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AdminStatusChip(label: request.status.label, color: contactStatusColor(request.status)),
                  const SizedBox(height: 4),
                  Text(_formatDate(request.createdAt), style: textTheme.labelSmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SelectableText(request.contactInfo, style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          Text(request.message, maxLines: 3, overflow: TextOverflow.ellipsis, style: textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (busy) ...[
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final status in ContactRequestStatus.values)
                      AdminFilterChip(
                        label: status.label,
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

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year}';
  }
}
