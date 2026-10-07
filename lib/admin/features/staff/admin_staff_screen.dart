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
import '../../widgets/admin_section_card.dart';
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

class _View extends StatefulWidget {
  const _View({required this.canManage});

  final bool canManage;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final _search = TextEditingController();
  StaffRole? _roleFilter;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminStaffController>();
    final canManage = widget.canManage;

    // Un même compte peut porter plusieurs rôles (staff_roles a une ligne
    // par rôle) : regrouper par e-mail pour n'afficher chaque personne
    // qu'une fois, avec ses rôles en pastilles.
    final byEmail = <String, List<AdminStaffMember>>{};
    for (final member in controller.members) {
      byEmail.putIfAbsent(member.email, () => []).add(member);
    }
    final emails = byEmail.keys.where((email) {
      final query = _search.text.trim().toLowerCase();
      final matchesQuery = query.isEmpty || email.toLowerCase().contains(query);
      final matchesRole = _roleFilter == null || byEmail[email]!.any((member) => member.role == _roleFilter);
      return matchesQuery && matchesRole;
    }).toList()..sort();

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              AdminPageHeader(
                icon: Icons.badge_rounded,
                title: 'Personnel',
                subtitle: 'Annuaire des accès, rôles et responsabilités de la console.',
                actions: [
                  IconButton(
                    tooltip: 'Actualiser le personnel',
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
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.xl),
                      children: [
                        _StaffHero(
                          accounts: byEmail.length,
                          roles: controller.members.length,
                          canManage: canManage,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _StaffMetrics(members: controller.members, accounts: byEmail.length),
                        const SizedBox(height: AppSpacing.lg),
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
                                    'Consultation seule · seuls les super administrateurs peuvent accorder ou retirer un rôle.',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: AppSpacing.lg),
                        AdminSectionCard(
                          title: 'Annuaire des accès',
                          icon: Icons.manage_accounts_rounded,
                          trailing: Text('${emails.length} / ${byEmail.length} compte${byEmail.length > 1 ? 's' : ''}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _search,
                                decoration: InputDecoration(
                                  hintText: 'Rechercher un compte par e-mail…',
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  suffixIcon: _search.text.isEmpty ? null : IconButton(tooltip: 'Effacer', onPressed: _search.clear, icon: const Icon(Icons.close_rounded)),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              DropdownButtonFormField<StaffRole?>(
                                initialValue: _roleFilter,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'Filtrer par rôle', prefixIcon: Icon(Icons.filter_list_rounded), isDense: true),
                                items: [
                                  const DropdownMenuItem<StaffRole?>(value: null, child: Text('Tous les rôles')),
                                  for (final role in StaffRole.values)
                                    DropdownMenuItem<StaffRole?>(value: role, child: Text(role.label)),
                                ],
                                onChanged: (role) => setState(() => _roleFilter = role),
                              ),
                              const SizedBox(height: AppSpacing.md),
                        if (controller.isLoading && controller.members.isEmpty)
                          const SizedBox(height: 240, child: Center(child: CircularProgressIndicator()))
                        else if (controller.members.isEmpty)
                          const SizedBox(height: 240, child: AdminEmptyState(icon: Icons.group_off_rounded, message: 'Aucun membre du personnel pour l\'instant.'))
                        else if (emails.isEmpty)
                          const SizedBox(height: 220, child: AdminEmptyState(icon: Icons.search_off_rounded, message: 'Aucun compte ne correspond à ces critères.', detail: 'Changez le terme recherché ou le rôle sélectionné.'))
                        else
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final wide = constraints.maxWidth >= 820;
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
                              final columns = constraints.maxWidth >= 1240 ? 3 : 2;
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: emails.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  mainAxisSpacing: AppSpacing.sm,
                                  crossAxisSpacing: AppSpacing.sm,
                                  mainAxisExtent: 220,
                                ),
                                itemBuilder: (context, index) => EntranceFadeSlide(
                                  index: index,
                                  child: _StaffCard(email: emails[index], members: byEmail[emails[index]]!, canManage: canManage, busy: controller.isMutating, onRevoke: (member) => _confirmRevoke(context, controller, member)),
                                ),
                              );
                            },
                          ),
                            ],
                          ),
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

