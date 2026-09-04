import 'package:flutter/material.dart';

import '../../../../core/platform/app_platform_style.dart';
import '../../../../core/validation/input_limits.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glow_focus_field.dart';
import '../../../../core/widgets/gradient_icon_badge.dart';
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
    this.initialTemplate,
  });

  final DraftingMode mode;
  final List<ProfessionalTemplate> templates;
  final ValueChanged<DraftingRequest> onSubmit;

  /// Modèle présélectionné à l'ouverture (mode rédaction), lorsque la
  /// feuille est lancée depuis une carte de modèle précise.
  final ProfessionalTemplate? initialTemplate;

  @override
  State<DraftingIntakeSheet> createState() => _DraftingIntakeSheetState();
}

class _DraftingIntakeSheetState extends State<DraftingIntakeSheet> {
  ProfessionalTemplate? _selectedTemplate;

  @override
  void initState() {
    super.initState();
    _selectedTemplate = widget.initialTemplate;
  }
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
    if (AppPlatformStyle.of(context) == AppPlatformStyle.desktop) {
      return _buildDesktopDialog(context);
    }
    return _buildMobileSheet(context);
  }

  Widget _buildMobileSheet(BuildContext context) {
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
                _IntakeDialogHeader(
                  mode: widget.mode,
                  title: _sheetTitle(),
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
                      ..._buildFormFields(context),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 13, color: AppColors.textDisabled),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Le document généré doit être relu par un professionnel avant utilisation.',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: AppColors.textDisabled),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      LuxuryElevatedButton(
                        onPressed: _canSubmit ? _submit : null,
                        icon: Icons.auto_awesome_rounded,
                        child: Text(_submitLabel()),
                      ),
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

  Widget _buildDesktopDialog(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.86;

    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      backgroundColor: Colors.transparent,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 660, maxHeight: maxHeight),
        child: SmokedGlassSurface(
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.28), width: 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IntakeDialogHeader(
                mode: widget.mode,
                title: _sheetTitle(),
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
                    children: _buildFormFields(context),
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
                        const Icon(Icons.info_outline_rounded, size: 13, color: AppColors.textDisabled),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Le document généré doit être relu par un professionnel avant utilisation.',
                            style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    LuxuryElevatedButton(
                      onPressed: _canSubmit ? _submit : null,
                      icon: Icons.auto_awesome_rounded,
                      child: Text(_submitLabel()),
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
                  child: GlowFocusField(
                    child: TextField(
                      controller: _controllerFor(field),
                      onChanged: (_) => setState(() {}),
                      maxLength: AppInputLimits.shortField,
                      decoration: InputDecoration(labelText: field, filled: false, counterText: ''),
                    ),
                  ),
                ),
              GlowFocusField(
                child: TextField(
                  controller: _instructionsController,
                  maxLines: 3,
                  maxLength: AppInputLimits.instructions,
                  decoration: const InputDecoration(
                    labelText: 'Instructions complémentaires (facultatif)',
                    filled: false,
                  ),
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
            GlowFocusField(
              child: TextField(
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
            ),
            const SizedBox(height: AppSpacing.sm),
            GlowFocusField(
              child: TextField(
                controller: _instructionsController,
                maxLines: 2,
                maxLength: AppInputLimits.instructions,
                decoration: const InputDecoration(
                  labelText: "Points d'attention (facultatif)",
                  filled: false,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      _DomainPicker(
        selected: _selectedDomain,
        onSelected: (domain) => setState(() => _selectedDomain = domain),
        wrap: AppPlatformStyle.of(context) == AppPlatformStyle.desktop,
      ),
    ];
  }

  List<Widget> _buildConsultationFields(BuildContext context) {
    return [
      GlassContainer(
        child: GlowFocusField(
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
      ),
      const SizedBox(height: AppSpacing.md),
      _DomainPicker(
        selected: _selectedDomain,
        onSelected: (domain) => setState(() => _selectedDomain = domain),
        wrap: AppPlatformStyle.of(context) == AppPlatformStyle.desktop,
      ),
    ];
  }
}

({IconData icon, Color tint, String eyebrow, String subtitle}) _modeIntakeStyle(DraftingMode mode) {
  switch (mode) {
    case DraftingMode.redaction:
      return (
        icon: Icons.draw_rounded,
        tint: AppColors.metalDeepGold,
        eyebrow: 'RÉDACTION D\'ACTE',
        subtitle: 'Renseignez le contexte, l\'IA rédige l\'acte au fil de l\'eau.',
      );
    case DraftingMode.audit:
      return (
        icon: Icons.rule_rounded,
        tint: AppColors.metalCobalt,
        eyebrow: 'AUDIT DE CONTRAT',
        subtitle: 'Collez le contrat : l\'IA isole les clauses fragiles et les réécrit.',
      );
    case DraftingMode.consultation:
      return (
        icon: Icons.balance_rounded,
        tint: AppColors.metalEmerald,
        eyebrow: 'CONSULTATION APPROFONDIE',
        subtitle: 'Posez la question de droit : réponse argumentée, sources à l\'appui.',
      );
  }
}

class _IntakeDialogHeader extends StatelessWidget {
  const _IntakeDialogHeader({required this.mode, required this.title, required this.onClose});

  final DraftingMode mode;
  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = _modeIntakeStyle(mode);

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.md, AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [style.tint.withValues(alpha: 0.14), style.tint.withValues(alpha: 0.03)],
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.gold.withValues(alpha: 0.16), width: 0.6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientIconBadge(
            icon: style.icon,
            size: 44,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(style.tint, Colors.white, 0.35)!,
                style.tint,
                Color.lerp(style.tint, AppColors.nightBlueDeep, 0.35)!,
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  style.eyebrow,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.goldLight,
                    letterSpacing: AppLetterSpacing.caps,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: textTheme.headlineSmall?.copyWith(fontFamily: 'Libre Caslon Display'),
                ),
                const SizedBox(height: 4),
                Text(
                  style.subtitle,
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

class _DomainPicker extends StatelessWidget {
  const _DomainPicker({required this.selected, required this.onSelected, this.wrap = false});

  final LegalDomain? selected;
  final ValueChanged<LegalDomain?> onSelected;
  final bool wrap;

  Widget _chip(BuildContext context, LegalDomain domain) => ChoiceChip(
        label: Text(domain.label),
        selected: selected == domain,
        onSelected: (_) => onSelected(selected == domain ? null : domain),
        selectedColor: AppColors.gold.withValues(alpha: 0.22),
        backgroundColor: AppColors.legalBlueDark.withValues(alpha: 0.6),
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Branche du droit (facultatif)', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        if (wrap)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [for (final domain in LegalDomain.values) _chip(context, domain)],
          )
        else
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final domain in LegalDomain.values)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: _chip(context, domain),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
