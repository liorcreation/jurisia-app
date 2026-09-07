import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/supabase/supabase_config.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/jurisia_mark.dart';
import '../../core/widgets/luxury_scaffold_background.dart';
import '../../core/widgets/shimmer_sweep.dart';
import '../../core/widgets/smoked_glass_surface.dart';
import '../../core/widgets/tap_scale.dart';
import '../../theme/app_theme.dart';
import '../auth/staff_role.dart';
import '../features/audit/admin_audit_screen.dart';
import '../features/contact_requests/admin_contact_requests_screen.dart';
import '../features/dashboard/admin_dashboard_screen.dart';
import '../features/library_cms/admin_library_cms_screen.dart';
import '../features/prompt_studio/admin_prompt_studio_screen.dart';
import '../features/review_room/admin_review_room_screen.dart';
import '../features/staff/admin_staff_screen.dart';
import '../features/subscriptions/admin_subscriptions_screen.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_ambience.dart';
import 'admin_shell_scope.dart';

const double _kSidebarWidth = 292;

/// En dessous de cette largeur, la sidebar permanente devient un tiroir —
/// même convention que le registre mobile/tablette de l'app grand public
/// (`AppPlatformStyle.wideBreakpoint`) : téléphones et tablettes en
/// portrait passent en tiroir, desktop et tablettes en paysage gardent le
/// panneau permanent.
const double _kWideBreakpoint = 1000;

class _AdminDestination {
  const _AdminDestination({
    required this.group,
    required this.label,
    required this.icon,
    required this.screen,
  });

  final String group;
  final String label;
  final IconData icon;
  final Widget screen;
}

