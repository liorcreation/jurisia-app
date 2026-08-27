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
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SmokedGlassSurface(
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: AppColors.glassBorder, width: 0.6),
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
