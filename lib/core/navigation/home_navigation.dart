import 'package:flutter/material.dart';

import '../../features/library/presentation/screens/library_screen.dart';
import '../../features/litigation/presentation/screens/litigation_screen.dart';
import '../../features/professional/presentation/screens/professional_screen.dart';
import '../../features/student/presentation/screens/student_screen.dart';
import '../../theme/app_theme.dart';
import '../widgets/luxury_scaffold_background.dart';
import '../widgets/smoked_glass_surface.dart';

class _NavDestination {
  const _NavDestination({required this.label, required this.icon, required this.selectedIcon});

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _destinations = [
  _NavDestination(
    label: 'Litiges',
    icon: Icons.forum_outlined,
    selectedIcon: Icons.forum_rounded,
  ),
  _NavDestination(
    label: 'Bibliothèque',
    icon: Icons.local_library_outlined,
    selectedIcon: Icons.local_library_rounded,
  ),
  _NavDestination(
    label: 'Étudiant',
    icon: Icons.school_outlined,
    selectedIcon: Icons.school_rounded,
  ),
  _NavDestination(
    label: 'Professionnel',
    icon: Icons.workspace_premium_outlined,
    selectedIcon: Icons.workspace_premium_rounded,
  ),
];

/// Coquille de navigation principale de JurisIA, reliant les quatre modules
/// obligatoires : Litiges et consultations, Bibliothèque juridique, Espace
/// étudiant et Espace professionnel. S'adapte entre une barre de navigation
/// inférieure (mobile) et un rail latéral (web, tablette, desktop), toutes
/// deux habillées en verre fumé sombre.
class HomeNavigation extends StatefulWidget {
  const HomeNavigation({super.key});

  static const double _wideLayoutBreakpoint = 800;

  @override
  State<HomeNavigation> createState() => _HomeNavigationState();
}

class _HomeNavigationState extends State<HomeNavigation> {
  int _selectedIndex = 0;

  static const _screens = [
    LitigationScreen(),
    LibraryScreen(),
    StudentScreen(),
    ProfessionalScreen(),
  ];

  void _onSelect(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= HomeNavigation._wideLayoutBreakpoint;

    final body = IndexedStack(index: _selectedIndex, children: _screens);

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: isWide
            ? Row(
                children: [
                  _SideRail(selectedIndex: _selectedIndex, onSelect: _onSelect),
                  const VerticalDivider(width: 1, color: AppColors.divider),
                  Expanded(child: body),
                ],
              )
            : body,
        bottomNavigationBar: isWide ? null : _BottomNavBar(selectedIndex: _selectedIndex, onSelect: _onSelect),
      ),
    );
  }
}

/// Icône de destination avec dégradé or et lueur d'accentuation lorsque
/// sélectionnée.
class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.icon, required this.selected, this.size = 24});

  final IconData icon;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, size: size, color: Colors.white);

    return SizedBox(
      height: size + 10,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          AnimatedOpacity(
            opacity: selected ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
            child: Container(
              width: size * 1.6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: AppShadows.goldGlowSoft,
                color: AppColors.gold.withValues(alpha: 0.001),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.fastOutSlowIn,
              switchOutCurve: Curves.fastOutSlowIn,
              child: selected
                  ? ShaderMask(
                      key: const ValueKey('selected'),
                      shaderCallback: (bounds) => AppGradients.goldMetallic.createShader(bounds),
                      child: iconWidget,
                    )
                  : Icon(
                      icon,
                      key: const ValueKey('unselected'),
                      size: size,
                      color: AppColors.textSecondary,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SmokedGlassSurface(
      border: const Border(right: BorderSide(color: AppColors.glassBorder, width: 0.6)),
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: ShaderMask(
                shaderCallback: (bounds) => AppGradients.goldMetallic.createShader(bounds),
                child: Text(
                  'JurisIA',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            for (var i = 0; i < _destinations.length; i++)
              _RailItem(
                destination: _destinations[i],
                selected: selectedIndex == i,
                onTap: () => onSelect(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({required this.destination, required this.selected, required this.onTap});

  final _NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Material(
        color: selected ? AppColors.gold.withValues(alpha: 0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                _NavIcon(icon: selected ? destination.selectedIcon : destination.icon, selected: selected, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    destination.label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: selected ? AppColors.gold : AppColors.textSecondary,
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

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SmokedGlassSurface(
      border: const Border(top: BorderSide(color: AppColors.glassBorder, width: 0.6)),
      child: SafeArea(
        child: SizedBox(
          height: 74,
          child: Row(
            children: [
              for (var i = 0; i < _destinations.length; i++)
                Expanded(
                  child: _BottomNavItem(
                    destination: _destinations[i],
                    selected: selectedIndex == i,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({required this.destination, required this.selected, required this.onTap});

  final _NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _NavIcon(icon: selected ? destination.selectedIcon : destination.icon, selected: selected, size: 22),
          const SizedBox(height: 3),
          Text(
            destination.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected ? AppColors.gold : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
