import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/litigation/presentation/controllers/litigation_chat_controller.dart';
import '../navigation/nav_destinations.dart';
import '../widgets/glow_focus_field.dart';
import '../widgets/jurisia_mark.dart';
import '../widgets/luxury_elevated_button.dart';
import '../widgets/shimmer_sweep.dart';
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

/// La sidebar unifiée de JurisIA — la grammaire ChatGPT / Claude (marque,
/// action « Nouvelle consultation », recherche escamotable, espaces, puis
/// historique daté), dans un registre « cabinet numérique » propre à
/// JurisIA : panneau de verre fumé cerclé d'un filet d'or **vivant**, plaques
/// d'espace facettées, mot-symbole en serif qui capte la lumière, monogramme
/// métallique animé. Dépliée, seul le mot « JurisIA » figure en tête ; c'est
/// le rail replié qui porte la marque, bien en évidence.
class JurisIASidebar extends StatefulWidget {
  const JurisIASidebar({super.key, required this.variant});

  final SidebarVariant variant;

  @override
  State<JurisIASidebar> createState() => _JurisIASidebarState();
}

class _JurisIASidebarState extends State<JurisIASidebar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final ValueNotifier<String> _query = ValueNotifier<String>('');

  bool _searchOpen = false;

  bool get _isRail => widget.variant == SidebarVariant.rail;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _query.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() => _searchOpen = !_searchOpen);
    if (_searchOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocus.requestFocus());
    } else {
      _searchController.clear();
      _query.value = '';
    }
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
            const Positioned.fill(child: IgnorePointer(child: _SidebarAmbience())),
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
          // La marque, bien représentée — comme ChatGPT une fois la colonne
          // repliée. Tap = déplier.
          Tooltip(
            message: 'Déplier la navigation',
            child: TapScale(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: shell.toggleNav,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: JurisIAAppIconTile(size: 40),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _RailIconButton(
            icon: Icons.search_rounded,
            tooltip: 'Rechercher',
            onTap: shell.openNav,
          ),
          const SizedBox(height: AppSpacing.xs),
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
          onSearch: _toggleSearch,
          searchActive: _searchOpen,
          collapseTooltip: isDrawer ? 'Fermer' : 'Replier la navigation',
          onCollapse: () {
            if (isDrawer) {
              Navigator.of(context).maybePop();
            } else {
              shell.toggleNav();
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
          child: LuxuryElevatedButton(
            icon: Icons.add_comment_rounded,
            onPressed: () => _startNewConsultation(context),
            child: const Text('Nouvelle consultation'),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.fastOutSlowIn,
          alignment: Alignment.topCenter,
          child: _searchOpen ? _searchField(context) : const SizedBox(width: double.infinity),
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
              const _FadingRule(),
              SidebarContextSection(query: _query),
            ],
          ),
        ),
        const _FadingRule(),
        const Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: SidebarProfileCard(),
        ),
      ],
    );
  }

  Widget _searchField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      child: GlowFocusField(
        borderRadius: AppRadius.pill,
        child: ValueListenableBuilder<String>(
          valueListenable: _query,
          builder: (context, query, _) => TextField(
            controller: _searchController,
            focusNode: _searchFocus,
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
              suffixIcon: IconButton(
                icon: const Icon(Icons.close_rounded, size: 16),
                tooltip: 'Fermer la recherche',
                onPressed: _toggleSearch,
              ),
            ),
          ),
        ),
      ),
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
/// actif. L'espace actif porte en plus un lent reflet d'or qui la traverse
/// en boucle — le repère « vous êtes ici », vivant.
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
    final tile = AnimatedContainer(
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
            ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.32), blurRadius: 10)]
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

    if (!selected) return tile;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.32),
      child: ShimmerSweep(duration: const Duration(milliseconds: 3600), child: tile),
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

/// En-tête de la sidebar dépliée : le mot-symbole « JurisIA » (serif, reflet
/// métallique qui glisse lentement — vivant), la loupe de recherche, et le
/// contrôle de repli. Suivi d'un filet d'or que traverse un éclat périodique.
class _BrandHeader extends StatelessWidget {
  const _BrandHeader({
    required this.onSearch,
    required this.searchActive,
    required this.collapseTooltip,
    required this.onCollapse,
  });

  final VoidCallback onSearch;
  final bool searchActive;
  final String collapseTooltip;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.sm),
          child: Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => AppGradients.goldMetallic.createShader(bounds),
                child: const Text(
                  'JurisIA',
                  style: TextStyle(
                    fontFamily: 'Libre Caslon Display',
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              _HeaderControl(
                tooltip: 'Rechercher une consultation',
                icon: Icons.search_rounded,
                active: searchActive,
                onPressed: onSearch,
              ),
              const SizedBox(width: 6),
              _HeaderControl(
                tooltip: collapseTooltip,
                icon: Icons.view_sidebar_rounded,
                onPressed: onCollapse,
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xs),
          child: _TravelingGlint(),
        ),
      ],
    );
  }
}

