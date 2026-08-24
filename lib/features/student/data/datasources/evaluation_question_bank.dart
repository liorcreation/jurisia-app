import '../../../../models/student/evaluation_model.dart';

/// Frontière data vers la banque de questions candidates utilisée en repli
/// lorsque la génération par l'IA n'est pas disponible ou échoue.
abstract class EvaluationQuestionBank {
  /// Questions candidates pour un module. Chaque tentative en tire un
  /// sous-ensemble aléatoire, garantissant un renouvellement des questions
  /// d'une tentative à l'autre.
  List<EvaluationQuestion> candidatesFor(String moduleId);
}

/// Banque locale : cinq questions candidates par module (mélange de QCM et
/// de cas pratiques, chacune notée sur 5 points), permettant de tirer un
/// jeu de quatre questions différent à chaque tentative.
class LocalEvaluationQuestionBank implements EvaluationQuestionBank {
  const LocalEvaluationQuestionBank();

  @override
  List<EvaluationQuestion> candidatesFor(String moduleId) => _bank[moduleId] ?? const [];
}

EvaluationQuestion _qcm(
  String id,
  String statement,
  List<String> options,
  int correct,
  String explanation,
) {
  return EvaluationQuestion(
    id: id,
    type: QuestionType.qcm,
    statement: statement,
    points: 5,
    options: options,
    correctOptionIndex: correct,
    explanation: explanation,
  );
}

EvaluationQuestion _cas(
  String id,
  String statement,
  List<String> expectedElements,
  String explanation,
) {
  return EvaluationQuestion(
    id: id,
    type: QuestionType.casPratique,
    statement: statement,
    points: 5,
    expectedAnswerElements: expectedElements,
    explanation: explanation,
  );
}

