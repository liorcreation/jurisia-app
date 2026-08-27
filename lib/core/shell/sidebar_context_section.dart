import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'sidebar_sections/contact_requests_section.dart';
import 'sidebar_sections/library_favorites_section.dart';
import 'sidebar_sections/litigation_history_section.dart';
import 'sidebar_sections/professional_documents_section.dart';
import 'sidebar_sections/student_progress_section.dart';

/// Section contextuelle de la sidebar : son contenu dépend de l'espace
/// actif — historique des consultations pour Litiges, favoris pour la
/// Bibliothèque, progression pour l'Étudiant, documents récents pour le
/// Professionnel, demandes en cours pour Contacter.
class SidebarContextSection extends StatelessWidget {
  const SidebarContextSection({super.key, required this.query});

  final ValueNotifier<String> query;

  @override
  Widget build(BuildContext context) {
    switch (AppShellScope.of(context).selectedIndex) {
      case 0:
        return LitigationHistorySection(query: query);
      case 1:
        return const LibraryFavoritesSection();
      case 2:
        return const StudentProgressSection();
      case 3:
        return const ProfessionalDocumentsSection();
      case 4:
        return const ContactRequestsSection();
      default:
        return const SizedBox.shrink();
    }
  }
}
