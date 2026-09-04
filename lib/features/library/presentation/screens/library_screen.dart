import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/platform/app_platform_style.dart';
import '../../../../core/widgets/app_shell_menu_button.dart';
import '../../../../core/widgets/entrance_fade.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/luxury_scaffold_background.dart';
import '../../../../core/widgets/shimmer_sweep.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../models/legal_document/legal_document_model.dart';
import '../../../../models/legal_document/legal_domain.dart';
import '../../../../theme/app_theme.dart';
import '../controllers/library_controller.dart';
import '../widgets/document_category_badge.dart';
import '../widgets/document_tag.dart';
import '../widgets/document_type_icon.dart';
import '../widgets/summary_only_badge.dart';
import 'document_detail_screen.dart';

/// Section 2 — Bibliothèque juridique : moteur de recherche intelligent sur
/// l'ensemble des textes et décisions (Constitution, codes, lois, décrets,
/// arrêtés, jurisprudence, traités, modèles d'actes). Le [LibraryController]
/// est fourni par la coquille applicative ([AppShell]).
///
/// Deux mises en page : « la grande bibliothèque » sur desktop (recherche
/// radiante, navigation par catégories métalliques, résultats en grille
/// vivante) ; le fil vertical filtré habituel sur mobile / iOS / Android.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) => const _LibraryView();
}

class _LibraryView extends StatefulWidget {
  const _LibraryView();

