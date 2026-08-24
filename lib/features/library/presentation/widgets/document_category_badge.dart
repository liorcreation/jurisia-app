import 'package:flutter/material.dart';

import '../../../../models/legal_document/legal_document_model.dart';
import '../../../../theme/app_theme.dart';
import 'document_type_icon.dart';

/// Dégradé métallique associé à chaque catégorie de document : chaque type
/// reçoit une teinte de métal distincte (cobalt, bronze, argent, cuivre,
/// gunmetal, émeraude, or rose, or profond) plutôt qu'une déclinaison d'or,
/// afin de réserver l'or aux accents d'action.
LinearGradient metallicGradientForDocumentType(LegalDocumentType type) {
  switch (type) {
    case LegalDocumentType.constitution:
      return _brushed(AppColors.metalSilver);
    case LegalDocumentType.code:
      return _brushed(AppColors.metalCobalt);
    case LegalDocumentType.loi:
      return _brushed(AppColors.metalBronze);
    case LegalDocumentType.decret:
      return _brushed(AppColors.metalCopper);
    case LegalDocumentType.arrete:
      return _brushed(AppColors.metalGunmetal);
    case LegalDocumentType.jurisprudence:
      return _brushed(AppColors.metalDeepGold);
    case LegalDocumentType.traite:
      return _brushed(AppColors.metalEmerald);
    case LegalDocumentType.modeleActe:
      return _brushed(AppColors.metalRoseGold);
  }
}

LinearGradient _brushed(Color base) {
  final light = Color.lerp(base, Colors.white, 0.32)!;
  final dark = Color.lerp(base, Colors.black, 0.32)!;
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [light, base, dark],
    stops: const [0.0, 0.55, 1.0],
  );
}

/// Badge de catégorie « éclat métallique » d'un document juridique,
/// remplaçant l'aplat doré par un dégradé métallique propre à son type.
class DocumentCategoryBadge extends StatelessWidget {
  const DocumentCategoryBadge({super.key, required this.type, this.size = 44});

  final LegalDocumentType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: metallicGradientForDocumentType(type),
        borderRadius: BorderRadius.circular(AppRadius.small),
        boxShadow: [
          BoxShadow(
            color: AppColors.nightBlueDeep.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(iconForDocumentType(type), color: AppColors.nightBlueDeep, size: size * 0.5),
    );
  }
}
