import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/library/presentation/controllers/library_controller.dart';
import '../../../features/library/presentation/screens/document_detail_screen.dart';
import '../../../models/legal_document/legal_document_model.dart';
import '../app_shell.dart';
import 'sidebar_section_scaffold.dart';

/// Section contextuelle « Favoris » — les documents de la bibliothèque
/// marqués en favori, accès direct à la fiche.
class LibraryFavoritesSection extends StatelessWidget {
  const LibraryFavoritesSection({super.key});

  static const int _maxItems = 6;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LibraryController>();
    final favorites = controller.favoriteDocuments;

    return SidebarSection(
      title: 'Favoris',
      children: [
        if (favorites.isEmpty)
          const SidebarSectionEmpty(
            'Marquez un texte en favori pour le retrouver ici.',
          )
        else
          for (final document in favorites.take(_maxItems))
            SidebarSectionTile(
              icon: Icons.bookmark_rounded,
              title: document.title,
              subtitle: '${document.type.label} · ${document.reference}',
              onTap: () {
                AppShellScope.of(context).selectModule(1);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider<LibraryController>.value(
                      value: controller,
                      child: DocumentDetailScreen(documentId: document.id),
                    ),
                  ),
                );
              },
            ),
      ],
    );
  }
}
