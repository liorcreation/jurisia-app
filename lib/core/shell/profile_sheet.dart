import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/profile/domain/entities/user_profession.dart';
import '../../features/profile/presentation/controllers/profile_controller.dart';
import '../legal/legal_document_screen.dart';
import '../legal/legal_documents.dart';
import '../platform/app_platform_style.dart';
import '../validation/input_limits.dart';
import '../widgets/glow_focus_field.dart';
import '../widgets/luxury_elevated_button.dart';
import '../widgets/smoked_glass_surface.dart';
import '../../theme/app_theme.dart';
import 'profile_monogram.dart';

/// Ouvre la feuille profil : feuille modale en bas d'écran sur mobile,
/// boîte de dialogue centrée sur desktop. Édition du nom / rôle, accès aux
/// mentions légales, déconnexion.
Future<void> showProfileSheet(BuildContext context) {
  final controller = context.read<ProfileController>();
  final isDesktop = AppPlatformStyle.of(context) == AppPlatformStyle.desktop;

  final body = ChangeNotifierProvider<ProfileController>.value(
    value: controller,
    child: const _ProfileSheetBody(),
  );

  if (isDesktop) {
    return showDialog<void>(
      context: context,
      barrierColor: AppColors.nightBlueDeep.withValues(alpha: 0.55),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.all(AppSpacing.xl),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          child: SmokedGlassSurface(
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.28), width: 0.8),
            child: body,
          ),
        ),
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SmokedGlassSurface(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
      border: Border.all(color: AppColors.glassBorder, width: 0.6),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: body,
      ),
    ),
  );
}

class _ProfileSheetBody extends StatefulWidget {
  const _ProfileSheetBody();

  @override
  State<_ProfileSheetBody> createState() => _ProfileSheetBodyState();
}

