import '../../../../models/legal_document/legal_domain.dart';
import '../../../../models/training/training_category.dart';

/// Catalogue embarqué : il permet d'afficher l'orientation instantanément,
/// même avant la synchronisation du catalogue administrable Supabase.
class TrainingCatalogLocalDataSource {
  const TrainingCatalogLocalDataSource();

  List<TrainingCategory> getAll() => _categories;
}

const _categories = <TrainingCategory>[
  TrainingCategory(
    id: 'cert-droit-famille',
    title: 'Droit de la famille',
    subtitle: 'État des personnes, mariage, succession',
    description:
        'Maîtrisez les mécanismes essentiels de la famille et du patrimoine, avec des cas pratiques contextualisés.',
    trainingType: TrainingType.certifying,
    isAvailable: true,
    domain: LegalDomain.famille,
    icon: 'family',
    sortOrder: 10,
  ),
  TrainingCategory(
    id: 'cert-public-fondamental',
    title: 'Droit public fondamental',
    subtitle: 'Constitution, administration, libertés',
    description:
        'Comprenez l’organisation de l’État, les libertés publiques et le raisonnement administratif.',
    trainingType: TrainingType.certifying,
    isAvailable: true,
    domain: LegalDomain.administratif,
    icon: 'account_balance',
    sortOrder: 20,
  ),
  TrainingCategory(
    id: 'cert-droit-affaires',
    title: 'Droit des affaires',
    subtitle: 'Entreprise, contrats, OHADA',
    description:
        'Développez les réflexes juridiques indispensables à la vie des entreprises et aux opérations commerciales.',
    trainingType: TrainingType.certifying,
    isAvailable: true,
    domain: LegalDomain.commercial,
    icon: 'business_center',
    sortOrder: 30,
  ),
  TrainingCategory(
    id: 'cert-droit-assurances',
    title: 'Droit des assurances',
    subtitle: 'Risques, garanties, indemnisation',
    description:
        'Analysez une police, identifiez les garanties et construisez une réponse solide en cas de sinistre.',
    trainingType: TrainingType.certifying,
    isAvailable: true,
    domain: LegalDomain.civil,
    icon: 'verified_user',
    sortOrder: 40,
  ),
  TrainingCategory(
    id: 'cert-droit-immobilier',
    title: 'Droit immobilier',
    subtitle: 'Foncier, baux, transactions',
    description:
        'Sécurisez les opérations immobilières et foncières, de la vérification des titres à la rédaction des actes.',
    trainingType: TrainingType.certifying,
    isAvailable: true,
    domain: LegalDomain.foncier,
    icon: 'domain',
    sortOrder: 50,
  ),
  TrainingCategory(
    id: 'lmd-university-course',
    title: 'Parcours universitaire LMD',
    subtitle: 'Licence 1 à Master 2',
    description:
        'Le parcours académique structuré sera ouvert dans une prochaine phase de JurisIA.',
    trainingType: TrainingType.lmd,
    isAvailable: false,
    domain: LegalDomain.autre,
    icon: 'school',
    sortOrder: 100,
  ),
];