/// Coquille de la console : sidebar permanente à largeur fixe (registre
/// « cabinet numérique » cobalt, ambiance vivante, navigation groupée) +
/// `IndexedStack` des sections autorisées par le rôle de l'opérateur.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.identity, required this.onSignOut});

  final StaffIdentity identity;
  final Future<void> Function() onSignOut;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final List<_AdminDestination> _destinations = _buildDestinations();

  List<_AdminDestination> _buildDestinations() {
    final identity = widget.identity;
    return [
      _AdminDestination(
        group: 'Vue d\'ensemble',
        label: 'Tableau de bord',
        icon: Icons.dashboard_rounded,
        screen: AdminDashboardScreen(identity: identity),
      ),
      if (identity.canReviewDocuments || identity.canPublishPrompts)
        _AdminDestination(
          group: 'Opérations',
          label: 'Salle de revue',
          icon: Icons.fact_check_rounded,
          screen: AdminReviewRoomScreen(identity: identity),
        ),
      if (identity.canOperate)
        const _AdminDestination(
          group: 'Opérations',
          label: 'Mise en relation',
          icon: Icons.support_agent_rounded,
          screen: AdminContactRequestsScreen(),
        ),
      if (identity.canSeeBilling)
        const _AdminDestination(
          group: 'Opérations',
          label: 'Abonnements',
          icon: Icons.credit_card_rounded,
          screen: AdminSubscriptionsScreen(),
        ),
      if (identity.canEditContent)
        _AdminDestination(
          group: 'Contenu',
          label: 'CMS Bibliothèque',
          icon: Icons.menu_book_rounded,
          screen: AdminLibraryCmsScreen(identity: identity),
        ),
      if (identity.canEditContent)
        _AdminDestination(
          group: 'Contenu',
          label: 'Studio de prompts',
          icon: Icons.auto_awesome_rounded,
          screen: AdminPromptStudioScreen(identity: identity),
        ),
      const _AdminDestination(
        group: 'Système',
        label: 'Journal d\'audit',
        icon: Icons.receipt_long_rounded,
        screen: AdminAuditScreen(),
      ),
      _AdminDestination(
        group: 'Système',
        label: 'Personnel',
        icon: Icons.badge_rounded,
        screen: AdminStaffScreen(identity: identity),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return LuxuryScaffoldBackground(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= _kWideBreakpoint;
          final content = IndexedStack(
            index: _index,
            children: [for (final destination in _destinations) destination.screen],
          );

          if (wide) {
            return AdminShellScope(
              openDrawer: null,
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, 0, AppSpacing.md),
                      child: SizedBox(
                        width: _kSidebarWidth,
                        child: _Sidebar(
                          destinations: _destinations,
                          selectedIndex: _index,
                          onSelect: (i) => setState(() => _index = i),
                          identity: widget.identity,
                          onSignOut: widget.onSignOut,
                        ),
                      ),
                    ),
                    Expanded(child: content),
                  ],
                ),
              ),
            );
          }

          return AdminShellScope(
            openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
            child: Scaffold(
              key: _scaffoldKey,
              backgroundColor: Colors.transparent,
              drawerScrimColor: Colors.black.withValues(alpha: 0.55),
              drawer: Drawer(
                backgroundColor: Colors.transparent,
                elevation: 0,
                width: math.min(320, constraints.maxWidth * 0.86),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: _Sidebar(
                    destinations: _destinations,
                    selectedIndex: _index,
                    onSelect: (i) {
                      setState(() => _index = i);
                      Navigator.of(context).maybePop();
                    },
                    identity: widget.identity,
                    onSignOut: widget.onSignOut,
                  ),
                ),
              ),
              body: content,
            ),
          );
        },
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
    final radius = BorderRadius.circular(AppRadius.large);

    // Pas de largeur imposée ici : le panneau permanent (desktop) et le
    // tiroir (mobile/tablette) contraignent chacun leur propre largeur côté
    // appelant — un `SizedBox` fixe ici déborderait du tiroir sur un petit
    // téléphone.
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: AppShadows.floating),
      child: SmokedGlassSurface(
        borderRadius: radius,
        border: Border.all(color: AdminTheme.accent.withValues(alpha: 0.26), width: 0.8),
        child: Stack(
          children: [
            const Positioned.fill(child: IgnorePointer(child: AdminAmbience())),
            SafeArea(
              right: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _BrandHeader(),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      children: _buildNavChildren(),
                    ),
                  ),
                  const _FadingRule(),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: _ProfileCard(identity: identity, onSignOut: onSignOut),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildNavChildren() {
    final children = <Widget>[];
    String? currentGroup;
    for (var i = 0; i < destinations.length; i++) {
      final destination = destinations[i];
      if (destination.group != currentGroup) {
        currentGroup = destination.group;
        if (children.isNotEmpty) children.add(const SizedBox(height: AppSpacing.sm));
        children.add(_GroupLabel(currentGroup));
      }
      children.add(
        _NavItem(
          destination: destination,
          selected: i == selectedIndex,
          onTap: () => onSelect(i),
        ),
      );
    }
    return children;
  }
}

/// En-tête de marque de la sidebar : plaque cobalt + monogramme, mot
/// « JurisIA » en serif, pastille « ADMIN » — le repère immédiat qui évite
/// toute confusion avec l'application grand public.
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AdminTheme.accent.withValues(alpha: 0.55), width: 0.9),
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.4),
                radius: 1.1,
                colors: [AppColors.nightBlue, AppColors.nightBlueDeep],
              ),
              boxShadow: AdminGradients.cobaltGlowSoft,
            ),
            child: JurisIAMark(size: 24, gradient: AdminGradients.cobaltMetallic),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('JurisIA', style: textTheme.titleMedium?.copyWith(fontFamily: 'Libre Caslon Display')),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        gradient: AppGradients.goldSheen,
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                      child: Text(
                        'ADMIN',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.nightBlueDeep,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('Console', style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, 6),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textDisabled,
              letterSpacing: AppLetterSpacing.caps,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({required this.destination, required this.selected, required this.onTap});

  final _AdminDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final selected = widget.selected;

    Widget pill = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        gradient: selected
            ? LinearGradient(
                colors: [AdminTheme.accent.withValues(alpha: 0.28), AdminTheme.accent.withValues(alpha: 0.10)],
              )
            : null,
        color: selected ? null : (_hovered ? Colors.white.withValues(alpha: 0.04) : Colors.transparent),
        border: Border.all(
          color: selected ? AdminTheme.accent.withValues(alpha: 0.5) : Colors.transparent,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: selected ? AdminTheme.accentLight : Colors.transparent,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            widget.destination.icon,
            size: 18,
            color: selected ? AdminTheme.accentLight : AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              widget.destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium?.copyWith(
                color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );

    if (selected) pill = ShimmerSweep(duration: const Duration(milliseconds: 2600), child: pill);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            onTap: widget.onTap,
            child: pill,
          ),
        ),
      ),
    );
  }
}

class _FadingRule extends StatelessWidget {
  const _FadingRule();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AdminTheme.accent.withValues(alpha: 0.35),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

/// Carte profil en pied de sidebar : monogramme cobalt, e-mail du compte
/// connecté, rôle principal, déconnexion.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.identity, required this.onSignOut});

  final StaffIdentity identity;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final email = SupabaseConfig.isReady ? SupabaseConfig.client.auth.currentUser?.email : null;
    final initial = (email?.isNotEmpty ?? false) ? email!.substring(0, 1).toUpperCase() : '?';
    final roleLabel = identity.primary?.label ?? 'Personnel';

    return GlassContainer(
      borderRadius: AppRadius.medium,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AdminGradients.cobaltMetallic,
                  boxShadow: AdminGradients.cobaltGlowSoft,
                ),
                child: Text(
                  initial,
                  style: textTheme.titleSmall?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      email ?? 'Compte du personnel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(shape: BoxShape.circle, gradient: AdminGradients.cobaltSheen),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            roleLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelSmall?.copyWith(color: AdminTheme.accentLight),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TapScale(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                onTap: onSignOut,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    color: AppColors.error.withValues(alpha: 0.10),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.35), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.logout_rounded, size: 14, color: AppColors.error),
                      const SizedBox(width: 6),
                      Text(
                        'Se déconnecter',
                        style: textTheme.labelSmall?.copyWith(color: AppColors.error, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
