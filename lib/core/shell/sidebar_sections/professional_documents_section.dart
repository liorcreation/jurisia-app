import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/professional/domain/entities/drafting_request.dart';
import '../../../features/professional/presentation/controllers/professional_documents_controller.dart';
import '../../../features/professional/presentation/screens/drafting_result_screen.dart';
import '../app_shell.dart';
import 'sidebar_section_scaffold.dart';

/// Section contextuelle « Documents récents » — les actes, audits et notes
/// déjà générés, ouverts en lecture seule.
class ProfessionalDocumentsSection extends StatelessWidget {
  const ProfessionalDocumentsSection({super.key});

  static const int _maxItems = 6;

  String _modeLabel(DraftingMode mode) {
    switch (mode) {
      case DraftingMode.redaction:
        return 'Acte rédigé';
      case DraftingMode.audit:
        return 'Audit de contrat';
      case DraftingMode.consultation:
        return 'Note de synthèse';
    }
  }

  @override
  Widget build(BuildContext context) {
    final documents = context.watch<ProfessionalDocumentsController>().recentResults;

    return SidebarSection(
      title: 'Documents récents',
      children: [
        if (documents.isEmpty)
          const SidebarSectionEmpty('Vos actes et audits générés apparaîtront ici.')
        else
          for (final document in documents.take(_maxItems))
            SidebarSectionTile(
              icon: Icons.article_outlined,
              title: document.title,
              subtitle: _modeLabel(document.mode),
              onTap: () {
                AppShellScope.of(context).selectModule(3);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => DraftingResultScreen(result: document)),
                );
              },
            ),
      ],
    );
  }
}
