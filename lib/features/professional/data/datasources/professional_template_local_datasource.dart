import '../../../../models/legal_document/legal_domain.dart';
import '../../domain/entities/professional_template.dart';

/// Frontière data vers les modèles d'actes proposés en rédaction rapide.
abstract class ProfessionalTemplateDataSource {
  List<ProfessionalTemplate> getAll();
}

/// Modèles d'actes prêts à l'emploi couvrant les besoins civils, locatifs,
/// professionnels et commerciaux les plus fréquents.
class LocalProfessionalTemplateDataSource
    implements ProfessionalTemplateDataSource {
  const LocalProfessionalTemplateDataSource();

  @override
  List<ProfessionalTemplate> getAll() => _templates;
}

const _templates = <ProfessionalTemplate>[
  ProfessionalTemplate(
    id: 'template-contrat-vente',
    type: DraftingActType.contratVente,
    title: 'Contrat de vente',
    description:
        'Cadre complet pour formaliser la vente d’un bien, d’un produit ou d’un actif.',
    domain: LegalDomain.civil,
    requiredFields: [
      'Identité et adresse du vendeur',
      'Identité et adresse de l’acheteur',
      'Description précise du bien vendu',
      'Prix et modalités de paiement',
      'Date et lieu de livraison ou de remise',
    ],
  ),
  ProfessionalTemplate(
    id: 'template-bail-habitation',
    type: DraftingActType.bailHabitation,
    title: 'Bail à usage d’habitation',
    description:
        'Contrat de location d’un logement, structuré autour des obligations du bailleur et du locataire.',
    domain: LegalDomain.civil,
    requiredFields: [
      'Nom et adresse du bailleur',
      'Nom et adresse du locataire',
      'Adresse et désignation du logement',
      'Durée du bail',
      'Montant du loyer et des charges',
      'Dépôt de garantie et modalités de paiement',
    ],
  ),
  ProfessionalTemplate(
    id: 'template-bail-professionnel',
    type: DraftingActType.bailProfessionnel,
    title: 'Bail à usage professionnel',
    description:
        'Contrat de location d’un local destiné à une activité professionnelle, commerciale ou libérale.',
    domain: LegalDomain.commercial,
    requiredFields: [
      'Nom et adresse du bailleur',
      'Nom et forme du preneur',
      'Adresse et description des locaux',
      'Activité autorisée dans les lieux',
      'Durée du bail',
      'Loyer, charges et révision',
    ],
  ),
  ProfessionalTemplate(
    id: 'template-bail-commercial',
    type: DraftingActType.bailCommercial,
    title: 'Bail commercial',
    description:
        'Contrat de location d\'un local à usage commercial, industriel ou artisanal.',
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
    description:
        'Contrat de prestation de services entre un prestataire et un client.',
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
    description:
        'Statuts constitutifs d\'une société à responsabilité limitée ou par actions simplifiée.',
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
  ProfessionalTemplate(
    id: 'template-mise-en-demeure',
    type: DraftingActType.miseEnDemeure,
    title: 'Mise en demeure',
    description:
        'Lettre formelle demandant l’exécution d’une obligation dans un délai déterminé.',
    domain: LegalDomain.civil,
    requiredFields: [
      'Identité et adresse de l’expéditeur',
      'Identité et adresse du destinataire',
      'Obligation ou engagement concerné',
      'Faits et dates utiles',
      'Délai accordé pour régulariser',
      'Pièces ou justificatifs à mentionner',
    ],
  ),
  ProfessionalTemplate(
    id: 'template-contrat-partenariat',
    type: DraftingActType.contratPartenariat,
    title: 'Contrat de partenariat',
    description:
        'Accord de collaboration précisant les contributions, responsabilités et objectifs des partenaires.',
    domain: LegalDomain.commercial,
    requiredFields: [
      'Identité et forme des partenaires',
      'Objet et objectifs du partenariat',
      'Contributions de chaque partenaire',
      'Durée et calendrier de collaboration',
      'Répartition des revenus et des charges',
      'Conditions de résiliation',
    ],
  ),
  ProfessionalTemplate(
    id: 'template-autre',
    type: DraftingActType.other,
    title: 'Autre',
    description:
        'Un besoin spécifique ? Transmettez vos références pour être orienté vers le bon professionnel.',
    domain: LegalDomain.autre,
    requiredFields: [],
  ),
];