class _ProfileSheetBodyState extends State<_ProfileSheetBody> {
  late final TextEditingController _nameController;
  UserProfession? _profession;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileController>().profile;
    _nameController = TextEditingController(text: profile?.fullName ?? '');
    _profession = profile?.profession;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final controller = context.read<ProfileController>();
    await controller.save(
      fullName: _nameController.text.trim(),
      profession: _profession,
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmSignOut() async {
    final controller = context.read<ProfileController>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Vous devrez saisir à nouveau vos identifiants à la prochaine ouverture.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Se déconnecter', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (mounted) Navigator.of(context).pop();
    await controller.signOut();
  }

  void _openDocument(String title, String content) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LegalDocumentScreen(title: title, content: content)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProfileController>();
    final profile = controller.profile;

    if (AppPlatformStyle.of(context) == AppPlatformStyle.desktop) {
      return _DesktopProfileBody(
        controller: controller,
        nameController: _nameController,
        profession: _profession,
        onProfessionChanged: (value) => setState(() => _profession = value),
        onSave: _save,
        onSignOut: _confirmSignOut,
        onOpenDocument: _openDocument,
      );
    }

    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ProfileMonogram(profile: profile, size: 52),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.displayName ?? 'Mon compte',
                        style: textTheme.titleLarge?.copyWith(fontFamily: 'Libre Caslon Display'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (profile?.email.isNotEmpty ?? false)
                        Text(
                          profile!.email,
                          style: textTheme.labelSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            GlowFocusField(
              child: TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                maxLength: AppInputLimits.fullName,
                decoration: const InputDecoration(labelText: 'Nom complet', counterText: ''),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<UserProfession>(
              initialValue: _profession,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Vous êtes'),
              items: [
                for (final profession in UserProfession.values)
                  DropdownMenuItem(value: profession, child: Text(profession.label)),
              ],
              onChanged: (value) => setState(() => _profession = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            LuxuryElevatedButton(
              onPressed: controller.isSaving ? null : _save,
              child: controller.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.nightBlueDeep),
                    )
                  : const Text('Enregistrer'),
            ),
            const Divider(height: AppSpacing.xl),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description_outlined),
              title: const Text("Conditions générales d'utilisation"),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _openDocument('CGU', LegalDocuments.termsOfService),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Politique de confidentialité'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _openDocument('Politique de confidentialité', LegalDocuments.privacyPolicy),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: const Text('Se déconnecter', style: TextStyle(color: AppColors.error)),
              onTap: _confirmSignOut,
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
//  DESKTOP — « La carte de membre »
// ===========================================================================

class _DesktopProfileBody extends StatelessWidget {
  const _DesktopProfileBody({
    required this.controller,
    required this.nameController,
    required this.profession,
    required this.onProfessionChanged,
    required this.onSave,
    required this.onSignOut,
    required this.onOpenDocument,
  });

  final ProfileController controller;
  final TextEditingController nameController;
  final UserProfession? profession;
  final ValueChanged<UserProfession?> onProfessionChanged;
  final Future<void> Function() onSave;
  final Future<void> Function() onSignOut;
  final void Function(String title, String content) onOpenDocument;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final profile = controller.profile;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // --- en-tête identité ------------------------------------------
        Container(
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
              ProfileMonogram(profile: profile, size: 56),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MON COMPTE',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.goldLight,
                        letterSpacing: AppLetterSpacing.caps,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      profile?.displayName ?? 'Mon compte',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.headlineSmall?.copyWith(fontFamily: 'Libre Caslon Display'),
                    ),
                    if (profile?.email.isNotEmpty ?? false) ...[
                      const SizedBox(height: 2),
                      Text(
                        profile!.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Fermer',
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
        // --- corps --------------------------------------------------------
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _ProfEyebrow('Votre identité'),
                const SizedBox(height: AppSpacing.md),
                GlowFocusField(
                  child: TextField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    maxLength: AppInputLimits.fullName,
                    decoration: const InputDecoration(
                      labelText: 'Nom complet',
                      counterText: '',
                      filled: false,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Vous êtes',
                  style: textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final value in UserProfession.values)
                      _ProfessionChip(
                        label: value.label,
                        selected: profession == value,
                        onTap: () => onProfessionChanged(profession == value ? null : value),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                LuxuryElevatedButton(
                  onPressed: controller.isSaving ? null : onSave,
                  icon: Icons.check_rounded,
                  child: controller.isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.nightBlueDeep,
                          ),
                        )
                      : const Text('Enregistrer'),
                ),
                const SizedBox(height: AppSpacing.lg),
                Divider(color: AppColors.gold.withValues(alpha: 0.14), height: 1),
                const SizedBox(height: AppSpacing.lg),
                const _ProfEyebrow('L\'application'),
                const SizedBox(height: AppSpacing.md),
                _ProfLinkRow(
                  icon: Icons.description_outlined,
                  label: "Conditions générales d'utilisation",
                  onTap: () => onOpenDocument('CGU', LegalDocuments.termsOfService),
                ),
                const SizedBox(height: 6),
                _ProfLinkRow(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Politique de confidentialité',
                  onTap: () => onOpenDocument(
                    'Politique de confidentialité',
                    LegalDocuments.privacyPolicy,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _ProfLinkRow(
                  icon: Icons.logout_rounded,
                  label: 'Se déconnecter',
                  danger: true,
                  onTap: onSignOut,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfEyebrow extends StatelessWidget {
  const _ProfEyebrow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 1, color: AppColors.gold.withValues(alpha: 0.6)),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.goldLight,
                letterSpacing: AppLetterSpacing.caps,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _ProfessionChip extends StatelessWidget {
  const _ProfessionChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            color: selected
                ? AppColors.gold.withValues(alpha: 0.16)
                : AppColors.legalBlueDark.withValues(alpha: 0.5),
            border: Border.all(
              color: selected
                  ? AppColors.gold.withValues(alpha: 0.6)
                  : AppColors.gold.withValues(alpha: 0.18),
              width: selected ? 1 : 0.7,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check_rounded, size: 13, color: AppColors.goldLight),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfLinkRow extends StatefulWidget {
  const _ProfLinkRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  State<_ProfLinkRow> createState() => _ProfLinkRowState();
}

class _ProfLinkRowState extends State<_ProfLinkRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = widget.danger ? AppColors.error : AppColors.goldLight;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppRadius.small),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm + 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.small),
              color: _hovered
                  ? accent.withValues(alpha: widget.danger ? 0.08 : 0.07)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    border: Border.all(color: accent.withValues(alpha: 0.28), width: 0.7),
                  ),
                  child: Icon(widget.icon, size: 15, color: accent),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    widget.label,
                    style: textTheme.bodyMedium?.copyWith(
                      color: widget.danger ? AppColors.error : AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: widget.danger
                      ? AppColors.error.withValues(alpha: 0.7)
                      : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
