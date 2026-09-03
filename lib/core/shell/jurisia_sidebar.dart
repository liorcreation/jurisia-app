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
import 'sidebar_sections/sidebar_section_scaffold.dart';

/// Comment la sidebar est présentée : contenu d'un `Drawer` (mobile), panneau
/// permanent (desktop large), ou rail d'icônes réduit (desktop replié).
enum SidebarVariant { drawer, permanent, rail }

/// La sidebar unifiée de JurisIA — navigation principale sur toutes les
/// plateformes. Organisée comme les assistants modernes (marque, action
/// « Nouvelle consultation », recherche, historique daté), mais dans un
/// registre « cabinet numérique » propre à JurisIA : panneau de verre fumé
/// cerclé d'un filet d'or, plaques d'espace facettées comme des pierres
/// taillées, marque « rose des précisions », monogramme métallique animé.
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
    final rounded = widget.variant != SidebarVariant.drawer;
    final radius = BorderRadius.circular(AppRadius.large);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: rounded ? radius : null,
        boxShadow: rounded ? AppShadows.floating : null,
      ),
      child: SmokedGlassSurface(
        borderRadius: rounded ? radius : null,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.22), width: 0.7),
        child: Stack(
          children: [
            // Filet de lumière rasante le long du bord supérieur — le détail
            // qui « vend » le verre.
            Positioned(
              top: 0,
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: IgnorePointer(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.16),
                        AppColors.goldLight.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              right: false,
              child: _isRail ? _buildRail(context) : _buildExpanded(context),
            ),
          ],
        ),
      ),
    );
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
                child: JurisIAMark(size: 26),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _RailTick(),
          const SizedBox(height: AppSpacing.md),
          _RailNewConsultationButton(onTap: () => _startNewConsultation(context)),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < kNavDestinations.length; i++)
            _RailModuleButton(
              destination: kNavDestinations[i],
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
          trailing: _HeaderControl(
            tooltip: isDrawer ? 'Fermer' : 'Replier la navigation',
            icon: isDrawer ? Icons.close_rounded : Icons.chevron_left_rounded,
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
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.legalBlueDark.withValues(alpha: 0.55),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.goldLight),
                  prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  hintText: 'Rechercher une consultation…',
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: const BorderSide(color: AppColors.glassBorder, width: 0.6),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: const BorderSide(color: AppColors.glassBorder, width: 0.6),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: const BorderSide(color: AppColors.cobalt, width: 1),
                  ),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16),
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
            padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 2, AppSpacing.sm, AppSpacing.md),
            children: [
              const SidebarGroupLabel('Espaces'),
              for (var i = 0; i < kNavDestinations.length; i++)
                _ModuleRow(
                  destination: kNavDestinations[i],
                  selected: shell.selectedIndex == i,
                  onTap: () => shell.selectModule(i),
                ),
              const SizedBox(height: AppSpacing.xs),
              _FadingRule(),
              SidebarContextSection(query: _query),
            ],
          ),
        ),
        _FadingRule(),
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

/// Plaque d'icône facettée — un petit carré à coins très arrondis dans le
/// registre « pierre taillée » de la marque : verre sombre cerclé d'un filet
/// d'or au repos, entièrement doré (icône gravée en creux) une fois l'espace
/// actif.
class _FacetedTile extends StatelessWidget {
  const _FacetedTile({
    required this.icon,
    required this.selected,
    this.hovered = false,
    this.size = 26,
  });

  final IconData icon;
  final bool selected;
  final bool hovered;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.fastOutSlowIn,
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        gradient: selected ? AppGradients.goldMetallic : null,
        color: selected ? null : AppColors.legalBlueDark.withValues(alpha: 0.5),
        border: Border.all(
          color: selected
              ? Colors.transparent
              : hovered
                  ? AppColors.gold.withValues(alpha: 0.38)
                  : AppColors.glassBorder,
          width: 0.8,
        ),
        boxShadow: selected
            ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.3), blurRadius: 9)]
            : null,
      ),
      child: Icon(
        icon,
        size: size * 0.56,
        color: selected
            ? AppColors.nightBlueDeep
            : hovered
                ? AppColors.goldLight
                : AppColors.textSecondary,
      ),
    );
  }
}

/// Ligne d'espace de la sidebar dépliée : petite plaque facettée + libellé,
/// hauteur uniforme (densité « ChatGPT »). L'espace actif porte un fond doré
/// discret et son libellé passe à l'or.
class _ModuleRow extends StatefulWidget {
  const _ModuleRow({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ModuleRow> createState() => _ModuleRowState();
}

class _ModuleRowState extends State<_ModuleRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final selected = widget.selected;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 1),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.fastOutSlowIn,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.medium),
                color: selected
                    ? AppColors.gold.withValues(alpha: 0.13)
                    : _hovered
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.transparent,
              ),
              child: Row(
                children: [
                  _FacetedTile(
                    icon: selected ? widget.destination.selectedIcon : widget.destination.icon,
                    selected: selected,
                    hovered: _hovered,
                  ),
                  const SizedBox(width: AppSpacing.sm + 2),
                  Expanded(
                    child: Text(
                      widget.destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontSize: 13.5,
                        color: selected
                            ? AppColors.gold
                            : _hovered
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// En-tête de marque : marque « rose des précisions », mot-symbole en serif
/// à reflet métallique, contrôle de repli, et un filet d'or qui s'efface aux
/// extrémités.
class _BrandHeader extends StatelessWidget {
  const _BrandHeader({this.trailing});

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.sm),
          child: Row(
            children: [
              const JurisIAMark(size: 24),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: ShaderMask(
                  shaderCallback: (bounds) => AppGradients.goldMetallic.createShader(bounds),
                  child: const Text(
                    'JurisIA',
                    style: TextStyle(
                      fontFamily: 'Libre Caslon Display',
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xs),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.gold.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bouton de contrôle de l'en-tête (repli / fermeture) — pastille de verre
/// discrète plutôt qu'un `IconButton` nu.
class _HeaderControl extends StatelessWidget {
  const _HeaderControl({required this.tooltip, required this.icon, required this.onPressed});

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: TapScale(
        child: Material(
          color: AppColors.legalBlueDark.withValues(alpha: 0.5),
          shape: const CircleBorder(side: BorderSide(color: AppColors.glassBorder, width: 0.6)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(icon, size: 18, color: AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

/// Filet de séparation qui s'efface aux extrémités.
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
            AppColors.divider,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

// --- Rail (desktop replié) --------------------------------------------------

/// Petit repère doré vertical en tête de rail, écho du filet de l'en-tête
/// déplié.
class _RailTick extends StatelessWidget {
  const _RailTick();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.gold.withValues(alpha: 0.5),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _RailNewConsultationButton extends StatelessWidget {
  const _RailNewConsultationButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: TapScale(
        child: Tooltip(
          message: 'Nouvelle consultation',
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppGradients.goldMetallic,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(color: AppColors.gold.withValues(alpha: 0.35), blurRadius: 12),
                  ],
                ),
                child: const Icon(Icons.add_comment_rounded, size: 20, color: AppColors.nightBlueDeep),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RailModuleButton extends StatefulWidget {
  const _RailModuleButton({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_RailModuleButton> createState() => _RailModuleButtonState();
}

class _RailModuleButtonState extends State<_RailModuleButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: TapScale(
          child: Tooltip(
            message: widget.destination.label,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                child: _FacetedTile(
                  icon: widget.selected
                      ? widget.destination.selectedIcon
                      : widget.destination.icon,
                  selected: widget.selected,
                  hovered: _hovered,
                  size: 40,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
