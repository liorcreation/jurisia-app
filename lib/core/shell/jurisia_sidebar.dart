import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/litigation/presentation/controllers/litigation_chat_controller.dart';
import '../navigation/nav_destinations.dart';
import '../widgets/glow_focus_field.dart';
import '../widgets/jurisia_mark.dart';
import '../widgets/luxury_elevated_button.dart';
import '../widgets/smoked_glass_surface.dart';
import '../widgets/tap_scale.dart';
import '../../theme/app_theme.dart';
import 'app_shell.dart';
import 'sidebar_context_section.dart';
import 'sidebar_profile_card.dart';

/// Comment la sidebar est présentée : contenu d'un `Drawer` (mobile), panneau
/// permanent (desktop large), ou rail d'icônes réduit (desktop replié).
enum SidebarVariant { drawer, permanent, rail }

/// La sidebar unifiée de JurisIA — navigation principale sur toutes les
/// plateformes. Organisée comme les assistants modernes (marque, action
/// « Nouvelle consultation », recherche, historique daté), mais dans le
/// registre haut de gamme de JurisIA : verre fumé, filet d'or brossé, marque
/// « rose des précisions ».
class JurisIASidebar extends StatefulWidget {
  const JurisIASidebar({super.key, required this.variant});

  final SidebarVariant variant;

  @override
  State<JurisIASidebar> createState() => _JurisIASidebarState();
}

class _JurisIASidebarState extends State<JurisIASidebar> {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _query = ValueNotifier<String>('');

  bool get _isRail => widget.variant == SidebarVariant.rail;

  @override
  void dispose() {
    _searchController.dispose();
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.large);
    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: widget.variant == SidebarVariant.drawer ? null : radius,
        boxShadow: widget.variant == SidebarVariant.drawer ? null : AppShadows.floating,
      ),
      child: SmokedGlassSurface(
        borderRadius: widget.variant == SidebarVariant.drawer ? null : radius,
        border: Border.all(color: AppColors.glassBorder, width: 0.6),
        child: SafeArea(
          right: false,
          child: _isRail ? _buildRail(context) : _buildExpanded(context),
        ),
      ),
    );
    return decorated;
  }

  // --- Rail replié (desktop) -------------------------------------------

  Widget _buildRail(BuildContext context) {
    final shell = AppShellScope.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Tooltip(
            message: 'Déplier la navigation',
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              onTap: shell.toggleNav,
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.sm),
                child: JurisIAMark(size: 24),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _RailIconButton(
            icon: Icons.add_comment_rounded,
            tooltip: 'Nouvelle consultation',
            gold: true,
            onTap: () => _startNewConsultation(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < kNavDestinations.length; i++)
            _RailIconButton(
              icon: kNavDestinations[i].icon,
              selectedIcon: kNavDestinations[i].selectedIcon,
              tooltip: kNavDestinations[i].label,
              selected: shell.selectedIndex == i,
              onTap: () => shell.selectModule(i),
            ),
          const Spacer(),
          const SidebarProfileCard(compact: true),
        ],
      ),
    );
  }

  // --- Sidebar dépliée (permanent + drawer) ---------------------------

  Widget _buildExpanded(BuildContext context) {
    final shell = AppShellScope.of(context);
    final isDrawer = widget.variant == SidebarVariant.drawer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BrandHeader(
          trailing: IconButton(
            tooltip: isDrawer ? 'Fermer' : 'Replier la navigation',
            icon: Icon(isDrawer ? Icons.close_rounded : Icons.chevron_left_rounded),
            onPressed: () {
              if (isDrawer) {
                Navigator.of(context).maybePop();
              } else {
                shell.toggleNav();
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
          child: LuxuryElevatedButton(
            icon: Icons.add_comment_rounded,
            onPressed: () => _startNewConsultation(context),
            child: const Text('Nouvelle consultation'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
          child: GlowFocusField(
            borderRadius: AppRadius.pill,
            child: ValueListenableBuilder<String>(
              valueListenable: _query,
              builder: (context, query, _) => TextField(
                controller: _searchController,
                onChanged: (value) => _query.value = value,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  hintText: 'Rechercher une consultation…',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _query.value = '';
                          },
                        ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.md),
            children: [
              _SectionLabel('Espaces'),
              for (var i = 0; i < kNavDestinations.length; i++)
                _ModuleRow(
                  destination: kNavDestinations[i],
                  selected: shell.selectedIndex == i,
                  onTap: () => shell.selectModule(i),
                ),
              const SizedBox(height: AppSpacing.sm),
              SidebarContextSection(query: _query),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 0.6),
        const Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: SidebarProfileCard(),
        ),
      ],
    );
  }

  void _startNewConsultation(BuildContext context) {
    context.read<LitigationChatController>().startNewConsultation();
    AppShellScope.of(context).selectModule(0);
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({this.trailing});

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.sm),
      child: Row(
        children: [
          const JurisIAMark(size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ShaderMask(
              shaderCallback: (bounds) => AppGradients.goldMetallic.createShader(bounds),
              child: const Text(
                'JurisIA',
                style: TextStyle(
                  fontFamily: 'Libre Caslon Display',
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textDisabled,
              fontWeight: FontWeight.w700,
              letterSpacing: AppLetterSpacing.caps,
            ),
      ),
    );
  }
}

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({required this.destination, required this.selected, required this.onTap});

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
      child: Material(
        color: selected ? AppColors.gold.withValues(alpha: 0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.fastOutSlowIn,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 11),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  width: 3,
                  height: selected ? 18 : 0,
                  decoration: BoxDecoration(
                    gradient: AppGradients.goldSheen,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                selected
                    ? ShaderMask(
                        shaderCallback: (bounds) => AppGradients.goldMetallic.createShader(bounds),
                        child: Icon(destination.selectedIcon, size: 21, color: Colors.white),
                      )
                    : Icon(destination.icon, size: 21, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    destination.label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: selected ? AppColors.gold : AppColors.textSecondary,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
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

class _RailIconButton extends StatelessWidget {
  const _RailIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.selectedIcon,
    this.selected = false,
    this.gold = false,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String tooltip;
  final VoidCallback onTap;
  final bool selected;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final effectiveIcon = selected ? (selectedIcon ?? icon) : icon;
    final child = gold
        ? ShaderMask(
            shaderCallback: (bounds) => AppGradients.goldMetallic.createShader(bounds),
            child: Icon(effectiveIcon, size: 22, color: Colors.white),
          )
        : Icon(
            effectiveIcon,
            size: 22,
            color: selected ? AppColors.gold : AppColors.textSecondary,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: TapScale(
        child: Tooltip(
          message: tooltip,
          child: Material(
            color: selected ? AppColors.gold.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              child: Padding(padding: const EdgeInsets.all(10), child: child),
            ),
          ),
        ),
      ),
    );
  }
}
