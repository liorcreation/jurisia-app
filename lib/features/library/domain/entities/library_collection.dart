import '../../../../models/legal_document/legal_document_model.dart';
import '../../../../models/legal_document/legal_domain.dart';

/// Collection éditoriale affichée dans la bibliothèque JurisIA.
///
/// L'ordre de cette liste est contractuel : il correspond à la navigation
/// principale souhaitée pour les six packs juridiques.
class LibraryCollection {
  const LibraryCollection({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String tag;
  final String title;
  final String subtitle;
  final String icon;
}

const libraryCollections = <LibraryCollection>[
  LibraryCollection(
    tag: 'pack-droit-famille',
    title: 'Droit de la famille et des personnes',
    subtitle: 'Personnes, famille, mariage et successions',
    icon: 'family',
  ),
  LibraryCollection(
    tag: 'pack-obligations',
    title: 'DROIT DES OBLIGATIONS',
    subtitle: 'Obligations, contrats et responsabilité',
    icon: 'obligations',
  ),
  LibraryCollection(
    tag: 'pack-penal',
    title: 'DROIT PENAL GÉNÉRAL - DROIT PENAL SPÉCIAL - ET PROCÉDURE PENALE',
    subtitle: 'Droit pénal général, spécial et procédure pénale',
    icon: 'penal',
  ),
  LibraryCollection(
    tag: 'pack-droit-judiciaire-prive',
    title: 'DROIT JUDICIAIRE PRIVÉ',
    subtitle: 'Procédure civile et organisation judiciaire',
    icon: 'judicial',
  ),
  LibraryCollection(
    tag: 'pack-droit-administratif',
    title: 'DROIT ADMINISTRATIF ET JURISPRUDENCE ADMINISTRATIVE',
    subtitle: 'Action, contentieux et justice administrative',
    icon: 'administrative',
  ),
  LibraryCollection(
    tag: 'pack-droit-bancaire-assurances',
    title: 'DROIT BANCAIRE ET DES ASSURANCES',
    subtitle: 'Banque, assurances et réglementation UMOA/CIMA',
    icon: 'banking',
  ),
];

/// Le pack famille est historiquement identifié par son domaine dans le
/// corpus. Les cinq autres packs sont explicitement marqués par leur tag.
bool documentBelongsToLibraryCollection(
  LegalDocument document,
  String collectionTag,
) {
  if (collectionTag == 'pack-droit-famille') {
    return document.domain == LegalDomain.famille ||
        document.tags.contains(collectionTag);
  }
  return document.tags.contains(collectionTag);
}

