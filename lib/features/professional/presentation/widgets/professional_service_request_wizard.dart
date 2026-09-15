import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/platform/app_platform_style.dart';
import '../../../../core/widgets/luxury_elevated_button.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../../theme/app_theme.dart';
import '../controllers/professional_service_request_controller.dart';
import '../../domain/entities/professional_service_request.dart';
import '../../domain/entities/professional_service_category.dart';

/// Ouvre le parcours de demande sur mobile, tablette ou desktop avec la même
/// machine d’étapes et le même contrat de persistance.
Future<void> showProfessionalServiceRequestWizard(
  BuildContext context, {
  ProfessionalRequestKind initialKind = ProfessionalRequestKind.legalAct,
  ProfessionalServiceCategory? initialCategory,
  String? initialActType,
}) async {
  final controller = context.read<ProfessionalServiceRequestController>();
  controller.resetStatus();

  final wizard = ProfessionalServiceRequestWizard(
    initialKind: initialKind,
    initialCategory: initialCategory,
    initialActType: initialActType,
  );
  if (AppPlatformStyle.of(context) == AppPlatformStyle.desktop) {
    await showDialog<void>(
      context: context,
      barrierColor: AppColors.nightBlueDeep.withValues(alpha: 0.72),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 840),
          child: wizard,
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
        child: wizard,
      ),
    );
  }
}

class ProfessionalServiceRequestWizard extends StatefulWidget {
  const ProfessionalServiceRequestWizard({
    super.key,
    this.initialKind = ProfessionalRequestKind.legalAct,
    this.initialCategory,
    this.initialActType,
  });

  final ProfessionalRequestKind initialKind;
  final ProfessionalServiceCategory? initialCategory;
  final String? initialActType;

  @override
  State<ProfessionalServiceRequestWizard> createState() =>
      _ProfessionalServiceRequestWizardState();
}