final Map<String, List<EvaluationQuestion>> _bank = {
  // --------------------------------------------------------------- L1 ----
  'l1-module-1': [
    _qcm(
      'q-l1m1-1',
      'La règle de droit se distingue de la règle morale principalement par :',
      const ['Son ancienneté', 'Sa sanction étatique', 'Sa popularité', 'Sa longueur'],
      1,
      'La règle de droit est assortie d\'une sanction étatique (contrainte), contrairement à la '
          'règle morale qui relève de la conscience individuelle.',
    ),
    _qcm(
      'q-l1m1-2',
      'Dans la hiérarchie des normes, la loi est :',
      const [
        'Supérieure à la Constitution',
        'Supérieure aux traités',
        'Inférieure à la Constitution et aux traités',
        'Au même rang que les arrêtés',
      ],
      2,
      'La loi est subordonnée à la Constitution et aux traités régulièrement ratifiés.',
    ),
    _qcm(
      'q-l1m1-3',
      'La jurisprudence est :',
      const ['Une source écrite', 'Une source non écrite', 'Un synonyme de la loi', 'Un règlement'],
      1,
      'La jurisprudence, interprétation du droit par les tribunaux, est une source non écrite.',
    ),
    _qcm(
      'q-l1m1-4',
      'Un décret est édicté par :',
      const ['Le Parlement', 'Le pouvoir exécutif', 'Un tribunal', 'Un maire'],
      1,
      'Le décret est un acte réglementaire pris par le pouvoir exécutif.',
    ),
    _cas(
      'q-l1m1-5',
      'Un texte réglementaire contredit une loi. Expliquez lequel des deux textes doit primer et pourquoi.',
      const ['hiérarchie des normes', 'la loi prime sur le règlement', 'décret'],
      'En vertu de la hiérarchie des normes, la loi est supérieure au règlement (décret, arrêté) '
          'qui doit lui être conforme.',
    ),
  ],
  'l1-module-2': [
    _qcm(
      'q-l1m2-1',
      'La personnalité juridique d\'une personne physique commence :',
      const ['À la majorité', 'À la naissance (vivante et viable)', 'Au mariage', 'À l\'obtention d\'une pièce d\'identité'],
      1,
      'La personnalité juridique commence à la naissance, à condition que l\'enfant soit né '
          'vivant et viable.',
    ),
    _qcm(
      'q-l1m2-2',
      'La capacité d\'exercice est :',
      const [
        'L\'aptitude à être titulaire de droits',
        'L\'aptitude à exercer soi-même ses droits',
        'Un synonyme de nationalité',
        'Réservée aux personnes morales',
      ],
      1,
      'La capacité d\'exercice est l\'aptitude à exercer soi-même les droits dont on est titulaire.',
    ),
    _qcm(
      'q-l1m2-3',
      'Une personne morale acquiert la personnalité juridique :',
      const ['À sa création orale', 'Par immatriculation ou déclaration', 'Jamais', 'Automatiquement à 18 ans'],
      1,
      'La personne morale acquiert la personnalité juridique par immatriculation ou déclaration '
          'selon sa forme.',
    ),
    _qcm(
      'q-l1m2-4',
      'Un acte de naissance est dressé par :',
      const ['Un notaire', 'Un huissier', 'L\'officier d\'état civil', 'Un juge'],
      2,
      'C\'est l\'officier d\'état civil qui dresse les actes d\'état civil (naissance, mariage, décès).',
    ),
    _cas(
      'q-l1m2-5',
      'Un mineur signe seul un contrat de vente important. Expliquez si ce contrat est pleinement valable.',
      const ['capacité d\'exercice limitée', 'représentant légal', 'annulation possible'],
      'Le mineur ayant une capacité d\'exercice limitée, l\'acte peut être annulé faute '
          'd\'intervention de son représentant légal.',
    ),
  ],
  'l1-module-3': [
    _qcm(
      'q-l1m3-1',
      'La Cour de cassation contrôle :',
      const ['Les faits et le droit', 'Uniquement le droit', 'Uniquement les faits', 'Rien, elle est consultative'],
      1,
      'La Cour de cassation ne contrôle que la bonne application du droit par les juges du fond.',
    ),
    _qcm(
      'q-l1m3-2',
      'L\'appel permet :',
      const ['Un réexamen complet en fait et en droit', 'Un contrôle du seul droit', 'Une médiation', 'Une expertise'],
      0,
      'L\'appel est une voie de recours ordinaire qui réexamine l\'affaire en fait et en droit.',
    ),
    _qcm(
      'q-l1m3-3',
      'L\'huissier de justice est notamment chargé :',
      const ['De juger les litiges', 'De signifier les actes et exécuter les décisions', 'De voter les lois', 'D\'authentifier les testaments'],
      1,
      'L\'huissier signifie les actes de procédure et procède à l\'exécution forcée des décisions.',
    ),
    _qcm(
      'q-l1m3-4',
      'Le ministère public :',
      const ['Représente une partie privée', 'Défend l\'intérêt de la société', 'Est un syndicat', 'N\'existe qu\'en appel'],
      1,
      'Le ministère public défend l\'intérêt général de la société dans les affaires qui l\'exigent.',
    ),
    _cas(
      'q-l1m3-5',
      'Une partie perd son procès en première instance et souhaite faire réexaminer l\'ensemble de l\'affaire, faits compris. Quelle voie de recours doit-elle exercer ?',
      const ['appel', 'réexamen en fait et en droit', 'cour d\'appel'],
      'L\'appel permet un réexamen complet de l\'affaire, en fait comme en droit, devant la cour d\'appel.',
    ),
  ],

  // --------------------------------------------------------------- L2 ----
  'l2-module-1': [
    _qcm(
      'q-l2m1-1',
      'Le contrat se forme par :',
      const ['La seule intention du vendeur', 'La rencontre d\'une offre et d\'une acceptation', 'Un jugement', 'Un décret'],
      1,
      'Le contrat naît de la rencontre d\'une offre et d\'une acceptation portant sur ses éléments essentiels.',
    ),
    _qcm(
      'q-l2m1-2',
      'La responsabilité délictuelle suppose :',
      const ['Un contrat préalable', 'Une faute, un dommage et un lien de causalité', 'Une décision administrative', 'Un acte notarié'],
      1,
      'Trois conditions cumulatives : une faute, un dommage et un lien de causalité entre les deux.',
    ),
    _qcm(
      'q-l2m1-3',
      'La force majeure, en matière contractuelle, a pour effet :',
      const ['D\'aggraver la faute', 'D\'exonérer le débiteur défaillant', 'De rendre le contrat nul', 'De doubler les dommages et intérêts'],
      1,
      'La force majeure (imprévisible, irrésistible, extérieure) exonère le débiteur de sa responsabilité contractuelle.',
    ),
    _qcm(
      'q-l2m1-4',
      'La mise en demeure est en principe requise pour engager :',
      const ['La responsabilité délictuelle', 'La responsabilité contractuelle', 'La responsabilité pénale', 'Aucune des deux'],
      1,
      'La responsabilité contractuelle suppose, en principe, la mise en demeure préalable du débiteur défaillant.',
    ),
    _cas(
      'q-l2m1-5',
      'Un fournisseur livre en retard en raison d\'une grève générale imprévisible et insurmontable. Expliquez s\'il peut être exonéré de sa responsabilité.',
      const ['force majeure', 'imprévisible', 'irrésistible', 'exonération'],
      'Si les conditions de la force majeure sont réunies (imprévisibilité, irrésistibilité, extériorité), le débiteur peut être exonéré.',
    ),
  ],
  'l2-module-2': [
    _qcm(
      'q-l2m2-1',
      'Un acte administratif unilatéral s\'impose :',
      const ['Avec le consentement du destinataire', 'Sans le consentement du destinataire', 'Uniquement après vote du Parlement', 'Jamais aux particuliers'],
      1,
      'L\'acte unilatéral s\'impose sans le consentement de son destinataire, au nom de l\'intérêt général.',
    ),
    _qcm(
      'q-l2m2-2',
      'Le recours pour excès de pouvoir est porté devant :',
      const ['Le juge judiciaire', 'Le juge administratif', 'Un arbitre privé', 'Le maire'],
      1,
      'C\'est le juge administratif qui connaît du recours pour excès de pouvoir contre un acte administratif.',
    ),
    _qcm(
      'q-l2m2-3',
      'Les contrats administratifs se caractérisent notamment par :',
      const ['L\'absence de tout contrôle', 'Des clauses exorbitantes du droit commun', 'L\'interdiction de sanction', 'Leur nature toujours orale'],
      1,
      'Ils comportent des clauses exorbitantes conférant des prérogatives à l\'administration (contrôle, modification, sanction).',
    ),
    _qcm(
      'q-l2m2-4',
      'Un vice de compétence dans un acte administratif peut entraîner :',
      const ['Son renforcement', 'Son annulation par le juge', 'Sa transformation en loi', 'Rien'],
      1,
      'Un vice de compétence est un motif d\'annulation de l\'acte administratif par le juge administratif.',
    ),
    _cas(
      'q-l2m2-5',
      'Une commune modifie unilatéralement un marché public en cours d\'exécution. Expliquez si cela est possible et sur quel fondement.',
      const ['clause exorbitante', 'pouvoir de modification unilatérale', 'équilibre financier'],
      'L\'administration dispose d\'un pouvoir de modification unilatérale, contrepartie du droit du cocontractant à l\'équilibre financier du contrat.',
    ),
  ],
  'l2-module-3': [
    _qcm(
      'q-l2m3-1',
      'Les trois prérogatives du droit de propriété sont :',
      const ['Usus, fructus, abusus', 'Usage, fruit, vente', 'Location, vente, don', 'Achat, revente, don'],
      0,
      'La propriété confère l\'usus (user), le fructus (percevoir les fruits) et l\'abusus (disposer).',
    ),
    _qcm(
      'q-l2m3-2',
      'L\'usufruitier dispose :',
      const ['De l\'abusus seul', 'De l\'usus et du fructus', 'D\'aucun droit', 'De la pleine propriété'],
      1,
      'L\'usufruitier a l\'usus et le fructus ; le nu-propriétaire conserve l\'abusus.',
    ),
    _qcm(
      'q-l2m3-3',
      'Une servitude grève :',
      const ['Le fonds dominant au profit du fonds servant', 'Le fonds servant au profit du fonds dominant', 'Uniquement les meubles', 'Uniquement les créances'],
      1,
      'La servitude est une charge pesant sur le fonds servant au profit du fonds dominant.',
    ),
    _qcm(
      'q-l2m3-4',
      'En indivision, chaque propriétaire détient :',
      const ['La pleine propriété exclusive du bien', 'Une quote-part sur l\'ensemble du bien', 'Rien juridiquement', 'Un usufruit temporaire'],
      1,
      'En indivision, chaque indivisaire détient une quote-part abstraite sur l\'ensemble du bien.',
    ),
    _cas(
      'q-l2m3-5',
      'Un nu-propriétaire souhaite vendre seul l\'immeuble grevé d\'un usufruit. Expliquez les limites de son pouvoir.',
      const ['abusus', 'accord de l\'usufruitier', 'droits de l\'usufruitier préservés'],
      'Le nu-propriétaire ne peut disposer du bien sans respecter les droits de l\'usufruitier, dont l\'usus et le fructus subsistent.',
    ),
  ],

  // --------------------------------------------------------------- L3 ----
  'l3-module-1': [
    _qcm(
      'q-l3m1-1',
      'Est commerçant celui qui :',
      const ['Effectue un acte de commerce isolé', 'Accomplit des actes de commerce à titre de profession habituelle', 'Possède un diplôme de commerce', 'Travaille pour l\'État'],
      1,
      'La qualité de commerçant suppose l\'accomplissement d\'actes de commerce à titre de profession habituelle.',
    ),
    _qcm(
      'q-l3m1-2',
      'L\'élément essentiel du fonds de commerce est :',
      const ['Le matériel', 'La clientèle', 'Les stocks', 'L\'enseigne'],
      1,
      'Sans clientèle, il n\'y a pas de fonds de commerce : c\'en est l\'élément essentiel.',
    ),
    _qcm(
      'q-l3m1-3',
      'Entre commerçants, la preuve :',
      const ['Doit être écrite', 'Est libre (tout moyen)', 'Est impossible', 'Nécessite un acte notarié'],
      1,
      'Le droit commercial admet la liberté de la preuve entre commerçants.',
    ),
    _qcm(
      'q-l3m1-4',
      'L\'entreprenant, statut prévu par l\'OHADA, est :',
      const ['Une grande société cotée', 'Un régime allégé pour l\'activité individuelle', 'Un syndicat professionnel', 'Une juridiction'],
      1,
      'L\'entreprenant bénéficie d\'un régime simplifié, allégeant les obligations du commerçant de droit commun.',
    ),
    _cas(
      'q-l3m1-5',
      'Un commerçant cède son fonds de commerce mais conserve sa clientèle en ouvrant un magasin concurrent juste à côté. Expliquez le problème juridique posé.',
      const ['clientèle', 'élément essentiel', 'obligation de non-concurrence'],
      'La clientèle étant l\'élément essentiel cédé, le cédant est en principe tenu d\'une obligation de non-concurrence envers l\'acquéreur.',
    ),
  ],
  'l3-module-2': [
    _qcm(
      'q-l3m2-1',
      'Le critère distinctif du contrat de travail est :',
      const ['Le montant du salaire', 'Le lien de subordination juridique', 'La durée du contrat', 'Le lieu de travail'],
      1,
      'C\'est le lien de subordination juridique envers l\'employeur qui caractérise le contrat de travail.',
    ),
    _qcm(
      'q-l3m2-2',
      'Un CDD conclu hors des cas légaux risque :',
      const ['D\'être requalifié en CDI', 'D\'être automatiquement nul', 'De devenir un contrat commercial', 'Rien de particulier'],
      0,
      'Un CDD conclu hors des cas légalement prévus est susceptible d\'être requalifié en CDI.',
    ),
    _qcm(
      'q-l3m2-3',
      'Un licenciement sans cause réelle et sérieuse est qualifié de :',
      const ['Régulier', 'Abusif', 'Automatique', 'Collectif obligatoirement'],
      1,
      'Le licenciement pour motif personnel doit reposer sur une cause réelle et sérieuse, à défaut il est abusif.',
    ),
    _qcm(
      'q-l3m2-4',
      'La faute grave du salarié a pour effet :',
      const ['D\'augmenter le préavis', 'De dispenser l\'employeur du préavis', 'D\'annuler le contrat rétroactivement', 'Rien'],
      1,
      'La faute grave prive le salarié du droit au préavis.',
    ),
    _cas(
      'q-l3m2-5',
      'Un employeur licencie un salarié sans lui indiquer aucun motif précis ni organiser d\'entretien préalable. Expliquez la qualification probable de ce licenciement.',
      const ['sans cause réelle et sérieuse', 'abusif', 'dommages et intérêts'],
      'L\'absence de motif précis et de procédure régulière conduit généralement à qualifier le licenciement d\'abusif, ouvrant droit à des dommages et intérêts.',
    ),
  ],
  'l3-module-3': [
    _qcm(
      'q-l3m3-1',
      'Le principe du contradictoire impose que :',
      const ['Seul le juge parle', 'Chaque partie puisse discuter les prétentions et preuves adverses', 'Les parties ne se rencontrent jamais', 'Le procès soit secret'],
      1,
      'Le contradictoire garantit à chaque partie le droit de discuter les prétentions, moyens et preuves de l\'autre.',
    ),
    _qcm(
      'q-l3m3-2',
      'La compétence territoriale se détermine, en principe, par :',
      const ['Le lieu du procès précédent', 'Le domicile du défendeur', 'La nationalité du demandeur', 'Le hasard'],
      1,
      'En principe, le tribunal compétent territorialement est celui du domicile du défendeur.',
    ),
    _qcm(
      'q-l3m3-3',
      'L\'opposition est ouverte :',
      const ['Au vainqueur du procès', 'Au défendeur défaillant contre un jugement par défaut', 'Uniquement en appel', 'Au ministère public seul'],
      1,
      'L\'opposition permet au défendeur qui ne s\'est pas présenté de faire rétracter un jugement rendu par défaut.',
    ),
    _qcm(
      'q-l3m3-4',
      'Le pourvoi en cassation porte sur :',
      const ['Les faits uniquement', 'Le droit uniquement', 'Les faits et le droit', 'Rien de précis'],
      1,
      'Le pourvoi en cassation est une voie de recours extraordinaire réservée aux questions de droit.',
    ),
    _cas(
      'q-l3m3-5',
      'Un jugement est rendu à l\'encontre d\'un tiers qui n\'était pas partie à l\'instance et qui s\'estime lésé. Quelle voie de recours peut-il exercer ?',
      const ['tierce opposition', 'tiers lésé', 'non partie à l\'instance'],
      'La tierce opposition permet à un tiers lésé par un jugement auquel il n\'était pas partie de le contester.',
    ),
  ],

  // --------------------------------------------------------------- M1 ----
  'm1-module-1': [
    _qcm(
      'q-m1m1-1',
      'Une société acquiert la personnalité morale :',
      const ['À la signature des statuts', 'À son immatriculation', 'Au premier bénéfice réalisé', 'Jamais'],
      1,
      'La personnalité morale est acquise à compter de l\'immatriculation de la société.',
    ),
    _qcm(
      'q-m1m1-2',
      'Les apports en industrie correspondent :',
      const ['À de l\'argent', 'À un immeuble', 'Au savoir-faire ou travail d\'un associé', 'À une créance'],
      2,
      'L\'apport en industrie consiste à mettre son travail ou son savoir-faire à disposition de la société.',
    ),
    _qcm(
      'q-m1m1-3',
      'La dissolution judiciaire pour juste motif peut être prononcée en cas de :',
      const ['Bénéfice trop élevé', 'Mésentente grave entre associés', 'Changement de siège social', 'Recrutement d\'un salarié'],
      1,
      'Une mésentente grave paralysant le fonctionnement social peut justifier une dissolution judiciaire.',
    ),
    _qcm(
      'q-m1m1-4',
      'L\'assemblée des associés est notamment compétente pour :',
      const ['Gérer le quotidien de la société', 'Approuver les comptes annuels', 'Signer chaque facture', 'Recruter chaque salarié'],
      1,
      'L\'approbation des comptes annuels relève de la compétence de l\'assemblée des associés.',
    ),
    _cas(
      'q-m1m1-5',
      'Deux associés à parts égales sont dans un désaccord total et permanent, bloquant toute décision. Expliquez la solution envisageable.',
      const ['mésentente grave', 'dissolution judiciaire', 'juste motif'],
      'La mésentente grave entre associés paralysant le fonctionnement social constitue un juste motif de dissolution judiciaire.',
    ),
  ],
  'm1-module-2': [
    _qcm(
      'q-m1m2-1',
      'L\'abus de biens sociaux consiste à :',
      const [
        'Investir dans l\'intérêt de la société',
        'Utiliser les biens sociaux contrairement à l\'intérêt de la société à des fins personnelles',
        'Payer les salariés',
        'Déposer les comptes annuels',
      ],
      1,
      'L\'abus de biens sociaux suppose un usage des biens sociaux contraire à l\'intérêt de la société, à des fins personnelles.',
    ),
    _qcm(
      'q-m1m2-2',
      'Les trois éléments constitutifs d\'une infraction sont :',
      const ['Légal, matériel, moral', 'Civil, pénal, administratif', 'Direct, indirect, mixte', 'Public, privé, mixte'],
      0,
      'Toute infraction suppose un élément légal, un élément matériel et, sauf exception, un élément moral.',
    ),
    _qcm(
      'q-m1m2-3',
      'Une délégation de pouvoirs exonératoire suppose que le délégataire ait :',
      const ['Uniquement de l\'ancienneté', 'Compétence, autorité et moyens', 'Un lien familial avec le dirigeant', 'Un contrat oral'],
      1,
      'La délégation n\'est valable que si le délégataire dispose de la compétence, de l\'autorité et des moyens nécessaires.',
    ),
    _qcm(
      'q-m1m2-4',
      'La responsabilité pénale d\'une société :',
      const [
        'Exclut celle du dirigeant',
        'Peut se cumuler avec celle du dirigeant',
        'N\'existe pas',
        'Ne concerne que les impôts',
      ],
      1,
      'La responsabilité pénale de la personne morale peut se cumuler avec celle de la personne physique auteur des faits.',
    ),
    _cas(
      'q-m1m2-5',
      'Un dirigeant a valablement délégué la sécurité du site à un responsable compétent, doté de l\'autorité et des moyens nécessaires. Un accident survient. Expliquez si le dirigeant reste pénalement responsable.',
      const ['délégation de pouvoirs valable', 'exonération', 'compétence autorité moyens'],
      'Une délégation de pouvoirs valable (compétence, autorité, moyens) est en principe exonératoire pour le dirigeant délégant.',
    ),
  ],
  'm1-module-3': [
    _qcm(
      'q-m1m3-1',
      'Le principe de légalité de l\'impôt signifie que :',
      const ['Seul un décret peut créer un impôt', 'Seule la loi peut créer un impôt', 'L\'impôt est facultatif', 'Le maire fixe librement l\'impôt'],
      1,
      'Seule la loi peut créer, modifier ou supprimer un impôt.',
    ),
    _qcm(
      'q-m1m3-2',
      'La TVA est un exemple d\'impôt :',
      const ['Direct', 'Indirect', 'Local uniquement', 'Facultatif'],
      1,
      'La TVA est un impôt indirect, répercuté sur le prix des biens et services.',
    ),
    _qcm(
      'q-m1m3-3',
      'L\'impôt sur les sociétés est assis sur :',
      const ['Le chiffre d\'affaires brut', 'Le bénéfice net', 'Le capital social', 'Le nombre de salariés'],
      1,
      'L\'impôt sur les sociétés est calculé sur le bénéfice net, après déduction des charges déductibles.',
    ),
    _qcm(
      'q-m1m3-4',
      'Le non-respect des obligations fiscales peut entraîner :',
      const ['Aucune conséquence', 'Des pénalités et majorations', 'Une dissolution automatique', 'Un changement de nationalité'],
      1,
      'Le manquement aux obligations déclaratives ou de paiement expose à des pénalités et majorations.',
    ),
    _cas(
      'q-m1m3-5',
      'Une société omet délibérément de déclarer une partie de son chiffre d\'affaires pour réduire son imposition. Expliquez la qualification et les conséquences possibles.',
      const ['fraude fiscale', 'pénalités', 'poursuites'],
      'Une dissimulation volontaire de revenus imposables peut être qualifiée de fraude fiscale, exposant à pénalités et poursuites.',
    ),
  ],

  // --------------------------------------------------------------- M2 ----
  'm2-module-1': [
    _qcm(
      'q-m2m1-1',
      'Un acte uniforme OHADA, par rapport au droit national contraire :',
      const ['Lui est toujours inférieur', 'Lui est supérieur, y compris postérieur', 'N\'a aucun effet', 'Ne s\'applique qu\'aux sociétés cotées'],
      1,
      'Les actes uniformes priment sur le droit interne contraire, antérieur comme postérieur.',
    ),
    _qcm(
      'q-m2m1-2',
      'La CCJA est notamment compétente pour :',
      const ['Juger les crimes internationaux', 'Interpréter et appliquer les actes uniformes', 'Élire les chefs d\'État', 'Fixer les prix agricoles'],
      1,
      'La Cour commune de justice et d\'arbitrage est la juridiction suprême du contentieux des actes uniformes.',
    ),
    _qcm(
      'q-m2m1-3',
      'La CCJA remplace, pour son domaine de compétence :',
      const ['Les tribunaux de première instance', 'Les cours de cassation nationales', 'Les mairies', 'Les notaires'],
      1,
      'La CCJA se substitue aux cours de cassation nationales pour le contentieux des actes uniformes.',
    ),
    _qcm(
      'q-m2m1-4',
      'L\'objectif principal de l\'harmonisation OHADA est :',
      const ['Créer une monnaie unique', 'Sécuriser l\'investissement par un droit commun prévisible', 'Supprimer les juridictions nationales', 'Unifier les impôts'],
      1,
      'L\'harmonisation vise à sécuriser l\'investissement et faciliter les échanges par un droit des affaires commun et prévisible.',
    ),
    _cas(
      'q-m2m1-5',
      'Une juridiction nationale rend une décision contraire à l\'interprétation retenue par la CCJA sur un acte uniforme. Expliquez la portée de cette décision.',
      const ['CCJA juridiction suprême', 'interprétation uniforme', 'primauté'],
      'La CCJA étant la juridiction suprême pour l\'interprétation des actes uniformes, son interprétation prévaut sur celle des juridictions nationales.',
    ),
  ],
  'm2-module-2': [
    _qcm(
      'q-m2m2-1',
      'Dans une médiation, le médiateur :',
      const ['Impose une solution', 'Aide les parties à trouver leur propre solution', 'Rend une sentence', 'Représente l\'État'],
      1,
      'Le médiateur, tiers neutre, aide les parties à construire elles-mêmes une solution, sans la leur imposer.',
    ),
    _qcm(
      'q-m2m2-2',
      'Un accord de médiation homologué par le juge :',
      const ['Reste sans valeur', 'Acquiert force exécutoire', 'Devient une loi', 'Doit être renégocié chaque année'],
      1,
      'L\'homologation confère à l\'accord de médiation force exécutoire.',
    ),
    _qcm(
      'q-m2m2-3',
      'L\'arbitrage aboutit à :',
      const ['Un simple avis consultatif', 'Une sentence ayant autorité de chose jugée', 'Une loi', 'Un décret'],
      1,
      'La sentence arbitrale a l\'autorité de la chose jugée entre les parties.',
    ),
    _qcm(
      'q-m2m2-4',
      'La clause compromissoire est :',
      const [
        'Un accord conclu après la naissance du litige',
        'Une clause insérée dans le contrat, avant tout litige',
        'Une décision de justice',
        'Un acte notarié obligatoire',
      ],
      1,
      'La clause compromissoire est stipulée dans le contrat, avant la naissance de tout litige, contrairement au compromis.',
    ),
    _cas(
      'q-m2m2-5',
      'Deux entreprises souhaitent que tout litige futur découlant de leur contrat soit tranché rapidement et confidentiellement par des experts du secteur plutôt que par un tribunal étatique. Quel mécanisme leur convient et comment l\'organiser contractuellement ?',
      const ['arbitrage', 'clause compromissoire', 'confidentialité'],
      'L\'arbitrage, organisé par une clause compromissoire insérée au contrat, répond à ce besoin de célérité, de confidentialité et d\'expertise.',
    ),
  ],
  'm2-module-3': [
    _qcm(
      'q-m2m3-1',
      'Une bonne rédaction contractuelle doit notamment :',
      const ['Être la plus courte possible sans exception', 'Anticiper les hypothèses de défaillance', 'Éviter toute définition', 'Être rédigée oralement'],
      1,
      'Anticiper l\'exécution et les défaillances (clauses résolutoires, garanties) est un objectif clé de la rédaction contractuelle.',
    ),
    _qcm(
      'q-m2m3-2',
      'Un acte de procédure doit notamment respecter :',
      const ['Aucune forme particulière', 'Des mentions obligatoires à peine de nullité', 'Uniquement la langue orale', 'Le format d\'un contrat commercial'],
      1,
      'Les actes de procédure doivent respecter des mentions obligatoires et délais, à peine de nullité.',
    ),
    _qcm(
      'q-m2m3-3',
      'Un moyen de droit bien structuré articule :',
      const ['Uniquement des faits', 'Règle de droit, faits, conséquence juridique', 'Uniquement une opinion', 'Une citation sans lien avec l\'affaire'],
      1,
      'Un moyen efficace identifie la règle de droit, les faits qui s\'y rattachent, et la conséquence juridique tirée.',
    ),
    _qcm(
      'q-m2m3-4',
      'Une clause de garantie dans un acte de cession vise à :',
      const ['Réduire le prix automatiquement', 'Protéger le cessionnaire contre des passifs non révélés', 'Annuler la cession', 'Remplacer les statuts'],
      1,
      'La clause de garantie organise l\'indemnisation du cessionnaire en cas de passif ou vice non révélé lors de la cession.',
    ),
    _cas(
      'q-m2m3-5',
      'Un acte contractuel est rédigé de façon si détaillée qu\'il devient contradictoire et difficile à comprendre pour les parties elles-mêmes. Expliquez le principe de rédaction qui n\'a pas été respecté.',
      const ['équilibre exhaustivité lisibilité', 'lisibilité', 'contradictions internes'],
      'La rédaction doit rechercher l\'équilibre entre exhaustivité et lisibilité ; un acte trop touffu nuit à sa compréhension et peut receler des contradictions.',
    ),
  ],
};
