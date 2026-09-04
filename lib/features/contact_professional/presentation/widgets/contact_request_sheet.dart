import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/platform/app_platform_style.dart';
import '../../../../core/validation/input_limits.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glow_focus_field.dart';
import '../../../../core/widgets/gradient_icon_badge.dart';
import '../../../../core/widgets/luxury_elevated_button.dart';
import '../../../../core/widgets/smoked_glass_surface.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/entities/professional_category.dart';
import '../controllers/contact_professional_controller.dart';
import 'professional_category_card.dart';

/// Formulaire de prise de contact affiché en feuille modale après le choix
/// d'une catégorie de professionnel.
class ContactRequestSheet extends StatefulWidget {
  const ContactRequestSheet({super.key, required this.category});

  final ProfessionalCategory category;

  @override
  State<ContactRequestSheet> createState() => _ContactRequestSheetState();
}

class _ContactRequestSheetState extends State<ContactRequestSheet> {
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty &&
      _contactController.text.trim().isNotEmpty &&
      _messageController.text.trim().isNotEmpty;

  Future<void> _submit(ContactProfessionalController controller) async {
    final success = await controller.submit(
      category: widget.category,
      fullName: _nameController.text,
      contactInfo: _contactController.text,
      message: _messageController.text,
    );
    if (!mounted || !success) return;

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Demande envoyée. Un ${widget.category.label.toLowerCase()} partenaire vous recontactera prochainement.',
        ),
        backgroundColor: AppColors.legalBlueDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ContactProfessionalController>();

    if (AppPlatformStyle.of(context) == AppPlatformStyle.desktop) {
      return _buildDesktopDialog(context, controller);
    }
    return _buildMobileSheet(context, controller);
  }

  Widget? _noticeCard(BuildContext context) {
    final notice = widget.category.formNotice;
    if (notice == null) return null;
    return GlassContainer(
      borderColor: AppColors.gold,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.gold, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(notice, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }

  Widget _fieldsCard() {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlowFocusField(
            child: TextField(
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              maxLength: AppInputLimits.shortField,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                filled: false,
                counterText: '',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          GlowFocusField(
            child: TextField(
              controller: _contactController,
              onChanged: (_) => setState(() {}),
              maxLength: AppInputLimits.shortField,
              decoration: const InputDecoration(
                labelText: 'Téléphone ou e-mail',
                filled: false,
                counterText: '',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          GlowFocusField(
            child: TextField(
              controller: _messageController,
              onChanged: (_) => setState(() {}),
              maxLines: 4,
              maxLength: AppInputLimits.contactMessage,
              decoration: const InputDecoration(
                labelText: 'Décrivez brièvement votre besoin',
                alignLabelWithHint: true,
                filled: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _errorText(BuildContext context, ContactProfessionalController controller) {
    if (controller.status != ContactSubmissionStatus.error || controller.errorMessage == null) {
      return null;
    }
    return Text(
      controller.errorMessage!,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error),
    );
  }

  Widget _submitButton(ContactProfessionalController controller, bool submitting) {
    return LuxuryElevatedButton(
      onPressed: _canSubmit && !submitting ? () => _submit(controller) : null,
      child: submitting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.nightBlueDeep),
            )
          : const Text('Envoyer la demande'),
    );
  }

  Widget _buildMobileSheet(BuildContext context, ContactProfessionalController controller) {
    final submitting = controller.status == ContactSubmissionStatus.submitting;
    final notice = _noticeCard(context);
    final error = _errorText(context, controller);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SmokedGlassSurface(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
            border: const Border(top: BorderSide(color: AppColors.glassBorder, width: 0.6)),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.glassBorder,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                _ContactDialogHeader(
                  category: widget.category,
                  onClose: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    children: [
                      if (notice != null) ...[notice, const SizedBox(height: AppSpacing.md)],
                      _fieldsCard(),
                      if (error != null) ...[const SizedBox(height: AppSpacing.sm), error],
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          const Icon(Icons.lock_outline_rounded, size: 13, color: AppColors.textDisabled),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Vos coordonnées ne sont partagées qu\'avec le partenaire qui prend la demande.',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: AppColors.textDisabled),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _submitButton(controller, submitting),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopDialog(BuildContext context, ContactProfessionalController controller) {
    final textTheme = Theme.of(context).textTheme;
    final submitting = controller.status == ContactSubmissionStatus.submitting;
    final notice = _noticeCard(context);
    final error = _errorText(context, controller);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.86;

    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      backgroundColor: Colors.transparent,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 620, maxHeight: maxHeight),
        child: SmokedGlassSurface(
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.28), width: 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ContactDialogHeader(
                category: widget.category,
                onClose: () => Navigator.of(context).maybePop(),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (notice != null) ...[notice, const SizedBox(height: AppSpacing.md)],
                      _fieldsCard(),
                      if (error != null) ...[const SizedBox(height: AppSpacing.sm), error],
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.gold.withValues(alpha: 0.14), width: 0.6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock_outline_rounded, size: 13, color: AppColors.textDisabled),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Vos coordonnées ne sont partagées qu\'avec le partenaire qui prend la demande.',
                            style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _submitButton(controller, submitting),
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

class _ContactDialogHeader extends StatelessWidget {
  const _ContactDialogHeader({required this.category, required this.onClose});

  final ProfessionalCategory category;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.md, AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gold.withValues(alpha: 0.12), AppColors.gold.withValues(alpha: 0.03)],
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.gold.withValues(alpha: 0.16), width: 0.6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientIconBadge(icon: iconForCategory(category), size: 44),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MISE EN RELATION',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.goldLight,
                    letterSpacing: AppLetterSpacing.caps,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Contacter un ${category.label.toLowerCase()}',
                  style: textTheme.headlineSmall?.copyWith(fontFamily: 'Libre Caslon Display'),
                ),
                const SizedBox(height: 4),
                Text(
                  category.description,
                  style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.35),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Fermer',
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
