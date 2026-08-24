import '../../../../models/legal_document/legal_domain.dart';
import '../../domain/entities/professional_template.dart';

/// Frontière data vers les modèles d'actes proposés en rédaction rapide.
abstract class ProfessionalTemplateDataSource {
  List<ProfessionalTemplate> getAll();
}

/// Quatre modèles d'actes courants du droit des affaires, couvrant les
/// actions rapides du tableau de bord professionnel.
class LocalProfessionalTemplateDataSource implements ProfessionalTemplateDataSource {
  const LocalProfessionalTemplateDataSource();

  @override
  List<ProfessionalTemplate> getAll() => _templates;
}

const _templates = <ProfessionalTemplate>[
  ProfessionalTemplate(
    id: 'template-bail-commercial',
    type: DraftingActType.bailCommercial,
    title: 'Bail commercial',
    description: 'Contrat de location d\'un local à usage commercial, industriel ou artisanal.',
    domain: LegalDomain.commercial,
    requiredFields: [
      'Nom et adresse du bailleur',
      'Nom et adresse du preneur',
      'Adresse et désignation du local loué',
      'Durée du bail',
      'Montant du loyer mensuel',
      'Destination des lieux (activité autorisée)',
    ],
  ),
  ProfessionalTemplate(
    id: 'template-contrat-prestation',
    type: DraftingActType.contratPrestation,
    title: 'Contrat de prestation',
    description: 'Contrat de prestation de services entre un prestataire et un client.',
    domain: LegalDomain.civil,
    requiredFields: [
      'Nom du prestataire',
      'Nom du client',
      'Description de la prestation',
      'Durée ou délai d\'exécution',
      'Rémunération et modalités de paiement',
    ],
  ),
  ProfessionalTemplate(
    id: 'template-statuts-societe',
    type: DraftingActType.statutsSociete,
    title: 'Statuts SARL/SAS',
    description: 'Statuts constitutifs d\'une société à responsabilité limitée ou par actions simplifiée.',
    domain: LegalDomain.commercial,
    requiredFields: [
      'Forme sociale (SARL ou SAS)',
      'Dénomination sociale',
      'Objet social',
      'Montant du capital social',
      'Associés/actionnaires et répartition des parts',
      'Adresse du siège social',
    ],
  ),
  ProfessionalTemplate(
    id: 'template-contrat-travail',
    type: DraftingActType.contratTravail,
    title: 'Contrat de travail',
    description: 'Contrat de travail à durée indéterminée ou déterminée.',
    domain: LegalDomain.travail,
    requiredFields: [
      'Nom de l\'employeur',
      'Nom du salarié',
      'Intitulé du poste',
      'Type de contrat (CDI ou CDD)',
      'Durée du travail',
      'Rémunération mensuelle brute',
    ],
  ),
];