  @override
  State<_LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<_LibraryView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openDetail(BuildContext context, LibraryController controller, String documentId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<LibraryController>.value(
          value: controller,
          child: DocumentDetailScreen(documentId: documentId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LibraryController>();

    void clearAll() {
      controller.clearFilters();
      _searchController.clear();
    }

    if (AppPlatformStyle.of(context) == AppPlatformStyle.desktop) {
      return _DesktopLibrary(
        controller: controller,
        searchController: _searchController,
        onOpenDetail: (id) => _openDetail(context, controller, id),
        onClearAll: clearAll,
      );
    }

    return _MobileLibrary(
      controller: controller,
      searchController: _searchController,
      onOpenDetail: (id) => _openDetail(context, controller, id),
      onClearAll: clearAll,
    );
  }
}

// ===========================================================================
//  MOBILE / TABLETTE — « la bibliothèque de poche »
// ===========================================================================

class _MobileLibrary extends StatelessWidget {
  const _MobileLibrary({
    required this.controller,
    required this.searchController,
    required this.onOpenDetail,
    required this.onClearAll,
  });

  final LibraryController controller;
  final TextEditingController searchController;
  final ValueChanged<String> onOpenDetail;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final results = controller.results;
    final all = controller.allDocuments;
    final counts = <LegalDocumentType, int>{};
    for (final document in all) {
      counts[document.type] = (counts[document.type] ?? 0) + 1;
    }

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Bibliothèque juridique'),
          leading: const AppShellMenuButton(),
          actions: [
            IconButton(
              tooltip: controller.favoritesOnly
                  ? 'Afficher tous les documents'
                  : 'Afficher les favoris',
              icon: Icon(
                controller.favoritesOnly ? Icons.star_rounded : Icons.star_border_rounded,
                color: AppColors.gold,
              ),
              onPressed: controller.toggleFavoritesOnly,
            ),
          ],
        ),
        body: Stack(
          children: [
            const Positioned.fill(child: IgnorePointer(child: _LibraryAmbience())),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                    child: _RadiantSearchField(
                      controller: searchController,
                      onChanged: controller.updateKeyword,
                      onClear: () {
                        searchController.clear();
                        controller.updateKeyword('');
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      children: [
                        _MobileFacet(
                          gradient: AppGradients.goldMetallic,
                          icon: Icons.apps_rounded,
                          label: 'Tous',
                          count: all.length,
                          selected: controller.selectedType == null,
                          onTap: () => controller.selectType(null),
                        ),
                        for (final type in LegalDocumentType.values)
                          _MobileFacet(
                            gradient: metallicGradientForDocumentType(type),
                            icon: iconForDocumentType(type),
                            label: type.label,
                            count: counts[type] ?? 0,
                            selected: controller.selectedType == type,
                            onTap: () => controller.selectType(type),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      children: [
                        for (final domain in LegalDomain.values)
                          Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.sm),
                            child: _FilterChip(
                              label: domain.label,
                              selected: controller.selectedDomain == domain,
                              onSelected: () => controller.selectDomain(domain),
                              compact: true,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                    child: _ResultsBar(
                      count: results.length,
                      hasFilters: controller.hasActiveFilters,
                      onClear: onClearAll,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Expanded(
                    child: results.isEmpty
                        ? _EmptyResults(onClear: onClearAll)
                        // Sur téléphone, une colonne ; sur tablette, la
                        // largeur permet deux cartes de front — la grille
                        // se replie d'elle-même, jamais figée à 1 colonne.
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              // La largeur utile est celle qui reste une fois
                              // ôtées les marges du défilement (posées plus
                              // bas) : sans quoi deux cartes calculées sur la
                              // largeur pleine débordent du couloir réel et le
                              // Wrap n'en tient plus qu'une par ligne.
                              final available = constraints.maxWidth - AppSpacing.md * 2;
                              final cols = available >= 640 ? 2 : 1;
                              final cardWidth = cols == 1
                                  ? available
                                  : (available - AppSpacing.sm) / 2;
                              return SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.md,
                                  AppSpacing.xs,
                                  AppSpacing.md,
                                  AppSpacing.xl,
                                ),
                                child: Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  children: [
                                    for (var index = 0; index < results.length; index++)
                                      SizedBox(
                                        width: cardWidth,
                                        child: EntranceFadeSlide(
                                          index: index,
                                          child: _LibraryDocCard(
                                            document: results[index],
                                            onOpen: () => onOpenDetail(results[index].id),
                                            onToggleFavorite: () =>
                                                controller.toggleBookmark(results[index].id),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
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

class _MobileFacet extends StatelessWidget {
  const _MobileFacet({
    required this.gradient,
    required this.icon,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final Gradient gradient;
  final IconData icon;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: TapScale(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 4, AppSpacing.sm + 2, 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                color: selected
                    ? AppColors.gold.withValues(alpha: 0.14)
                    : AppColors.legalBlueDark.withValues(alpha: 0.45),
                border: Border.all(
                  color: selected
                      ? AppColors.gold.withValues(alpha: 0.5)
                      : AppColors.glassBorder,
                  width: selected ? 1 : 0.6,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Icon(icon, size: 13, color: AppColors.nightBlueDeep),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: textTheme.labelMedium?.copyWith(
                      color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$count',
                    style: textTheme.labelSmall?.copyWith(
                      color: selected ? AppColors.goldLight : AppColors.textDisabled,
                      fontWeight: FontWeight.w700,
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

// ===========================================================================
//  DESKTOP — « la grande bibliothèque »
// ===========================================================================

class _DesktopLibrary extends StatelessWidget {
  const _DesktopLibrary({
    required this.controller,
    required this.searchController,
    required this.onOpenDetail,
    required this.onClearAll,
  });

  final LibraryController controller;
  final TextEditingController searchController;
  final ValueChanged<String> onOpenDetail;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final results = controller.results;
    final all = controller.allDocuments;

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(child: IgnorePointer(child: _LibraryAmbience())),
              Column(
                children: [
                  _LibraryHeader(
                    total: all.length,
                    favoritesOnly: controller.favoritesOnly,
                    onToggleFavorites: controller.toggleFavoritesOnly,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1120),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSpacing.xl,
                              AppSpacing.lg,
                              AppSpacing.xxl,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _RadiantSearchField(
                                  controller: searchController,
                                  onChanged: controller.updateKeyword,
                                  onClear: () {
                                    searchController.clear();
                                    controller.updateKeyword('');
                                  },
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                _FacetStrip(
                                  documents: all,
                                  selected: controller.selectedType,
                                  onSelect: controller.selectType,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                _DomainFilterBar(
                                  selected: controller.selectedDomain,
                                  onSelect: controller.selectDomain,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                _ResultsBar(
                                  count: results.length,
                                  hasFilters: controller.hasActiveFilters,
                                  onClear: onClearAll,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                if (results.isEmpty)
                                  _EmptyResults(onClear: onClearAll)
                                else
                                  _ResultsGrid(
                                    results: results,
                                    onOpen: onOpenDetail,
                                    onToggleFavorite: controller.toggleBookmark,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({
    required this.total,
    required this.favoritesOnly,
    required this.onToggleFavorites,
  });

  final int total;
  final bool favoritesOnly;
  final VoidCallback onToggleFavorites;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.smokedGlass,
        border: Border(
          bottom: BorderSide(color: AppColors.gold.withValues(alpha: 0.18), width: 0.6),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.local_library_rounded, size: 18, color: AppColors.gold),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bibliothèque juridique',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.headlineSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  "$total textes officiels, codes, décisions et modèles d'actes",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _FavoritesToggle(active: favoritesOnly, onTap: onToggleFavorites),
        ],
      ),
    );
  }
}

class _FavoritesToggle extends StatelessWidget {
  const _FavoritesToggle({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: active ? 'Afficher tout le catalogue' : 'Afficher mes favoris',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              gradient: active ? AppGradients.goldMetallic : null,
              color: active ? null : AppColors.legalBlueDark.withValues(alpha: 0.5),
              border: Border.all(
                color: active ? Colors.transparent : AppColors.gold.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  active ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 15,
                  color: active ? AppColors.nightBlueDeep : AppColors.goldLight,
                ),
                const SizedBox(width: 6),
                Text(
                  'Favoris',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: active ? AppColors.nightBlueDeep : AppColors.goldLight,
                        fontWeight: FontWeight.w700,
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

/// Champ de recherche « radiant » : un éclat d'or parcourt lentement le
/// contour arrondi, comme une loupe qui balaie les rayons ; il vire au
/// cobalt et s'intensifie au focus.
class _RadiantSearchField extends StatefulWidget {
  const _RadiantSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_RadiantSearchField> createState() => _RadiantSearchFieldState();
}

class _RadiantSearchFieldState extends State<_RadiantSearchField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep =
      AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat();
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _focused = _focusNode.hasFocus);
    });
    widget.controller.addListener(_onText);
    _hasText = widget.controller.text.isNotEmpty;
  }

  void _onText() {
    final has = widget.controller.text.isNotEmpty;
    if (has != _hasText && mounted) setState(() => _hasText = has);
  }

  @override
  void dispose() {
    _sweep.dispose();
    _focusNode.dispose();
    widget.controller.removeListener(_onText);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: _sweep,
      builder: (context, child) {
        return CustomPaint(
          painter: _RadiantBorderPainter(rotation: _sweep.value * 2 * math.pi, focused: _focused),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(2.5),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.large),
            color: AppColors.legalBlueDark.withValues(alpha: 0.62),
            boxShadow: [
              BoxShadow(
                color: (_focused ? AppColors.cobalt : AppColors.nightBlueDeep)
                    .withValues(alpha: _focused ? 0.24 : 0.4),
                blurRadius: _focused ? 24 : 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 4, 8, 4),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: 22,
                color: _focused ? AppColors.cobalt : AppColors.goldLight,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  onChanged: widget.onChanged,
                  cursorColor: AppColors.cobalt,
                  style: textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                    hintText: 'Rechercher un texte, un article, une branche du droit…',
                  ),
                ),
              ),
              if (_hasText)
                IconButton(
                  tooltip: 'Effacer',
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                  onPressed: widget.onClear,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadiantBorderPainter extends CustomPainter {
  _RadiantBorderPainter({required this.rotation, required this.focused});

  final double rotation;
  final bool focused;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(1.25),
      const Radius.circular(AppRadius.large),
    );

    // Contour de base, discret.
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = (focused ? AppColors.cobalt : AppColors.glassBorder)
            .withValues(alpha: focused ? 0.9 : 0.7),
    );

    // Éclat qui tourne autour du contour.
    final glint = focused ? AppColors.cobalt : AppColors.goldLight;
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = focused ? 2.2 : 1.8
        ..shader = SweepGradient(
          transform: GradientRotation(rotation),
          colors: [
            Colors.transparent,
            glint.withValues(alpha: focused ? 0.95 : 0.6),
            glint.withValues(alpha: 0),
            Colors.transparent,
          ],
          stops: const [0.0, 0.06, 0.22, 1.0],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _RadiantBorderPainter oldDelegate) =>
      oldDelegate.rotation != rotation || oldDelegate.focused != focused;
}

/// Bandeau « Parcourir par catégorie » : une plaquette métallique par type de
/// document, avec son compteur.
class _FacetStrip extends StatelessWidget {
  const _FacetStrip({
    required this.documents,
    required this.selected,
    required this.onSelect,
  });

  final List<LegalDocument> documents;
  final LegalDocumentType? selected;
  final ValueChanged<LegalDocumentType?> onSelect;

  @override
  Widget build(BuildContext context) {
    final counts = <LegalDocumentType, int>{};
    for (final document in documents) {
      counts[document.type] = (counts[document.type] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Parcourir par catégorie'),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _Facet(
              icon: Icons.apps_rounded,
              badgeGradient: AppGradients.goldMetallic,
              label: 'Tous',
              sub: '${documents.length} textes',
              selected: selected == null,
              onTap: () => onSelect(null),
            ),
            for (final type in LegalDocumentType.values)
              _Facet(
                icon: iconForDocumentType(type),
                badgeGradient: metallicGradientForDocumentType(type),
                label: type.label,
                sub: () {
                  final n = counts[type] ?? 0;
                  return n <= 1 ? '$n texte' : '$n textes';
                }(),
                selected: selected == type,
                onTap: () => onSelect(type),
              ),
          ],
        ),
      ],
    );
  }
}

class _Facet extends StatefulWidget {
  const _Facet({
    required this.icon,
    required this.badgeGradient,
    required this.label,
    required this.sub,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Gradient badgeGradient;
  final String label;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_Facet> createState() => _FacetState();
}

class _FacetState extends State<_Facet> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Widget badge = Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: widget.badgeGradient,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Icon(widget.icon, size: 15, color: AppColors.nightBlueDeep),
    );
    if (widget.selected) {
      badge = ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.small),
        child: ShimmerSweep(duration: const Duration(milliseconds: 3400), child: badge),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: TapScale(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 156,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.medium),
                color: widget.selected
                    ? AppColors.gold.withValues(alpha: 0.14)
                    : _hovered
                        ? Colors.white.withValues(alpha: 0.05)
                        : AppColors.legalBlueDark.withValues(alpha: 0.4),
                border: Border.all(
                  color: widget.selected
                      ? AppColors.gold.withValues(alpha: 0.5)
                      : AppColors.glassBorder,
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  badge,
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelMedium?.copyWith(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: widget.selected ? AppColors.gold : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.sub,
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.textDisabled,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
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

class _DomainFilterBar extends StatelessWidget {
  const _DomainFilterBar({required this.selected, required this.onSelect});

  final LegalDomain? selected;
  final ValueChanged<LegalDomain?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Filtrer par branche du droit'),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final domain in LegalDomain.values)
              _DomainPill(
                label: domain.label,
                selected: selected == domain,
                onTap: () => onSelect(domain),
              ),
          ],
        ),
      ],
    );
  }
}

class _DomainPill extends StatefulWidget {
  const _DomainPill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_DomainPill> createState() => _DomainPillState();
}

class _DomainPillState extends State<_DomainPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              color: widget.selected
                  ? AppColors.gold.withValues(alpha: 0.18)
                  : _hovered
                      ? Colors.white.withValues(alpha: 0.05)
                      : AppColors.legalBlueDark.withValues(alpha: 0.5),
              border: Border.all(
                color: widget.selected
                    ? AppColors.gold.withValues(alpha: 0.55)
                    : AppColors.glassBorder,
                width: 0.7,
              ),
            ),
            child: Text(
              widget.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: widget.selected ? AppColors.gold : AppColors.textSecondary,
                    fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultsBar extends StatelessWidget {
  const _ResultsBar({required this.count, required this.hasFilters, required this.onClear});

  final int count;
  final bool hasFilters;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(
          count <= 1 ? '$count résultat' : '$count résultats',
          style: textTheme.titleSmall?.copyWith(color: AppColors.textPrimary),
        ),
        if (hasFilters) ...[
          const SizedBox(width: AppSpacing.md),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded, size: 15),
            label: const Text('Effacer les filtres'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              textStyle: textTheme.labelMedium,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
            ),
          ),
        ],
      ],
    );
  }
}

class _ResultsGrid extends StatelessWidget {
  const _ResultsGrid({
    required this.results,
    required this.onOpen,
    required this.onToggleFavorite,
  });

  final List<LegalDocument> results;
  final ValueChanged<String> onOpen;
  final ValueChanged<String> onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 720;
        final cardWidth = twoColumns
            ? (constraints.maxWidth - AppSpacing.md) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (var index = 0; index < results.length; index++)
              SizedBox(
                width: cardWidth,
                child: EntranceFadeSlide(
                  index: index,
                  child: _LibraryDocCard(
                    document: results[index],
                    onOpen: () => onOpen(results[index].id),
                    onToggleFavorite: () => onToggleFavorite(results[index].id),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LibraryDocCard extends StatefulWidget {
  const _LibraryDocCard({
    required this.document,
    required this.onOpen,
    required this.onToggleFavorite,
  });

  final LegalDocument document;
  final VoidCallback onOpen;
  final VoidCallback onToggleFavorite;

  @override
  State<_LibraryDocCard> createState() => _LibraryDocCardState();
}

class _LibraryDocCardState extends State<_LibraryDocCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final doc = widget.document;

    Widget badge = DocumentCategoryBadge(type: doc.type, size: 46);
    if (_hovered) {
      badge = ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.small),
        child: ShimmerSweep(duration: const Duration(milliseconds: 1500), child: badge),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GlassContainer(
        onTap: widget.onOpen,
        borderColor: _hovered ? AppColors.gold.withValues(alpha: 0.55) : AppColors.glassBorder,
        borderWidth: _hovered ? 0.9 : 0.5,
        padding: const EdgeInsets.all(14),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                badge,
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 24),
                        child: Text(
                          doc.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(
                            fontFamily: 'Libre Caslon Display',
                            fontWeight: FontWeight.w600,
                            height: 1.18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doc.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (doc.awaitingFullText) ...[
                        const SummaryOnlyBadge(compact: true),
                        const SizedBox(height: 6),
                      ],
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: [
                          DocumentTag(label: doc.type.label),
                          DocumentTag(label: doc.domain.label),
                          DocumentTag(label: 'Réf. ${doc.reference}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: -4,
              right: -4,
              child: _FavStar(active: doc.isFavorite, onTap: widget.onToggleFavorite),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavStar extends StatelessWidget {
  const _FavStar({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: active ? 'Retirer des favoris' : 'Ajouter aux favoris',
      child: TapScale(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  active ? Icons.star_rounded : Icons.star_border_rounded,
                  key: ValueKey(active),
                  size: 20,
                  color: AppColors.gold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 40, color: AppColors.textDisabled),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Aucun texte ne correspond à ces critères.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Réinitialiser la recherche'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 1.5,
          decoration: BoxDecoration(
            gradient: AppGradients.goldSheen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textDisabled,
                fontWeight: FontWeight.w700,
                letterSpacing: AppLetterSpacing.caps,
                fontSize: 10.5,
              ),
        ),
      ],
    );
  }
}

/// Poussière d'or en suspension sur toute la page — le même souffle vivant
/// que la sidebar, à peine perceptible.
class _LibraryAmbience extends StatefulWidget {
  const _LibraryAmbience();

  @override
  State<_LibraryAmbience> createState() => _LibraryAmbienceState();
}

class _LibraryAmbienceState extends State<_LibraryAmbience>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat();

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

  static final math.Random _rng = math.Random(23);
  static final List<_Mote> _motes = List.generate(
    12,
    (_) => _Mote(
      x: _rng.nextDouble(),
      radius: 0.6 + _rng.nextDouble() * 1.5,
      speed: 0.08 + _rng.nextDouble() * 0.2,
      drift: _rng.nextDouble() * math.pi * 2,
      phase: _rng.nextDouble(),
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final mote in _motes) {
      final progress = (mote.phase + t * mote.speed) % 1.0;
      final y = size.height * (1.05 - progress * 1.12);
      final x = size.width * mote.x + math.sin(progress * math.pi * 2 + mote.drift) * 14;
      final alpha = math.sin(progress * math.pi) * 0.1;
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

// ===========================================================================
//  MOBILE
// ===========================================================================

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.gold.withValues(alpha: 0.22),
      backgroundColor: AppColors.legalBlueDark.withValues(alpha: 0.6),
      labelStyle: (compact ? Theme.of(context).textTheme.labelSmall : Theme.of(context).textTheme.labelMedium)
          ?.copyWith(
        color: selected ? AppColors.gold : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        side: BorderSide(color: selected ? AppColors.gold : AppColors.glassBorder),
      ),
    );
  }
}
