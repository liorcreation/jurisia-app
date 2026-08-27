import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_shell_menu_button.dart';
import '../../../../core/widgets/entrance_fade.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/luxury_scaffold_background.dart';
import '../../../../models/legal_document/legal_document_model.dart';
import '../../../../models/legal_document/legal_domain.dart';
import '../../../../theme/app_theme.dart';
import '../controllers/library_controller.dart';
import '../widgets/document_card.dart';
import 'document_detail_screen.dart';

/// Section 2 — Bibliothèque juridique : moteur de recherche intelligent sur
/// l'ensemble des textes et décisions (Constitution, codes, lois, décrets,
/// arrêtés, jurisprudence, traités, modèles d'actes). Le [LibraryController]
/// est fourni par la coquille applicative ([AppShell]).
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
    final results = controller.results;

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Bibliothèque juridique'),
          leading: const AppShellMenuButton(),
          actions: [
            IconButton(
              tooltip: controller.favoritesOnly ? 'Afficher tous les documents' : 'Afficher les favoris',
              icon: Icon(
                controller.favoritesOnly ? Icons.star_rounded : Icons.star_border_rounded,
                color: AppColors.gold,
              ),
              onPressed: controller.toggleFavoritesOnly,
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                child: GlassContainer(
                  borderRadius: AppRadius.pill,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: TextField(
                    controller: _searchController,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                      hintText: 'Mot-clé, article, texte, domaine…',
                      suffixIcon: controller.keyword.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                controller.updateKeyword('');
                              },
                            ),
                    ),
                    onChanged: controller.updateKeyword,
                  ),
                ),
              ),
              SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  children: [
                    _FilterChip(
                      label: 'Tous',
                      selected: controller.selectedType == null,
                      onSelected: () => controller.selectType(null),
                    ),
                    for (final type in LegalDocumentType.values)
                      Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.sm),
                        child: _FilterChip(
                          label: type.label,
                          selected: controller.selectedType == type,
                          onSelected: () => controller.selectType(type),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                height: 44,
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
              const SizedBox(height: AppSpacing.xs),
              Expanded(
                child: results.isEmpty
                    ? Center(
                        child: Text(
                          'Aucun document ne correspond à votre recherche.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          0,
                          AppSpacing.md,
                          AppSpacing.md,
                        ),
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final doc = results[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: EntranceFadeSlide(
                              index: index,
                              child: LibraryDocumentCard(
                                document: doc,
                                onToggleFavorite: () => controller.toggleBookmark(doc.id),
                                onTap: () => _openDetail(context, controller, doc.id),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
