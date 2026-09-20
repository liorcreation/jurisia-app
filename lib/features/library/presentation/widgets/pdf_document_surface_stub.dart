import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PdfDocumentSurface extends StatelessWidget {
  const PdfDocumentSurface({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: () => launchUrl(Uri.parse(url)),
        icon: const Icon(Icons.picture_as_pdf_rounded),
        label: const Text('Ouvrir le PDF'),
      ),
    );
  }
}

