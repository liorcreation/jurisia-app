import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../widgets/luxury_scaffold_background.dart';
import '../widgets/markdown_text.dart';

/// Affiche un des documents juridiques de l'application (CGU, politique de
/// confidentialité, avertissement IA) en plein écran.
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(title)),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: MarkdownText(content),
          ),
        ),
      ),
    );
  }
}