class _ProfessionalServiceRequestWizardState
    extends State<ProfessionalServiceRequestWizard> {
  late ProfessionalRequestKind _kind;
  late ProfessionalServiceCategory _category;
  String? _selectedServiceType;
  bool _isOtherService = false;
  ProfessionalRequestUrgency _urgency = ProfessionalRequestUrgency.standard;
  ProfessionalAppointmentMode _appointmentMode =
      ProfessionalAppointmentMode.video;
  DateTime? _desiredDate;
  int _step = 0;

  final _actTypeController = TextEditingController();
  final _detailsController = TextEditingController();
  final _attachmentsController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;
    _category =
        widget.initialCategory ?? ProfessionalServiceCategory.jurisconsult;
    final initialActType = widget.initialActType?.trim();
    if (initialActType != null && initialActType.isNotEmpty) {
      if (_category.serviceTypes.contains(initialActType)) {
        _selectedServiceType = initialActType;
      } else {
        _isOtherService = true;
        _selectedServiceType = 'Autre';
        if (initialActType != 'Autre') _actTypeController.text = initialActType;
      }
    }
  }

  @override
  void dispose() {
    _actTypeController.dispose();
    _detailsController.dispose();
    _attachmentsController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _canContinue {
    switch (_step) {
      case 0:
        return true;
      case 1:
        final serviceType = _resolvedServiceType;
        return _detailsController.text.trim().length >= 12 &&
            serviceType.isNotEmpty &&
            (_kind != ProfessionalRequestKind.expertAppointment ||
                _desiredDate != null);
      case 2:
        return _nameController.text.trim().length >= 2 &&
            _emailController.text.contains('@') &&
            _phoneController.text.trim().length >= 6;
      case 3:
        return true;
    }
    return false;
  }

  String get _resolvedServiceType {
    if (_isOtherService) return _actTypeController.text.trim();
    return _selectedServiceType?.trim() ?? '';
  }

  void _next() {
    if (!_canContinue) return;
    setState(() => _step = (_step + 1).clamp(0, 3));
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step--);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 120)),
      initialDate: _desiredDate ?? DateTime.now().add(const Duration(days: 2)),
      builder: (context, child) =>
          Theme(data: Theme.of(context), child: child!),
    );
    if (picked != null && mounted) setState(() => _desiredDate = picked);
  }

  Future<void> _submit() async {
    final controller = context.read<ProfessionalServiceRequestController>();
    final success = await controller.submit(
      kind: _kind,
      category: _category.slug,
      actType: _resolvedServiceType,
      fullName: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      details: _detailsController.text,
      urgency: _urgency,
      attachmentNames: _attachmentsController.text.split(','),
      desiredDate: _desiredDate,
      appointmentMode: _kind == ProfessionalRequestKind.expertAppointment
          ? _appointmentMode
          : null,
    );
    if (!mounted || !success) return;

    Navigator.of(context).pop();
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text(
          'Demande reçue. Vous recevrez l’accusé et le suivi par e-mail.',
        ),
        backgroundColor: AppColors.legalBlueDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProfessionalServiceRequestController>();
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return PremiumSurface(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md + keyboard,
      ),
      radius: AppRadius.large,
      tone: PremiumSurfaceTone.elevated,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WizardHeader(step: _step, kind: _kind),
          const SizedBox(height: AppSpacing.md),
          Flexible(
            child: SingleChildScrollView(
              child: AnimatedSwitcher(
                duration: AppMotion.standard,
                switchInCurve: AppMotion.premium,
                child: KeyedSubtree(key: ValueKey(_step), child: _buildStep()),
              ),
            ),
          ),
          if (controller.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            PremiumStatusPill(
              label: controller.errorMessage!,
              tone: PremiumStatusTone.danger,
              icon: Icons.error_outline_rounded,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _WizardActions(
            step: _step,
            submitting:
                controller.status ==
                ProfessionalRequestSubmissionStatus.submitting,
            canContinue: _canContinue,
            onBack: _back,
            onNext: _step == 3 ? _submit : _next,
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildRequestTypeStep();
      case 1:
        return _buildNeedStep();
      case 2:
        return _buildIdentityStep();
      case 3:
        return _buildReviewStep();
    }
    return const SizedBox.shrink();
  }

  Widget _buildRequestTypeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(
          eyebrow: '01 — Votre parcours',
          title: 'Quel service recherchez-vous ?',
          subtitle:
              'Choisissez la catégorie qui correspond le mieux à votre besoin. Vous préciserez ensuite le service exact.',
        ),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 620 ? 2 : 1;
            final itemWidth = columns == 1
                ? constraints.maxWidth
                : (constraints.maxWidth - AppSpacing.sm) / 2;
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final category in ProfessionalServiceCategory.values)
                  SizedBox(
                    width: itemWidth,
                    child: _ServiceCategoryChoice(
                      category: category,
                      selected: _category == category,
                      onTap: () => setState(() {
                        _category = category;
                        if (_selectedServiceType != null &&
                            !category.serviceTypes.contains(
                              _selectedServiceType,
                            )) {
                          _selectedServiceType = null;
                          _isOtherService = false;
                          _actTypeController.clear();
                        }
                      }),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildNeedStep() {
    final isAppointment = _kind == ProfessionalRequestKind.expertAppointment;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(
          eyebrow: '02 — Type de service',
          title: isAppointment
              ? 'Préparons votre rendez-vous'
              : 'Cadrez l’acte à préparer',
          subtitle:
              'Ces éléments servent à orienter le dossier et à préparer un devis juste.',
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Quel type de service souhaitez-vous lancer ?',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.goldLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final serviceType in [..._category.serviceTypes, 'Autre']) ...[
          _ServiceTypeChoice(
            title: serviceType,
            selected:
                (_isOtherService && serviceType == 'Autre') ||
                (!_isOtherService && _selectedServiceType == serviceType),
            onTap: () => setState(() {
              _selectedServiceType = serviceType;
              _isOtherService = serviceType == 'Autre';
              if (!_isOtherService) _actTypeController.clear();
            }),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        if (_isOtherService) ...[
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _actTypeController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Décrivez le service recherché',
              hintText: 'Ex. formalité ou accompagnement spécifique…',
              prefixIcon: Icon(Icons.edit_note_rounded),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        for (final kind in ProfessionalRequestKind.values) ...[
          _ChoiceTile(
            selected: _kind == kind,
            icon: kind == ProfessionalRequestKind.legalAct
                ? Icons.article_rounded
                : Icons.calendar_month_rounded,
            title: kind.label,
            subtitle: kind.description,
            onTap: () => setState(() => _kind = kind),
          ),
          if (kind != ProfessionalRequestKind.values.last)
            const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _detailsController,
          onChanged: (_) => setState(() {}),
          minLines: 4,
          maxLines: 7,
          decoration: InputDecoration(
            labelText: isAppointment
                ? 'Objet du rendez-vous'
                : 'Contexte et instructions',
            hintText: isAppointment
                ? 'Exposez les points à traiter et les documents déjà disponibles.'
                : 'Parties, échéances, contraintes et clauses importantes…',
            prefixIcon: const Icon(Icons.notes_rounded),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<ProfessionalRequestUrgency>(
          initialValue: _urgency,
          decoration: const InputDecoration(
            labelText: 'Niveau d’urgence',
            prefixIcon: Icon(Icons.bolt_rounded),
          ),
          items: [
            for (final urgency in ProfessionalRequestUrgency.values)
              DropdownMenuItem(value: urgency, child: Text(urgency.label)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _urgency = value);
          },
        ),
        if (isAppointment) ...[
          const SizedBox(height: AppSpacing.md),
          _DatePickerField(date: _desiredDate, onTap: _pickDate),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<ProfessionalAppointmentMode>(
            initialValue: _appointmentMode,
            decoration: const InputDecoration(
              labelText: 'Format préféré',
              prefixIcon: Icon(Icons.video_call_rounded),
            ),
            items: [
              for (final mode in ProfessionalAppointmentMode.values)
                DropdownMenuItem(value: mode, child: Text(mode.label)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _appointmentMode = value);
            },
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _attachmentsController,
            decoration: const InputDecoration(
              labelText: 'Pièces à joindre (facultatif)',
              hintText: 'CNI, projet de contrat, justificatif…',
              prefixIcon: Icon(Icons.attach_file_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Séparez les noms par des virgules. Le dépôt sécurisé des fichiers sera proposé après l’accusé de réception.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _buildIdentityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepTitle(
          eyebrow: '03 — Coordonnées',
          title: 'Où devons-nous vous joindre ?',
          subtitle:
              'Ces informations restent liées à votre demande et servent uniquement au suivi.',
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _nameController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Nom complet',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _emailController,
          onChanged: (_) => setState(() {}),
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'E-mail de confirmation',
            prefixIcon: Icon(Icons.alternate_email_rounded),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _phoneController,
          onChanged: (_) => setState(() {}),
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Téléphone',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final isAppointment = _kind == ProfessionalRequestKind.expertAppointment;
    final attachmentNames = _attachmentsController.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepTitle(
          eyebrow: '04 — Vérification',
          title: 'Votre demande est prête',
          subtitle:
              'Vérifiez les éléments avant l’envoi sécurisé à notre équipe.',
        ),
        const SizedBox(height: AppSpacing.lg),
        PremiumSurface(
          tone: PremiumSurfaceTone.cobalt,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PremiumStatusPill(
                label: isAppointment ? 'Rendez-vous expert' : 'Acte juridique',
                tone: PremiumStatusTone.gold,
                icon: isAppointment
                    ? Icons.calendar_month_rounded
                    : Icons.article_rounded,
                compact: true,
              ),
              const SizedBox(height: AppSpacing.md),
              _ReviewLine(label: 'Catégorie', value: _category.label),
              _ReviewLine(label: 'Service', value: _resolvedServiceType),
              _ReviewLine(
                label: 'Demandeur',
                value: _nameController.text.trim(),
              ),
              _ReviewLine(
                label: 'Contact',
                value: _emailController.text.trim(),
              ),
              if (isAppointment)
                _ReviewLine(
                  label: 'Date souhaitée',
                  value: _desiredDate == null
                      ? 'À définir'
                      : _formatDate(_desiredDate!),
                ),
              if (isAppointment)
                _ReviewLine(label: 'Format', value: _appointmentMode.label),
              _ReviewLine(label: 'Délai', value: _urgency.label),
              if (attachmentNames.isNotEmpty)
                _ReviewLine(
                  label: 'Pièces prévues',
                  value: attachmentNames.join(', '),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Après envoi, vous recevez un accusé de réception. Un devis ou une proposition de créneau vous sera transmis par e-mail dès validation par le professionnel.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _WizardHeader extends StatelessWidget {
  const _WizardHeader({required this.step, required this.kind});

  final int step;
  final ProfessionalRequestKind kind;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DEMANDE PROFESSIONNELLE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                  letterSpacing: AppLetterSpacing.caps,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                kind == ProfessionalRequestKind.legalAct
                    ? 'Préparer un acte'
                    : 'Prendre rendez-vous',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontFamily: 'Libre Caslon Display',
                ),
              ),
            ],
          ),
        ),
        PremiumStatusPill(
          label: '${step + 1}/4',
          tone: PremiumStatusTone.info,
          compact: true,
        ),
      ],
    );
  }
}

class _WizardActions extends StatelessWidget {
  const _WizardActions({
    required this.step,
    required this.submitting,
    required this.canContinue,
    required this.onBack,
    required this.onNext,
  });

  final int step;
  final bool submitting;
  final bool canContinue;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final button = LuxuryElevatedButton(
      onPressed: canContinue && !submitting ? onNext : null,
      icon: step == 3 ? Icons.lock_rounded : Icons.arrow_forward_rounded,
      child: Text(
        submitting
            ? 'Envoi sécurisé…'
            : step == 3
            ? 'Envoyer la demande'
            : 'Continuer',
      ),
    );

    return Row(
      children: [
        if (step > 0)
          TextButton.icon(
            onPressed: submitting ? null : onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Retour'),
          ),
        if (step > 0) const Spacer(),
        if (step == 0)
          Expanded(child: button)
        else
          SizedBox(width: 220, child: button),
      ],
    );
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: theme.labelSmall?.copyWith(
            color: AppColors.gold,
            fontWeight: FontWeight.w700,
            letterSpacing: AppLetterSpacing.caps,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          title,
          style: theme.titleLarge?.copyWith(fontFamily: 'Libre Caslon Display'),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: theme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _ServiceCategoryChoice extends StatelessWidget {
  const _ServiceCategoryChoice({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final ProfessionalServiceCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      tone: selected ? PremiumSurfaceTone.cobalt : PremiumSurfaceTone.glass,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            category.icon,
            color: selected ? AppColors.gold : AppColors.cobaltLight,
            size: 23,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  category.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(
            selected
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: selected ? AppColors.gold : AppColors.cobaltLight,
          ),
        ],
      ),
    );
  }
}

class _ServiceTypeChoice extends StatelessWidget {
  const _ServiceTypeChoice({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      tone: selected ? PremiumSurfaceTone.cobalt : PremiumSurfaceTone.glass,
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_unchecked_rounded,
            color: selected ? AppColors.gold : AppColors.cobaltLight,
            size: 19,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(title)),
          if (title == 'Autre')
            const Icon(
              Icons.edit_note_rounded,
              color: AppColors.goldLight,
              size: 19,
            ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.gold : AppColors.cobaltLight;
    return PremiumSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      tone: selected ? PremiumSurfaceTone.cobalt : PremiumSurfaceTone.glass,
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            selected
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({required this.date, required this.onTap});

  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date souhaitée',
          prefixIcon: Icon(Icons.event_available_rounded),
        ),
        child: Text(date == null ? 'Choisir une date' : _formatDate(date!)),
      ),
    );
  }
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