class _StaffHero extends StatelessWidget {
  const _StaffHero({required this.accounts, required this.roles, required this.canManage});
  final int accounts;
  final int roles;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.large),
        gradient: LinearGradient(
          colors: [AdminTheme.accentDark.withValues(alpha: 0.92), AppColors.deepSlate.withValues(alpha: 0.90), AppColors.deepSlateDeep.withValues(alpha: 0.96)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AdminTheme.accentLight.withValues(alpha: 0.28)),
        boxShadow: [BoxShadow(color: AdminTheme.accent.withValues(alpha: 0.14), blurRadius: 30, spreadRadius: -12)],
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 650;
        final intro = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.gold.withValues(alpha: 0.38))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.admin_panel_settings_rounded, size: 15, color: AppColors.gold), const SizedBox(width: 7), Text('GOUVERNANCE DES ACCÈS', style: textTheme.labelSmall?.copyWith(color: AppColors.gold, letterSpacing: AppLetterSpacing.caps, fontWeight: FontWeight.w800))]),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Les bonnes personnes,\nles bons accès.', style: (compact ? textTheme.headlineSmall : textTheme.headlineMedium)?.copyWith(fontFamily: 'Libre Caslon Display', height: 1.05)),
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: Text('Une vue claire des équipes qui opèrent JurisIA. Les rôles sont regroupés par compte et chaque changement reste soumis aux contrôles serveur.', style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.45))),
        ]);
        final summary = Container(
          constraints: BoxConstraints(minWidth: compact ? 0 : 220, maxWidth: 270),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.055), borderRadius: BorderRadius.circular(AppRadius.medium), border: Border.all(color: Colors.white.withValues(alpha: 0.10))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ÉQUIPE ADMINISTRATIVE', style: textTheme.labelSmall?.copyWith(color: AdminTheme.accentLight, letterSpacing: AppLetterSpacing.caps, fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [const Icon(Icons.groups_rounded, size: 19, color: AppColors.gold), const SizedBox(width: 9), Text('$accounts compte${accounts > 1 ? 's' : ''}', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))]),
            const SizedBox(height: AppSpacing.xs),
            Text('$roles attributions de rôle', style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [Icon(canManage ? Icons.verified_user_rounded : Icons.visibility_rounded, size: 15, color: canManage ? AppColors.success : AppColors.textDisabled), const SizedBox(width: 6), Expanded(child: Text(canManage ? 'Gestion des rôles autorisée' : 'Accès en consultation', style: textTheme.labelSmall?.copyWith(color: canManage ? AppColors.success : AppColors.textSecondary)))]),
          ]),
        );
        return compact ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [intro, const SizedBox(height: AppSpacing.md), summary]) : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: intro), const SizedBox(width: AppSpacing.lg), summary]);
      }),
    );
  }
}

class _StaffMetrics extends StatelessWidget {
  const _StaffMetrics({required this.members, required this.accounts});
  final List<AdminStaffMember> members;
  final int accounts;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _StaffMetric(label: 'Comptes', value: accounts, icon: Icons.groups_rounded, color: AdminTheme.accentLight),
      _StaffMetric(label: 'Rôles actifs', value: members.length, icon: Icons.key_rounded, color: AppColors.gold),
      _StaffMetric(label: 'Super admins', value: members.where((member) => member.role == StaffRole.superAdmin).length, icon: Icons.admin_panel_settings_rounded, color: AppColors.error),
      _StaffMetric(label: 'Équipe juridique', value: members.where((member) => member.role == StaffRole.legalReviewer || member.role == StaffRole.contentEditor).length, icon: Icons.balance_rounded, color: AppColors.metalEmerald),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 680;
      return compact
          ? Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [for (final metric in metrics) SizedBox(width: (constraints.maxWidth - AppSpacing.sm) / 2, child: metric)])
          : Row(children: [for (var i = 0; i < metrics.length; i++) Expanded(child: Padding(padding: EdgeInsets.only(right: i == metrics.length - 1 ? 0 : AppSpacing.sm), child: metrics[i]))]);
    });
  }
}

class _StaffMetric extends StatelessWidget {
  const _StaffMetric({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => GlassContainer(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(children: [Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle), child: Icon(icon, size: 18, color: color)), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textDisabled, letterSpacing: AppLetterSpacing.caps, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text('$value', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontFamily: 'Libre Caslon Display'))]))]),
      );
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
              AdminAvatar(seed: email, size: 40),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(email, maxLines: 1, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text('${members.length} rôle${members.length > 1 ? 's' : ''} attribué${members.length > 1 ? 's' : ''}', style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
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
            Row(children: [const Icon(Icons.history_rounded, size: 14, color: AppColors.textDisabled), const SizedBox(width: 5), Expanded(child: Text('Dernier accès accordé par ${members.first.grantedByEmail}', maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled)))]),
          ],
          if (members.first.grantedAt != null) ...[
            const SizedBox(height: 4),
            Text('Depuis le ${_formatStaffDate(members.first.grantedAt!)}', style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled)),
          ],
        ],
      ),
    );
  }
}

String _formatStaffDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

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
