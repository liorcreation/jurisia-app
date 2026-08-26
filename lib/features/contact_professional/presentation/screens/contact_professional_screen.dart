import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/supabase/supabase_config.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/luxury_scaffold_background.dart';
import '../../../../theme/app_theme.dart';
import '../../data/repositories/contact_professional_repository_impl.dart';
import '../../domain/entities/contact_request.dart';
import '../../domain/entities/professional_category.dart';
import '../../domain/repositories/contact_professional_repository.dart';
import '../../domain/usecases/submit_contact_request_usecase.dart';
import '../controllers/contact_professional_controller.dart';
import '../widgets/contact_request_sheet.dart';
import '../widgets/professional_category_card.dart';

ContactProfessionalController _buildController() {
  final ContactProfessionalRepository repository = ContactProfessionalRepositoryImpl(
    supabaseClient: SupabaseConfig.isReady ? SupabaseConfig.client : null,
    userId: SupabaseConfig.isReady ? SupabaseConfig.client.auth.currentUser?.id : null,
  );
  return ContactProfessionalController(
    repository: repository,
    submitUseCase: SubmitContactRequestUseCase(repository: repository),
  );
}

/// Section 5 — Contacter un professionnel : mise en relation avec un
/// notaire, avocat, juriste, huissier, greffier ou juge partenaire, via une
/// demande de contact enregistrée et suivie dans Supabase.
class ContactProfessionalScreen extends StatelessWidget {
  const ContactProfessionalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ContactProfessionalController>(
      create: (_) => _buildController(),
      child: const _ContactProfessionalView(),
    );
  }
}

class _ContactProfessionalView extends StatelessWidget {
  const _ContactProfessionalView();

  void _openRequestSheet(BuildContext context, ProfessionalCategory category) {
    final controller = context.read<ContactProfessionalController>();
    controller.resetStatus();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ChangeNotifierProvider<ContactProfessionalController>.value(
        value: controller,
        child: ContactRequestSheet(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ContactProfessionalController>();

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Contacter un professionnel')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                'Mise en relation avec un professionnel du droit',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Choisissez le type de professionnel qu\'il vous faut : votre demande est transmise '
                'et un partenaire vous recontacte directement.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ProfessionalCategory.values.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.92,
                ),
                itemBuilder: (context, index) {
                  final category = ProfessionalCategory.values[index];
                  return ProfessionalCategoryCard(
                    category: category,
                    onTap: () => _openRequestSheet(context, category),
                  );
                },
              ),
              if (controller.requests.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Text('Mes demandes', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                for (final request in controller.requests)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _ContactRequestTile(request: request),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactRequestTile extends StatelessWidget {
  const _ContactRequestTile({required this.request});

  final ContactRequest request;

  Color _statusColor(ContactRequestStatus status) {
    switch (status) {
      case ContactRequestStatus.pending:
        return AppColors.warning;
      case ContactRequestStatus.contacted:
        return AppColors.success;
      case ContactRequestStatus.closed:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final statusColor = _statusColor(request.status);

    return GlassContainer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(iconForCategory(request.category), color: AppColors.gold, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.category.label, style: textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  request.message,
                  style: textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              request.status.label,
              style: textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