/// Bouton de contrôle de l'en-tête (recherche / repli) — pastille de verre
/// discrète ; passe à l'or lorsqu'elle est active.
class _HeaderControl extends StatelessWidget {
  const _HeaderControl({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.active = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: TapScale(
        child: Material(
          color: active
              ? AppColors.gold.withValues(alpha: 0.18)
              : AppColors.legalBlueDark.withValues(alpha: 0.5),
          shape: CircleBorder(
            side: BorderSide(
              color: active ? AppColors.gold.withValues(alpha: 0.6) : AppColors.glassBorder,
              width: 0.6,
            ),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                icon,
                size: 18,
                color: active ? AppColors.goldLight : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Filet d'or que traverse un éclat lumineux toutes les quelques secondes —
/// la lumière qui « accroche » le bord du verre. Rend l'en-tête vivant sans
/// rien qui distraie.
class _TravelingGlint extends StatefulWidget {
  const _TravelingGlint();

  @override
  State<_TravelingGlint> createState() => _TravelingGlintState();
}

class _TravelingGlintState extends State<_TravelingGlint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 6400))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(painter: _GlintPainter(_controller.value)),
      ),
    );
  }
}

class _GlintPainter extends CustomPainter {
  _GlintPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.gold.withValues(alpha: 0.22),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    // Éclat qui traverse (avec un temps mort entre deux passages).
    final phase = (t * 1.55) - 0.3;
    if (phase < 0 || phase > 1) return;
    final centerX = size.width * phase;
    final bandWidth = size.width * 0.26;
    final band = Rect.fromLTWH(centerX - bandWidth / 2, -1, bandWidth, size.height + 2);
    final fade = 1 - (phase - 0.5).abs() * 2; // s'éteint aux extrémités
    canvas.drawRect(
      band,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.goldLight.withValues(alpha: 0.85 * fade.clamp(0.0, 1.0)),
            Colors.transparent,
          ],
        ).createShader(band),
    );
  }

  @override
  bool shouldRepaint(covariant _GlintPainter oldDelegate) => oldDelegate.t != t;
}

/// Atmosphère du panneau : une lueur d'or qui dérive très lentement le long
/// du bord et quelques grains d'or en suspension — presque imperceptibles,
/// juste de quoi rendre la colonne vivante plutôt que figée.
class _SidebarAmbience extends StatefulWidget {
  const _SidebarAmbience();

  @override
  State<_SidebarAmbience> createState() => _SidebarAmbienceState();
}

class _SidebarAmbienceState extends State<_SidebarAmbience>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 24))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(painter: _AmbiencePainter(_controller.value)),
    );
  }
}

class _AmbiencePainter extends CustomPainter {
  _AmbiencePainter(this.t);

  final double t;

  static final math.Random _rng = math.Random(11);
  static final List<_Mote> _motes = List.generate(
    6,
    (_) => _Mote(
      x: _rng.nextDouble(),
      radius: 0.6 + _rng.nextDouble() * 1.3,
      speed: 0.12 + _rng.nextDouble() * 0.24,
      drift: _rng.nextDouble() * math.pi * 2,
      phase: _rng.nextDouble(),
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final phase = t * math.pi * 2;

    // Lueur d'or qui glisse doucement le long du bord gauche.
    final glowCenter = Offset(
      size.width * (0.12 + 0.05 * math.sin(phase)),
      size.height * (0.5 + 0.42 * math.sin(phase * 0.6)),
    );
    final glowRadius = size.height * 0.4;
    canvas.drawCircle(
      glowCenter,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.07),
            AppColors.gold.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: glowCenter, radius: glowRadius)),
    );

    // Grains d'or en suspension.
    final paint = Paint();
    for (final mote in _motes) {
      final progress = (mote.phase + t * mote.speed) % 1.0;
      final y = size.height * (1.04 - progress * 1.1);
      final x = size.width * mote.x + math.sin(progress * math.pi * 2 + mote.drift) * 10;
      final alpha = math.sin(progress * math.pi) * 0.12;
      if (alpha <= 0) continue;
      paint.color = AppColors.goldLight.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), mote.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbiencePainter oldDelegate) => oldDelegate.t != t;
}

class _Mote {
  const _Mote({
    required this.x,
    required this.radius,
    required this.speed,
    required this.drift,
    required this.phase,
  });

  final double x;
  final double radius;
  final double speed;
  final double drift;
  final double phase;
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

class _RailIconButton extends StatelessWidget {
  const _RailIconButton({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: TapScale(
        child: Tooltip(
          message: tooltip,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(icon, size: 20, color: AppColors.textSecondary),
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
