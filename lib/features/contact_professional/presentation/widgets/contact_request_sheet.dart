import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/validation/input_limits.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glow_focus_field.dart';
import '../../../../core/widgets/luxury_elevated_button.dart';
import '../../../../core/widgets/smoked_glass_surface.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/entities/professional_category.dart';
import '../controllers/contact_professional_controller.dart';

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
    final submitting = controller.status == ContactSubmissionStatus.submitting;
    final notice = widget.category.formNotice;

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
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.glassBorder,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                Text(
                  'Contacter un ${widget.category.label.toLowerCase()}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(widget.category.description, style: Theme.of(context).textTheme.bodyMedium),
                if (notice != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  GlassContainer(
                    borderColor: AppColors.gold,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppColors.gold, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(notice, style: Theme.of(context).textTheme.bodySmall),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                GlassContainer(
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
                ),
                if (controller.status == ContactSubmissionStatus.error &&
                    controller.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    controller.errorMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                LuxuryElevatedButton(
                  onPressed: _canSubmit && !submitting ? () => _submit(controller) : null,
                  child: submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.nightBlueDeep,
                          ),
                        )
                      : const Text('Envoyer la demande'),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          );
        },
      ),
    );
  }
}
