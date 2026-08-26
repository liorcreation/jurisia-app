import 'package:flutter/material.dart';

import '../../features/library/presentation/screens/library_screen.dart';
import '../../features/litigation/presentation/screens/litigation_screen.dart';
import '../../features/professional/presentation/screens/professional_screen.dart';
import '../../features/student/presentation/screens/student_screen.dart';
import '../../theme/app_theme.dart';
import '../platform/app_platform_style.dart';
import '../widgets/command_palette.dart';
import '../widgets/jurisia_mark.dart';
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
    final platformStyle = AppPlatformStyle.of(context);
    final isWide = platformStyle == AppPlatformStyle.desktop;

    final body = IndexedStack(index: _selectedIndex, children: _screens);

    Widget bottomBar() {
      if (isWide) return const SizedBox.shrink();
      return platformStyle == AppPlatformStyle.ios
          ? _IosTabBar(selectedIndex: _selectedIndex, onSelect: _onSelect)
          : _AndroidNavBar(selectedIndex: _selectedIndex, onSelect: _onSelect);
    }

    final scaffold = LuxuryScaffoldBackground(
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
        bottomNavigationBar: isWide ? null : bottomBar(),
      ),
    );

    if (!isWide) return scaffold;

    // Registre desktop « cabinet numérique » : ⌘K / Ctrl+K ouvre la palette
    // de commandes pour un juriste qui travaille au clavier.
    return CommandPaletteShortcut(onSelectModule: _onSelect, child: scaffold);
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
        width: 232,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const JurisIAMark(size: 22),
                  const SizedBox(width: AppSpacing.sm),
                  ShaderMask(
                    shaderCallback: (bounds) => AppGradients.goldMetallic.createShader(bounds),
                    child: Text(
                      'JurisIA',
                      style: const TextStyle(
                        fontFamily: 'Libre Caslon Display',
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
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

/// Barre d'onglets iOS — le registre « Verre glacé » : pas de pastille ni de
/// halo, seule la couleur de l'icône et du libellé change, comme sur iOS.
class _IosTabBar extends StatelessWidget {
  const _IosTabBar({required this.selectedIndex, required this.onSelect});

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
                  child: _IosTabItem(
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

class _IosTabItem extends StatelessWidget {
  const _IosTabItem({required this.destination, required this.selected, required this.onTap});

  final _NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.gold : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              selected ? destination.selectedIcon : destination.icon,
              key: ValueKey(selected),
              size: 22,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            destination.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

/// Barre de navigation Android — le registre « Or expressif » (Material 3) :
/// une pastille pleine derrière l'icône active et une vraie onde de
/// vibration Material au toucher.
class _AndroidNavBar extends StatelessWidget {
  const _AndroidNavBar({required this.selectedIndex, required this.onSelect});

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
                  child: _AndroidNavItem(
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

class _AndroidNavItem extends StatelessWidget {
  const _AndroidNavItem({required this.destination, required this.selected, required this.onTap});

  final _NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.gold : AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.fastOutSlowIn,
              width: 56,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                color: selected ? AppColors.gold.withValues(alpha: 0.20) : Colors.transparent,
              ),
              child: Icon(selected ? destination.selectedIcon : destination.icon, size: 21, color: color),
            ),
            const SizedBox(height: 3),
            Text(
              destination.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
