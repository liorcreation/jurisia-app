import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/platform/app_platform_style.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../../models/training/training_category.dart';
import '../../../../theme/app_theme.dart';
import '../../../professional/domain/entities/professional_service_request.dart';
import '../../../professional/presentation/controllers/professional_service_request_controller.dart';

Future<void> showTrainingEnrollmentForm(
  BuildContext context, {
  required TrainingCategory category,
}) async {
  final controller = context.read<ProfessionalServiceRequestController>();
  controller.resetStatus();
  final form = ChangeNotifierProvider.value(
    value: controller,
    child: _TrainingEnrollmentForm(category: category),
  );
  if (AppPlatformStyle.of(context) == AppPlatformStyle.desktop) {
    await showDialog<void>(
      context: context,
      barrierColor: AppColors.nightBlueDeep.withValues(alpha: .58),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: form,
        ),
      ),
    );
  } else {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: form,
      ),
    );
  }
}

class _TrainingEnrollmentForm extends StatefulWidget {
  const _TrainingEnrollmentForm({required this.category});

  final TrainingCategory category;

  @override
  State<_TrainingEnrollmentForm> createState() =>
      _TrainingEnrollmentFormState();
}

class _TrainingEnrollmentFormState extends State<_TrainingEnrollmentForm> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _message = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  bool get _valid =>
      _name.text.trim().length >= 2 &&
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim()) &&
      _phone.text.trim().length >= 6;

  Future<void> _submit() async {
    final controller = context.read<ProfessionalServiceRequestController>();
    final success = await controller.submit(
      kind: ProfessionalRequestKind.trainingEnrollment,
      category: 'jurisconsulte',
      actType: 'Formation en présentiel — ${widget.category.title}',
      fullName: _name.text,
      email: _email.text,
      phone: _phone.text,
      details: [
        'Demande d’inscription à la formation en présentiel « ${widget.category.title} ».',
        if (_message.text.trim().isNotEmpty) _message.text.trim(),
      ].join('\n\n'),
      urgency: ProfessionalRequestUrgency.standard,
      attachmentNames: const [],
      desiredDate: null,
      appointmentMode: null,
    );
    if (!mounted || !success) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          controller.lastEmailDispatched
              ? 'Votre demande d’inscription a été transmise à JurisIA.'
              : 'Votre demande est enregistrée ; la notification e-mail de l’équipe doit encore être configurée.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProfessionalServiceRequestController>();
    return PremiumSurface(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      tone: PremiumSurfaceTone.elevated,
      radius: AppRadius.large,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.school_rounded, color: AppColors.goldDark),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Inscription en présentiel',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontFamily: 'Libre Caslon Display',
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Fermer',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            Text(
              widget.category.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.goldDark,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _name,
              onChanged: (_) => setState(() {}),
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nom complet'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _email,
              onChanged: (_) => setState(() {}),
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Adresse e-mail'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _phone,
              onChanged: (_) => setState(() {}),
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Téléphone'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _message,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Disponibilités ou précision (facultatif)',
              ),
            ),
            if (controller.errorMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                controller.errorMessage!,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed:
                  _valid &&
                      controller.status !=
                          ProfessionalRequestSubmissionStatus.submitting
                  ? _submit
                  : null,
              icon:
                  controller.status ==
                      ProfessionalRequestSubmissionStatus.submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: const Text('Envoyer ma demande'),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Votre demande est adressée à l’équipe JurisIA ; la confirmation vous sera envoyée par e-mail.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
