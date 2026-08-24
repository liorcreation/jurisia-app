import 'package:flutter/material.dart';

import '../../../../models/legal_document/legal_document_model.dart';

/// Icône associée à chaque catégorie de document juridique.
IconData iconForDocumentType(LegalDocumentType type) {
  switch (type) {
    case LegalDocumentType.constitution:
      return Icons.account_balance_rounded;
    case LegalDocumentType.code:
      return Icons.menu_book_rounded;
    case LegalDocumentType.loi:
      return Icons.gavel_rounded;
    case LegalDocumentType.decret:
      return Icons.description_rounded;
    case LegalDocumentType.arrete:
      return Icons.article_rounded;
    case LegalDocumentType.jurisprudence:
      return Icons.balance_rounded;
    case LegalDocumentType.traite:
      return Icons.public_rounded;
    case LegalDocumentType.modeleActe:
      return Icons.draw_rounded;
  }
}
