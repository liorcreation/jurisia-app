import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

final Set<String> _registeredPdfViews = <String>{};

class PdfDocumentSurface extends StatelessWidget {
  const PdfDocumentSurface({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final viewType = 'jurisia-pdf-${url.hashCode}';
    if (_registeredPdfViews.add(viewType)) {
      ui_web.platformViewRegistry.registerViewFactory(viewType, (viewId) {
        final frame = web.HTMLIFrameElement()
          ..src = url
          ..title = 'Document PDF JurisIA'
          ..style.border = '0'
          ..style.width = '100%'
          ..style.height = '100%'
          ..setAttribute('allowfullscreen', 'true');
        return frame;
      });
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: HtmlElementView(viewType: viewType),
    );
  }
}

