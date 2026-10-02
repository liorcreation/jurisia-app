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
import '../../../../theme/app_theme.dart';
import '../controllers/library_controller.dart';
import '../../domain/entities/library_collection.dart';
import '../widgets/document_category_badge.dart';
import '../widgets/document_tag.dart';
import '../widgets/document_type_icon.dart';
import '../widgets/summary_only_badge.dart';
import 'document_detail_screen.dart';
import 'pdf_document_screen.dart';

/// Bibliothèque juridique de référence de JurisIA.
/// Le périmètre est volontairement fermé pendant la phase de constitution du
/// corpus officiel. Le [LibraryController] est fourni par [AppShell].
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

  void _openDetail(
    BuildContext context,
    LibraryController controller,
    String documentId,
  ) {
    final document = controller.documentById(documentId);
    final pdfUrl = document == null ? null : pdfUrlForDocument(document);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<LibraryController>.value(
          value: controller,
          child: pdfUrl == null
              ? DocumentDetailScreen(documentId: documentId)
              : PdfDocumentScreen(document: document!, pdfUrl: pdfUrl),
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

    if (controller.selectedCollectionTag == null) {
      return _LibraryPackCatalog(
        documents: controller.allDocuments,
        onSelect: controller.selectCollection,
      );
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

class _LibraryPackCatalog extends StatelessWidget {
  const _LibraryPackCatalog({required this.documents, required this.onSelect});

  final List<LegalDocument> documents;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Bibliothèque juridique'),
          leading: const AppShellMenuButton(),
        ),
        body: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(child: _LibraryAmbience()),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _LibraryLandingHero(documentCount: documents.length),
                        const SizedBox(height: 30),
                        const _CollectionSectionHeading(),
                        const SizedBox(height: AppSpacing.md),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 1040
                                ? 3
                                : constraints.maxWidth >= 680
                                ? 2
                                : 1;
                            final gap = AppSpacing.md;
                            final width = columns == 1
                                ? constraints.maxWidth
                                : (constraints.maxWidth - gap * (columns - 1)) /
                                      columns;
                            return Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: [
                                for (
                                  var index = 0;
                                  index < libraryCollections.length;
                                  index++
                                )
                                  SizedBox(
                                    width: width,
                                    child: EntranceFadeSlide(
                                      index: index,
                                      stagger: const Duration(milliseconds: 70),
                                      child: _PackCard(
                                        collection: libraryCollections[index],
                                        index: index + 1,
                                        count: documents
                                            .where(
                                              (document) =>
                                                  documentBelongsToLibraryCollection(
                                                    document,
                                                    libraryCollections[index]
                                                        .tag,
                                                  ),
                                            )
                                            .length,
                                        onTap: () => onSelect(
                                          libraryCollections[index].tag,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const _LibraryCatalogFootnote(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryLandingHero extends StatelessWidget {
  const _LibraryLandingHero({required this.documentCount});

  final int documentCount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 680;
        return Container(
          clipBehavior: Clip.antiAlias,
          padding: EdgeInsets.all(compact ? 22 : 34),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.large + 4),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF17385E), Color(0xFF101C30), Color(0xFF0B101A)],
              stops: [0, 0.54, 1],
            ),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: AppColors.nightBlueDeep.withValues(alpha: 0.38),
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: compact ? -150 : 70,
                top: compact ? -170 : -230,
                child: IgnorePointer(
                  child: Container(
                    width: 430,
                    height: 430,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.07),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.cobaltLight.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (compact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LibraryEyebrow(),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Le droit, organisé pour éclairer vos décisions.',
                      style: textTheme.headlineMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontFamily: 'Libre Caslon Display',
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Explorez les ressources de JurisIA par domaine, puis ouvrez chaque document dans son lecteur dédié.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _LibraryMetric(
                          icon: Icons.grid_view_rounded,
                          value: '${libraryCollections.length}',
                          label: 'domaines',
                        ),
                        _LibraryMetric(
                          icon: Icons.menu_book_rounded,
                          value: '$documentCount',
                          label: 'références',
                        ),
                      ],
                    ),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LibraryEyebrow(),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Le droit, organisé pour éclairer vos décisions.',
                            style: textTheme.displaySmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontFamily: 'Libre Caslon Display',
                              height: 1.04,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 620),
                            child: Text(
                              'Explorez les ressources de JurisIA par domaine, puis ouvrez chaque document dans son lecteur dédié.',
                              style: textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.55,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    _LibraryCorpusSeal(documentCount: documentCount),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _LibraryEyebrow extends StatelessWidget {
  const _LibraryEyebrow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            size: 14,
            color: AppColors.gold,
          ),
          const SizedBox(width: 7),
          Text(
            'BIBLIOTHÈQUE JURISIA',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.goldLight,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryCorpusSeal extends StatelessWidget {
  const _LibraryCorpusSeal({required this.documentCount});

  final int documentCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 178,
      height: 178,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.025),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.32)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cobaltLight.withValues(alpha: 0.12),
            blurRadius: 42,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 146,
          height: 146,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                libraryCollections.length.toString().padLeft(2, '0'),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppColors.goldLight,
                  fontFamily: 'Libre Caslon Display',
                  height: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'COLLECTIONS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cobalt.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$documentCount références',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryMetric extends StatelessWidget {
  const _LibraryMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.goldLight),
          const SizedBox(width: 7),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CollectionSectionHeading extends StatelessWidget {
  const _CollectionSectionHeading();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('Votre bibliothèque'),
              const SizedBox(height: 8),
              Text(
                'Explorez les packs',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontFamily: 'Libre Caslon Display',
                ),
              ),
            ],
          ),
        ),
        Text(
          '01 — 06',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.goldLight,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _LibraryCatalogFootnote extends StatelessWidget {
  const _LibraryCatalogFootnote();

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: AppRadius.medium,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          const Icon(
            Icons.tips_and_updates_outlined,
            size: 17,
            color: AppColors.gold,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Choisissez une matière pour parcourir uniquement ses ressources. Sélectionnez un document pour l’ouvrir dans son lecteur dédié.',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackCard extends StatefulWidget {
  const _PackCard({
    required this.collection,
    required this.index,
    required this.count,
    required this.onTap,
  });

  final LibraryCollection collection;
  final int index;
  final int count;
  final VoidCallback onTap;

  @override
  State<_PackCard> createState() => _PackCardState();
}

class _PackCardState extends State<_PackCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: TapScale(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppRadius.large),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              height: 246,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.large),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _hovered
                      ? const [Color(0xFF1B3E66), Color(0xFF111C2D)]
                      : const [Color(0xD9172639), Color(0xB80D131E)],
                ),
                border: Border.all(
                  color: _hovered
                      ? AppColors.gold.withValues(alpha: 0.62)
                      : AppColors.glassBorder,
                  width: _hovered ? 1.1 : 0.8,
                ),
                boxShadow: _hovered
                    ? [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.13),
                          blurRadius: 28,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 0,
                    top: -17,
                    child: IgnorePointer(
                      child: Text(
                        widget.index.toString().padLeft(2, '0'),
                        style: textTheme.displayLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.035),
                          fontFamily: 'Libre Caslon Display',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            transform: Matrix4.rotationZ(_hovered ? 0.045 : 0),
                            transformAlignment: Alignment.center,
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: AppGradients.goldMetallic,
                              borderRadius: BorderRadius.circular(
                                AppRadius.medium,
                              ),
                              boxShadow: _hovered
                                  ? [
                                      BoxShadow(
                                        color: AppColors.gold.withValues(
                                          alpha: 0.28,
                                        ),
                                        blurRadius: 18,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              _iconForCollection(widget.collection.icon),
                              color: AppColors.nightBlueDeep,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'PACK ${widget.index.toString().padLeft(2, '0')}',
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.goldLight,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_outward_rounded,
                            color: _hovered
                                ? AppColors.goldLight
                                : AppColors.textDisabled,
                            size: 19,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        widget.collection.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontFamily: 'Libre Caslon Display',
                          fontWeight: FontWeight.w700,
                          height: 1.14,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.collection.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.gold.withValues(alpha: 0.46),
                              AppColors.glassBorder,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.menu_book_rounded,
                            size: 15,
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.count} ${widget.count == 1 ? 'document' : 'documents'}',
                            style: textTheme.labelMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'EXPLORER',
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.goldLight,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
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
    final collectionDocuments = controller.allDocuments
        .where(
          (document) => documentBelongsToLibraryCollection(
            document,
            controller.selectedCollectionTag!,
          ),
        )
        .toList(growable: false);
    final counts = <LegalDocumentType, int>{};
    for (final document in collectionDocuments) {
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
                controller.favoritesOnly
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: AppColors.gold,
              ),
              onPressed: controller.toggleFavoritesOnly,
            ),
          ],
        ),
        body: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(child: _LibraryAmbience()),
            ),
            SafeArea(
              child: Column(
                children: [
                  _SelectedCollectionHeader(
                    collectionTag: controller.selectedCollectionTag!,
                    count: results.length,
                    totalCount: collectionDocuments.length,
                    onBack: onClearAll,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      0,
                    ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      children: [
                        _MobileFacet(
                          gradient: AppGradients.goldMetallic,
                          icon: Icons.apps_rounded,
                          label: 'Tous',
                          count: collectionDocuments.length,
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
                  const Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      0,
                    ),
                    child: _CorpusScopeBanner(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      0,
                    ),
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
                              final available =
                                  constraints.maxWidth - AppSpacing.md * 2;
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
                                    for (
                                      var index = 0;
                                      index < results.length;
                                      index++
                                    )
                                      SizedBox(
                                        width: cardWidth,
                                        child: EntranceFadeSlide(
                                          index: index,
                                          child: _LibraryDocCard(
                                            document: results[index],
                                            onOpen: () =>
                                                onOpenDetail(results[index].id),
                                            onToggleFavorite: () =>
                                                controller.toggleBookmark(
                                                  results[index].id,
                                                ),
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
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$count',
                    style: textTheme.labelSmall?.copyWith(
                      color: selected
                          ? AppColors.goldLight
                          : AppColors.textDisabled,
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

class _SelectedCollectionHeader extends StatelessWidget {
  const _SelectedCollectionHeader({
    required this.collectionTag,
    required this.count,
    required this.totalCount,
    required this.onBack,
  });

  final String collectionTag;
  final int count;
  final int totalCount;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final collection = libraryCollections.firstWhere(
      (item) => item.tag == collectionTag,
      orElse: () => libraryCollections.first,
    );
    final position = libraryCollections.indexOf(collection) + 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final textTheme = Theme.of(context).textTheme;
          final icon = Container(
            width: compact ? 42 : 54,
            height: compact ? 42 : 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppGradients.goldMetallic,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              _iconForCollection(collection.icon),
              color: AppColors.nightBlueDeep,
              size: compact ? 21 : 27,
            ),
          );
          final title = Text(
            collection.title,
            maxLines: compact ? 3 : 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
              fontFamily: 'Libre Caslon Display',
              fontWeight: FontWeight.w700,
              height: 1.08,
            ),
          );
          final backButton = compact
              ? IconButton(
                  tooltip: 'Retour aux packs',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AppColors.goldLight,
                )
              : OutlinedButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.grid_view_rounded, size: 16),
                  label: const Text('Tous les packs'),
                );

          return GlassContainer(
            padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
            borderRadius: AppRadius.large,
            borderColor: AppColors.gold.withValues(alpha: 0.28),
            child: Stack(
              children: [
                Positioned(
                  right: compact ? 0 : 12,
                  top: compact ? 8 : 0,
                  child: IgnorePointer(
                    child: Icon(
                      _iconForCollection(collection.icon),
                      size: compact ? 84 : 122,
                      color: AppColors.gold.withValues(alpha: 0.035),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'PARCOURS DES PACKS',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.textDisabled,
                              letterSpacing: 1.15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${position.toString().padLeft(2, '0')} / ${libraryCollections.length.toString().padLeft(2, '0')}',
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.goldLight,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: position / libraryCollections.length,
                        minHeight: 3,
                        backgroundColor: Colors.white.withValues(alpha: 0.07),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.gold,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        if (!compact) ...[
                          icon,
                          const SizedBox(width: AppSpacing.md),
                        ],
                        if (compact) icon,
                        if (compact) const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'COLLECTION  ${position.toString().padLeft(2, '0')} / ${libraryCollections.length.toString().padLeft(2, '0')}',
                                style: textTheme.labelSmall?.copyWith(
                                  color: AppColors.goldLight,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.15,
                                ),
                              ),
                              if (!compact) ...[
                                const SizedBox(height: 5),
                                title,
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        backButton,
                      ],
                    ),
                    if (compact) ...[
                      const SizedBox(height: AppSpacing.sm),
                      title,
                    ],
                    const SizedBox(height: 7),
                    Text(
                      collection.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _PackMetric(
                          icon: Icons.menu_book_rounded,
                          label:
                              '$totalCount ${totalCount == 1 ? 'document' : 'documents'}',
                        ),
                        if (count != totalCount)
                          _PackMetric(
                            icon: Icons.filter_alt_rounded,
                            label:
                                '$count ${count == 1 ? 'résultat' : 'résultats'}',
                          )
                        else
                          const _PackMetric(
                            icon: Icons.verified_rounded,
                            label: 'Corpus du pack',
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PackMetric extends StatelessWidget {
  const _PackMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.legalBlueDark.withValues(alpha: 0.62),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border: Border.all(color: AppColors.glassBorder),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.gold),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
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
    final collectionDocuments = controller.allDocuments
        .where(
          (document) => documentBelongsToLibraryCollection(
            document,
            controller.selectedCollectionTag!,
          ),
        )
        .toList(growable: false);

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(
                child: IgnorePointer(child: _LibraryAmbience()),
              ),
              Column(
                children: [
                  _LibraryHeader(
                    total: collectionDocuments.length,
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
                                _SelectedCollectionHeader(
                                  collectionTag:
                                      controller.selectedCollectionTag!,
                                  count: results.length,
                                  totalCount: collectionDocuments.length,
                                  onBack: onClearAll,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                _RadiantSearchField(
                                  controller: searchController,
                                  onChanged: controller.updateKeyword,
                                  onClear: () {
                                    searchController.clear();
                                    controller.updateKeyword('');
                                  },
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                _FacetStrip(
                                  documents: collectionDocuments,
                                  selected: controller.selectedType,
                                  onSelect: controller.selectType,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                const _CorpusScopeBanner(),
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
          bottom: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.18),
            width: 0.6,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_library_rounded,
            size: 18,
            color: AppColors.gold,
          ),
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
                  '$total documents dans le pack actif',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              gradient: active ? AppGradients.goldMetallic : null,
              color: active
                  ? null
                  : AppColors.legalBlueDark.withValues(alpha: 0.5),
              border: Border.all(
                color: active
                    ? Colors.transparent
                    : AppColors.gold.withValues(alpha: 0.4),
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
                    color: active
                        ? AppColors.nightBlueDeep
                        : AppColors.goldLight,
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
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat();
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
          painter: _RadiantBorderPainter(
            rotation: _sweep.value * 2 * math.pi,
            focused: _focused,
          ),
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
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                    hintText:
                        'Rechercher un texte, un article, une branche du droit…',
                  ),
                ),
              ),
              if (_hasText)
                IconButton(
                  tooltip: 'Effacer',
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
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

IconData _iconForCollection(String icon) {
  switch (icon) {
    case 'family':
      return Icons.family_restroom_rounded;
    case 'obligations':
      return Icons.handshake_rounded;
    case 'penal':
      return Icons.gavel_rounded;
    case 'judicial':
      return Icons.account_balance_rounded;
    case 'administrative':
      return Icons.policy_rounded;
    case 'banking':
      return Icons.account_balance_wallet_rounded;
    default:
      return Icons.menu_book_rounded;
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
        child: ShimmerSweep(
          duration: const Duration(milliseconds: 3400),
          child: badge,
        ),
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
                            color: widget.selected
                                ? AppColors.gold
                                : AppColors.textPrimary,
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

class _CorpusScopeBanner extends StatelessWidget {
  const _CorpusScopeBanner();

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      borderRadius: AppRadius.medium,
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, size: 17, color: AppColors.gold),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Consultation limitée au pack ouvert · textes, doctrine et ressources pédagogiques.',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsBar extends StatelessWidget {
  const _ResultsBar({
    required this.count,
    required this.hasFilters,
    required this.onClear,
  });

  final int count;
  final bool hasFilters;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        return Row(
          children: [
            Expanded(
              child: Text(
                count <= 1 ? '$count résultat' : '$count résultats',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (hasFilters) ...[
              const SizedBox(width: AppSpacing.sm),
              Tooltip(
                message: 'Effacer tous les filtres',
                child: TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, size: 15),
                  label: Text(compact ? 'Effacer' : 'Effacer les filtres'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    textStyle: textTheme.labelMedium,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
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
    final hasPdf = pdfUrlForDocument(doc) != null;

    Widget badge = DocumentCategoryBadge(type: doc.type, size: 46);
    if (_hovered) {
      badge = ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.small),
        child: ShimmerSweep(
          duration: const Duration(milliseconds: 1500),
          child: badge,
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GlassContainer(
        onTap: widget.onOpen,
        borderColor: _hovered
            ? AppColors.gold.withValues(alpha: 0.55)
            : AppColors.glassBorder,
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
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _DocumentAccessBadge(hasPdf: hasPdf),
                          _DocumentStatusBadge(status: doc.status),
                          if (doc.awaitingFullText)
                            const SummaryOnlyBadge(compact: true),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: [
                          DocumentTag(label: doc.type.label),
                          DocumentTag(label: doc.domain.label),
                        ],
                      ),
                      if (doc.reference.trim().isNotEmpty) ...[
                        const SizedBox(height: 5),
                        _DocumentReferenceLine(reference: doc.reference),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            hasPdf ? 'OUVRIR LE PDF' : 'OUVRIR LA FICHE',
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.goldLight,
                              letterSpacing: 0.9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_outward_rounded,
                            size: 16,
                            color: AppColors.goldLight.withValues(alpha: 0.8),
                          ),
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
              child: _FavStar(
                active: doc.isFavorite,
                onTap: widget.onToggleFavorite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentAccessBadge extends StatelessWidget {
  const _DocumentAccessBadge({required this.hasPdf});

  final bool hasPdf;

  @override
  Widget build(BuildContext context) {
    final color = hasPdf ? AppColors.success : AppColors.cobaltLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasPdf ? Icons.picture_as_pdf_rounded : Icons.article_outlined,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            hasPdf ? 'LECTURE PDF' : 'NOTICE DOCUMENTAIRE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentStatusBadge extends StatelessWidget {
  const _DocumentStatusBadge({required this.status});

  final LegalDocumentStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      LegalDocumentStatus.enVigueur => (
        AppColors.success,
        Icons.verified_rounded,
      ),
      LegalDocumentStatus.modifie => (AppColors.warning, Icons.update_rounded),
      LegalDocumentStatus.abroge => (
        AppColors.textDisabled,
        Icons.history_rounded,
      ),
      LegalDocumentStatus.projet => (
        AppColors.cobaltLight,
        Icons.edit_note_rounded,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentReferenceLine extends StatelessWidget {
  const _DocumentReferenceLine({required this.reference});

  final String reference;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.legalBlueDark.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Text(
        'Réf. $reference',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondary,
          height: 1.25,
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
            const Icon(
              Icons.search_off_rounded,
              size: 40,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Aucun texte ne correspond à ces critères.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
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
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 30),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) =>
          CustomPaint(painter: _AmbiencePainter(_controller.value)),
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
      final x =
          size.width * mote.x +
          math.sin(progress * math.pi * 2 + mote.drift) * 14;
      final alpha = math.sin(progress * math.pi) * 0.1;
      if (alpha <= 0) continue;
      paint.color = AppColors.goldLight.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), mote.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbiencePainter oldDelegate) =>
      oldDelegate.t != t;
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
