import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../core/widgets/entrance_fade.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/gradient_icon_badge.dart';
import '../../../core/widgets/luxury_scaffold_background.dart';
import '../../../theme/app_theme.dart';
import '../../auth/staff_role.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_ambience.dart';
import '../../widgets/admin_avatar.dart';
import '../../widgets/admin_empty_state.dart';
import '../../widgets/admin_page_header.dart';
import 'admin_staff_controller.dart';
import 'admin_staff_member.dart';
import 'admin_staff_repository.dart';

Color _roleTint(StaffRole role) => switch (role) {
      StaffRole.superAdmin => AppColors.gold,
      StaffRole.admin => AdminTheme.accent,
      StaffRole.contentEditor => AppColors.metalEmerald,
      StaffRole.legalReviewer => AppColors.metalEmerald,
      StaffRole.partnerManager => AppColors.metalRoseGold,
      StaffRole.supportAgent => AdminTheme.accentLight,
      StaffRole.analyst => AppColors.metalSilver,
    };

/// Console — Personnel : qui a accès à cette console, avec quel rôle.
/// L'octroi/retrait d'un rôle est réservé aux super administrateurs (le
/// reste du personnel peut consulter la liste, jamais la modifier) — la
/// vraie garde-fou est côté serveur (voir
/// migration_011_staff_management.sql), cet écran ne fait qu'y donner accès.
class AdminStaffScreen extends StatelessWidget {
  const AdminStaffScreen({super.key, required this.identity});

  final StaffIdentity identity;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminStaffController>(
      create: (_) => AdminStaffController(
        repository: SupabaseAdminStaffRepository(client: SupabaseConfig.client),
      ),
      child: _View(canManage: identity.canManageStaff),
    );
  }
}

class _View extends StatelessWidget {
  const _View({required this.canManage});

  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminStaffController>();
    final textTheme = Theme.of(context).textTheme;

    // Un même compte peut porter plusieurs rôles (staff_roles a une ligne
    // par rôle) : regrouper par e-mail pour n'afficher chaque personne
    // qu'une fois, avec ses rôles en pastilles.
    final byEmail = <String, List<AdminStaffMember>>{};
    for (final member in controller.members) {
      byEmail.putIfAbsent(member.email, () => []).add(member);
    }
    final emails = byEmail.keys.toList()..sort();

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              AdminPageHeader(
                icon: Icons.badge_rounded,
                title: 'Personnel',
                subtitle: 'Qui a accès à la console, avec quel rôle — ${controller.members.length} rôle(s) actif(s).',
                actions: [
                  IconButton(
                    tooltip: 'Rafraîchir',
                    onPressed: controller.isLoading ? null : controller.load,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              Expanded(
                child: Stack(
                  children: [
                    const Positioned.fill(child: IgnorePointer(child: AdminAmbience())),
                    ListView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        if (controller.error != null)
                          AdminErrorBanner(message: controller.error!, onDismiss: controller.dismissError),
                        if (controller.error != null) const SizedBox(height: AppSpacing.md),
                        if (canManage) ...[
                          _GrantCard(controller: controller),
                          const SizedBox(height: AppSpacing.md),
                        ] else
                          GlassContainer(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    'Seul un super administrateur peut accorder ou retirer un rôle.',
                                    style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: AppSpacing.md),
                        if (controller.isLoading && controller.members.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (controller.members.isEmpty)
                          const AdminEmptyState(
                            icon: Icons.group_off_rounded,
                            message: 'Aucun membre du personnel pour l\'instant.',
                          )
                        else
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final wide = constraints.maxWidth >= 760;
                              if (!wide) {
                                return Column(
                                  children: [
                                    for (var i = 0; i < emails.length; i++)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                        child: EntranceFadeSlide(
                                          index: i,
                                          child: _StaffCard(
                                            email: emails[i],
                                            members: byEmail[emails[i]]!,
                                            canManage: canManage,
                                            busy: controller.isMutating,
                                            onRevoke: (member) => _confirmRevoke(context, controller, member),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              }
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: emails.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: AppSpacing.sm,
                                  crossAxisSpacing: AppSpacing.sm,
                                  mainAxisExtent: 140,
                                ),
                                itemBuilder: (context, index) => EntranceFadeSlide(
                                  index: index,
                                  child: _StaffCard(
                                    email: emails[index],
                                    members: byEmail[emails[index]]!,
                                    canManage: canManage,
                                    busy: controller.isMutating,
                                    onRevoke: (member) => _confirmRevoke(context, controller, member),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
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

  Future<void> _confirmRevoke(
    BuildContext context,
    AdminStaffController controller,
    AdminStaffMember member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer ce rôle ?'),
        content: Text('${member.email} perdra le rôle « ${member.role.label} ».'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.revokeRole(userId: member.userId, role: member.role);
    }
  }
}

class _GrantCard extends StatefulWidget {
  const _GrantCard({required this.controller});

  final AdminStaffController controller;

  @override
  State<_GrantCard> createState() => _GrantCardState();
}

class _GrantCardState extends State<_GrantCard> {
  final _emailController = TextEditingController();
  StaffRole _role = StaffRole.supportAgent;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    final success = await widget.controller.grantRole(email: email, role: _role);
    if (success && mounted) _emailController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final busy = widget.controller.isMutating;

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: AdminTheme.accent.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GradientIconBadge(
                icon: Icons.person_add_alt_1_rounded,
                size: 34,
                gradient: AdminGradients.cobaltMetallic,
                iconColor: AppColors.textPrimary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Accorder un rôle',
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'La personne doit déjà avoir un compte JurisIA — ce formulaire ne fait '
            'qu\'accorder un rôle à un compte existant, recherché par e-mail.',
            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 560;
              final email = TextField(
                controller: _emailController,
                enabled: !busy,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail du compte', isDense: true),
              );
              final role = DropdownButtonFormField<StaffRole>(
                initialValue: _role,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Rôle', isDense: true),
                items: [
                  for (final role in StaffRole.values) DropdownMenuItem(value: role, child: Text(role.label)),
                ],
                onChanged: busy ? null : (value) => setState(() => _role = value ?? _role),
              );
              if (!wide) {
                return Column(
                  children: [email, const SizedBox(height: AppSpacing.sm), role],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: email),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(flex: 2, child: role),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: busy ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: AdminTheme.accent),
              icon: busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.person_add_alt_1_rounded, size: 16),
              label: const Text('Accorder'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({
    required this.email,
    required this.members,
    required this.canManage,
    required this.busy,
    required this.onRevoke,
  });

  final String email;
  final List<AdminStaffMember> members;
  final bool canManage;
  final bool busy;
  final ValueChanged<AdminStaffMember> onRevoke;

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
              AdminAvatar(seed: email, size: 32),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SelectableText(email, maxLines: 1, style: textTheme.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final member in members)
                _RoleChip(
                  member: member,
                  onRevoke: canManage ? (busy ? null : () => onRevoke(member)) : null,
                ),
            ],
          ),
          if (members.first.grantedByEmail != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Accordé par ${members.first.grantedByEmail}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.member, required this.onRevoke});

  final AdminStaffMember member;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    final tint = _roleTint(member.role);
    return Container(
      padding: EdgeInsets.only(left: AppSpacing.sm, right: onRevoke != null ? 4 : AppSpacing.sm, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: tint.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            member.role.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: tint, fontWeight: FontWeight.w700),
          ),
          if (onRevoke != null) ...[
            const SizedBox(width: 2),
            InkWell(
              customBorder: const CircleBorder(),
              onTap: onRevoke,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(Icons.close_rounded, size: 13, color: tint),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
