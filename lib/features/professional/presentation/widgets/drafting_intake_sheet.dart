import 'package:flutter/material.dart';

import '../../../../core/validation/input_limits.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/luxury_elevated_button.dart';
import '../../../../core/widgets/smoked_glass_surface.dart';
import '../../../../models/legal_document/legal_domain.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/entities/drafting_request.dart';
import '../../domain/entities/professional_template.dart';

/// Formulaire de saisie affiché en feuille modale avant de lancer une
/// rédaction, un audit ou une consultation, adapté au mode choisi.
class DraftingIntakeSheet extends StatefulWidget {
  const DraftingIntakeSheet({
    super.key,
    required this.mode,
    required this.templates,
    required this.onSubmit,
  });

  final DraftingMode mode;
  final List<ProfessionalTemplate> templates;
  final ValueChanged<DraftingRequest> onSubmit;

  @override
  State<DraftingIntakeSheet> createState() => _DraftingIntakeSheetState();
}

class _DraftingIntakeSheetState extends State<DraftingIntakeSheet> {
  ProfessionalTemplate? _selectedTemplate;
  LegalDomain? _selectedDomain;
  final Map<String, TextEditingController> _fieldControllers = {};
  final TextEditingController _mainTextController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();

  @override
  void dispose() {
    for (final controller in _fieldControllers.values) {
      controller.dispose();
    }
    _mainTextController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  TextEditingController _controllerFor(String field) {
    return _fieldControllers.putIfAbsent(field, () => TextEditingController());
  }

  bool get _canSubmit {
    switch (widget.mode) {
      case DraftingMode.redaction:
        final template = _selectedTemplate;
        if (template == null) return false;
        return template.requiredFields.every((field) => _controllerFor(field).text.trim().isNotEmpty);
      case DraftingMode.audit:
        return _mainTextController.text.trim().isNotEmpty;
      case DraftingMode.consultation:
        return _mainTextController.text.trim().isNotEmpty;
    }
  }

  void _submit() {
    if (!_canSubmit) return;

    final DraftingRequest request;
    switch (widget.mode) {
      case DraftingMode.redaction:
        request = DraftingRequest(
          mode: DraftingMode.redaction,
          template: _selectedTemplate,
          fieldValues: {
            for (final field in _selectedTemplate!.requiredFields) field: _controllerFor(field).text.trim(),
          },
          instructions: _instructionsController.text.trim(),
        );
      case DraftingMode.audit:
        request = DraftingRequest(
          mode: DraftingMode.audit,
          contractText: _mainTextController.text.trim(),
          instructions: _instructionsController.text.trim(),
          domainHint: _selectedDomain,
        );
      case DraftingMode.consultation:
        request = DraftingRequest(
          mode: DraftingMode.consultation,
          instructions: _mainTextController.text.trim(),
          domainHint: _selectedDomain,
        );
    }

    Navigator.of(context).pop();
    widget.onSubmit(request);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
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
                Text(_sheetTitle(), style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.md),
                ..._buildFormFields(context),
                const SizedBox(height: AppSpacing.lg),
                LuxuryElevatedButton(
                  onPressed: _canSubmit ? _submit : null,
                  child: Text(_submitLabel()),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          );
        },
      ),
    );
  }

  String _sheetTitle() {
    switch (widget.mode) {
      case DraftingMode.redaction:
        return 'Rédiger un acte';
      case DraftingMode.audit:
        return 'Auditer un contrat';
      case DraftingMode.consultation:
        return 'Consultation approfondie';
    }
  }

  String _submitLabel() {
    switch (widget.mode) {
      case DraftingMode.redaction:
        return 'Générer le document';
      case DraftingMode.audit:
        return 'Analyser le contrat';
      case DraftingMode.consultation:
        return 'Lancer la consultation';
    }
  }

  List<Widget> _buildFormFields(BuildContext context) {
    switch (widget.mode) {
      case DraftingMode.redaction:
        return _buildRedactionFields(context);
      case DraftingMode.audit:
        return _buildAuditFields(context);
      case DraftingMode.consultation:
        return _buildConsultationFields(context);
    }
  }

  List<Widget> _buildRedactionFields(BuildContext context) {
    return [
      GlassContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choisissez un modèle', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final template in widget.templates)
                  ChoiceChip(
                    label: Text(template.title),
                    selected: _selectedTemplate?.id == template.id,
                    onSelected: (_) => setState(() => _selectedTemplate = template),
                    selectedColor: AppColors.gold.withValues(alpha: 0.22),
                    backgroundColor: AppColors.legalBlueDark.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                  ),
              ],
            ),
            if (_selectedTemplate != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_selectedTemplate!.description, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
      if (_selectedTemplate != null) ...[
        const SizedBox(height: AppSpacing.md),
        GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final field in _selectedTemplate!.requiredFields)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: TextField(
                    controller: _controllerFor(field),
                    onChanged: (_) => setState(() {}),
                    maxLength: AppInputLimits.shortField,
                    decoration: InputDecoration(labelText: field, filled: false, counterText: ''),
                  ),
                ),
              TextField(
                controller: _instructionsController,
                maxLines: 3,
                maxLength: AppInputLimits.instructions,
                decoration: const InputDecoration(
                  labelText: 'Instructions complémentaires (facultatif)',
                  filled: false,
                ),
              ),
            ],
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildAuditFields(BuildContext context) {
    return [
      GlassContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _mainTextController,
              onChanged: (_) => setState(() {}),
              maxLines: 10,
              maxLength: AppInputLimits.contractText,
              decoration: const InputDecoration(
                labelText: 'Collez le texte du contrat à auditer',
                alignLabelWithHint: true,
                filled: false,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _instructionsController,
              maxLines: 2,
              maxLength: AppInputLimits.instructions,
              decoration: const InputDecoration(
                labelText: "Points d'attention (facultatif)",
                filled: false,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      _DomainPicker(
        selected: _selectedDomain,
        onSelected: (domain) => setState(() => _selectedDomain = domain),
      ),
    ];
  }

  List<Widget> _buildConsultationFields(BuildContext context) {
    return [
      GlassContainer(
        child: TextField(
          controller: _mainTextController,
          onChanged: (_) => setState(() {}),
          maxLines: 8,
          maxLength: AppInputLimits.consultationQuestion,
          decoration: const InputDecoration(
            labelText: 'Décrivez la question juridique à traiter',
            alignLabelWithHint: true,
            filled: false,
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      _DomainPicker(
        selected: _selectedDomain,
        onSelected: (domain) => setState(() => _selectedDomain = domain),
      ),
    ];
  }
}

class _DomainPicker extends StatelessWidget {
  const _DomainPicker({required this.selected, required this.onSelected});

  final LegalDomain? selected;
  final ValueChanged<LegalDomain?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Branche du droit (facultatif)', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final domain in LegalDomain.values)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(domain.label),
                    selected: selected == domain,
                    onSelected: (_) => onSelected(selected == domain ? null : domain),
                    selectedColor: AppColors.gold.withValues(alpha: 0.22),
                    backgroundColor: AppColors.legalBlueDark.withValues(alpha: 0.6),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
