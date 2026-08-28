import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/luxury_scaffold_background.dart';
import '../../../features/contact_professional/domain/entities/contact_request.dart';
import '../../../features/contact_professional/domain/entities/professional_category.dart';
import '../../../theme/app_theme.dart';
import '../../theme/admin_theme.dart';
import 'admin_contact_request.dart';
import 'admin_contact_request_repository.dart';
import 'admin_contact_requests_controller.dart';

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
        appBar: AppBar(
          title: const Text('Demandes de mise en relation'),
          actions: [
            IconButton(
              tooltip: 'Rafraîchir',
              onPressed: controller.isLoading ? null : controller.load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _FilterBar(controller: controller),
              if (controller.error != null)
                _ErrorBanner(message: controller.error!, onDismiss: controller.dismissError),
              Expanded(
                child: controller.isLoading && controller.items.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : controller.items.isEmpty
                        ? const Center(child: Text('Aucune demande.'))
                        : ListView.separated(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            itemCount: controller.items.length,
                            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) => _RequestCard(
                              request: controller.items[index],
                              busy: controller.isUpdating(controller.items[index].id),
                              onStatus: (status) =>
                                  controller.updateStatus(controller.items[index].id, status),
                            ),
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
    Widget chip(String label, ContactRequestStatus? status, int? count) {
      final selected = controller.filter == status;
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: ChoiceChip(
          label: Text(count == null ? label : '$label · $count'),
          selected: selected,
          onSelected: (_) => controller.setFilter(status),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            chip('Toutes', null, controller.items.length),
            for (final status in ContactRequestStatus.values)
              chip(status.label, status, controller.countFor(status)),
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
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: AdminTheme.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Text(request.category.label, style: textTheme.labelSmall),
              ),
              const Spacer(),
              Text(_formatDate(request.createdAt), style: textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(request.fullName, style: textTheme.titleSmall),
          SelectableText(request.contactInfo, style: textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(request.message, style: textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (busy)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text('Statut', style: textTheme.labelSmall),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    for (final status in ContactRequestStatus.values)
                      ChoiceChip(
                        label: Text(status.label),
                        selected: request.status == status,
                        onSelected: busy ? null : (_) => onStatus(status),
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
