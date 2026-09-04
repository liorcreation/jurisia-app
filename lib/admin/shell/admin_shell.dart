import 'package:flutter/material.dart';

import '../../core/widgets/luxury_scaffold_background.dart';
import '../../theme/app_theme.dart';
import '../auth/staff_role.dart';
import '../features/audit/admin_audit_screen.dart';
import '../features/contact_requests/admin_contact_requests_screen.dart';
import '../features/dashboard/admin_dashboard_screen.dart';
import '../features/staff/admin_staff_screen.dart';
import '../features/subscriptions/admin_subscriptions_screen.dart';
import '../theme/admin_theme.dart';

class _AdminDestination {
  const _AdminDestination({required this.label, required this.icon, required this.screen});
  final String label;
  final IconData icon;
  final Widget screen;
}

/// Coquille de la console : barre latérale permanente (accent cobalt, badge
/// « ADMIN » visible en permanence) + `IndexedStack` des sections
/// autorisées par le rôle de l'opérateur.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.identity, required this.onSignOut});

  final StaffIdentity identity;
  final Future<void> Function() onSignOut;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  late final List<_AdminDestination> _destinations = _buildDestinations();

  List<_AdminDestination> _buildDestinations() {
    final identity = widget.identity;
    return [
      _AdminDestination(
        label: 'Tableau de bord',
        icon: Icons.dashboard_rounded,
        screen: AdminDashboardScreen(identity: identity),
      ),
      if (identity.canOperate)
        const _AdminDestination(
          label: 'Demandes de mise en relation',
          icon: Icons.support_agent_rounded,
          screen: AdminContactRequestsScreen(),
        ),
      if (identity.canSeeBilling)
        const _AdminDestination(
          label: 'Abonnements',
          icon: Icons.credit_card_rounded,
          screen: AdminSubscriptionsScreen(),
        ),
      const _AdminDestination(
        label: 'Journal d\'audit',
        icon: Icons.receipt_long_rounded,
        screen: AdminAuditScreen(),
      ),
      _AdminDestination(
        label: 'Personnel',
        icon: Icons.badge_rounded,
        screen: AdminStaffScreen(identity: identity),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Row(
          children: [
            _Sidebar(
              destinations: _destinations,
              selectedIndex: _index,
              onSelect: (i) => setState(() => _index = i),
              identity: widget.identity,
              onSignOut: widget.onSignOut,
            ),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: [for (final destination in _destinations) destination.screen],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
    required this.identity,
    required this.onSignOut,
  });

  final List<_AdminDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final StaffIdentity identity;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: 236,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.legalBlueDark, AppColors.nightBlueDeep],
        ),
        border: Border(right: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Text(
                    'JurisIA',
                    style: textTheme.titleLarge?.copyWith(fontFamily: 'Libre Caslon Display'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AdminTheme.accent,
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                    child: Text(
                      'ADMIN',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                children: [
                  for (var i = 0; i < destinations.length; i++)
                    _NavItem(
                      destination: destinations[i],
                      selected: i == selectedIndex,
                      onTap: () => onSelect(i),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(identity.primary?.label ?? 'Personnel', style: textTheme.labelMedium),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: onSignOut,
                    icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.error),
                    label: const Text('Se déconnecter', style: TextStyle(color: AppColors.error)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.destination, required this.selected, required this.onTap});

  final _AdminDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      child: Material(
        color: selected ? AdminTheme.accent.withValues(alpha: 0.16) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.small),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.small),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 10),
            child: Row(
              children: [
                Icon(
                  destination.icon,
                  size: 18,
                  color: selected ? AdminTheme.accentLight : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    destination.label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
